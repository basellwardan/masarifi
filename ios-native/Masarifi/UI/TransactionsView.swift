import SwiftUI

struct TransactionsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var filter: Filter = .all
    @State private var sheetIn = false

    enum Filter: Hashable { case all, expense, income }

    private struct DayGroup: Identifiable {
        var id: Date
        var label: String
        var items: [Tx]
    }

    var body: some View {
        let t = store.t
        let month = store.txs(in: store.viewMonth)
        let list = month.filter {
            switch filter {
            case .all: return true
            case .expense: return $0.type == .expense
            case .income: return $0.type == .income
            }
        }
        let groups = Self.group(list, t)

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                GradHeader(title: t.transactions, action: AnyView(
                    GlassCircleButton(icon: .calendar, label: t.pickMonth) { store.openSheet(.month) }
                ))

                VStack(spacing: 0) {
                    Text("\(t.monthSpend) · \(DateText.monthName(store.viewMonth.month, store.settings.lang))")
                        .ui(17)
                        .foregroundStyle(.white.opacity(0.78))
                    MoneyView(value: AppStore.sum(month, .expense), style: .balance(44), countUp: true)
                        .padding(.top, 6)
                    GlassChip {
                        Text(t.income)
                        MoneyView(value: AppStore.sum(month, .income), style: .chip)
                    }
                    .padding(.top, 12)
                }
                .padding(.top, 22)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .modifier(Rise(index: 0, distance: 12))

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        ChipToggle(title: t.all, on: filter == .all) { pick(.all) }
                        ChipToggle(title: t.expenses, on: filter == .expense) { pick(.expense) }
                        ChipToggle(title: t.income, on: filter == .income) { pick(.income) }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if groups.isEmpty {
                                EmptyList(t: t)
                            }
                            ForEach(groups) { g in
                                Text(g.label)
                                    .ui(13)
                                    .foregroundStyle(Palette.muted)
                                    .padding(.top, 18)
                                    .padding(.bottom, 4)
                                ForEach(g.items) { tx in
                                    TxRow(tx: tx) { store.openSheet(.add(tx.type, editID: tx.id, prefill: nil)) }
                                        .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                        .animation(.easeOutApp(0.28), value: filter)
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(.top, 22)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(
                    WhiteSheetShape()
                        .fill(.white)
                        .shadow(color: Color(hex: 0x050F33, opacity: 0.18), radius: 15, y: -8)
                )
                .offset(y: sheetIn ? 0 : 200)
            }
            ListFade(color: .white)
        }
        .background(Palette.screen)
        .onAppear { withAnimation(.framer(200, 26)) { sheetIn = true } }
    }

    private func pick(_ f: Filter) {
        Haptic.tap()
        filter = f
    }

    private static func group(_ list: [Tx], _ t: Strings) -> [DayGroup] {
        let cal = Calendar.current
        var out: [DayGroup] = []
        for tx in list {
            let day = cal.startOfDay(for: tx.date)
            if out.last?.id == day {
                out[out.count - 1].items.append(tx)
            } else {
                out.append(DayGroup(id: day, label: DateText.dayHeader(day, t), items: [tx]))
            }
        }
        return out
    }
}
