import SwiftUI

struct DayGroup: Identifiable {
    var id: Date
    var label: String
    var items: [Tx]

    static func group(_ list: [Tx], _ t: Strings) -> [DayGroup] {
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

struct TransactionsView: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID
    @State private var filter: Filter = .all

    enum Filter: Hashable { case all, expense, income }

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
        let groups = DayGroup.group(list, t)

        NavigationStack {
            List {
                Section {
                    MonthSummaryCard(month: month)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if groups.isEmpty {
                    ContentUnavailableView(t.noTx, systemImage: "tray", description: Text(t.noTxHint))
                        .listRowBackground(Color.clear)
                }
                ForEach(groups) { g in
                    Section(g.label) {
                        ForEach(g.items) { tx in
                            TxListRow(tx: tx, source: "list-\(tx.id)", zoom: zoom)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .animation(.snappy, value: filter)
            .navigationTitle(t.transactions)
            .safeAreaBar(edge: .top) {
                Picker("", selection: $filter) {
                    Text(t.all).tag(Filter.all)
                    Text(t.expenses).tag(Filter.expense)
                    Text(t.income).tag(Filter.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.openSheet(.month, from: "month-tx")
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel(t.pickMonth)
                }
                .matchedTransitionSource(id: "month-tx", in: zoom)
            }
            .sensoryFeedback(.selection, trigger: filter)
        }
    }
}

/// A list row with native swipe actions, a context menu, and a sheet that
/// zooms out of the row when tapped.
struct TxListRow: View {
    @Environment(AppStore.self) private var store
    let tx: Tx
    let source: String
    var zoom: Namespace.ID

    var body: some View {
        let t = store.t
        Button {
            store.openSheet(.add(tx.type, editID: tx.id, prefill: nil), from: source)
        } label: {
            TxRow(tx: tx)
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: source, in: zoom)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(t.delete, systemImage: "trash", role: .destructive) {
                deleteWithUndo(tx, store)
            }
        }
        .swipeActions(edge: .leading) {
            Button(t.edit, systemImage: "pencil") {
                store.openSheet(.add(tx.type, editID: tx.id, prefill: nil), from: source)
            }
            .tint(Palette.brand)
        }
        .contextMenu { TxMenu(tx: tx, source: source) }
    }
}

/// The month's spending on a navy card, like a Wallet card.
struct MonthSummaryCard: View {
    @Environment(AppStore.self) private var store
    let month: [Tx]

    var body: some View {
        let t = store.t
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(t.monthSpend) · \(DateText.monthName(store.viewMonth.month, store.settings.lang))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            MoneyText(AppStore.sum(month, .expense), size: 38, weight: .bold, relativeTo: .largeTitle)
                .foregroundStyle(.white)
            GlassChip {
                Image(systemName: "arrow.down.left")
                Text(t.income)
                MoneyText(AppStore.sum(month, .income), size: 15, weight: .semibold, relativeTo: .subheadline)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.hero, in: .rect(cornerRadius: 26, style: .continuous))
    }
}
