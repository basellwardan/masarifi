import Foundation

/// UI text in Arabic (default) and English. Same wording as src/lib/i18n.ts.
/// `t.balance` reads the key "balance"; a missing key shows the key itself.
@dynamicMemberLookup
struct Strings {
    let lang: Lang
    private let table: [String: String]

    subscript(dynamicMember key: String) -> String { table[key] ?? key }

    var voiceExamples: [String] {
        lang == .ar
            ? ["دفعت 25 تكسي", "قبضت الراتب ألفين ونص", "صرفت خمسين ليرة على قهوة"]
            : ["Paid 25 for a taxi", "Received salary 2,500", "Spent 50 on coffee"]
    }

    func currencyName(_ c: CurrencyCode) -> String { self[dynamicMember: c.rawValue] }

    static func of(_ lang: Lang) -> Strings { lang == .ar ? ar : en }

    static let ar = Strings(lang: .ar, table: [
        "appName": "مصاريفي",
        "tagline": "كل ليرة بمكانها.\nتابع مصاريفك بالليرة الجديدة ببساطة.",
        "welcome": "أهلاً فيك 👋",
        "start": "ابدأ",
        "next": "التالي",
        "back": "رجوع",
        "done": "تم",
        "yourName": "شو اسمك؟",
        "namePlaceholder": "اكتب اسمك",
        "addPhoto": "أضف صورة",
        "startingBalance": "كم معك هلق؟",
        "startingHint": "رصيدك الحالي، بتقدر تعدله لاحقاً",
        "allSet": "كلشي جاهز",
        "allSetHint": "سجّل مصاريفك بالكتابة أو بصوتك من زر المايك.",
        "letsGo": "يلا نبدأ",
        "home": "الرئيسية",
        "balance": "الرصيد",
        "thisMonth": "هذا الشهر",
        "deposit": "إيداع",
        "withdraw": "سحب",
        "recent": "آخر العمليات",
        "viewAll": "عرض الكل",
        "noTx": "لسا ما في عمليات",
        "noTxHint": "اضغط إيداع أو سحب، أو احكي بالمايك",
        "today": "اليوم",
        "yesterday": "مبارح",
        "transactions": "العمليات",
        "all": "الكل",
        "expenses": "المصاريف",
        "income": "الدخل",
        "monthSpend": "مصاريف الشهر",
        "monthIncome": "دخل الشهر",
        "stats": "الإحصائيات",
        "noStats": "ما في مصاريف بهالشهر",
        "voice": "إدخال صوتي",
        "tapToSpeak": "اضغط واحكي",
        "listening": "عم اسمعك…",
        "voiceHint": "مثلاً: \"صرفت خمسين ألف على البقالة\"",
        "quickAdd": "احكي مصروفك…",
        "didntCatch": "ما فهمت المبلغ، جرّب مرة تانية",
        "micUnavailable": "التعرّف على الصوت غير متاح على هالجهاز",
        "micDenied": "لازم تسمح باستخدام المايك والتعرّف على الكلام من الإعدادات",
        "confirm": "تأكيد",
        "edit": "تعديل",
        "cancel": "إلغاء",
        "save": "حفظ",
        "delete": "حذف",
        "amount": "المبلغ",
        "notePlaceholderExpense": "على شو صرفت؟ مثلاً: قهوة مع الشباب",
        "notePlaceholderIncome": "من وين إجت المصاري؟ مثلاً: الراتب",
        "others": "أخرى",
        "swipeHint": "اسحب البطاقة لتغيير الشهر",
        "expense": "مصروف",
        "incomeOne": "دخل",
        "settings": "الإعدادات",
        "language": "اللغة",
        "currency": "العملة",
        "syp_new": "ليرة سورية جديدة",
        "syp_old": "ليرة سورية قديمة",
        "usd": "دولار أمريكي",
        "usdRate": "سعر الدولار",
        "usdRateHint": "كم ليرة جديدة بالدولار",
        "oldNote": "1 ليرة جديدة = 100 ليرة قديمة",
        "share": "مشاركة مصاريفي",
        "shareHint": "كل المصاريف مع الرصيد المتبقي",
        "profile": "الملف الشخصي",
        "name": "الاسم",
        "editBalance": "الرصيد الافتتاحي",
        "reset": "مسح كل البيانات",
        "resetConfirm": "متأكد؟ رح تنمسح كل العمليات",
        "about": "حول التطبيق",
        "version": "الإصدار",
        "notifications": "الإشعارات",
        "noNotifications": "ما في إشعارات جديدة",
        "spentMoreThan": "صرفت هالشهر أكتر من دخلك",
        "topCategory": "أكتر شي صرفت عليه",
        "pickMonth": "اختر الشهر",
        "remaining": "الرصيد المتبقي",
        "totalExpenses": "مجموع المصاريف",
        "byItem": "على شو انصرفت",
        "allTransactions": "كل العمليات",
        "shareTitle": "مصاريفي",
        "swap": "تبديل العملة",
    ])

