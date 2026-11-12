import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var spins = 0

    var body: some View {
        let t = store.t
        let monthTxs = store.txs(in: store.viewMonth)
        // clamp(340px, 53dvh, 470px)
        let heroHeight = min(max(340, metrics.height * 0.53), 470)

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                hero(t, height: heroHeight)
                actions(t).modifier(Rise(index: 4))
                HStack(alignment: .firstTextBaseline) {
                    Text(t.recent)
                        .ui(22, .semibold)
                        .tracking(-0.22)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Button(t.viewAll) { store.setTab(.tx) }
                        .buttonStyle(.plain)
                        .ui(16)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
                .modifier(Rise(index: 5))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(monthTxs.prefix(12)) { tx in
                            TxRow(tx: tx) { store.openSheet(.add(tx.type, editID: tx.id, prefill: nil)) }
                                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
                        }
                        if monthTxs.isEmpty {
                            EmptyList(t: t).modifier(Rise(index: 6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            ListFade(color: Palette.page)
        }
        .background(Palette.page)
    }

    // MARK: hero

    private func hero(_ t: Strings, height: CGFloat) -> some View {
        let pct = store.monthChangePct
        let w = metrics.width
        return ZStack(alignment: .top) {
            Palette.hero

            // soft light rising from the bottom edge (.hero::after)
            EllipticalGradient(colors: [Color(hex: 0x8CBEFF, opacity: 0.55), Color(hex: 0x8CBEFF, opacity: 0)],
                               center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                .frame(width: 1.103 * w, height: 0.772 * height)
                .position(x: w / 2, y: 1.02 * height)

            VStack(spacing: 0) {
                HStack {
                    Button { store.setTab(.settings) } label: { AvatarView(size: 46) }
                        .buttonStyle(PressStyle(scale: 0.92))
                        .accessibilityLabel(t.profile)
                    Spacer()
                    GlassCircleButton(icon: .bell, label: t.notifications, badge: pct < 0) {
                        store.openSheet(.notifications)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, metrics.top + 10)
                .modifier(Rise(index: 0))

                VStack(spacing: 0) {
                    Text(t.balance)
                        .ui(17)
                        .foregroundStyle(.white.opacity(0.78))
                        .modifier(Rise(index: 1))
                    MoneyView(value: store.balance, style: .balance(min(max(42, w * 0.13), 56)), countUp: true)
                        .padding(.top, 6)
                        .modifier(Rise(index: 2))
                    GlassChip {
                        Icon(pct >= 0 ? .trendingUp : .trendingDown, size: 14, stroke: 1.8)
                        Text(String(format: "%.2f%%", abs(pct)))
                            .font(AppFont.num(13.5, .regular))
                            .tracking(-0.27)
                            .environment(\.layoutDirection, .leftToRight)
                        Text(t.thisMonth)
                    }
                    .padding(.top, 12)
                    .modifier(Rise(index: 3))
                }
                .padding(.top, min(max(8, metrics.height * 0.025), 28))
                Spacer(minLength: 0)
            }

            CardStack()
                .frame(height: 150)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: height)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40, style: .circular))
    }

    // MARK: withdraw · swap · deposit

    private func actions(_ t: Strings) -> some View {
        GlassGroup {
            HStack(spacing: 8) {
                PillButton {
                    Haptic.tap()
                    store.openSheet(.add(.expense, editID: nil, prefill: nil))
                } label: {
                    Icon(.arrowUpRight, size: 20, stroke: 1.7)
                    Text(t.withdraw)
                }
                PillButton(width: 52) {
                    Haptic.tap()
                    spins += 1
                    store.cycleCurrency()
                } label: {
                    Icon(.arrowUpDown, size: 20, stroke: 1.7)
                        .rotationEffect(.degrees(Double(spins) * 180))
                        .animation(.framer(320, 22), value: spins)
                }
                .accessibilityLabel(t.currency)
                PillButton {
                    Haptic.tap()
                    store.openSheet(.add(.income, editID: nil, prefill: nil))
                } label: {
                    Icon(.arrowDownRight, size: 20, stroke: 1.7)
                    Text(t.deposit)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct EmptyList: View {
    let t: Strings

    var body: some View {
        VStack(spacing: 6) {
            Text(t.noTx).ui(16, .semibold).foregroundStyle(Palette.ink2)
            Text(t.noTxHint).ui(16).foregroundStyle(Palette.muted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }
}

/// The glass card stack in the hero. The front card shows one month's
/// spending; swipe it sideways to flick through months (it flies off and the
/// next one rises from behind). Tapping it opens Statistics.
struct CardStack: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var drag: CGFloat = 0
    @State private var dragging = false
    @State private var flyDir: CGFloat = 1
    @State private var shake = 0
    @State private var shown = false

    var body: some View {
        let w = metrics.width
        let key = store.viewMonth
        ZStack(alignment: .top) {
            backCard(width: w * 0.68, top: 30, visible: 26, opacity: 0.55, delay: 0.2)
            backCard(width: w * 0.78, top: 41, visible: 15, opacity: 0.75, delay: 0.14)
            ZStack {
                front(key)
                    .id(key)
                    .transition(.asymmetric(
                        insertion: .modifier(active: CardMotion(y: -14, scale: 0.9, opacity: 0),
                                             identity: CardMotion()),
                        removal: .modifier(active: CardMotion(x: flyDir * 340, rotation: flyDir * 14, opacity: 0),
                                           identity: CardMotion())
                    ))
            }
            .frame(width: w * 0.88, height: 140)
            .padding(.top, 54)
        }
        .frame(maxWidth: .infinity)
        .onAppear { shown = true }
    }

    private func backCard(width: CGFloat, top: CGFloat, visible: CGFloat, opacity: Double, delay: Double) -> some View {
        // only the strip that peeks above the front card is drawn
        let shape = RoundedRectangle(cornerRadius: 22, style: .circular)
        return shape
            .fill(.white.opacity(0.14))
            .overlay(shape.stroke(.white.opacity(0.26), lineWidth: 1))
            .frame(width: width, height: 120)
            .frame(height: visible, alignment: .top)
            .clipped()
            .opacity(shown ? opacity : 0)
            .offset(y: shown ? 0 : 60)
            .animation(.easeOutApp(0.5).delay(delay), value: shown)
            .padding(.top, top)
    }

    private func front(_ key: MonthKey) -> some View {
        let t = store.t
        let lang = store.settings.lang
        let spend = AppStore.sum(store.txs(in: key), .expense)
        let label = key.year == MonthKey.current.year
            ? DateText.monthName(key.month, lang, short: true)
            : "\(DateText.monthName(key.month, lang, short: true)) \(key.year)"

        return HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 18) {
                Text(t.monthSpend)
                    .ui(13.5)
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize()
                MoneyView(value: spend, style: MoneyStyle(size: 13.5, weight: .regular, color: .white.opacity(0.92), symSize: 12))
                    .opacity(0.85)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            Text(label)
                .font(AppFont.ui(16, lang == .en ? .heavy : .bold, lang))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .transformEffect(lang == .en ? CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: 3, ty: 0) : .identity)
        }
        .frame(height: 24)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shake) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            LinearKeyframe(-8, duration: 0.0875)
            LinearKeyframe(7, duration: 0.0875)
            LinearKeyframe(-4, duration: 0.0875)
            LinearKeyframe(0, duration: 0.0875)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .darkGlass(RoundedRectangle(cornerRadius: 22, style: .circular), fill: 0.18, interactive: true)
        .scaleEffect(dragging ? 1.02 : 1)
        .offset(x: drag)
        .onTapGesture { store.setTab(.stats) }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { v in
                    dragging = true
                    drag = v.translation.width * 0.7
                }
                .onEnded(end)
        )
        .animation(.framer(400, 30), value: dragging)
        .accessibilityHint(t.swipeHint)
    }

    private func end(_ v: DragGesture.Value) {
        dragging = false
        let dx = v.translation.width
        let vx = v.velocity.width
        let fast = abs(vx) > 450
        guard abs(dx) >= 60 || fast else {
            withAnimation(.framer(500, 35)) { drag = 0 }
            return
        }
        let right = (fast ? vx : dx) > 0
        // like turning pages: English swipe left for the next month, Arabic (RTL) swipe right
        let toNext = store.settings.lang == .ar ? right : !right
        if toNext && store.viewMonth >= .current {
            withAnimation(.framer(500, 35)) { drag = 0 }
            shake += 1 // no future months: small "nope" wiggle
            return
        }
        Haptic.tap()
        flyDir = right ? 1 : -1
        let next = store.viewMonth.shifted(by: toNext ? 1 : -1)
        // let the new fly direction reach the outgoing card before it leaves
        DispatchQueue.main.async {
            withAnimation(.framer(300, 30)) {
                drag = 0
                store.viewMonth = next
            }
        }
    }
}

/// Position / tilt / fade used by the month card's enter and exit.
struct CardMotion: ViewModifier {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scale: CGFloat = 1
    var rotation: Double = 0
    var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .opacity(opacity)
    }
}
