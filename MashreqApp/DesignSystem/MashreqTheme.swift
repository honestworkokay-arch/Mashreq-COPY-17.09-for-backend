import SwiftUI

// MARK: - Цвета и размеры, измеренные по референсам Mashreq

enum MashreqTheme {
    static let orange = Color(hex: 0xFF5F00)
    static let orangeDeep = Color(hex: 0xE54D00)
    static let orangeMid = Color(hex: 0xFF6B00)
    static let orangeLight = Color(hex: 0xFFA719)
    static let orangeSoft = Color(hex: 0xFFF1E6)
    static let orangeWash = Color(hex: 0xFFF6EE)
    static let ink = Color(hex: 0x1C1C1E)
    static let bodyInk = Color(hex: 0x2C2C2E)
    static let secondaryInk = Color(hex: 0x858589)
    static let line = Color(hex: 0xECECEC)
    static let sectionBackground = Color(hex: 0xF8F9FD)
    static let fieldBackground = Color(hex: 0xFBFBFD)
    static let helpBackground = Color(hex: 0xFFF3DD)
    static let helpIcon = Color(hex: 0xB26B25)
    static let canvas = Color(hex: 0xF7F7F8)
    static let success = Color(hex: 0x34C759)
    static let faceIDGreen = Color(hex: 0x61E66B)
    static let error = Color(hex: 0xB4232F)

    static let horizontalPadding: CGFloat = 22
    static let sectionGap: CGFloat = 24
    static let fieldGap: CGFloat = 28
    static let cardInset: CGFloat = 16
    static let cardRadius: CGFloat = 8
    static let buttonHeight: CGFloat = 60

    static let headerGradient = LinearGradient(
        stops: [
            .init(color: orange, location: 0),
            .init(color: orangeMid, location: 0.58),
            .init(color: orangeLight, location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 29LT Bukra

/// Все пять начертаний, выгруженных с Mashreq, подключены отдельными файлами.
/// Системный synthetic bold отключён самим выбором точного PostScript-имени.
enum MashreqFontWeight {
    case light
    case regular
    case medium
    case semibold
    case bold

    var postScriptName: String {
        switch self {
        case .light: "29LTBukra-Light"
        case .regular: "29LTBukra-Regular"
        case .medium: "29LTBukra-Medium"
        case .semibold: "29LTBukra-SemiBold"
        case .bold: "29LTBukra-Bold"
        }
    }
}

/// Единая шкала размеров, измеренная по присланным мобильным референсам.
enum MashreqTextSize {
    static let nano: CGFloat = 9
    static let micro: CGFloat = 10
    static let caption: CGFloat = 11
    static let meta: CGFloat = 12
    static let bodySmall: CGFloat = 13
    static let copy: CGFloat = 14
    static let label: CGFloat = 15
    static let titleSmall: CGFloat = 16
    static let title: CGFloat = 17
    static let headline: CGFloat = 18
    static let section: CGFloat = 20
    static let sectionLarge: CGFloat = 21
    static let displaySmall: CGFloat = 23
    static let display: CGFloat = 28
}

extension Font {
    /// Нативный 29LT Bukra с фиксированным размером для screenshot-accurate верстки.
    static func mashreq(size: CGFloat, weight: MashreqFontWeight = .light) -> Font {
        .custom(weight.postScriptName, fixedSize: size).leading(.tight)
    }
}

extension Color {
    /// Позволяет хранить фирменные цвета в одном месте в шестнадцатеричном виде.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension View {
    /// Единая тень белых карточек из исходных экранов.
    func mashreqCardShadow() -> some View {
        shadow(color: .black.opacity(0.10), radius: 11, x: 0, y: 6)
    }
}

/// Неглубокая дуга повторяет фирменную нижнюю границу оранжевой шапки.
struct MashreqHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 18))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 18),
            control: CGPoint(x: rect.midX, y: rect.maxY + 8)
        )
        path.closeSubpath()
        return path
    }
}

/// Почти плоская нижняя дуга компактных flow-header.
/// В отличие от высокой дуги главных экранов, здесь центр ниже краёв всего на несколько pt.
struct MashreqFlowHeaderShape: Shape {
    let curveDepth: CGFloat

    func path(in rect: CGRect) -> Path {
        let safeDepth = max(0, min(curveDepth, rect.height / 2))
        let edgeY = rect.maxY - safeDepth

        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: edgeY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: edgeY),
            control: CGPoint(x: rect.midX, y: rect.maxY + safeDepth)
        )
        path.closeSubpath()
        return path
    }
}
