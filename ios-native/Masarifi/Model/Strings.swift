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
            ? ["دفعت 25 تكسي", "قبضت الراتب ألفين ونص", "قهوة بعشرين ليرة"]
            : ["Taxi 2500", "Received salary 1.5 million", "Coffee 20 thousand"]
    }

    func currencyName(_ c: CurrencyCode) -> String { self[dynamicMember: c.rawValue] }
    /// Short name that fits a segmented control ("New SYP").
    func currencyShort(_ c: CurrencyCode) -> String { self[dynamicMember: "cur_" + c.rawValue] }

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
        "copied": "انسخ الملخص",
        "saved": "انحفظ",
        "deleted": "انحذف",
        "undo": "تراجع",
        "cur_syp_new": "ل.س جديدة",
        "cur_syp_old": "ل.س قديمة",
        "cur_usd": "دولار",
        "filter": "تصفية",
        "continueTitle": "متابعة",
        "feat1": "سجّل بصوتك",
        "feat1Sub": "احكي شو صرفت، ومصاريفي بيفهم المبلغ وإذا دخل أو مصروف.",
        "feat2": "بالليرة الجديدة",
        "feat2Sub": "وبتقدر تعرض المبالغ بالقديمة أو بالدولار بسعرك.",
        "feat3": "كلشي على جهازك",
        "feat3Sub": "بياناتك محفوظة على تلفونك بدون حساب، وبتقدر تشارك ملخصك.",
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
        "copied": "Summary copied",
        "saved": "Saved",
        "deleted": "Deleted",
        "undo": "Undo",
        "cur_syp_new": "New SYP",
        "cur_syp_old": "Old SYP",
        "cur_usd": "USD",
        "filter": "Filter",
        "continueTitle": "Continue",
        "feat1": "Say it out loud",
        "feat1Sub": "Tell it what you spent and it works out the amount and whether money came in or went out.",
        "feat2": "In the new pound",
        "feat2Sub": "Or show amounts in old pounds or dollars at your own rate.",
        "feat3": "Stays on your phone",
        "feat3Sub": "Everything is saved on your phone with no account, and you can share a summary.",
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

/// An SF Symbol and colour that fit what the user wrote or said (same
/// keyword groups as src/lib/categories.ts). There are no user-facing categories.
struct TxIcon: Equatable {
    let symbol: String
    let hex: UInt32
}

enum IconHints {
    private static let groups: [(TxIcon, [String])] = [
        (TxIcon(symbol: "cart.fill", hex: 0x34C759), ["بقاله", "سوبرماركت", "ماركت", "خضره", "خضار", "فواكه", "فاكهه", "لحمه", "لحم", "خبز", "سمانه", "مونه", "grocery", "groceries", "market", "supermarket", "bread"]),
        (TxIcon(symbol: "tshirt.fill", hex: 0xAF52DE), ["تياب", "ثياب", "ملابس", "لباس", "قميص", "بنطلون", "كنزه", "جاكيت", "صباط", "حذاء", "كندره", "clothes", "shoes", "shirt", "jacket"]),
        (TxIcon(symbol: "cross.case.fill", hex: 0xFF3B30), ["دوا", "دواء", "ادويه", "صيدليه", "دكتور", "طبيب", "مشفى", "مستشفى", "تحاليل", "عياده", "اسنان", "pharmacy", "doctor", "medicine", "hospital"]),
        (TxIcon(symbol: "dumbbell.fill", hex: 0xFF9500), ["نادي", "جيم", "رياضه", "كوره", "مسبح", "gym", "sport", "football"]),
        (TxIcon(symbol: "cup.and.saucer.fill", hex: 0xA2845E), ["مطعم", "قهوه", "كافيه", "كافي", "اركيله", "نركيله", "اكل", "غدا", "عشا", "فطور", "شاورما", "فلافل", "بيتزا", "سندويش", "عصير", "restaurant", "coffee", "cafe", "lunch", "dinner", "breakfast", "food", "pizza"]),
        (TxIcon(symbol: "bus.fill", hex: 0x007AFF), ["تكسي", "تاكسي", "سرفيس", "سرافيس", "باص", "بنزين", "مازوت", "سفر", "مواصلات", "تذكره", "طياره", "taxi", "bus", "fuel", "petrol", "travel", "ticket", "uber"]),
        (TxIcon(symbol: "bolt.fill", hex: 0xFFCC00), ["كهربا", "كهرباء", "مياه", "نت", "انترنت", "فاتوره", "فواتير", "رصيد", "موبايل", "امبير", "امبيرات", "اشتراك", "bill", "bills", "internet", "electricity", "water", "phone"]),
        (TxIcon(symbol: "house.fill", hex: 0x30B0C7), ["ايجار", "اجار", "بيت", "غاز", "جره", "اثاث", "تصليح", "منظفات", "rent", "home", "house", "furniture"]),
        (TxIcon(symbol: "graduationcap.fill", hex: 0x5856D6), ["جامعه", "كتب", "كتاب", "قسط", "دروس", "مدرسه", "دوره", "محاضرات", "نوطه", "university", "school", "books", "course", "tuition"]),
        (TxIcon(symbol: "gift.fill", hex: 0xFF2D55), ["هديه", "هدايا", "عيديه", "gift", "gifts", "present"]),
        (TxIcon(symbol: "banknote.fill", hex: 0x34C759), ["راتب", "معاش", "salary", "paycheck", "wage"]),
        (TxIcon(symbol: "paperplane.fill", hex: 0x32ADE6), ["حواله", "حوالات", "remittance", "transfer"]),
    ]

    private static var cache: [String: TxIcon] = [:]

    static func icon(for text: String, type: TxType) -> TxIcon {
        let key = "\(type.rawValue)|\(text)"
        if let hit = cache[key] { return hit }
        let tokens = ArabicText.tokens(text)
        var found = type == .expense
            ? TxIcon(symbol: "arrow.up.right", hex: 0x8E8E93)
            : TxIcon(symbol: "arrow.down.left", hex: 0x34C759)
        outer: for (icon, words) in groups {
            for t in tokens where ArabicText.stems(t).contains(where: { words.contains($0) }) {
                found = icon
                break outer
            }
        }
        cache[key] = found
        return found
    }
}
