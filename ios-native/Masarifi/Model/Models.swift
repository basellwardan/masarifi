import Foundation

enum TxType: String, Codable, CaseIterable, Hashable {
    case expense, income
}

/// Amounts are always stored in the new Syrian pound (1 new = 100 old).
enum CurrencyCode: String, Codable, CaseIterable, Hashable {
    case sypNew = "syp_new"
    case sypOld = "syp_old"
    case usd
}

enum Lang: String, Codable, CaseIterable, Hashable {
    case ar, en
}

struct Tx: Codable, Identifiable, Hashable {
    var id: String
    var type: TxType
    /// always new SYP
    var amount: Double
    /// what it was spent on / where it came from, exactly as typed or said
    var note: String
    var date: Date

    static func newID() -> String {
        String(Int(Date().timeIntervalSince1970 * 1000), radix: 36) + String(UUID().uuidString.prefix(6)).lowercased()
    }
}

struct Profile: Codable, Equatable {
    var name: String = ""
    var photo: Data? = nil
    /// new SYP
    var openingBalance: Double = 0
}

struct AppSettings: Codable, Equatable {
    var lang: Lang = .ar
    var currency: CurrencyCode = .sypNew
    /// new SYP per 1 USD
    var usdRate: Double = 110
}

struct PersistedState: Codable, Equatable {
    var onboarded: Bool
    var profile: Profile
    var settings: AppSettings
    var txs: [Tx]
}

struct MonthKey: Hashable, Comparable {
    var year: Int
    var month: Int // 1...12

    static var current: MonthKey {
        let c = Calendar.current.dateComponents([.year, .month], from: Date())
        return MonthKey(year: c.year ?? 2026, month: c.month ?? 1)
    }

    func shifted(by delta: Int) -> MonthKey {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let next = Calendar.current.date(byAdding: .month, value: delta, to: date) ?? date
        let c = Calendar.current.dateComponents([.year, .month], from: next)
        return MonthKey(year: c.year ?? year, month: c.month ?? month)
    }

    func contains(_ date: Date) -> Bool {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return c.year == year && c.month == month
    }

    static func < (a: MonthKey, b: MonthKey) -> Bool {
        (a.year, a.month) < (b.year, b.month)
    }
}

/// One thing the money went on, grouped by the user's own words.
struct SpendItem: Identifiable, Hashable {
    var id: String
    var label: String
    var total: Double
    var isOthers = false
}
