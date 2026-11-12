import SwiftUI
import UIKit

// MARK: - Money

/// How an amount is drawn: number font, muted fraction, smaller symbol.
struct MoneyStyle {
    var size: CGFloat
    var weight: Font.Weight = .medium
    var color: Color = Palette.ink
    /// nil = same as `color`
    var fracColor: Color? = nil
    var symSize: CGFloat? = nil
    var symColor: Color? = nil
    var symWeight: Font.Weight? = nil
    /// space between the number and the symbol
    var symGap: CGFloat? = nil

    /// Recent transactions / list rows (.tx-amount)
    static let row = MoneyStyle(size: 16, weight: .medium, symSize: 12, symColor: Palette.muted, symGap: 4)
    /// Statistics tiles (.tile-amount)
    static let tile = MoneyStyle(size: 18, weight: .medium, fracColor: Palette.muted, symSize: 11, symColor: Palette.muted, symGap: 4)
    /// Big amount in the white sheets (.big-amount)
    static func big(_ width: CGFloat) -> MoneyStyle {
        let size = min(max(36, width * 0.11), 46)
        return MoneyStyle(size: size, weight: .medium, fracColor: Palette.muted2, symSize: size * 0.4, symColor: Palette.muted, symGap: 6)
    }
    /// White balance on the gradients (.balance-amount)
    static func balance(_ size: CGFloat) -> MoneyStyle {
        MoneyStyle(size: size, weight: .semibold, color: .white, fracColor: .white.opacity(0.48),
                   symSize: size * 0.42, symColor: .white.opacity(0.7), symWeight: .medium, symGap: 6)
    }
    /// Inside a glass chip
    static let chip = MoneyStyle(size: 13.5, weight: .regular, color: .white.opacity(0.85))
}

/// One amount, laid out like the APK's Money component ("12,680" + ".42" + "ل.س").
/// It is a plain value view so SwiftUI can animate `value` (count-up).
struct MoneyLabel: View, Animatable {
    var value: Double
    let currency: CurrencyCode
    let rate: Double
    let lang: Lang
    let style: MoneyStyle
    var signed = false

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let p = Currency.parts(value, currency, rate: rate, lang: lang, signed: signed)
        let font = AppFont.num(style.size, style.weight)
        let track = -0.02 * style.size
        let number = Text(p.sign + (p.symbolFirst ? p.symbol : "") + p.int)
            .font(font).foregroundStyle(style.color).tracking(track)
            + Text(p.frac).font(font).foregroundStyle(style.fracColor ?? style.color).tracking(track)
        HStack(alignment: .firstTextBaseline, spacing: style.symGap ?? style.size * 0.3) {
            number
            if !p.symbolFirst {
                Text(p.symbol)
                    .font(AppFont.ui(style.symSize ?? style.size, style.symWeight ?? style.weight, lang))
                    .foregroundStyle(style.symColor ?? style.color)
            }
        }
        .lineLimit(1)
        .fixedSize()
        // amounts always read left-to-right, even in Arabic
        .environment(\.layoutDirection, .leftToRight)
    }
}

/// Money with the APK's motion: counts up from 0 when shown (`countUp`), and
/// slides sideways when the display currency changes.
struct MoneyView: View {
    @Environment(AppStore.self) private var store
    let value: Double
    var style: MoneyStyle
    var signed = false
    var countUp = false
    @State private var shown: Double = 0

    var body: some View {
        let s = store.settings
        let dx: CGFloat = s.lang == .ar ? -28 : 28
        ZStack {
            MoneyLabel(value: countUp ? shown : value, currency: s.currency, rate: s.usdRate,
                       lang: s.lang, style: style, signed: signed)
                .id(s.currency)
                .transition(.asymmetric(
                    insertion: .offset(x: dx).combined(with: .opacity),
                    removal: .offset(x: -dx).combined(with: .opacity)
                ))
        }
        .animation(.easeOutApp(0.28), value: s.currency)
        .onAppear {
            guard countUp else { return }
            withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.9)) { shown = value }
        }
        .onChange(of: value) {
            guard countUp else { return }
            withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.9)) { shown = value }
        }
    }
}

// MARK: - Avatar

