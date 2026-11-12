import Foundation

/// Arabic/English text helpers shared by the voice parser and the icon hints.
/// Port of src/lib/normalize.ts and src/lib/categories.ts (stems) from the Android app.
enum ArabicText {
    private static let scalarMap: [UInt32: String] = {
        var m: [UInt32: String] = [:]
        let indic = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        let persian = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        for (i, d) in indic.enumerated() { m[d.unicodeScalars.first!.value] = String(i) }
        for (i, d) in persian.enumerated() { m[d.unicodeScalars.first!.value] = String(i) }
        for a in ["أ", "إ", "آ", "ٱ"] { m[a.unicodeScalars.first!.value] = "ا" }
        m["ة".unicodeScalars.first!.value] = "ه"
        m["ى".unicodeScalars.first!.value] = "ي"
        m["ؤ".unicodeScalars.first!.value] = "و"
        m["ئ".unicodeScalars.first!.value] = "ي"
        m["٫".unicodeScalars.first!.value] = "."
        return m
    }()

    /// Lowercase, unify Arabic letter variants and digits, drop diacritics.
    static func normalize(_ text: String) -> String {
        var out = ""
        for scalar in text.lowercased().unicodeScalars {
            let v = scalar.value
            if (0x064B...0x0652).contains(v) || v == 0x0640 { continue } // harakat + tatweel
            if let r = scalarMap[v] { out += r } else { out.unicodeScalars.append(scalar) }
        }
        out = out.replacingOccurrences(of: #"(\d),(?=\d{3}\b)"#, with: "$1", options: .regularExpression)
        out = out.replacingOccurrences(of: #"[،,؟?!:;"'()]"#, with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: #"\.(?!\d)"#, with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespaces)
    }

    static func tokens(_ text: String) -> [String] {
        normalize(text).split(separator: " ").map(String.init)
    }

    private static let prefixes = ["وبال", "بال", "وال", "لل", "ال", "عال", "ب", "و", "ل", "ع"]

    /// A token plus its forms without glued prefixes (بالبقالة → بقاله).
    static func stems(_ token: String) -> [String] {
        var out = [token]
        for p in prefixes where token.hasPrefix(p) && token.count - p.count >= 2 {
            out.append(String(token.dropFirst(p.count)))
        }
        return out
    }
}

struct ParsedVoice: Equatable {
    var type: TxType
    /// amount in `unit` (or the user's display currency when nil)
    var amount: Double?
    var unit: CurrencyCode?
    /// everything the user said, kept as the transaction's description
    var note: String
}

/// Port of src/lib/voiceParser.ts. Keep the two in step: both apps must read
/// "صرفت خمسين ألف على البقالة" the same way.
enum VoiceParser {
    // MARK: number words
    private static let small: [String: Double] = [
        "صفر": 0,
        "واحد": 1, "وحده": 1, "واحده": 1,
        "اثنين": 2, "اثنان": 2, "اتنين": 2, "تنين": 2,
        "ثلاث": 3, "ثلاثه": 3, "تلات": 3, "تلاته": 3, "تلت": 3,
        "اربع": 4, "اربعه": 4,
        "خمس": 5, "خمسه": 5,
        "ست": 6, "سته": 6, "سد": 6,
        "سبع": 7, "سبعه": 7,
        "ثمان": 8, "ثماني": 8, "ثمانيه": 8, "تمن": 8, "تمنه": 8, "تماني": 8, "تمانيه": 8,
        "تسع": 9, "تسعه": 9,
        "عشر": 10, "عشره": 10,
        "احدعش": 11, "حدعش": 11, "احدعشر": 11, "حداشر": 11,
        "اثنعش": 12, "اطنعش": 12, "اتنعش": 12, "اثناعشر": 12,
        "ثلطعش": 13, "تلطعش": 13, "تلتعش": 13,
        "اربعطعش": 14, "اربعتعش": 14,
        "خمسطعش": 15, "خمستعش": 15,
        "ستطعش": 16, "سطعش": 16,
        "سبعطعش": 17, "سبعتعش": 17,
        "تمنطعش": 18, "تمانطعش": 18,
        "تسعطعش": 19, "تسعتعش": 19,
        "عشرين": 20, "عشرون": 20,
        "ثلاثين": 30, "تلاتين": 30, "ثلاثون": 30,
        "اربعين": 40, "اربعون": 40,
        "خمسين": 50, "خمسون": 50,
        "ستين": 60, "ستون": 60,
        "سبعين": 70, "سبعون": 70,
        "ثمانين": 80, "تمانين": 80, "ثمانون": 80,
        "تسعين": 90, "تسعون": 90,
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
        "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    private static let hundreds: [String: Double] = [
        "ميه": 100, "مئه": 100, "مايه": 100, "مائه": 100, "hundred": 100,
        "ميتين": 200, "مئتين": 200, "مئتان": 200, "ميتان": 200,
        "ثلاثميه": 300, "تلتميه": 300, "ثلاثمئه": 300,
        "اربعميه": 400, "اربعمئه": 400,
        "خمسميه": 500, "خمسمئه": 500,
        "ستميه": 600, "ستمئه": 600,
        "سبعميه": 700, "سبعمئه": 700,
        "ثمانميه": 800, "تمنميه": 800, "ثمانمئه": 800, "تمانميه": 800,
        "تسعميه": 900, "تسعمئه": 900,
    ]

    private static let scales: [String: Double] = [
        "الف": 1000, "الاف": 1000, "الوف": 1000, "thousand": 1000, "thousands": 1000,
        "الفين": 2000, "الفان": 2000,
        "مليون": 1e6, "ملايين": 1e6, "مليونين": 2e6, "million": 1e6, "millions": 1e6,
        "مليار": 1e9, "billion": 1e9,
    ]
    private static let duals: Set<String> = ["الفين", "الفان", "مليونين"]

    private static let half: Set<String> = ["نص", "نصف", "half"]
    private static let quarter: Set<String> = ["ربع", "quarter"]
    private static let filler: Set<String> = ["و", "and", "a"]

    private enum NumTok {
        case lit(Double), small(Double), hundred(Double), scale(Double, String), half, quarter, filler
    }

    private static func matches(_ s: String, _ pattern: String) -> Bool {
        s.range(of: pattern, options: .regularExpression) != nil
    }

    private static func classify(_ raw: String) -> NumTok? {
        var forms = [raw]
        // conjunction / preposition glued to the number: وخمسين، بعشرين، بـ50
        if (raw.hasPrefix("و") || raw.hasPrefix("ب")) && raw.count > 1 { forms.append(String(raw.dropFirst())) }
        if raw.hasPrefix("وب") || raw.hasPrefix("بال") { forms.append(String(raw.dropFirst(2))) }
        for t in forms {
            if matches(t, #"^\d+(\.\d+)?$"#), let v = Double(t) { return .lit(v) }
            if matches(t, #"^\d+(\.\d+)?[km]$"#), let v = Double(t.dropLast()) {
                return .lit(v * (t.hasSuffix("k") ? 1000 : 1e6))
            }
            if let v = small[t] { return .small(v) }
            if let v = hundreds[t] { return .hundred(v) }
            if let v = scales[t] { return .scale(v, t) }
            if half.contains(t) { return .half }
            if quarter.contains(t) { return .quarter }
        }
        if filler.contains(raw) { return .filler }
        return nil
    }

    /// The first spoken/written amount in a normalized token list.
    static func parseAmount(_ tokens: [String]) -> Double? {
        var total = 0.0
        var current = 0.0
        var lastMag = 1.0 // magnitude of the last group, for "ونص" / "وربع"
        var started = false

        for raw in tokens {
            guard let tok = classify(raw) else {
                if started { break }
                continue
            }
            if case .filler = tok { continue }
            if !started {
                if case .half = tok { continue }
                if case .quarter = tok { continue }
            }
            started = true
            switch tok {
            case .lit(let v), .small(let v):
                current += v
                lastMag = 1
            case .hundred(let v):
                if v == 100 && current > 0 && current < 10 { current *= 100 } else { current += v }
                lastMag = 100
            case .scale(let v, let word):
                let multiplicand = current > 0 ? current : 1
                // "الفين" / "مليونين" already carry their count
                let isDual = duals.contains(word)
                total += (isDual && current == 0) ? v : multiplicand * (isDual ? v / 2 : v)
                current = 0
                lastMag = isDual ? v / 2 : v
            case .half:
                current += lastMag / 2
            case .quarter:
                current += lastMag / 4
            case .filler:
                break
            }
        }
        let value = total + current
        return started && value > 0 ? value : nil
    }

    // MARK: intent and currency
    /// Words that mean money came in.
    private static let incomeWords: Set<String> = [
        "قبضت", "قبضنا", "استلمت", "استلمنا", "وصلني", "وصلتني", "وصلنا", "اجاني", "اجتني", "اجتنا", "جاني",
        "ربحت", "كسبت", "اودعت", "ايداع", "دخل", "نزل", "راتب", "معاش", "حواله", "مكافاه", "عيديه",
        "received", "receive", "got", "earned", "deposit", "deposited", "salary", "income",
    ]
    /// Words that mean money went out.
    private static let expenseWords: Set<String> = [
        "صرفت", "صرفنا", "دفعت", "دفعنا", "اشتريت", "شريت", "اشترينا", "سحبت", "عطيت", "اعطيت", "سددت", "حولت",
        "دفع", "مصروف", "مصاريف", "spent", "spend", "paid", "pay", "bought", "buy", "withdrew", "withdraw",
    ]
    private static let usdWords: Set<String> = ["دولار", "دولارات", "دولارين", "usd", "dollar", "dollars", "$"]
    private static let oldWords: Set<String> = ["قديم", "قديمه", "old"]
    private static let newWords: Set<String> = ["جديد", "جديده", "new"]

    private static func firstIndex(_ tokens: [String], _ words: Set<String>) -> Int? {
        tokens.firstIndex { t in ArabicText.stems(t).contains { words.contains($0) } }
    }

    /// Income or withdraw from the words alone: whichever kind of word comes
    /// first wins ("دفعت من الراتب" is a withdraw). With neither, a withdraw.
    static func detectType(_ tokens: [String]) -> TxType {
        let inc = firstIndex(tokens, incomeWords)
        let exp = firstIndex(tokens, expenseWords)
        switch (inc, exp) {
        case (nil, _): return .expense
        case (_, nil): return .income
        case let (i?, e?): return i < e ? .income : .expense
        }
    }

    static func parse(_ text: String) -> ParsedVoice {
        let tokens = ArabicText.tokens(text.replacingOccurrences(of: "$", with: " $ "))
        let type = detectType(tokens)

        var unit: CurrencyCode?
        if firstIndex(tokens, usdWords) != nil { unit = .usd }
        else if firstIndex(tokens, oldWords) != nil { unit = .sypOld }
        else if firstIndex(tokens, newWords) != nil { unit = .sypNew }

        var amount = parseAmount(tokens)
        // "دولارين" = two dollars with no number
        if amount == nil && tokens.contains(where: { ArabicText.stems($0).contains("دولارين") }) { amount = 2 }

        let note = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return ParsedVoice(type: type, amount: amount, unit: unit, note: note)
    }
}
