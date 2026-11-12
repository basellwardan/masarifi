import SwiftUI

/// Add or edit a transaction: withdraw/deposit, amount on a keypad (or by
/// voice), and what it was for.
struct AddSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let initialType: TxType
    let editID: String?
    let prefill: ActiveSheet.Prefill?

    @State private var type: TxType = .expense
    @State private var amountText = ""
    @State private var note = ""
    @State private var listener = SpeechListener()
    @State private var loaded = false
    @FocusState private var noteFocused: Bool

    private var existing: Tx? { editID.flatMap { id in store.txs.first { $0.id == id } } }

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        let cur = store.settings.currency
        let value = Double(amountText) ?? 0
        let valueNew = Currency.toNew(value, cur, rate: store.settings.usdRate)

        NavigationStack {
            VStack(spacing: 10) {
                // amount
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if cur == .usd { Text("$").font(.system(size: 30, weight: .semibold, design: .rounded)) }
                        Text(display)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(amountText.isEmpty ? .tertiary : .primary)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.2), value: amountText)
                        if cur != .usd {
                            Text(Currency.symbol(cur, lang))
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .environment(\.layoutDirection, .leftToRight)
                    Text(value > 0 && cur != .sypNew ? "≈ " + Currency.format(valueNew, .sypNew, rate: store.settings.usdRate, lang: lang) : " ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    TextField(type == .expense ? t.notePlaceholderExpense : t.notePlaceholderIncome, text: $note)
                        .focused($noteFocused)
                        .submitLabel(.done)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color(.tertiarySystemFill), in: .capsule)
                    Button(action: toggleMic) {
                        Image(systemName: listener.isListening ? "stop.fill" : "mic.fill")
                            .font(.title3)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 46, height: 46)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(listener.isListening ? .regular.tint(.red).interactive() : .regular.interactive(), in: .circle)
                    .symbolEffect(.pulse, isActive: listener.isListening)
                    .accessibilityLabel(t.voice)
                }

                keypad(cur)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(existing == nil ? (type == .expense ? t.withdraw : t.deposit) : t.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $type) {
                        Text(t.withdraw).tag(TxType.expense)
                        Text(t.deposit).tag(TxType.income)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: existing == nil ? 190 : 150)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: { Image(systemName: "xmark") }
                }
                if let existing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            dismiss()
                            deleteWithUndo(existing, store)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                        .accessibilityLabel(t.delete)
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save(valueNew) } label: { Image(systemName: "checkmark") }
                        .disabled(!(valueNew > 0))
                }
            }
        }
        .presentationDetents([.custom(EntryDetent.self)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .sensoryFeedback(.selection, trigger: type)
        .onAppear(perform: load)
        .onDisappear { listener.cancel() }
        .onChange(of: listener.failure) {
            guard let f = listener.failure else { return }
            store.showToast(f == .denied ? t.micDenied : t.micUnavailable)
        }
    }

    private var display: String {
        guard !amountText.isEmpty else { return "0" }
        let parts = amountText.split(separator: ".", omittingEmptySubsequences: false)
        let int = Int(parts[0]).map { Currency.grouped($0) } ?? String(parts[0])
        return parts.count > 1 ? "\(int).\(parts[1])" : int
    }

    private func keypad(_ cur: CurrencyCode) -> some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "del"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 4) {
            ForEach(keys, id: \.self) { k in
                Button { press(k, cur) } label: {
                    Group {
                        if k == "del" {
                            Image(systemName: "delete.left").font(.title2)
                        } else {
                            Text(k).font(.system(size: 28, weight: .medium, design: .rounded))
                        }
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(KeyStyle())
                .accessibilityLabel(k == "del" ? "delete" : k)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func press(_ k: String, _ cur: CurrencyCode) {
        Haptic.tap()
        let digits = Currency.fractionDigits(cur)
        var s = amountText
        switch k {
        case "del":
            if !s.isEmpty { s.removeLast() }
        case ".":
            if digits > 0 && !s.contains(".") { s = (s.isEmpty ? "0" : s) + "." }
        default:
            if let dot = s.firstIndex(of: "."), s.distance(from: dot, to: s.endIndex) - 1 >= digits { break }
            if s.replacingOccurrences(of: ".", with: "").count >= 12 { break }
            s = s == "0" ? k : s + k
        }
        amountText = s
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        type = existing?.type ?? initialType
        note = existing?.note ?? prefill?.note ?? ""
        if let v = existing?.amount ?? prefill?.amount {
            let cur = store.settings.currency
            amountText = SettingsView.trim(Currency.fromNew(v, cur, rate: store.settings.usdRate), Currency.fractionDigits(cur))
        }
    }

    private func toggleMic() {
        if listener.isListening { listener.stop(); return }
        Haptic.medium()
        noteFocused = false
        listener.start(lang: store.settings.lang) { text in
            guard !text.isEmpty else { return }
            let p = VoiceParser.parse(text)
            type = p.type
            note = p.note
            if let a = p.amount {
                let cur = store.settings.currency
                let asNew = Currency.toNew(a, p.unit ?? cur, rate: store.settings.usdRate)
                amountText = SettingsView.trim(Currency.fromNew(asNew, cur, rate: store.settings.usdRate), Currency.fractionDigits(cur))
            }
        }
    }

    private func save(_ valueNew: Double) {
        guard valueNew > 0 else { return }
        Haptic.success()
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.snappy) {
            if let existing {
                store.updateTx(existing.id, type: type, amount: valueNew, note: text)
            } else {
                store.addTx(type: type, amount: valueNew, note: text)
            }
        }
        store.showToast(store.t.saved)
        dismiss()
    }
}

/// About 60% of the screen: half-height, but never too short for the keypad
/// on small iPhones.
private struct EntryDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        max(context.maxDetentValue * 0.6, min(480, context.maxDetentValue))
    }
}

