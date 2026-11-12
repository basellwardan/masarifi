import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var rate = ""
    @State private var opening = ""
    @State private var confirmReset = false
    @State private var picking = false
    @State private var picked: PhotosPickerItem?
    @State private var sheetIn = false
    @State private var resetWork: DispatchWorkItem?

    var body: some View {
        @Bindable var store = store
        let t = store.t

        VStack(spacing: 0) {
            GradHeader(title: t.settings)

            VStack(spacing: 0) {
                Button { picking = true } label: {
                    AvatarView(size: 78)
                        .overlay(alignment: .bottomTrailing) {
                            Icon(.camera, size: 14, stroke: 1.8)
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .darkGlass(Circle())
                                .offset(x: 6, y: 4)
                        }
                }
                .buttonStyle(PressStyle(scale: 0.94))
                .accessibilityLabel(t.addPhoto)
                Text(store.profile.name.isEmpty ? t.appName : store.profile.name)
                    .ui(20, .semibold)
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                GlassChip {
                    Text(t.remaining)
                    MoneyView(value: store.balance, style: .chip)
                }
                .padding(.top, 10)
            }
            .padding(.top, 18)
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
            .modifier(Rise(index: 0, distance: 12))

            ScrollView {
                VStack(spacing: 0) {
                    profileGroup(t).modifier(Rise(index: 0, distance: 16, delay: 0.1))
                    prefsGroup(t).modifier(Rise(index: 1, distance: 16, delay: 0.16))
                    PillButton(black: true, height: 62, action: share) {
                        Icon(.share2, size: 20, stroke: 1.7)
                        Text(t.share)
                    }
                    .padding(.bottom, 6)
                    .modifier(Rise(index: 2, distance: 16, delay: 0.22))
                    Text(t.shareHint)
                        .ui(12.5)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                        .modifier(Rise(index: 3, distance: 16, delay: 0.28))
                    aboutGroup(t).modifier(Rise(index: 4, distance: 16, delay: 0.34))
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, metrics.bottom + 110)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .clipShape(WhiteSheetShape())
            .background(
                WhiteSheetShape()
                    .fill(.white)
                    .shadow(color: Color(hex: 0x050F33, opacity: 0.18), radius: 15, y: -8)
            )
            .offset(y: sheetIn ? 0 : 200)
        }
        .background(Palette.screen)
        .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
        .onChange(of: picked) {
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self), let square = PhotoTools.square(data) {
                    store.profile.photo = square
                }
            }
        }
        .onAppear {
            syncFields()
            withAnimation(.framer(200, 26)) { sheetIn = true }
        }
    }

    // MARK: groups

    private func profileGroup(_ t: Strings) -> some View {
        @Bindable var store = store
        return SettingsGroup {
            SettingsRow(icon: .user, title: t.name) {
                TextField("", text: $store.profile.name)
                    .ui(15, .medium)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .frame(width: 140, height: 38)
                    .background(Capsule().fill(.white))
            }
            SettingsRow(icon: .wallet, title: t.editBalance, divider: true) {
                NumberField(text: $opening, width: 120)
                    .onChange(of: opening) {
                        let raw = Self.clean(opening)
                        if raw != opening { opening = raw; return }
                        let v = Double(raw) ?? 0
                        store.profile.openingBalance = Currency.toNew(v, store.settings.currency, rate: store.settings.usdRate)
                    }
            }
        }
    }

    private func prefsGroup(_ t: Strings) -> some View {
        SettingsGroup {
            SettingsRow(icon: .languages, title: t.language) {
                MiniSeg(id: "lang", value: store.settings.lang, options: [(.ar, "عربي"), (.en, "EN")]) { v in
                    store.settings.lang = v
                }
            }
            SettingsRow(icon: .coins, title: t.currency, sub: t.currencyName(store.settings.currency), divider: true) {
                MiniSeg(id: "cur", value: store.settings.currency, options: [
                    (.sypNew, store.settings.lang == .ar ? "جديدة" : "New"),
                    (.sypOld, store.settings.lang == .ar ? "قديمة" : "Old"),
                    (.usd, "$"),
                ]) { v in
                    store.settings.currency = v
                    syncFields()
                }
            }
            SettingsRow(icon: .dollarSign, title: t.usdRate, sub: t.usdRateHint, divider: true) {
                NumberField(text: $rate, width: 96)
                    .onChange(of: rate) {
                        let raw = Self.clean(rate)
                        if raw != rate { rate = raw; return }
                        if let v = Double(raw), v > 0 { store.settings.usdRate = v }
                    }
            }
            Text(t.oldNote)
                .ui(12.5)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
    }

    private func aboutGroup(_ t: Strings) -> some View {
        SettingsGroup {
            SettingsRow(icon: .info, title: t.about, sub: "\(t.appName) · \(t.version) \(Self.version)") { EmptyView() }
            Button(action: reset) {
                SettingsRow(icon: .rotateCcw, iconColor: Palette.danger, title: confirmReset ? t.resetConfirm : t.reset, divider: true) { EmptyView() }
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle(scale: 0.98))
        }
    }

    // MARK: actions

    private func share() {
        Haptic.medium()
        var items: [Any] = [ShareExport.summary(store)]
        if let csv = ShareExport.csvFile(store) { items.append(csv) }
        ShareSheet.present(items)
    }

    private func reset() {
        Haptic.medium()
        if !confirmReset {
            confirmReset = true
            resetWork?.cancel()
            let work = DispatchWorkItem { confirmReset = false }
            resetWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
            return
        }
        resetWork?.cancel()
        confirmReset = false
        withAnimation(.easeInOut(duration: 0.4)) { store.resetAll() }
    }

    private func syncFields() {
        let c = store.settings.currency
        let v = Currency.fromNew(store.profile.openingBalance, c, rate: store.settings.usdRate)
        opening = Self.trim(v, Currency.fractionDigits(c))
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
            if let d = ch.wholeNumberValue, ch.isNumber {
                out.append(String(d))
            } else if (ch == "." || ch == "," || ch == "٫") && !dot {
                dot = true
                out.append(".")
            }
        }
        return out
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/// `.group`: grey rounded block of rows.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(Palette.tile, in: RoundedRectangle(cornerRadius: 22, style: .circular))
            .padding(.bottom, 12)
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: LucideIcon
    var iconColor: Color = Palette.rowIconInk
    let title: String
    var sub: String? = nil
    /// hairline above (.row + .row)
    var divider = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            Icon(icon, size: 18, stroke: 1.7)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ui(15.5, .medium).foregroundStyle(Palette.ink)
                if let sub {
                    Text(sub).ui(12.5).foregroundStyle(Palette.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .frame(minHeight: 58)
        .overlay(alignment: .top) {
            if divider { Rectangle().fill(Palette.divider).frame(height: 1) }
        }
    }
}

/// White capsule number input (.rate-input).
struct NumberField: View {
    @Binding var text: String
    var width: CGFloat

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.decimalPad)
            .font(AppFont.num(15, .semibold))
            .multilineTextAlignment(.center)
            .environment(\.layoutDirection, .leftToRight)
            .frame(width: width, height: 38)
            .background(Capsule().fill(.white))
    }
}

/// Small segmented control with a sliding black pill (.mini-seg).
struct MiniSeg<T: Hashable>: View {
    let id: String
    let value: T
    let options: [(T, String)]
    let onChange: (T) -> Void
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let on = option.0 == value
                Button {
                    Haptic.tap()
                    onChange(option.0)
                } label: {
                    Text(option.1)
                        .ui(13.5, .semibold)
                        .foregroundStyle(on ? .white : Palette.muted)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background {
                            if on {
                                Capsule().fill(.black).matchedGeometryEffect(id: id, in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(.white))
        .animation(.framer(500, 38), value: value)
    }
}
