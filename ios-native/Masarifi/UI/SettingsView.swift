import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var picked: PhotosPickerItem?
    @State private var rateText = ""
    @State private var openingText = ""
    @State private var sharing = false
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
                                        .font(.system(size: 11))
                                        .padding(6)
                                        .background(.thinMaterial, in: Circle())
                                }
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.profile.name.isEmpty ? t.appName : store.profile.name)
                                .font(.title3.weight(.semibold))
                            HStack(spacing: 4) {
                                Text(t.remaining)
                                MoneyText(value: store.balance, size: 13, weight: .regular, color: .secondary)
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(t.profile) {
                    LabeledContent(t.name) {
                        TextField(t.namePlaceholder, text: $store.profile.name)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent(t.editBalance) {
                        TextField("0", text: $openingText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: openingText) {
                                let v = Double(openingText.replacingOccurrences(of: ",", with: ".")) ?? 0
                                store.profile.openingBalance = Currency.toNew(v, store.settings.currency, rate: store.settings.usdRate)
                            }
                    }
                }

                Section {
                    Picker(t.language, selection: $store.settings.lang) {
                        Text("العربية").tag(Lang.ar)
                        Text("English").tag(Lang.en)
                    }
                    .pickerStyle(.segmented)
                    Picker(t.currency, selection: $store.settings.currency) {
                        ForEach(CurrencyCode.allCases, id: \.self) { c in
                            Text(t.currencyName(c)).tag(c)
                        }
                    }
                    LabeledContent {
                        TextField("110", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: rateText) {
                                if let v = Double(rateText.replacingOccurrences(of: ",", with: ".")), v > 0 {
                                    store.settings.usdRate = v
                                }
                            }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(t.usdRate)
                            Text(t.usdRateHint).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(t.language + " · " + t.currency)
                } footer: {
                    Text(t.oldNote)
                }

                Section {
                    Button {
                        sharing = true
                    } label: {
                        Label(t.share, systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .glassButton(prominent: true)
                    .tint(Palette.ink)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text(t.shareHint).frame(maxWidth: .infinity)
                }

                Section {
                    LabeledContent(t.about, value: "\(t.appName) · \(t.version) 2.0")
                    Button(t.reset, role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle(t.settings)
            .confirmationDialog(t.resetConfirm, isPresented: $confirmReset, titleVisibility: .visible) {
                Button(t.reset, role: .destructive) { withAnimation { store.resetAll() } }
            }
            .sheet(isPresented: $sharing) {
                ActivityView(items: shareItems())
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear { syncFields() }
        .onChange(of: store.settings.currency) { syncFields() }
        .onChange(of: picked) {
            Task {
                if let data = try? await picked?.loadTransferable(type: Data.self) {
                    store.profile.photo = PhotoTools.square(data)
                }
            }
        }
    }

    private func shareItems() -> [Any] {
        var items: [Any] = [ShareExport.summary(store)]
        if let csv = ShareExport.csvFile(store) { items.append(csv) }
        return items
    }

    private func syncFields() {
        let c = store.settings.currency
        let v = Currency.fromNew(store.profile.openingBalance, c, rate: store.settings.usdRate)
        openingText = v == 0 ? "" : String(format: "%.\(Currency.fractionDigits(c))f", v)
        rateText = String(format: "%g", store.settings.usdRate)
    }
}