    static let en = Strings(lang: .en, table: [
        "appName": "My Expenses",
        "tagline": "Every pound in its place.\nTrack your spending in the new Syrian pound.",
        "welcome": "Welcome 👋",
        "start": "Get started",
        "next": "Next",
        "back": "Back",
        "done": "Done",
        "yourName": "What's your name?",
        "namePlaceholder": "Your name",
        "addPhoto": "Add photo",
        "startingBalance": "How much do you have now?",
        "startingHint": "Your current balance, you can change it later",
        "allSet": "You're all set",
        "allSetHint": "Log expenses by typing or with your voice from the mic button.",
        "letsGo": "Let's go",
        "home": "Home",
        "balance": "Balance",
        "thisMonth": "this month",
        "deposit": "Deposit",
        "withdraw": "Withdraw",
        "recent": "Recent Transactions",
        "viewAll": "View All",
        "noTx": "No transactions yet",
        "noTxHint": "Tap Deposit or Withdraw, or use the mic",
        "today": "Today",
        "yesterday": "Yesterday",
        "transactions": "Transactions",
        "all": "All",
        "expenses": "Expenses",
        "income": "Income",
        "monthSpend": "Spent this month",
        "monthIncome": "Income this month",
        "stats": "Statistics",
        "noStats": "No expenses this month",
        "voice": "Voice",
        "tapToSpeak": "Tap and speak",
        "listening": "Listening…",
        "voiceHint": "e.g. \"Spent 50 thousand on groceries\"",
        "quickAdd": "Say an expense…",
        "didntCatch": "Didn't catch the amount, try again",
        "micUnavailable": "Speech recognition is not available on this device",
        "micDenied": "Allow the microphone and speech recognition in Settings",
        "confirm": "Confirm",
        "edit": "Edit",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "amount": "Amount",
        "notePlaceholderExpense": "What was it for? e.g. coffee with friends",
        "notePlaceholderIncome": "Where did it come from? e.g. salary",
        "others": "Others",
        "swipeHint": "Swipe the card to change the month",
        "expense": "Expense",
        "incomeOne": "Income",
        "settings": "Settings",
        "language": "Language",
        "currency": "Currency",
        "syp_new": "New Syrian pound",
        "syp_old": "Old Syrian pound",
        "usd": "US dollar",
        "usdRate": "Dollar rate",
        "usdRateHint": "New SYP per 1 USD",
        "oldNote": "1 new pound = 100 old pounds",
        "share": "Share my expenses",
        "shareHint": "All expenses with the remaining balance",
        "profile": "Profile",
        "name": "Name",
        "editBalance": "Opening balance",
        "reset": "Erase all data",
        "resetConfirm": "Are you sure? All transactions will be deleted",
        "about": "About",
        "version": "Version",
        "notifications": "Notifications",
        "noNotifications": "No new notifications",
        "spentMoreThan": "You spent more than you earned this month",
        "topCategory": "What you spent the most on",
        "pickMonth": "Pick a month",
        "remaining": "Remaining balance",
        "totalExpenses": "Total expenses",
        "byItem": "Where it went",
        "allTransactions": "All transactions",
        "shareTitle": "My Expenses",
        "swap": "Switch currency",
    ])
}

enum DateText {
    private static let arMonths = [
        "كانون الثاني", "شباط", "آذار", "نيسان", "أيار", "حزيران",
        "تموز", "آب", "أيلول", "تشرين الأول", "تشرين الثاني", "كانون الأول",
    ]

    /// Levantine month names in Arabic (كانون الثاني …), English otherwise. `month` is 1...12.
    static func monthName(_ month: Int, _ lang: Lang, short: Bool = false) -> String {
        if lang == .ar { return arMonths[(month - 1 + 12) % 12] }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        let names = short ? f.shortMonthSymbols! : f.monthSymbols!
        return names[(month - 1 + 12) % 12]
    }

