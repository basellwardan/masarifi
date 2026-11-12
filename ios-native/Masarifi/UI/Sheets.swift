import SwiftUI

/// Add or edit a transaction: withdraw/deposit, amount on a keypad (or by
/// voice), and what it was for.
struct AddSheet: View {
    @Environment(AppStore.self) private var store

    let initialType: TxType
    let editID: String?
    let prefill: ActiveSheet.Prefill?

    @State private var type: TxType = .expense
    @State private var amountText = ""
    @State private var note = ""
    @State private var listener = SpeechListener()
    @State private var loaded = false
    @State private var pulse = false
    @Namespace private var seg

    private var existing: Tx? { editID.flatMap { id in store.txs.first { $0.id == id } } }

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        let cur = store.settings.currency
        let value = Double(amountText) ?? 0
        let valueNew = Currency.toNew(value, cur, rate: store.settings.usdRate)

        VStack(spacing: 0) {
            // withdraw / deposit
            HStack(spacing: 6) {
                ForEach([TxType.expense, .income], id: \.self) { k in
                    let on = type == k
                    Button {
                        guard k != type else { return }
                        Haptic.tap()
                        type = k
                    } label: {
                        Text(k == .expense ? t.withdraw : t.deposit)
                            .ui(15, .semibold)
                            .foregroundStyle(on ? .white : Palette.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background {
                                if on { Capsule().fill(.black).matchedGeometryEffect(id: "seg", in: seg) }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(5)
            .background(Capsule().fill(Palette.tile))
            .animation(.framer(500, 38), value: type)

            // amount
            HStack(spacing: 10) {
                Button(action: toggleMic) {
                    Icon(.mic, size: 18, stroke: 1.8)
                        .foregroundStyle(listener.isListening ? .white : Palette.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(listener.isListening ? Color.black : Palette.pill))
                        .scaleEffect(pulse ? 1.12 : 1)
                        .contentShape(Circle())
                }
                .buttonStyle(PressStyle(scale: 0.9))
                .accessibilityLabel(t.voice)
                HStack(spacing: 0) {
                    if cur == .usd {
                        Text("$").font(AppFont.num(28, .medium)).foregroundStyle(Palette.ink)
                    }
                    Text(display)
                        .font(AppFont.num(44, .medium))
                        .tracking(-0.88)
                        .foregroundStyle(amountText.isEmpty ? Palette.muted2 : Palette.ink)
                        .id(display)
                        .transition(.asymmetric(insertion: .offset(y: 12).combined(with: .opacity),
                                                removal: .offset(y: -12).combined(with: .opacity)))
                }
                .environment(\.layoutDirection, .leftToRight)
                .animation(.easeOut(duration: 0.16), value: display)
                if cur != .usd {
                    Text(Currency.symbol(cur, lang)).ui(16).foregroundStyle(Palette.muted)
                }
            }
            .lineLimit(1)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Text(value > 0 && cur != .sypNew ? "≈ " + Currency.format(valueNew, .sypNew, rate: store.settings.usdRate, lang: lang) : " ")
                .ui(13)
                .foregroundStyle(Palette.muted)
                .frame(minHeight: 18)

            TextField("", text: $note, prompt: Text(type == .expense ? t.notePlaceholderExpense : t.notePlaceholderIncome)
                .foregroundStyle(Palette.muted))
                .ui(15)
                .submitLabel(.done)
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
                .padding(.top, 12)

            keypad(cur)
                .padding(.top, 10)

            HStack(spacing: 8) {
                if let existing {
                    PillButton(width: 52) { remove(existing) } label: {
                        Icon(.trash2, size: 20, stroke: 1.7).foregroundStyle(Palette.danger)
                    }
                    .accessibilityLabel(t.delete)
                }
                PillButton(black: true) { save(valueNew) } label: { Text(t.save) }
                    .opacity(valueNew > 0 ? 1 : 0.35)
                    .animation(.easeOut(duration: 0.2), value: valueNew > 0)
            }
            .padding(.top, 10)
        }
        .onAppear(perform: load)
        .onDisappear { listener.cancel() }
        .onChange(of: listener.isListening) {
            if listener.isListening {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            }
        }
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
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(keys, id: \.self) { k in
                Button { press(k, cur) } label: {
                    ZStack {
                        if k == "del" {
                            Icon(.delete, size: 24, stroke: 1.6)
                        } else {
                            Text(k).font(AppFont.num(24, .medium))
                        }
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
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
            amountText = SettingsView.trim(Currency.fromNew(v, cur, rate: store.settings.usdRate), Currency.fractionDigits(cur))
        }
    }

    private func toggleMic() {
        if listener.isListening { listener.stop(); return }
        Haptic.medium()
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
        Haptic.medium()
        UIApplication.shared.endEditing()
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.framer(300, 30)) {
            if let existing {
                store.updateTx(existing.id, type: type, amount: valueNew, note: text)
            } else {
                store.addTx(type: type, amount: valueNew, note: text)
            }
        }
        store.showToast(store.t.saved)
        store.closeSheet()
    }

    private func remove(_ tx: Tx) {
        UIApplication.shared.endEditing()
        let removed = withAnimation(.easeOut(duration: 0.22)) { store.deleteTx(tx.id) }
        store.closeSheet()
        if let removed { store.showToast(store.t.deleted, undo: removed) }
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 18, style: .circular)
                    .fill(configuration.isPressed ? Palette.tile : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.framer(500, 30), value: configuration.isPressed)
    }
}

struct MonthSheet: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        let view = store.viewMonth
        VStack(spacing: 0) {
            HStack {
                Text(t.pickMonth).ui(23, .semibold).foregroundStyle(Palette.ink)
                Spacer()
                HStack(spacing: 6) {
                    stepButton(lang == .ar ? .chevronRight : .chevronLeft) {
                        store.viewMonth = MonthKey(year: view.year - 1, month: view.month)
                    }
                    Text(String(view.year))
                        .font(AppFont.num(16, .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(minWidth: 48)
                    stepButton(lang == .ar ? .chevronLeft : .chevronRight) {
                        store.viewMonth = MonthKey(year: view.year + 1, month: view.month)
                    }
                }
            }
            .padding(.bottom, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(1...12, id: \.self) { m in
                    ChipToggle(title: DateText.monthName(m, lang), on: view.month == m, fill: true) {
                        Haptic.tap()
                        store.viewMonth = MonthKey(year: view.year, month: m)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { store.closeSheet() }
                    }
                }
            }
        }
    }

    private func stepButton(_ icon: LucideIcon, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Icon(icon, size: 18, stroke: 2)
                .foregroundStyle(Palette.ink)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Palette.pill))
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle(scale: 0.9))
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
        let over = spend > income && spend > 0

        VStack(alignment: .leading, spacing: 0) {
            Text(t.notifications).ui(23, .semibold).foregroundStyle(Palette.ink)
                .padding(.bottom, 16)
            if over {
                insight(icon: .trendingDown, iconColor: Palette.danger, title: t.spentMoreThan) {
                    MoneyView(value: spend - income, style: MoneyStyle(size: 12.5, weight: .regular, color: Palette.muted))
                }
            }
            if let top {
                insight(icon: IconHints.icon(for: top.label, type: .expense), title: t.topCategory, trailing: .trendingUp) {
                    HStack(spacing: 4) {
                        Text(top.label.isEmpty ? t.expense : top.label).ui(12.5).foregroundStyle(Palette.muted)
                        Text("·").ui(12.5).foregroundStyle(Palette.muted)
                        MoneyView(value: top.total, style: MoneyStyle(size: 12.5, weight: .regular, color: Palette.muted))
                    }
                }
            }
            if !over && top == nil {
                VStack(spacing: 10) {
                    Icon(.bellOff, size: 28, stroke: 1.4)
                    Text(t.noNotifications).ui(16)
                }
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            }
        }
    }

    private func insight<Sub: View>(icon: LucideIcon, iconColor: Color = Palette.rowIconInk, title: String,
                                    trailing: LucideIcon? = nil, @ViewBuilder sub: () -> Sub) -> some View {
        HStack(spacing: 14) {
            Icon(icon, size: 18, stroke: 1.7)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ui(15.5, .medium).foregroundStyle(Palette.ink)
                sub()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Icon(trailing, size: 18, stroke: 1.7).foregroundStyle(Palette.muted)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
        .padding(.bottom, 10)
    }
}
