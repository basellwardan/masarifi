import Foundation
import Observation
import SwiftUI

enum ActiveSheet: Identifiable, Equatable {
    case add(TxType, editID: String?, prefill: Prefill?)
    case month
    case notifications
    case voice

    struct Prefill: Equatable {
        var amount: Double? // new SYP
        var note: String
    }

    var id: String {
        switch self {
        case .add(let type, let edit, _): return "add-\(type.rawValue)-\(edit ?? "new")"
        case .month: return "month"
        case .notifications: return "notifications"
        case .voice: return "voice"
        }
    }
}

enum AppTab: Hashable, CaseIterable {
    case home, activity, settings
}

/// The Transactions tab shows either the list or the statistics.
enum ActivityMode: Hashable, CaseIterable {
    case list, stats
}

/// Black pill at the bottom ("Saved", "Deleted · Undo").
struct Toast: Equatable {
    var id = UUID()
    var message: String
    /// a deleted transaction the Undo button puts back
    var undo: Tx?
}

@Observable
final class AppStore {
    var onboarded = false
    var profile = Profile()
    var settings = AppSettings()
    var txs: [Tx] = []

    // UI state (not saved)
    var viewMonth = MonthKey.current
    var sheet: ActiveSheet?
    /// id of the button a sheet zooms out of (matchedTransitionSource)
    var sheetSource = ""
    var tab: AppTab = .home
    var activityMode: ActivityMode = .list
    var toast: Toast?

    private static let key = "masarifi.native.v1"
    private var saveWork: DispatchWorkItem?
    private var toastWork: DispatchWorkItem?

    init() {
        load()
        #if DEBUG
        applyScreenshotArguments()
        #endif
        watchForChanges()
    }