struct AvatarView: View {
    @Environment(AppStore.self) private var store
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            if let data = store.profile.photo, let image = PhotoCache.image(data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Palette.teal400, Palette.blue600], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(initial)
                    .font(AppFont.ui(size * 0.4, .semibold, store.settings.lang))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 2))
    }

    private var initial: String {
        store.profile.name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "م"
    }
}

/// Decodes the avatar photo once instead of on every redraw.
enum PhotoCache {
    private static var last: (Data, UIImage)?

    static func image(_ data: Data) -> UIImage? {
        if let last, last.0 == data { return last.1 }
        guard let img = UIImage(data: data) else { return nil }
        last = (data, img)
        return img
    }
}

// MARK: - Glass pieces on the gradients

/// `.glass.glass-circle`: 46pt round glass button with a white icon.
struct GlassCircleButton: View {
    let icon: LucideIcon
    var label: String
    var badge = false
    let action: () -> Void
    @State private var shown = false

    var body: some View {
        Button(action: action) {
            Icon(icon, size: 20, stroke: 1.6)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .contentShape(Circle())
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle()
                            .fill(Color(hex: 0x3DDC84))
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color(hex: 0x0A2463, opacity: 0.9), lineWidth: 2))
                            .padding(.top, 11)
                            .padding(.trailing, 12)
                    }
                }
        }
        .buttonStyle(PressStyle(scale: 0.9))
        .darkGlass(Circle(), interactive: true)
        .scaleEffect(shown ? 1 : 0.8)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.framer(400, 30)) { shown = true } }
        .accessibilityLabel(label)
    }
}

/// `.glass.glass-chip`: small glass capsule with text.
struct GlassChip<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) { content }
            .ui(13.5)
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .darkGlass(Capsule())
    }
}

/// Back arrow + title + optional action (GradHeader).
struct GradHeader: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    var title: String?
    var action: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            GlassCircleButton(icon: store.settings.lang == .ar ? .arrowRight : .arrowLeft, label: "back") {
                store.setTab(.home)
            }
            Spacer(minLength: 0)
            if let title {
                Text(title)
                    .ui(18, .semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .modifier(Rise(index: 0, distance: -6))
            }
            Spacer(minLength: 0)
            if let action {
                action
            } else {
                Color.clear.frame(width: 46, height: 46)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, metrics.top + 10)
    }
}

// MARK: - Buttons on white

/// `.pill-btn`: 58pt capsule, grey (or black) with Liquid Glass press.
struct PillButton<Label: View>: View {
    var black = false
    var height: CGFloat = 58
    var width: CGFloat? = nil
    let action: () -> Void
    @ViewBuilder var label: Label

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) { label }
                .ui(16, .semibold)
                .foregroundStyle(black ? .white : Palette.ink)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .frame(width: width, height: height)
                .contentShape(Capsule())
        }
        .buttonStyle(PressStyle(scale: 0.96))
        .pillGlass(Capsule(), color: black ? .black : Palette.pill)
    }
}

/// `.chip.plain` toggle (filters, months).
struct ChipToggle: View {
    let title: String
    let on: Bool
    var fill = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ui(14, .medium)
                .lineLimit(1)
                .foregroundStyle(on ? .white : Palette.ink2)
                .padding(.horizontal, fill ? 0 : 18)
                .frame(maxWidth: fill ? .infinity : nil)
                .frame(height: 40)
                .background(Capsule().fill(on ? Color.black : Palette.pill))
                .contentShape(Capsule())
                .animation(.easeOutApp(0.25), value: on)
        }
        .buttonStyle(PressStyle(scale: 0.95))
    }
}

// MARK: - Transaction row

struct TxRow: View {
    @Environment(AppStore.self) private var store
    let tx: Tx
    var onTap: () -> Void
    @State private var drag: CGFloat = 0

