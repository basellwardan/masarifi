import SwiftUI

struct TransactionsView: View {
    @Environment(AppStore.self) private var store
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
        let groups = Dictionary(grouping: list) { Calendar.current.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }

        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Text("\(t.monthSpend) · \(DateText.monthName(store.viewMonth.month, store.settings.lang))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        MoneyText(value: AppStore.sum(month, .expense), size: 40, weight: .semibold)
                        HStack(spacing: 6) {
                            Text(t.income)
                            MoneyText(value: AppStore.sum(month, .income), size: 13, weight: .medium, color: .secondary)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                if groups.isEmpty {
                    ContentUnavailableView(t.noTx, systemImage: "tray", description: Text(t.noTxHint))
                        .listRowBackground(Color.clear)
                }

                ForEach(groups, id: \.key) { group in
                    Section(DateText.dayHeader(group.key, t)) {
                        ForEach(group.value) { tx in
                            Button {
                                store.sheet = .add(tx.type, editID: tx.id, prefill: nil)
                            } label: {
                                TxRowView(tx: tx).padding(.vertical, -4)
                            }
                            .tint(Palette.ink)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(t.delete, systemImage: "trash", role: .destructive) {
                                    withAnimation { store.deleteTx(tx.id) }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(t.edit, systemImage: "pencil") {
                                    store.sheet = .add(tx.type, editID: tx.id, prefill: nil)
                                }
                                .tint(Palette.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .animation(.snappy, value: list)
            .navigationTitle(t.transactions)
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("", selection: $filter) {
                    Text(t.all).tag(Filter.all)
                    Text(t.expenses).tag(Filter.expense)
                    Text(t.income).tag(Filter.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.sheet = .month } label: { Image(systemName: "calendar") }
                        .accessibilityLabel(t.pickMonth)
                }
            }
            .sensoryFeedback(.selection, trigger: filter)
        }
    }
}