    #if DEBUG
    /// Simulator screenshots on CI: `-uiDemo` loads sample data, `-uiTab 2`
    /// opens a screen (0 home, 1 transactions, 2 statistics, 3 settings),
    /// `-uiSheet add|month|notifications|voice`, `-uiLang en`,
    /// `-uiWelcome` shows onboarding. Not compiled into release builds.
    private func applyScreenshotArguments() {
        let args = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard
        guard args.contains("-uiDemo") || args.contains("-uiWelcome") else { return }
        settings = AppSettings(lang: defaults.string(forKey: "uiLang") == "en" ? .en : .ar, currency: .sypNew, usdRate: 110)
        profile = Profile(name: "سام", photo: nil, openingBalance: 9500)
        let cal = Calendar.current
        func day(_ back: Int, _ hour: Int, _ minute: Int) -> Date {
            let d = cal.date(byAdding: .day, value: -back, to: Date()) ?? Date()
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: d) ?? d
        }
        txs = [
            Tx(id: "d1", type: .expense, amount: 50, note: "صرفت خمسين ليرة على قهوة", date: day(0, 11, 0)),
            Tx(id: "d2", type: .expense, amount: 604.36, note: "سوبرماركت الشام", date: day(0, 9, 42)),
            Tx(id: "d3", type: .income, amount: 1875.5, note: "", date: day(0, 8, 15)),
            Tx(id: "d4", type: .expense, amount: 24, note: "رصيد موبايل", date: day(1, 10, 22)),
            Tx(id: "d5", type: .expense, amount: 25, note: "دفعت 25 تكسي للجامعة", date: day(1, 9, 0)),
            Tx(id: "d6", type: .expense, amount: 296.65, note: "جاكيت شتوي", date: day(2, 18, 5)),
            Tx(id: "d7", type: .expense, amount: 207, note: "اشتراك النادي", date: day(2, 17, 30)),
            Tx(id: "d8", type: .expense, amount: 273, note: "قهوة مع الشباب", date: day(3, 20, 10)),
            Tx(id: "d9", type: .expense, amount: 154, note: "صيدلية", date: day(3, 12, 0)),
            Tx(id: "d10", type: .expense, amount: 420, note: "ايجار", date: day(4, 9, 0)),
            Tx(id: "d11", type: .expense, amount: 98.8, note: "خبز وخضرة", date: day(4, 8, 0)),
            Tx(id: "d12", type: .income, amount: 500, note: "الراتب", date: day(5, 9, 0)),
        ]
        onboarded = !args.contains("-uiWelcome")
        switch defaults.integer(forKey: "uiTab") {
        case 1: showActivity(.list)
        case 2: showActivity(.stats)
        case 3: tab = .settings
        default: tab = .home
        }
        switch defaults.string(forKey: "uiSheet") {
        case "add": sheet = .add(.expense, editID: nil, prefill: nil)
        case "month": sheet = .month
        case "notifications": sheet = .notifications
        case "voice": sheet = .voice
        default: break
        }
    }
    #endif

    // MARK: navigation
    func setTab(_ next: AppTab) { tab = next }

    /// Opens the Transactions tab on the list or the statistics.
    func showActivity(_ mode: ActivityMode) {
        activityMode = mode
        tab = .activity
    }

    /// Opens a sheet that grows out of the view marked with `source`.
    func openSheet(_ s: ActiveSheet, from source: String = "") {
        sheetSource = source
        sheet = s
    }
    func closeSheet() { sheet = nil }

    func showToast(_ message: String, undo: Tx? = nil) {
        toastWork?.cancel()
        toast = Toast(message: message, undo: undo)
        let work = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (undo == nil ? 2.2 : 4.5), execute: work)
    }

    func hideToast() {
        toastWork?.cancel()
        toast = nil
    }

    /// Saves shortly after any saved field changes (batched, so typing a name
    /// or a burst of edits writes once).
    private func watchForChanges() {
        withObservationTracking {
            _ = persisted
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.scheduleSave()
                self?.watchForChanges()
            }
        }
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.save() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func saveNow() {
        saveWork?.cancel()
        save()
    }

    var t: Strings { Strings.of(settings.lang) }

    var persisted: PersistedState {
        PersistedState(onboarded: onboarded, profile: profile, settings: settings, txs: txs)
    }

    // MARK: persistence
    func load() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let s = try? JSONDecoder().decode(PersistedState.self, from: data) {
            apply(s)
        } else if let migrated = CapacitorMigration.load() {
            apply(migrated)
            save()
        }
    }

    func save() {
        let state = persisted
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(state) {
                UserDefaults.standard.set(data, forKey: Self.key)
            }
        }
    }

    private func apply(_ s: PersistedState) {
        onboarded = s.onboarded
        profile = s.profile
        settings = s.settings
        txs = s.txs.sorted { $0.date > $1.date }
    }

    // MARK: mutations
    func addTx(type: TxType, amount: Double, note: String, date: Date = Date()) {
        txs.insert(Tx(id: Tx.newID(), type: type, amount: amount, note: note, date: date), at: 0)
        txs.sort { $0.date > $1.date }
    }

    func updateTx(_ id: String, type: TxType, amount: Double, note: String) {
        guard let i = txs.firstIndex(where: { $0.id == id }) else { return }
        txs[i].type = type
        txs[i].amount = amount
        txs[i].note = note
    }

    @discardableResult
    func deleteTx(_ id: String) -> Tx? {
        guard let i = txs.firstIndex(where: { $0.id == id }) else { return nil }
        return txs.remove(at: i)
    }

    func restoreTx(_ tx: Tx) {
        guard !txs.contains(where: { $0.id == tx.id }) else { return }
        txs.append(tx)
        txs.sort { $0.date > $1.date }
    }

    func cycleCurrency() {
        let all = CurrencyCode.allCases
        let i = all.firstIndex(of: settings.currency) ?? 0
        settings.currency = all[(i + 1) % all.count]
    }

    func resetAll() {
        onboarded = false
        profile = Profile()
        txs = []
        viewMonth = .current
        tab = .home
        sheet = nil
    }

    // MARK: derived
    var balance: Double {
        txs.reduce(profile.openingBalance) { $1.type == .income ? $0 + $1.amount : $0 - $1.amount }
    }

    func txs(in month: MonthKey) -> [Tx] {
        txs.filter { month.contains($0.date) }
    }

    static func sum(_ list: [Tx], _ type: TxType) -> Double {
        list.reduce(0) { $1.type == type ? $0 + $1.amount : $0 }
    }

    /// Percent change of the balance since the start of the current month.
    var monthChangePct: Double {
        let month = txs(in: .current)
        let net = Self.sum(month, .income) - Self.sum(month, .expense)
        let start = balance - net
        if start <= 0 { return net == 0 ? 0 : (net > 0 ? 100 : -100) }
        return net / start * 100
    }

    /// Spending grouped by the user's own words, biggest first.
    static func byItem(_ list: [Tx], _ type: TxType) -> [SpendItem] {
        var map: [String: SpendItem] = [:]
        var order: [String] = []
        for tx in list where tx.type == type {
            let label = tx.note.trimmingCharacters(in: .whitespaces)
            let key = ArabicText.normalize(label).isEmpty ? "__\(type.rawValue)" : ArabicText.normalize(label)
            if map[key] != nil {
                map[key]!.total += tx.amount
            } else {
                map[key] = SpendItem(id: key, label: label, total: tx.amount)
                order.append(key)
            }
        }
        return order.compactMap { map[$0] }.sorted { $0.total > $1.total }
    }

    // MARK: formatting helpers
    func money(_ v: Double, signed: Bool = false) -> String {
        Currency.format(v, settings.currency, rate: settings.usdRate, lang: settings.lang, signed: signed)
    }

    func title(of tx: Tx) -> String {
        let n = tx.note.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? (tx.type == .expense ? t.expense : t.incomeOne) : n
    }
}

