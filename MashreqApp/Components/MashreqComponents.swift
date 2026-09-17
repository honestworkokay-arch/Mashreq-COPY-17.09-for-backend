import SwiftUI

/// Общий источник scroll-offset для экранов с исчезающим Mashreq header.
/// Маркер имеет реальную высоту 1 pt: в отличие от zero-height GeometryReader
/// SwiftUI не оптимизирует его и стабильно сообщает движение во время жеста.
struct MashreqScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MashreqScrollOffsetReader: View {
    let coordinateSpace: String

    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: MashreqScrollOffsetPreferenceKey.self,
                value: geometry.frame(in: .named(coordinateSpace)).minY
            )
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}

/// Единый трекер прокрутки для всех исчезающих Mashreq-хедеров.
/// На iOS 18+ читаем настоящий contentOffset самого ScrollView; на iOS 17
/// сохраняем совместимый GeometryReader-вариант с нормализацией стартовой точки.
private struct MashreqScrollOffsetTrackingModifier: ViewModifier {
    @Binding var scrollOffset: CGFloat
    let coordinateSpace: String

    @State private var legacyRestingMinY: CGFloat?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .coordinateSpace(name: coordinateSpace)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    // В состоянии покоя contentOffset равен -contentInsets.top.
                    // Сумма даёт ровно 0, а при движении вверх — реальные pt жеста.
                    max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                } action: { _, newOffset in
                    scrollOffset = newOffset
                }
        } else {
            content
                .coordinateSpace(name: coordinateSpace)
                .onPreferenceChange(MashreqScrollOffsetPreferenceKey.self) { markerMinY in
                    // Стартовая координата зависит от safe area и NavigationStack,
                    // поэтому запоминаем её вместо ошибочного предположения minY == 0.
                    let restingMinY = legacyRestingMinY ?? markerMinY
                    if legacyRestingMinY == nil {
                        legacyRestingMinY = markerMinY
                    }
                    scrollOffset = max(0, restingMinY - markerMinY)
                }
        }
    }
}

extension View {
    /// Подключается непосредственно к ScrollView и возвращает положительный
    /// scroll-offset в pt: 0 — верх экрана, больше 0 — контент движется вверх.
    func mashreqTrackScrollOffset(
        _ scrollOffset: Binding<CGFloat>,
        coordinateSpace: String
    ) -> some View {
        modifier(
            MashreqScrollOffsetTrackingModifier(
                scrollOffset: scrollOffset,
                coordinateSpace: coordinateSpace
            )
        )
    }
}

struct MashreqHeader<Content: View>: View {
    let title: String?
    let height: CGFloat
    let showsBack: Bool
    let usesReferenceBackground: Bool
    let titleFontSize: CGFloat
    let titleFontWeight: MashreqFontWeight
    let titleOffsetY: CGFloat
    let referenceBottomCurveDepth: CGFloat
    let referenceBackAssetName: String
    let referenceBackOffsetY: CGFloat
    let onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    init(
        title: String? = nil,
        height: CGFloat = 210,
        showsBack: Bool = false,
        usesReferenceBackground: Bool = false,
        titleFontSize: CGFloat = 16,
        titleFontWeight: MashreqFontWeight = .regular,
        titleOffsetY: CGFloat = 0,
        referenceBottomCurveDepth: CGFloat = 0,
        referenceBackAssetName: String = "ReferenceFlowBack",
        referenceBackOffsetY: CGFloat = 0,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.height = height
        self.showsBack = showsBack
        self.usesReferenceBackground = usesReferenceBackground
        self.titleFontSize = titleFontSize
        self.titleFontWeight = titleFontWeight
        self.titleOffsetY = titleOffsetY
        self.referenceBottomCurveDepth = referenceBottomCurveDepth
        self.referenceBackAssetName = referenceBackAssetName
        self.referenceBackOffsetY = referenceBackOffsetY
        self.onBack = onBack
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if usesReferenceBackground {
                    // Точный градиент из референса. Дополнительные 10 pt уходят
                    // под обрезку и полностью скрывают белую полосу исходного кадра.
                    GeometryReader { proxy in
                        Image("ReferenceFlowHeaderBackground")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: height + 10, alignment: .top)
                            .clipped()
                    }
                    .frame(height: height)
                    .clipShape(
                        MashreqFlowHeaderShape(curveDepth: referenceBottomCurveDepth)
                    )
                } else {
                    MashreqHeaderShape()
                        .fill(MashreqTheme.headerGradient)
                        .frame(height: height)
                }
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 14) {
                HStack {
                    if showsBack {
                        Button { onBack?() ?? dismiss() } label: {
                            Group {
                                if usesReferenceBackground {
                                    Image(referenceBackAssetName)
                                        .resizable()
                                        .interpolation(.high)
                                        .scaledToFit()
                                } else {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 22, weight: .regular))
                                        .foregroundStyle(.white)
                                }
                            }
                                .frame(width: 44, height: 44)
                                .offset(y: referenceBackOffsetY)
                        }
                        .accessibilityLabel("Back")
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }

                    Spacer()
                    if let title {
                        Text(title)
                            .font(.mashreq(size: titleFontSize, weight: titleFontWeight))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .offset(y: titleOffsetY)
                    }
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)

                content()
            }
        }
        .frame(height: height)
    }
}