    static func monthTitle(_ key: MonthKey, _ lang: Lang) -> String {
        "\(monthName(key.month, lang)) \(key.year)"
    }

    private static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func txDate(_ date: Date, _ t: Strings) -> String {
        let cal = Calendar.current
        let sep = t.lang == .ar ? "،" : ","
        if cal.isDateInToday(date) { return "\(t.today)\(sep) \(time(date))" }
        if cal.isDateInYesterday(date) { return "\(t.yesterday)\(sep) \(time(date))" }
        let c = cal.dateComponents([.day, .month], from: date)
        let day = c.day ?? 1
        let month = c.month ?? 1
        let d = t.lang == .ar ? "\(day) \(monthName(month, .ar))" : "\(monthName(month, .en, short: true)) \(day)"
        return "\(d)\(sep) \(time(date))"
    }

    static func dayHeader(_ date: Date, _ t: Strings) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return t.today }
        if cal.isDateInYesterday(date) { return t.yesterday }
        let c = cal.dateComponents([.day, .month, .year], from: date)
        let (d, m, y) = (c.day ?? 1, c.month ?? 1, c.year ?? 2026)
        return t.lang == .ar ? "\(d) \(monthName(m, .ar)) \(y)" : "\(monthName(m, .en)) \(d), \(y)"
    }
}

/// Picks an SF Symbol that fits what the user wrote/said. There are no
/// user-facing categories; this only chooses an icon.
enum IconHints {
    private static let groups: [(String, [String])] = [
        ("cart", ["بقاله", "سوبرماركت", "ماركت", "خضره", "خضار", "فواكه", "فاكهه", "لحمه", "لحم", "خبز", "سمانه", "مونه", "grocery", "groceries", "market", "supermarket", "bread"]),
        ("tshirt", ["تياب", "ثياب", "ملابس", "لباس", "قميص", "بنطلون", "كنزه", "جاكيت", "صباط", "حذاء", "كندره", "clothes", "shoes", "shirt", "jacket"]),
        ("cross.case", ["دوا", "دواء", "ادويه", "صيدليه", "دكتور", "طبيب", "مشفى", "مستشفى", "تحاليل", "عياده", "اسنان", "pharmacy", "doctor", "medicine", "hospital"]),
        ("dumbbell", ["نادي", "جيم", "رياضه", "كوره", "مسبح", "gym", "sport", "football"]),
        ("cup.and.saucer", ["مطعم", "قهوه", "كافيه", "كافي", "اركيله", "نركيله", "اكل", "غدا", "عشا", "فطور", "شاورما", "فلافل", "بيتزا", "سندويش", "عصير", "restaurant", "coffee", "cafe", "lunch", "dinner", "breakfast", "food", "pizza"]),
        ("bus", ["تكسي", "تاكسي", "سرفيس", "سرافيس", "باص", "بنزين", "مازوت", "سفر", "مواصلات", "تذكره", "طياره", "taxi", "bus", "fuel", "petrol", "travel", "ticket", "uber"]),
        ("doc.text", ["كهربا", "كهرباء", "مياه", "نت", "انترنت", "فاتوره", "فواتير", "رصيد", "موبايل", "امبير", "امبيرات", "اشتراك", "bill", "bills", "internet", "electricity", "water", "phone"]),
        ("house", ["ايجار", "اجار", "بيت", "غاز", "جره", "اثاث", "تصليح", "منظفات", "rent", "home", "house", "furniture"]),
        ("graduationcap", ["جامعه", "كتب", "كتاب", "قسط", "دروس", "مدرسه", "دوره", "محاضرات", "نوطه", "university", "school", "books", "course", "tuition"]),
        ("gift", ["هديه", "هدايا", "عيديه", "gift", "gifts", "present"]),
        ("banknote", ["راتب", "معاش", "salary", "paycheck", "wage"]),
        ("paperplane", ["حواله", "حوالات", "remittance", "transfer"]),
    ]

    private static var cache: [String: String] = [:]

    static func symbol(for text: String, type: TxType) -> String {
        let key = "\(type.rawValue)|\(text)"
        if let hit = cache[key] { return hit }
        let tokens = ArabicText.tokens(text)
        var found = type == .expense ? "arrow.up.right" : "arrow.down.left"
        outer: for (symbol, words) in groups {
            for t in tokens where ArabicText.stems(t).contains(where: { words.contains($0) }) {
                found = symbol
                break outer
            }
        }
        cache[key] = found
        return found
    }
}
