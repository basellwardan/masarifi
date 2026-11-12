import Foundation

enum Currency {
    static let oldPerNew: Double = 100

    static func fromNew(_ value: Double, _ cur: CurrencyCode, rate: Double) -> Double {
        switch cur {
        case .sypOld: return value * oldPerNew
        case .usd: return rate > 0 ? value / rate : 0
        case .sypNew: return value
        }
    }

    static func toNew(_ value: Double, _ cur: CurrencyCode, rate: Double) -> Double {
        switch cur {
        case .sypOld: return value / oldPerNew
        case .usd: return value * rate
        case .sypNew: return value
        }
    }

    static func fractionDigits(_ cur: CurrencyCode) -> Int {
        cur == .sypOld ? 0 : 2
    }

    static func symbol(_ cur: CurrencyCode, _ lang: Lang) -> String {
        switch (cur, lang) {
        case (.usd, _): return "$"
        case (.sypOld, .ar): return "ل.س قديمة"
        case (.sypNew, .ar): return "ل.س"
        case (.sypOld, .en): return "old SYP"
        case (.sypNew, .en): return "SYP"
        }
    }

    struct Parts {
        var sign: String
        var int: String
        var frac: String
        var symbol: String
        var symbolFirst: Bool
    }

    private static var formatters: [Int: NumberFormatter] = [:]

    private static func formatter(_ digits: Int) -> NumberFormatter {
        if let f = formatters[digits] { return f }
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.minimumFractionDigits = digits
        f.maximumFractionDigits = digits
        formatters[digits] = f
        return f
    }

    /// Latin digits in both languages, like the reference design ("12,680" + ".42").
    static func parts(_ valueNew: Double, _ cur: CurrencyCode, rate: Double, lang: Lang, signed: Bool = false) -> Parts {
        let v = fromNew(valueNew, cur, rate: rate)
        let digits = fractionDigits(cur)
        let text = formatter(digits).string(from: NSNumber(value: abs(v))) ?? "0"
        var int = text
        var frac = ""
        if let dot = text.firstIndex(of: ".") {
            int = String(text[..<dot])
            frac = String(text[dot...])
        }
        let rounded = (abs(v) * pow(10, Double(digits))).rounded() / pow(10, Double(digits))
        var sign = ""
        if v < 0 && rounded != 0 { sign = "-" } else if signed && v > 0 { sign = "+" }
        return Parts(sign: sign, int: int, frac: frac, symbol: symbol(cur, lang), symbolFirst: cur == .usd)
    }

    /// "12500" → "12,500" in Latin digits.
    static func grouped(_ n: Int) -> String {
        formatter(0).string(from: NSNumber(value: n)) ?? String(n)
    }

    static func format(_ valueNew: Double, _ cur: CurrencyCode, rate: Double, lang: Lang, signed: Bool = false) -> String {
        let p = parts(valueNew, cur, rate: rate, lang: lang, signed: signed)
        return p.symbolFirst ? "\(p.sign)\(p.symbol)\(p.int)\(p.frac)" : "\(p.sign)\(p.int)\(p.frac) \(p.symbol)"
    }
}