/// Единый sheet для безопасного выхода из уже начатой формы.
struct UnsavedProgressSheet: View {
    /// Высота измерена по второму референсу: верх sheet находится примерно
    /// на 56% высоты экрана iPhone, при этом нижняя safe area включена.
    static let referenceHeight: CGFloat = 374

    let onExit: () -> Void
    let onStay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xD6D6D6))
                .frame(width: 48, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            ZStack {
                WarningTriangleShape().fill(Color(hex: 0xFF9F19))
                Text("!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: 4)
            }
            .frame(width: 48, height: 44)
            .padding(.top, 25)

            Text("You will lose all progress")
                .font(.mashreq(size: 24, weight: .semibold))
                .padding(.top, 18)

            Text("Do you want to exit?")
                .font(.mashreq(size: 19, weight: .regular))
                .padding(.top, 16)

            Spacer(minLength: 25)

            MashreqOutlineButton(title: "I want to exit", action: onExit)
            MashreqPrimaryButton(title: "Stay on this screen", action: onStay)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.ignoresSafeArea())
    }
}

/// Общий стиль прикладных sheet: контейнер занимает всю доступную ширину,
/// а системный внешний радиус не оставляет белых просветов по краям.
extension View {
    func mashreqFullWidthSheet(
        height: CGFloat? = nil,
        dragIndicator: Visibility = .hidden
    ) -> some View {
        modifier(
            MashreqFullWidthSheetModifier(
                height: height,
                dragIndicator: dragIndicator
            )
        )
    }
}

private struct MashreqFullWidthSheetModifier: ViewModifier {
    let height: CGFloat?
    let dragIndicator: Visibility

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            detentedContent(content)
                .presentationSizing(.page)
        } else {
            detentedContent(content)
        }
    }

    @ViewBuilder
    private func detentedContent<SheetContent: View>(_ content: SheetContent) -> some View {
        if let height {
            styledContent(content)
                .presentationDetents([.height(height)])
        } else {
            styledContent(content)
        }
    }

    private func styledContent<SheetContent: View>(_ content: SheetContent) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .presentationDragIndicator(dragIndicator)
            .presentationCornerRadius(0)
            .presentationBackground(Color.white)
    }
}

/// Нижний Mashreq-sheet без системных горизонтальных inset. Контейнер
/// рисуется внутри полного viewport и всегда касается обоих краёв экрана.
extension View {
    func mashreqEdgeToEdgeBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: CGFloat,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            MashreqEdgeToEdgeBooleanSheetModifier(
                isPresented: isPresented,
                height: height,
                sheetContent: content
            )
        )
    }

    func mashreqEdgeToEdgeBottomSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        height: @escaping (Item) -> CGFloat,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            MashreqEdgeToEdgeItemSheetModifier(
                item: item,
                height: height,
                sheetContent: content
            )
        )
    }
}

private struct MashreqEdgeToEdgeBooleanSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let height: CGFloat
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                MashreqEdgeToEdgeSheetLayer(height: height, content: sheetContent)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.22), value: isPresented)
    }
}

private struct MashreqEdgeToEdgeItemSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let height: (Item) -> CGFloat
    @ViewBuilder let sheetContent: (Item) -> SheetContent

    func body(content: Content) -> some View {
        content.overlay {
            if let item {
                MashreqEdgeToEdgeSheetLayer(height: height(item)) {
                    sheetContent(item)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.22), value: item?.id)
    }
}

private struct MashreqEdgeToEdgeSheetLayer<SheetContent: View>: View {
    let height: CGFloat
    @ViewBuilder let content: () -> SheetContent

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            content()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAddTraits(.isModal)
    }
}

private struct WarningTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct MashreqBottomBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(tab.assetName(isActive: selection == tab))
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text(tab.rawValue)
                            .font(.mashreq(size: MashreqTextSize.micro, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? MashreqTheme.orange : MashreqTheme.secondaryInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                }
                .accessibilityIdentifier("tab-\(tab.rawValue.lowercased())")
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
        .background(.white)
        .overlay(alignment: .top) { Divider() }
    }
}

struct MashreqPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: MashreqTheme.buttonHeight)
                .background(MashreqTheme.orange)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: MashreqTheme.orange.opacity(0.22), radius: 5, y: 3)
        }
        .accessibilityIdentifier(title.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
}

struct MashreqOutlineButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mashreq(size: MashreqTextSize.copy, weight: .medium))
                .foregroundStyle(MashreqTheme.orange)
                .frame(maxWidth: .infinity)
                .frame(height: MashreqTheme.buttonHeight)
                .background(.white)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(MashreqTheme.orange, lineWidth: 1.5))
        }
    }
}

struct PanelCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(MashreqTheme.cardInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: MashreqTheme.cardRadius))
            .mashreqCardShadow()
    }
}

struct ActionIcon: View {
    let systemName: String
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(MashreqTheme.orangeSoft).frame(width: 40, height: 40)
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(MashreqTheme.orange)
            }
            Text(title)
                .font(.mashreq(size: MashreqTextSize.micro, weight: .medium))
                .foregroundStyle(MashreqTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Иконка действия из точного растрового референса, без SF Symbols.
struct ReferenceActionIcon: View {
    let assetName: String
    let title: String
    var iconSize: CGFloat = 44
    var preservesExplicitLineBreaks = false

    var body: some View {
        VStack(spacing: 6) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)

            Text(title)
                .font(.mashreq(size: MashreqTextSize.micro, weight: .medium))
                .foregroundStyle(MashreqTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                // Для подписей с заданным референсом переносом запрещаем
                // вертикальное сжатие, иначе последняя строка может исчезнуть.
                .fixedSize(horizontal: false, vertical: preservesExplicitLineBreaks)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UAEFlagView: View {
    var size: CGFloat = 48

    var body: some View {
        Image("UAEFlag")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityLabel("UAE")
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(transaction.reference)
                    .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
                Spacer()
                Text(transaction.amount)
                    .font(.mashreq(size: MashreqTextSize.label, weight: .semibold))
            }
            HStack {
                Text(transaction.title)
                    .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .regular))
                Spacer()
                if transaction.isProcessing {
                    Text("Processing")
                        .font(.mashreq(size: MashreqTextSize.caption, weight: .medium))
                        .foregroundStyle(MashreqTheme.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(MashreqTheme.orangeSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            Text("\(transaction.merchant)     \(transaction.location)")
                .font(.mashreq(size: MashreqTextSize.micro, weight: .light))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .lineLimit(2)
            Divider().padding(.top, 8)
        }
        .padding(.vertical, 12)
    }
}

struct SectionTitle: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.mashreq(size: MashreqTextSize.headline, weight: .semibold))
                .foregroundStyle(MashreqTheme.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.mashreq(size: MashreqTextSize.meta, weight: .semibold))
                    .foregroundStyle(MashreqTheme.orange)
            }
        }
    }
}

struct ProgressLine: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.28)).frame(height: 4)
                Capsule().fill(.white).frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}
