import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var spins = 0
    @Namespace private var glass

    var body: some View {
        let t = store.t
        let monthTxs = store.txs(in: store.viewMonth)
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero(t)
                    actions(t)
                    HStack(alignment: .firstTextBaseline) {
                        Text(t.recent).font(.system(size: 22, weight: .semibold))
                        Spacer()
                        Button(t.viewAll) { store.tab = .tx }
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 8)

                    LazyVStack(spacing: 0) {
                        ForEach(monthTxs.prefix(15)) { tx in
                            TxRowView(tx: tx)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                                .onTapGesture { store.sheet = .add(tx.type, editID: tx.id, prefill: nil) }
                                .contextMenu {
                                    Button(t.edit, systemImage: "pencil") { store.sheet = .add(tx.type, editID: tx.id, prefill: nil) }
                                    Button(t.delete, systemImage: "trash", role: .destructive) {
                                        withAnimation { store.deleteTx(tx.id) }
                                    }
                                }
                                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        }
                        if monthTxs.isEmpty {
                            VStack(spacing: 6) {
                                Text(t.noTx).font(.headline)
                                Text(t.noTxHint).font(.subheadline).foregroundStyle(Palette.muted)
                            }
                            .padding(.vertical, 30)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Palette.page)
            .ignoresSafeArea(edges: .top)
            .softScrollEdges()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { store.tab = .settings } label: { AvatarView(size: 34) }
                        .accessibilityLabel(t.profile)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.sheet = .notifications } label: {
                        Image(systemName: store.monthChangePct < 0 ? "bell.badge" : "bell")
                    }
                    .accessibilityLabel(t.notifications)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func hero(_ t: Strings) -> some View {
        let pct = store.monthChangePct
        return ZStack(alignment: .bottom) {
            Palette.hero
            RadialGradient(colors: [Color(hex: 0x8CBEFF, opacity: 0.55), .clear], center: .bottom, startRadius: 10, endRadius: 260)
            VStack(spacing: 10) {
                Text(t.balance)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.78))
                MoneyText(value: store.balance, size: 54, weight: .semibold, color: .white,
                          fracColor: .white.opacity(0.48), symbolColor: .white.opacity(0.7))
                    .padding(.horizontal, 20)
                HStack(spacing: 6) {
                    Image(systemName: pct >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                    Text(String(format: "%.2f%%", abs(pct))).monospacedDigit()
                    Text(t.thisMonth)
                }
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .liquidGlass(Capsule(), clear: true)
                Spacer(minLength: 0)
            }
            .padding(.top, 118)

            CardStack()
                .frame(height: 150)
        }
        .frame(height: 470)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40, style: .continuous))
    }

    private func actions(_ t: Strings) -> some View {
        // one blend group: the three glass buttons sit close enough to read as
        // a single bar and morph into each other when pressed
        GlassGroup(spacing: 14) {
            HStack(spacing: 8) {
                Button {
                    Haptic.tap()
                    store.sheet = .add(.expense, editID: nil, prefill: nil)
                } label: {
                    Label(t.withdraw, systemImage: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .glassButton()
                .glassID("withdraw", in: glass)

                Button {
                    Haptic.tap()
                    spins += 1
                    withAnimation(.snappy) { store.cycleCurrency() }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 17, weight: .semibold))
                        .rotationEffect(.degrees(Double(spins) * 180))
                        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: spins)
                        .frame(width: 32, height: 44)
                }
                .glassButton()
                .glassID("swap", in: glass)
                .accessibilityLabel(t.swap)

                Button {
                    Haptic.tap()
                    store.sheet = .add(.income, editID: nil, prefill: nil)
                } label: {
                    Label(t.deposit, systemImage: "arrow.down.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .glassButton()
                .glassID("deposit", in: glass)
            }
            .tint(Palette.ink)
            .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

/// The stack of glass cards in the hero. The front card shows a month's
/// spending; swipe it to flick through months, tap it for Statistics.
struct CardStack: View {
    @Environment(AppStore.self) private var store
    @State private var drag: CGFloat = 0
    @State private var flyDirection: CGFloat = 1
    @State private var nudge = 0

    var body: some View {
        let t = store.t
        let key = store.viewMonth
        let spend = AppStore.sum(store.txs(in: key), .expense)
        let label = key.year == MonthKey.current.year
            ? DateText.monthName(key.month, store.settings.lang, short: true)
            : DateText.monthTitle(key, store.settings.lang)

        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .top) {
                // back cards: only their top strips peek out above the front card
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(width: w * 0.68, height: 26)
                    .offset(y: 30)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: w * 0.78, height: 18)
                    .offset(y: 41)

                HStack(alignment: .center) {
                    HStack(spacing: 14) {
                        Text(t.monthSpend)
                        MoneyText(value: spend, size: 13.5, weight: .medium, color: .white.opacity(0.9),
                                  fracColor: .white.opacity(0.6), symbolColor: .white.opacity(0.7))
                    }
                    .font(.system(size: 13.5))
                    .foregroundStyle(.white.opacity(0.92))
                    Spacer()
                    Text(label)
                        .font(.system(size: 16, weight: .bold))
                        .italic(store.settings.lang == .en)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .frame(width: w * 0.88, height: 140, alignment: .top)
                .liquidGlass(RoundedRectangle(cornerRadius: 22, style: .continuous), tint: .white.opacity(0.06), interactive: true)
                .offset(x: drag, y: 54)
                .rotationEffect(.degrees(Double(drag / 22)), anchor: .bottom)
                .modifier(Shake(amount: CGFloat(nudge)))
                .id(key)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -14)),
                    removal: .offset(x: flyDirection * 420).combined(with: .opacity)
                ))
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { drag = $0.translation.width }
                        .onEnded { end($0) }
                )
                .onTapGesture { store.tab = .stats }
                .accessibilityHint(t.swipeHint)
            }
            .frame(width: w)
        }
    }

    private func end(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let fast = abs(value.predictedEndTranslation.width) > 180
        guard abs(dx) > 60 || fast else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = 0 }
            return
        }
        let right = (fast ? value.predictedEndTranslation.width : dx) > 0
        // like turning pages: English swipe left for the next month, Arabic swipe right
        let toNext = store.settings.lang == .ar ? right : !right
        if toNext && store.viewMonth >= .current {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = 0 }
            withAnimation(.linear(duration: 0.35)) { nudge += 1 }
            return
        }
        Haptic.select()
        flyDirection = right ? 1 : -1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            drag = 0
            store.viewMonth = store.viewMonth.shifted(by: toNext ? 1 : -1)
        }
    }
}

/// Small "no" wiggle when there is no next month.
struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(amount * .pi * 4), y: 0))
    }
}

struct TxRowView: View {
    @Environment(AppStore.self) private var store
    let tx: Tx

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: IconHints.symbol(for: tx.note, type: tx.type))
                .font(.system(size: 17))
                .foregroundStyle(Color(hex: 0x6C6D72))
                .frame(width: 44, height: 44)
                .background(Color(hex: 0xEEEFF1), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.title(of: tx))
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                Text(DateText.txDate(tx.date, store.t))
                    .font(.system(size: 12.5))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            MoneyText(value: tx.type == .expense ? -tx.amount : tx.amount, size: 16, weight: .medium,
                      fracColor: Palette.ink, symbolColor: Palette.muted)
        }
        .padding(.vertical, 10)
    }
}
