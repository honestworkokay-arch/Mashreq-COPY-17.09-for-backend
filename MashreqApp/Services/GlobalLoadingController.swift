import Lottie
import Network
import Observation
import SwiftUI
import UIKit

/// Единый таймлайн loader: overlay нельзя закрыть раньше полного цикла Lottie.
private enum LoadingTimeline {
    static let fullAnimationCycle: TimeInterval = 2.0
}

/// Единый источник состояния loader для всего приложения.
/// Причины независимы: завершение навигации не скроет offline-overlay и наоборот.
@MainActor
@Observable
final class GlobalLoadingController {
    enum Reason: Hashable {
        case navigation
        case connectivity
        case operation(UUID)
    }

    private(set) var activeReasons: Set<Reason> = []
    private(set) var isNavigationInProgress = false

    var isPresented: Bool {
        !activeReasons.isEmpty
    }

    private let minimumDisplayDuration: TimeInterval
    private let navigationLeadDuration: UInt64
    private let navigationWatchdogDuration: UInt64
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.madina.mashreqdemo.connectivity")

    private var shownAt: Date?
    private var reasonGenerations: [Reason: UInt64] = [:]
    private var navigationTask: Task<Void, Never>?
    private var navigationFinishTask: Task<Void, Never>?

    init(
        minimumDisplayDuration: TimeInterval = LoadingTimeline.fullAnimationCycle,
        navigationLeadDuration: TimeInterval = 0.09,
        navigationWatchdogDuration: TimeInterval = 2.0,
        monitorsConnectivity: Bool = true
    ) {
        self.minimumDisplayDuration = minimumDisplayDuration
        self.navigationLeadDuration = Self.nanoseconds(navigationLeadDuration)
        self.navigationWatchdogDuration = Self.nanoseconds(navigationWatchdogDuration)

        if monitorsConnectivity {
            startConnectivityMonitoring()
        }
    }

    deinit {
        pathMonitor.cancel()
    }

    /// Защищённый navigation push: повторный tap игнорируется до появления destination.
    @discardableResult
    func performNavigation(_ mutation: @escaping @MainActor () -> Void) -> Bool {
        guard !isNavigationInProgress else { return false }

        isNavigationInProgress = true
        let generation = show(.navigation)

        navigationTask?.cancel()
        navigationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Короткая пауза даёт overlay успеть проявиться до изменения path.
            try? await Task.sleep(nanoseconds: navigationLeadDuration)
            guard !Task.isCancelled else { return }
            mutation()

            // Страховка от зависшего состояния, если destination по какой-либо причине не появился.
            try? await Task.sleep(nanoseconds: navigationWatchdogDuration)
            guard !Task.isCancelled else { return }
            await hide(.navigation, generation: generation)
            releaseNavigationLock(generation: generation)
        }

        return true
    }

    /// Вызывается централизованно root-контейнером, когда новый экран реально появился.
    func destinationDidAppear() {
        guard isNavigationInProgress,
              let generation = reasonGenerations[.navigation]
        else { return }

        navigationTask?.cancel()
        navigationFinishTask?.cancel()
        navigationFinishTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await hide(.navigation, generation: generation)
            releaseNavigationLock(generation: generation)
        }
    }

    /// Универсальная точка расширения для будущей async/API-операции без API-слоёв сейчас.
    func perform<T>(_ operation: @escaping @MainActor () async throws -> T) async rethrows -> T {
        let reason = Reason.operation(UUID())
        let generation = show(reason)

        do {
            let result = try await operation()
            await hide(reason, generation: generation)
            return result
        } catch {
            await hide(reason, generation: generation)
            throw error
        }
    }

#if DEBUG
    /// Используется только автоматической runtime-проверкой и отсутствует в Release.
    func presentForQualityAssurance(duration: TimeInterval = 18) {
        let reason = Reason.operation(UUID())
        let generation = show(reason)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Self.nanoseconds(duration))
            await self?.hide(reason, generation: generation)
        }
    }