    var body: some View {
        let t = store.t
        HStack(spacing: 14) {
            Icon(IconHints.icon(for: tx.note, type: tx.type), size: 20, stroke: 1.6)
                .foregroundStyle(Palette.iconInk)
                .frame(width: 44, height: 44)
                .background(Palette.iconBg, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.title(of: tx))
                    .ui(16, .medium)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(DateText.txDate(tx.date, t))
                    .ui(12.5)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            MoneyView(value: tx.type == .expense ? -tx.amount : tx.amount, style: .row)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .offset(x: drag)
        .onTapGesture {
            Haptic.tap()
            onTap()
        }
        // swipe sideways to delete (with Undo), like the Android row
        .gesture(HorizontalPan(onChanged: { dx in
            drag = dx * 0.5
        }, onEnded: { dx, _ in
            if abs(dx) > 110 {
                Haptic.medium()
                withAnimation(.easeOut(duration: 0.22)) {
                    if let removed = store.deleteTx(tx.id) {
                        store.showToast(t.deleted, undo: removed)
                    }
                }
            } else {
                withAnimation(.framer(500, 35)) { drag = 0 }
            }
        }))
    }
}

/// A horizontal pan that only starts when the finger moves sideways, so
/// vertical scrolling in the list is untouched (UIKit recognizer, iOS 18).
struct HorizontalPan: UIGestureRecognizerRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (_ dx: CGFloat, _ vx: CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ pan: UIPanGestureRecognizer, context: Context) {
        let dx = pan.translation(in: pan.view).x
        switch pan.state {
        case .began, .changed:
            onChanged(dx)
        case .ended, .cancelled, .failed:
            onEnded(dx, pan.velocity(in: pan.view).x)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let v = pan.velocity(in: pan.view)
            return abs(v.x) > abs(v.y) * 1.2
        }
    }
}

// MARK: - Motion helpers

/// The APK's "rise" entrance: fade in while moving up, staggered by index.
struct Rise: ViewModifier {
    var index: Int
    var distance: CGFloat = 18
    /// explicit start delay; default staggers by index
    var delay: Double? = nil
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : distance)
            .onAppear {
                withAnimation(.framer(200, 24).delay(delay ?? 0.05 + Double(index) * 0.06)) { shown = true }
            }
    }
}

/// White sheet with 32pt top corners (.white-sheet).
struct WhiteSheetShape: Shape {
    var radius: CGFloat = 32

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(topLeadingRadius: radius, topTrailingRadius: radius, style: .circular).path(in: rect)
    }
}

/// Fades the end of a list into the background (.list-fade).
struct ListFade: View {
    var color: Color

    var body: some View {
        LinearGradient(stops: [.init(color: color.opacity(0), location: 0), .init(color: color, location: 0.7)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: 150)
            .allowsHitTesting(false)
    }
}

/// Wraps chips onto centred lines (flex-wrap: wrap; justify-content: center).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(proposal.width ?? .infinity, subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in makeRows(bounds.width, subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for i in row.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func makeRows(_ maxWidth: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].items.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > maxWidth && !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].items.isEmpty
            rows[rows.count - 1].items.append(i)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows.filter { !$0.items.isEmpty }
    }
}

/// Black capsule above the tab bar, with an optional Undo.
struct ToastView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics

    var body: some View {
        ZStack {
            if let toast = store.toast {
                HStack(spacing: 14) {
                    Text(toast.message)
                    if let undo = toast.undo {
                        Button {
                            withAnimation(.framer(300, 30)) { store.restoreTx(undo) }
                            store.hideToast()
                        } label: {
                            Text(store.t.undo)
                                .font(AppFont.ui(14, .semibold, store.settings.lang))
                                .foregroundStyle(Color(hex: 0x8FC0FF))
                        }
                    }
                }
                .ui(14)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Capsule().fill(.black.opacity(0.88)))
                .id(toast.id)
                .transition(.asymmetric(
                    insertion: .offset(y: 20).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                    removal: .offset(y: 10).combined(with: .opacity).combined(with: .scale(scale: 0.97))
                ))
            }
        }
        .animation(.framer(380, 30), value: store.toast)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, metrics.bottom + 84)
        .allowsHitTesting(store.toast != nil)
    }
}

/// System share sheet, presented from UIKit so it works over our custom views.
enum ShareSheet {
    static func present(_ items: [Any]) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController else { return }
        var top = root
        while let next = top.presentedViewController { top = next }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = top.view
        top.present(vc, animated: true)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
