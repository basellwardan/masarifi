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

enum AppTab: Hashable {
    case home, tx, stats, voice, settings
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
    var tab: AppTab = .home

    private static let key = "masarifi.native.v1"

    init() {
        load()
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
        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.key)
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

    func deleteTx(_ id: String) {
        txs.removeAll { $0.id == id }
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