/// Keypad key: highlights like the Phone app's keypad while pressed.
private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(Color(.tertiarySystemFill)).opacity(configuration.isPressed ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct MonthSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var year = MonthKey.current.year
    @Namespace private var glass

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        NavigationStack {
            GlassEffectContainer(spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(1...12, id: \.self) { m in
                        let key = MonthKey(year: year, month: m)
                        let on = key == store.viewMonth
                        Button {
                            Haptic.tap()
                            withAnimation(.snappy) { store.viewMonth = key }
                            dismiss()
                        } label: {
                            Text(DateText.monthName(m, lang))
                                .font(.subheadline.weight(on ? .semibold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(on ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(on ? .regular.tint(Palette.brand).interactive() : .regular.interactive(), in: .capsule)
                        .glassEffectID(m, in: glass)
                        .disabled(key > .current)
                        .opacity(key > .current ? 0.4 : 1)
                    }
                }
            }
            .padding(20)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(t.pickMonth)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { year -= 1 } label: { Image(systemName: "chevron.backward") }
                    Text(verbatim: String(year))
                        .font(.headline.monospacedDigit())
                        .contentTransition(.numericText(value: Double(year)))
                        .animation(.snappy, value: year)
                    Button { year += 1 } label: { Image(systemName: "chevron.forward") }
                        .disabled(year >= MonthKey.current.year)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { year = store.viewMonth.year }
    }
}

struct NotificationsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let t = store.t
        let month = store.txs(in: .current)
        let spend = AppStore.sum(month, .expense)
        let income = AppStore.sum(month, .income)
        let top = AppStore.byItem(month, .expense).first
        let over = spend > income && spend > 0

        NavigationStack {
            List {
                if over {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.spentMoreThan).font(.body.weight(.medium))
                            MoneyText(spend - income, size: 15, weight: .medium, relativeTo: .subheadline)
                                .foregroundStyle(.red)
                        }
                    } icon: {
                        SettingsIcon(symbol: "chart.line.downtrend.xyaxis", color: .red)
                    }
                }
                if let top {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.topCategory).font(.body.weight(.medium))
                            HStack(spacing: 4) {
                                Text(top.label.isEmpty ? t.expense : top.label)
                                Text("·")
                                MoneyText(top.total, size: 15, weight: .medium, relativeTo: .subheadline)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    } icon: {
                        CategoryIcon(icon: IconHints.icon(for: top.label, type: .expense), size: 30)
                    }
                }
            }
            .overlay {
                if !over && top == nil {
                    ContentUnavailableView(t.noNotifications, systemImage: "bell.slash")
                }
            }
            .navigationTitle(t.notifications)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
