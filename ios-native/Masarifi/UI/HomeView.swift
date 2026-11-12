import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID
    @State private var spins = 0
    @State private var pastHero = false

    var body: some View {
        let t = store.t
        let monthTxs = store.txs(in: store.viewMonth)
        let pct = store.monthChangePct

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero(t, pct: pct)
                    actions(t)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    recent(t, Array(monthTxs.prefix(8)))
                        .padding(.top, 28)
                }
                .padding(.bottom, 24)
                .background(Palette.grouped)
            }
            .background {
                // navy behind the bars and when pulling down, grey further down
                VStack(spacing: 0) {
                    Palette.heroTop
                    Palette.grouped
                }
                .ignoresSafeArea()
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .onScrollGeometryChange(for: Bool.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top > 300
            } action: { _, past in
                pastHero = past
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { store.setTab(.settings) } label: {
                        AvatarView(size: 32)
                    }
                    .accessibilityLabel(t.profile)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.openSheet(.notifications, from: "notifications")
                    } label: {
                        Image(systemName: pct < 0 ? "bell.badge" : "bell")
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.wiggle, options: .nonRepeating, value: pct < 0)
                    }
                    .accessibilityLabel(t.notifications)
                }
                .matchedTransitionSource(id: "notifications", in: zoom)
            }
            .toolbarColorScheme(pastHero ? nil : .dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: hero

    private func hero(_ t: Strings, pct: Double) -> some View {
        VStack(spacing: 0) {
            Text(t.balance)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.75))
            MoneyText(store.balance, size: 52, weight: .bold, relativeTo: .largeTitle)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.top, 4)
            GlassChip {
                Image(systemName: pct >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                    .environment(\.layoutDirection, .leftToRight)
                Text(String(format: "%.2f%%", abs(pct)))
                    .monospacedDigit()
                    .environment(\.layoutDirection, .leftToRight)
                Text(t.thisMonth)
            }
            .padding(.top, 12)
            CardStack()
                .frame(height: 150)
                .padding(.top, 28)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .background(Palette.hero)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36, style: .continuous))
    }

    // MARK: withdraw · swap · deposit (one glass blend group)

    private func actions(_ t: Strings) -> some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    Haptic.tap()
                    store.openSheet(.add(.expense, editID: nil, prefill: nil), from: "add-expense")
                } label: {
                    Label(t.withdraw, systemImage: "arrow.up.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .matchedTransitionSource(id: "add-expense", in: zoom)

                Button {
                    Haptic.tap()
                    spins += 1
                    store.cycleCurrency()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.headline)
                        .symbolEffect(.rotate, value: spins)
                }
                .accessibilityLabel(t.swap)

                Button {
                    Haptic.tap()
                    store.openSheet(.add(.income, editID: nil, prefill: nil), from: "add-income")
                } label: {
                    Label(t.deposit, systemImage: "arrow.down.left")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .matchedTransitionSource(id: "add-income", in: zoom)
            }
            .buttonStyle(.glass)
            .controlSize(.extraLarge)
            .foregroundStyle(.primary)
        }
    }

    // MARK: recent transactions (inset grouped card)

    private func recent(_ t: Strings, _ items: [Tx]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(t.recent).font(.title2.weight(.bold))
                Spacer()
                Button(t.viewAll) { store.setTab(.tx) }
                    .font(.body)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                if items.isEmpty {
                    ContentUnavailableView(t.noTx, systemImage: "tray", description: Text(t.noTxHint))
                        .padding(.vertical, 8)
                }
                ForEach(Array(items.enumerated()), id: \.element.id) { i, tx in
                    Button {
                        store.openSheet(.add(tx.type, editID: tx.id, prefill: nil), from: "home-\(tx.id)")
                    } label: {
                        TxRow(tx: tx)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: "home-\(tx.id)", in: zoom)
                    .contextMenu { TxMenu(tx: tx, source: "home-\(tx.id)") }
                    .transition(.opacity)
                    if i < items.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Palette.card, in: .rect(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 16)
        }
    }
}

/// The glass card stack in the hero. The front card shows one month's
/// spending; swipe it sideways to flick through months (it flies off and the
/// next one rises from behind). Tapping it opens Statistics.
struct CardStack: View {
    @Environment(AppStore.self) private var store
    @State private var drag: CGFloat = 0
    @State private var dragging = false
    @State private var flyDir: CGFloat = 1
    @State private var shake = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .top) {
                strip(width: w * 0.68, top: 0, visible: 26, opacity: 0.55)
                strip(width: w * 0.78, top: 11, visible: 15, opacity: 0.75)
                ZStack {
                    front(store.viewMonth)
                        .id(store.viewMonth)
                        .transition(.asymmetric(
                            insertion: .modifier(active: CardMotion(y: -14, scale: 0.9, opacity: 0), identity: CardMotion()),
                            removal: .modifier(active: CardMotion(x: flyDir * 340, rotation: flyDir * 14, opacity: 0), identity: CardMotion())
                        ))
                }
                .frame(width: w * 0.88, height: 130)
                .padding(.top, 24)
            }
            .frame(width: w)
        }
    }

    private func strip(width: CGFloat, top: CGFloat, visible: CGFloat, opacity: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return shape
            .fill(.white.opacity(0.14))
            .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 1))
            .frame(width: width, height: 100)
            .frame(height: visible, alignment: .top)
            .clipped()
            .opacity(opacity)
            .padding(.top, top)
    }

    private func front(_ key: MonthKey) -> some View {
        let t = store.t
        let lang = store.settings.lang
        let spend = AppStore.sum(store.txs(in: key), .expense)
        let label = key.year == MonthKey.current.year
            ? DateText.monthName(key.month, lang)
            : DateText.monthTitle(key, lang)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.headline)
                Spacer()
                Image(systemName: "chart.pie.fill").symbolRenderingMode(.hierarchical)
            }
            .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
            Text(t.monthSpend).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.7))
            MoneyText(spend, size: 22, weight: .bold, relativeTo: .title2)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shake) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            LinearKeyframe(-8, duration: 0.0875)
            LinearKeyframe(7, duration: 0.0875)
            LinearKeyframe(-4, duration: 0.0875)
            LinearKeyframe(0, duration: 0.0875)
        }
        .contentShape(.rect(cornerRadius: 24))
        .glassEffect(.clear.tint(.white.opacity(0.12)).interactive(), in: .rect(cornerRadius: 24, style: .continuous))
        .scaleEffect(dragging ? 1.03 : 1)
        .offset(x: drag)
        .rotationEffect(.degrees(Double(drag / 40)), anchor: .bottom)
        .onTapGesture { store.setTab(.stats) }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { v in
                    dragging = true
                    drag = v.translation.width * 0.7
                }
                .onEnded(end)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragging)
        .accessibilityElement(children: .combine)
        .accessibilityHint(t.swipeHint)
        .accessibilityAddTraits(.isButton)
    }

    private func end(_ v: DragGesture.Value) {
        dragging = false
        let dx = v.translation.width
        let vx = v.velocity.width
        let fast = abs(vx) > 450
        guard abs(dx) >= 60 || fast else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { drag = 0 }
            return
        }
        let right = (fast ? vx : dx) > 0
        // like turning pages: English swipe left for the next month, Arabic swipe right
        let toNext = store.settings.lang == .ar ? right : !right
        if toNext && store.viewMonth >= .current {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { drag = 0 }
            shake += 1
            return
        }
        Haptic.tap()
        flyDir = right ? 1 : -1
        let next = store.viewMonth.shifted(by: toNext ? 1 : -1)
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
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