#endif

    /// Отдельный reason позволяет корректно пережить смену Wi-Fi на Cellular.
    /// Overlay появляется только при реальном `.unsatisfied`.
    private func applyConnectivityStatus(_ status: NWPath.Status) {
        switch status {
        case .unsatisfied:
            _ = show(.connectivity)
        case .satisfied:
            guard let generation = reasonGenerations[.connectivity] else { return }
            Task { @MainActor [weak self] in
                await self?.hide(.connectivity, generation: generation)
            }
        case .requiresConnection:
            // Это не подтверждённый offline: сохраняем текущее состояние без ложного overlay.
            break
        @unknown default:
            break
        }
    }

    @discardableResult
    private func show(_ reason: Reason) -> UInt64 {
        let nextGeneration = (reasonGenerations[reason] ?? 0) &+ 1
        reasonGenerations[reason] = nextGeneration

        if activeReasons.isEmpty {
            shownAt = Date()
        }
        activeReasons.insert(reason)
        return nextGeneration
    }

    private func hide(_ reason: Reason, generation: UInt64) async {
        guard activeReasons.contains(reason) else { return }

        if let shownAt {
            let elapsed = Date().timeIntervalSince(shownAt)
            let remaining = minimumDisplayDuration - elapsed
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: Self.nanoseconds(remaining))
            }
        }

        // Если reason повторно активировался во время ожидания, старое hide его не снимает.
        guard reasonGenerations[reason] == generation else { return }
        activeReasons.remove(reason)
        reasonGenerations[reason] = nil

        if activeReasons.isEmpty {
            shownAt = nil
        }
    }

    private func releaseNavigationLock(generation: UInt64) {
        guard reasonGenerations[.navigation] == nil || reasonGenerations[.navigation] == generation else {
            return
        }
        isNavigationInProgress = false
        navigationTask = nil
        navigationFinishTask = nil
    }

    private func startConnectivityMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let status = path.status
            Task { @MainActor [weak self] in
                self?.applyConnectivityStatus(status)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    private nonisolated static func nanoseconds(_ seconds: TimeInterval) -> UInt64 {
        UInt64(max(0, seconds) * 1_000_000_000)
    }
}

/// Единственный fullscreen-overlay. Пока он в иерархии, его фон принимает все touch-события.
struct GlobalLoadingOverlay: View {
    // По замеру видео белый veil даёт #FEEFE3 над оранжевым header и чистый white над body.
    private let overlayOpacity = 0.90
    // Замер в одинаковом масштабе: 137×65 px в референсе против 129×60 px при 92 pt.
    private let animationWidth: CGFloat = 98
    private let animationOffset = CGSize(width: 7, height: 2)
    private let animationAspectRatio: CGFloat = 1500 / 722

    var body: some View {
        ZStack {
            Color.white
                .opacity(overlayOpacity)

            MashreqBloomAnimationView()
                .frame(width: animationWidth, height: animationWidth / animationAspectRatio)
                .offset(x: animationOffset.width, y: animationOffset.height)
                .clipped()
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
        .accessibilityIdentifier("global-loading-overlay")
    }
}

/// Нативный SwiftUI-компонент Lottie использует исходный JSON без перерисовки и изменения файла.
private struct MashreqBloomAnimationView: View {
    /// Исходный JSON и видео работают в одном темпе: 60 кадров при 30 fps.
    private let playbackSpeed = 1.0

    var body: some View {
        LottieView(animation: .named("mashreq_bloom"))
            .configure { view in
                view.backgroundBehavior = .pauseAndRestore
                view.contentMode = .scaleAspectFit
                view.clipsToBounds = true
                view.maskAnimationToBounds = true

                // JSON содержит служебный BG. Скрываем только слой фона во время рендера,
                // чтобы полупрозрачность определялась единым fullscreen-overlay.
                view.setValueProvider(
                    FloatValueProvider(0),
                    keypath: AnimationKeypath(keypath: "BG.Transform.Opacity")
                )
            }
            .resizable()
            .playing(loopMode: .loop)
            .animationSpeed(playbackSpeed)
            .clipped()
    }
}