/// Reads what the earlier (web-based) iPhone build saved, so updating to the
/// native app keeps every expense. Capacitor Preferences stored the zustand
/// state as JSON under "CapacitorStorage.masarifi-v1".
enum CapacitorMigration {
    static func load() -> PersistedState? {
        guard let json = UserDefaults.standard.string(forKey: "CapacitorStorage.masarifi-v1"),
              let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let state = root["state"] as? [String: Any]
        else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()

        var profile = Profile()
        if let p = state["profile"] as? [String: Any] {
            profile.name = p["name"] as? String ?? ""
            profile.openingBalance = (p["openingBalance"] as? NSNumber)?.doubleValue ?? 0
            if let url = p["photo"] as? String, let comma = url.firstIndex(of: ",") {
                profile.photo = Data(base64Encoded: String(url[url.index(after: comma)...]))
            }
        }
        var settings = AppSettings()
        if let s = state["settings"] as? [String: Any] {
            settings.lang = Lang(rawValue: s["lang"] as? String ?? "ar") ?? .ar
            settings.currency = CurrencyCode(rawValue: s["currency"] as? String ?? "syp_new") ?? .sypNew
            settings.usdRate = (s["usdRate"] as? NSNumber)?.doubleValue ?? 110
        }
        let txs: [Tx] = (state["txs"] as? [[String: Any]] ?? []).compactMap { r in
            guard let id = r["id"] as? String,
                  let type = TxType(rawValue: r["type"] as? String ?? ""),
                  let amount = (r["amount"] as? NSNumber)?.doubleValue,
                  let dateText = r["date"] as? String,
                  let date = iso.date(from: dateText) ?? isoPlain.date(from: dateText)
            else { return nil }
            return Tx(id: id, type: type, amount: amount, note: r["note"] as? String ?? "", date: date)
        }
        return PersistedState(
            onboarded: state["onboarded"] as? Bool ?? !txs.isEmpty,
            profile: profile,
            settings: settings,
            txs: txs
        )
    }
}
