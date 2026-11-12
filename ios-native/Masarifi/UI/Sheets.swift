import SwiftUI

/// Add or edit a transaction: type, amount on a keypad, and what it was for.
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
    @Namespace private var glass

    private var existing: Tx? { editID.flatMap { id in store.txs.first { $0.id == id } } }

    var body: some View {
        let t = store.t
        let cur = store.settings.currency
        let value = Double(amountText) ?? 0
        let valueNew = Currency.toNew(value, cur, rate: store.settings.usdRate)

        NavigationStack {
            VStack(spacing: 14) {
                Picker("", selection: $type) {
                    Text(t.withdraw).tag(TxType.expense)
                    Text(t.deposit).tag(TxType.income)
                }
                .pickerStyle(.segmented)

                GlassGroup(spacing: 16) {
                    HStack(spacing: 12) {
                        Button { toggleMic() } label: {
                            Image(systemName: listener.isListening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 18))
                                .frame(width: 44, height: 44)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .liquidGlass(Circle(), tint: listener.isListening ? Palette.blue.opacity(0.35) : nil, interactive: true)
                        .glassID("mic", in: glass)
                        .accessibilityLabel(t.voice)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if cur == .usd { Text("$").font(.system(size: 30, weight: .medium)) }
                            Text(display)
                                .font(.system(size: 46, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(amountText.isEmpty ? Color(hex: 0xB9BABE) : Palette.ink)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.18), value: amountText)
                            if cur != .usd {
                                Text(Currency.symbol(cur, store.settings.lang))
                                    .font(.system(size: 16))
                                    .foregroundStyle(Palette.muted)
                            }
                        }
                        .environment(\.layoutDirection, .leftToRight)
                    }
                }
                if value > 0 && cur != .sypNew {
                    Text("≈ " + Currency.format(valueNew, .sypNew, rate: store.settings.usdRate, lang: store.settings.lang))
                        .font(.footnote).foregroundStyle(Palette.muted)
                }

                TextField(type == .expense ? t.notePlaceholderExpense : t.notePlaceholderIncome, text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                keypad(cur)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .navigationTitle(existing == nil ? (type == .expense ? t.withdraw : t.deposit) : t.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: { Image(systemName: "xmark") }
                }
                if let existing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            withAnimation { store.deleteTx(existing.id) }
                            dismiss()
                        } label: { Image(systemName: "trash") }
                        .tint(.red)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save(valueNew) } label: { Image(systemName: "checkmark") }
                        .disabled(!(valueNew > 0))
                }
            }
        }
        .presentationDetents([.large])
        .sensoryFeedback(.selection, trigger: type)
        .onAppear(perform: load)
        .onDisappear { listener.cancel() }
    }

    private var display: String {
        guard !amountText.isEmpty else { return "0" }
        let parts = amountText.split(separator: ".", omittingEmptySubsequences: false)
        let int = Int(parts[0]).map { Currency.grouped($0) } ?? String(parts[0])
        return parts.count > 1 ? "\(int).\(parts[1])" : int
    }

    private func keypad(_ cur: CurrencyCode) -> some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "del"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(keys, id: \.self) { k in
                Button { press(k, cur) } label: {
                    Group {
                        if k == "del" { Image(systemName: "delete.left") } else { Text(k) }
                    }
                    .font(.system(size: 26, weight: .regular))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Rectangle())
                }
                .buttonStyle(KeyStyle())
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
            amountText = trim(Currency.fromNew(v, cur, rate: store.settings.usdRate), Currency.fractionDigits(cur))
        }
    }

    private func trim(_ v: Double, _ digits: Int) -> String {
        var s = String(format: "%.\(digits)f", v)
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        return s
    }

    private func toggleMic() {
        if listener.isListening { listener.stop(); return }
        Haptic.tap()
        listener.start(lang: store.settings.lang) { text in
            guard !text.isEmpty else { return }
            let p = VoiceParser.parse(text)
            withAnimation(.snappy) {
                type = p.type
                note = p.note
                if let a = p.amount {
                    let cur = store.settings.currency
                    let asNew = Currency.toNew(a, p.unit ?? cur, rate: store.settings.usdRate)
                    amountText = trim(Currency.fromNew(asNew, cur, rate: store.settings.usdRate), Currency.fractionDigits(cur))
                }
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
        dismiss()
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.ink)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(configuration.isPressed ? Palette.tile : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct MonthSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var year = MonthKey.current.year

    var body: some View {
        let t = store.t
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Button { year -= 1 } label: { Image(systemName: "chevron.backward") }
                    Text(String(year)).font(.headline.monospacedDigit()).frame(minWidth: 70)
                    Button { year += 1 } label: { Image(systemName: "chevron.forward") }
                        .disabled(year >= MonthKey.current.year)
                }
                .glassButton()
                .tint(Palette.ink)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(1...12, id: \.self) { m in
                        let key = MonthKey(year: year, month: m)
                        let on = key == store.viewMonth
                        Button {
                            Haptic.select()
                            withAnimation(.snappy) { store.viewMonth = key }
                            dismiss()
                        } label: {
                            Text(DateText.monthName(m, store.settings.lang))
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .glassButton(prominent: on)
                        .tint(Palette.ink)
                        .disabled(key > .current)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(t.pickMonth)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { year = store.viewMonth.year }
    }
}

struct NotificationsSheet: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let t = store.t
        let month = store.txs(in: .current)
        let spend = AppStore.sum(month, .expense)
        let income = AppStore.sum(month, .income)
        let top = AppStore.byItem(month, .expense).first
        NavigationStack {
            List {
                if spend > income && spend > 0 {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.spentMoreThan)
                            MoneyText(value: spend - income, size: 13, weight: .regular, color: .secondary)
                        }
                    } icon: {
                        Image(systemName: "chart.line.downtrend.xyaxis").foregroundStyle(.red)
                    }
                }
                if let top {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.topCategory)
                            HStack(spacing: 4) {
                                Text(top.label.isEmpty ? t.expense : top.label)
                                Text("·")
                                MoneyText(value: top.total, size: 13, weight: .regular, color: .secondary)
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: IconHints.symbol(for: top.label, type: .expense))
                    }
                }
                if !(spend > income && spend > 0) && top == nil {
                    ContentUnavailableView(t.noNotifications, systemImage: "bell.slash")
                }
            }
            .navigationTitle(t.notifications)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
