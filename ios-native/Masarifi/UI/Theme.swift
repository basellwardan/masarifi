import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// The Android build's design tokens (src/styles/tokens.css).
enum Palette {
    static let navy800 = Color(hex: 0x071A4A)
    static let blue600 = Color(hex: 0x1D56B0)
    static let teal400 = Color(hex: 0x3CC6D4)

    static let page = Color(hex: 0xF4F5F7)
    static let sheet = Color.white
    static let pill = Color(hex: 0xEBECEE)
    static let tile = Color(hex: 0xF4F4F6)
    static let iconBg = Color(hex: 0xEEEFF1)
    static let ink = Color(hex: 0x0B0B0C)
    static let ink2 = Color(hex: 0x2A2B2E)
    static let muted = Color(hex: 0x9B9CA1)
    static let muted2 = Color(hex: 0xB9BABE)
    static let danger = Color(hex: 0xD63C3C)
    static let iconInk = Color(hex: 0x6C6D72)
    static let rowIconInk = Color(hex: 0x55565B)
    static let tileIcon = Color(hex: 0x8D8E93)
    static let tabInk = Color(hex: 0x1C1D20)
    static let divider = Color(hex: 0xE7E8EB)
    static let grabber = Color(hex: 0xD9DADD)
    static let backdrop = Color(hex: 0x050F33, opacity: 0.45)

    /// Home hero
    static let hero = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x061541), location: 0),
            .init(color: Color(hex: 0x0A2463), location: 0.28),
            .init(color: Color(hex: 0x12408F), location: 0.58),
            .init(color: Color(hex: 0x2B69BF), location: 0.82),
            .init(color: Color(hex: 0x5D95DC), location: 1),
        ],
        startPoint: .top, endPoint: .bottom
    )

    /// Full-screen gradient (Transactions, Stats, Voice, Settings, Welcome, Splash)
    static let screen = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x061541), location: 0),
            .init(color: Color(hex: 0x0A2463), location: 0.38),
            .init(color: Color(hex: 0x12408F), location: 0.7),
            .init(color: Color(hex: 0x2763B9), location: 1),
        ],
        startPoint: .top, endPoint: .bottom
    )
}

/// Same easing the Android build uses everywhere (cubic-bezier(.22, 1, .36, 1)).
extension Animation {
    static func easeOutApp(_ duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    /// Framer Motion spring with the given stiffness/damping (mass 1).
    static func framer(_ stiffness: Double, _ damping: Double) -> Animation {
        .interpolatingSpring(mass: 1, stiffness: stiffness, damping: damping)
    }
}

// MARK: - Fonts (the APK's Inter + IBM Plex Sans Arabic, bundled)

enum AppFont {
    private static func interName(_ w: Font.Weight) -> String {
        if w == .heavy || w == .black { return "Inter-ExtraBold" }
        if w == .bold { return "Inter-Bold" }
        if w == .semibold { return "Inter-SemiBold" }
        if w == .medium { return "Inter-Medium" }
        return "Inter-Regular"
    }

    private static func plexName(_ w: Font.Weight) -> String {
        if w == .bold || w == .heavy || w == .black { return "IBMPlexSansArabic-Bold" }
        if w == .semibold { return "IBMPlexSansArabic-SemiBold" }
        if w == .medium { return "IBMPlexSansArabic-Medium" }
        return "IBMPlexSansArabic-Regular"
    }

    /// Text font: IBM Plex Sans Arabic in Arabic, Inter in English (like the CSS).
    static func ui(_ size: CGFloat, _ weight: Font.Weight, _ lang: Lang) -> Font {
        .custom(lang == .ar ? plexName(weight) : interName(weight), fixedSize: size)
    }

    /// Numbers always use Inter.
    static func num(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom(interName(weight), fixedSize: size)
    }
}

private struct LangKey: EnvironmentKey {
    static let defaultValue: Lang = .ar
}

/// Screen size and the system bars' insets, read once from the window.
struct Metrics: Equatable {
    var width: CGFloat = 393
    var height: CGFloat = 852
    var safeTop: CGFloat = 59
    var safeBottom: CGFloat = 34

    /// var(--safe-top) / var(--safe-bottom) from the Android CSS
    var top: CGFloat { max(safeTop, 28) }
    var bottom: CGFloat { max(safeBottom, 12) }

    static func current() -> Metrics {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.windows.first
        guard let window else { return Metrics() }
        return Metrics(width: window.bounds.width, height: window.bounds.height,
                       safeTop: window.safeAreaInsets.top, safeBottom: window.safeAreaInsets.bottom)
    }
}

private struct MetricsKey: EnvironmentKey {
    static let defaultValue = Metrics()
}

extension EnvironmentValues {
    var appLang: Lang {
        get { self[LangKey.self] }
        set { self[LangKey.self] = newValue }
    }

    var metrics: Metrics {
        get { self[MetricsKey.self] }
        set { self[MetricsKey.self] = newValue }
    }
}

private struct UIFontModifier: ViewModifier {
    @Environment(\.appLang) private var lang
    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(AppFont.ui(size, weight, lang))
    }
}

extension View {
    /// The app's text font at a fixed point size (no Dynamic Type, like the APK).
    func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> some View {
        modifier(UIFontModifier(size: size, weight: weight))
    }
}

// MARK: - Liquid Glass

@available(iOS 26.0, *)
private func glass(_ base: Glass, tint: Color?, interactive: Bool) -> Glass {
    var g = base
    if let tint { g = g.tint(tint) }
    if interactive { g = g.interactive() }
    return g
}

extension View {
    /// The APK's `.glass` (translucent white on the navy gradient) as Apple's
    /// clear Liquid Glass on iOS 26; the APK's own look before that.
    @ViewBuilder
    func darkGlass<S: Shape>(_ shape: S, fill: Double = 0.14, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(glass(.clear, tint: .white.opacity(fill * 0.5), interactive: interactive), in: shape)
        } else {
            self
                .background(shape.fill(.white.opacity(fill)))
                .overlay(shape.stroke(.white.opacity(0.26), lineWidth: 1))
        }
    }

    /// Light frosted glass (the floating tab bar).
    @ViewBuilder
    func barGlass<S: Shape>(_ shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(glass(.regular, tint: nil, interactive: true), in: shape)
        } else {
            self
                .background(shape.fill(Color(hex: 0xF0F1F4, opacity: 0.72)))
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.8), lineWidth: 1))
                .shadow(color: Color(hex: 0x071A4A, opacity: 0.12), radius: 15, y: 10)
        }
    }

    /// A solid APK pill (grey or black) that presses like Liquid Glass on iOS 26.
    @ViewBuilder
    func pillGlass<S: Shape>(_ shape: S, color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(shape.fill(color))
                .glassEffect(glass(.regular, tint: color, interactive: true), in: shape)
        } else {
            self.background(shape.fill(color))
        }
    }
}

/// Glass views placed together are drawn in one pass (GlassEffectContainer);
/// `spacing: 0` keeps neighbours as separate shapes like the APK.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

// MARK: - Press feedback (Framer's whileTap scale)

struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.framer(500, 30), value: configuration.isPressed)
    }
}

// MARK: - Haptics (Capacitor Haptics impact light / medium)

enum Haptic {
    private static let light: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private static let mediumGen: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    static func tap() { light.impactOccurred() }
    static func medium() { mediumGen.impactOccurred() }
}
