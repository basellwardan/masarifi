import SwiftUI

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

/// Colours from the reference screens.
enum Palette {
    static let navy = Color(hex: 0x071A4A)
    static let blue = Color(hex: 0x1D56B0)
    static let page = Color(hex: 0xF4F5F7)
    static let tile = Color(hex: 0xF4F4F6)
    static let ink = Color(hex: 0x0B0B0C)
    static let muted = Color(hex: 0x9B9CA1)

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

// MARK: - Liquid Glass

@available(iOS 26.0, *)
private func makeGlass(tint: Color?, interactive: Bool, clear: Bool) -> Glass {
    var glass: Glass = clear ? .clear : .regular
    if let tint { glass = glass.tint(tint) }
    if interactive { glass = glass.interactive() }
    return glass
}

extension View {
    /// Apple's Liquid Glass (iOS 26) in `shape`; Apple's frosted material before that.
    @ViewBuilder
    func liquidGlass<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = false, clear: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(makeGlass(tint: tint, interactive: interactive, clear: clear), in: shape)
        } else {
            self.background(clear ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial), in: shape)
        }
    }

    /// Morph identity for glass inside a `GlassGroup` (iOS 26).
    @ViewBuilder
    func glassID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// Several glass views that should read as one shape at rest (iOS 26).
    @ViewBuilder
    func glassUnion<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffectUnion(id: id, namespace: namespace)
        } else {
            self
        }
    }

    /// Apple's glass button style (iOS 26); bordered before that.
    @ViewBuilder
    func glassButton(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent { self.buttonStyle(.glassProminent) } else { self.buttonStyle(.glass) }
        } else {
            if prominent { self.buttonStyle(.borderedProminent) } else { self.buttonStyle(.bordered) }
        }
    }

    /// Tab bar shrinks while scrolling down and expands when scrolling up (iOS 26).
    @ViewBuilder
    func minimizeTabBarOnScroll() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }

    /// Soft scroll-edge effect under bars (iOS 26).
    @ViewBuilder
    func softScrollEdges() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }
}

/// Glass views placed together blend and morph into each other (Apple's
/// GlassEffectContainer, the "blend group"). Plain container before iOS 26.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

// MARK: - Money

/// Amount with a muted fraction ("12,680" + ".42") that rolls digit by digit
/// when it changes (numeric content transition).
struct MoneyText: View {
    @Environment(AppStore.self) private var store
    let value: Double
    var signed = false
    var size: CGFloat = 17
    var weight: Font.Weight = .medium
    var color: Color = Palette.ink
    var fracColor: Color = Palette.muted
    var symbolColor: Color = Palette.muted

    var body: some View {
        let p = Currency.parts(value, store.settings.currency, rate: store.settings.usdRate,
                               lang: store.settings.lang, signed: signed)
        let font = Font.system(size: size, weight: weight)
        let symFont = Font.system(size: max(11, size * 0.42), weight: .medium)
        // keep "-1,234.50" left-to-right inside Arabic text (LRI … PDI)
        let number = Text("\u{2066}\(p.sign)\(p.symbolFirst ? p.symbol : "")\(p.int)").font(font).foregroundStyle(color)
            + Text(p.frac).font(font).foregroundStyle(fracColor)
            + Text("\u{2069}")
        let symbol = p.symbolFirst ? Text("") : Text(" \(p.symbol)").font(symFont).foregroundStyle(symbolColor)
        return (number + symbol)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(value: value))
    }
}

// MARK: - Avatar

struct AvatarView: View {
    @Environment(AppStore.self) private var store
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let data = store.profile.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                let initial = store.profile.name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "م"
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x3CC6D4), Palette.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(initial).font(.system(size: size * 0.42, weight: .semibold)).foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Haptics

enum Haptic {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }
}
