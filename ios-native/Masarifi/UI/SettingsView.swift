import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var rate = ""
    @State private var opening = ""
    @State private var picked: PhotosPickerItem?
    @State private var confirmReset = false

    var body: some View {
        @Bindable var store = store
        let t = store.t

        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $picked, matching: .images) {
                            AvatarView(size: 64)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 24, height: 24)
                                        .glassEffect(.regular, in: .circle)
                                        .offset(x: 4, y: 4)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(t.addPhoto)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.profile.name.isEmpty ? t.appName : store.profile.name)
                                .font(.title2.weight(.semibold))
                            HStack(spacing: 4) {
                                Text(t.remaining)
                                MoneyText(store.balance, size: 15, weight: .medium, relativeTo: .subheadline)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section(t.profile) {
                    LabeledContent {
                        TextField(t.namePlaceholder, text: $store.profile.name)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                    } label: {
                        Label { Text(t.name) } icon: { SettingsIcon(symbol: "person.fill", color: .blue) }
                    }
                    LabeledContent {
                        TextField("0", text: $opening)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: opening) {
                                let v = Double(Self.clean(opening)) ?? 0
                                store.profile.openingBalance = Currency.toNew(v, store.settings.currency, rate: store.settings.usdRate)
                            }
                    } label: {
                        Label { Text(t.editBalance) } icon: { SettingsIcon(symbol: "wallet.bifold.fill", color: .green) }
                    }
                }

                Section {
                    Picker(selection: $store.settings.lang) {
                        Text("العربية").tag(Lang.ar)
                        Text("English").tag(Lang.en)
                    } label: {
                        Label { Text(t.language) } icon: { SettingsIcon(symbol: "globe", color: .blue) }
                    }
                    Picker(selection: $store.settings.currency) {
                        ForEach(CurrencyCode.allCases, id: \.self) { c in
                            Text(t.currencyName(c)).tag(c)
                        }
                    } label: {
                        Label { Text(t.currency) } icon: { SettingsIcon(symbol: "banknote.fill", color: .orange) }
                    }
                    LabeledContent {
                        TextField("110", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: rate) {
                                if let v = Double(Self.clean(rate)), v > 0 { store.settings.usdRate = v }
                            }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.usdRate)
                                Text(t.usdRateHint).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { SettingsIcon(symbol: "dollarsign", color: .teal) }
                    }
                } footer: {
                    Text(t.oldNote)
                }

                Section {
                    Button(action: share) {
                        Label { Text(t.share) } icon: { SettingsIcon(symbol: "square.and.arrow.up", color: Palette.brand) }
                    }
                    .foregroundStyle(.primary)
                } footer: {
                    Text(t.shareHint)
                }

                Section {
                    LabeledContent {
                        Text("\(t.appName) · \(t.version) \(Self.version)")
                    } label: {
                        Label { Text(t.about) } icon: { SettingsIcon(symbol: "info", color: .gray) }
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label { Text(t.reset) } icon: { SettingsIcon(symbol: "trash.fill", color: .red) }
                    }
                    .confirmationDialog(t.resetConfirm, isPresented: $confirmReset, titleVisibility: .visible) {
                        Button(t.reset, role: .destructive) {
                            withAnimation { store.resetAll() }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(t.settings)
        }
        .onAppear(perform: syncFields)
        .onChange(of: store.settings.currency) { syncFields() }
        .onChange(of: picked) {
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self), let square = PhotoTools.square(data) {
                    store.profile.photo = square
                }
            }
        }
    }

    private func share() {
        Haptic.medium()
        var items: [Any] = [ShareExport.summary(store)]
        if let csv = ShareExport.csvFile(store) { items.append(csv) }
        ShareSheet.present(items)
    }

    private func syncFields() {
        let c = store.settings.currency
        let v = Currency.fromNew(store.profile.openingBalance, c, rate: store.settings.usdRate)
        opening = v == 0 ? "" : Self.trim(v, Currency.fractionDigits(c))
        rate = Self.trim(store.settings.usdRate, 4)
    }

    static func trim(_ v: Double, _ digits: Int) -> String {
        var s = String(format: "%.\(digits)f", v)
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        return s
    }

    /// Keeps digits and one dot (Arabic digits and comma are accepted too).
    static func clean(_ s: String) -> String {
        var out = ""
        var dot = false
        for ch in s {
            if ch.isNumber, let d = ch.wholeNumberValue {
                out.append(String(d))
            } else if (ch == "." || ch == "," || ch == "٫") && !dot {
                dot = true
                out.append(".")
            }
        }
        return out
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

/// Search tab: every transaction, filtered as you type.
struct SearchView: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID
    @State private var query = ""

    var body: some View {
        let t = store.t
        let q = ArabicText.normalize(query)
        let results = q.isEmpty ? store.txs : store.txs.filter { ArabicText.normalize($0.note).contains(q) }
        let groups = DayGroup.group(results, t)

        NavigationStack {
            List {
                ForEach(groups) { g in
                    Section(g.label) {
                        ForEach(g.items) { tx in
                            TxListRow(tx: tx, source: "search-\(tx.id)", zoom: zoom)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if results.isEmpty {
                    if query.isEmpty {
                        ContentUnavailableView(t.noTx, systemImage: "tray", description: Text(t.noTxHint))
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .navigationTitle(t.search)
            .searchable(text: $query, prompt: t.searchPrompt)
        }
    }
}
