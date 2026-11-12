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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker(t.filter, selection: $filter) {
                        Label(t.all, systemImage: "tray.full").tag(Filter.all)
                        Label(t.expenses, systemImage: "arrow.up.right").tag(Filter.expense)
                        Label(t.income, systemImage: "arrow.down.left").tag(Filter.income)
                    }
                } label: {
                    Image(systemName: filter == .all
                          ? "line.3.horizontal.decrease"
                          : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel(t.filter)
            }
        }
        .sensoryFeedback(.selection, trigger: filter)
    }
}

/// Transactions and Statistics in one tab: a segmented switch in the bar
/// flips between the list and the bubbles.
struct ActivityTab: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID

    var body: some View {
        @Bindable var store = store
        let t = store.t
        NavigationStack {
            ZStack {
                if store.activityMode == .list {
                    TransactionsView(zoom: zoom)
                        .transition(.opacity)
                } else {
                    StatsView(zoom: zoom)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: store.activityMode)
            .navigationTitle(store.activityMode == .list ? t.transactions : t.stats)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(t.transactions, selection: $store.activityMode) {
                        Text(t.transactions).tag(ActivityMode.list)
                        Text(t.stats).tag(ActivityMode.stats)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 230)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.openSheet(.month, from: "month-activity")
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel(t.pickMonth)
                }
                .matchedTransitionSource(id: "month-activity", in: zoom)
            }
            .sensoryFeedback(.selection, trigger: store.activityMode)
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
