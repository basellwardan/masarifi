import XCTest
@testable import Masarifi

/// Same cases as src/lib/voiceParser.test.ts, so both apps understand speech alike.
final class VoiceParserTests: XCTestCase {
    private func check(_ text: String, _ type: TxType, _ amount: Double?, _ unit: CurrencyCode?,
                       file: StaticString = #filePath, line: UInt = #line) {
        let r = VoiceParser.parse(text)
        XCTAssertEqual(r.type, type, text, file: file, line: line)
        XCTAssertEqual(r.amount, amount, text, file: file, line: line)
        XCTAssertEqual(r.unit, unit, text, file: file, line: line)
    }

    func testArabic() {
        check("صرفت خمسين ألف على البقالة", .expense, 50000, nil)
        check("دفعت ٢٥٠٠ تكسي", .expense, 2500, nil)
        check("اشتريت قميص بعشرين دولار", .expense, 20, .usd)
        check("قبضت الراتب مليون ونص", .income, 1_500_000, nil)
        check("استلمت حوالة من أخي ١٥٠ دولار", .income, 150, .usd)
        check("وصلتني حوالة ١٥٠ دولار", .income, 150, .usd)
        check("ميتين وخمسين ليرة قهوة", .expense, 250, nil)
        check("تلت آلاف وخمسمية بالصيدلية", .expense, 3500, nil)
        check("خمس مية ليرة خبز", .expense, 500, nil)
        check("ألفين ليرة قديمة سرفيس", .expense, 2000, .sypOld)
        check("فاتورة الكهربا ٣٥ ألف ونص", .expense, 35500, nil)
        check("دفعت 12,500 للجامعة.", .expense, 12500, nil)
        check("مية ونص فلافل", .expense, 150, nil)
        check("دفعت من الراتب خمسين ألف إيجار", .expense, 50000, nil)
        check("قبضت مية دولار ودفعت منهم شي", .income, 100, .usd)
    }

    func testEnglish() {
        check("spent 45 dollars on coffee", .expense, 45, .usd)
        check("received salary two million", .income, 2_000_000, nil)
        check("taxi three thousand five hundred", .expense, 3500, nil)
        check("groceries 1.5k", .expense, 1500, nil)
    }

    func testKeepsWords() {
        XCTAssertEqual(VoiceParser.parse("  صرفت خمسين ليرة   على قهوة ").note, "صرفت خمسين ليرة على قهوة")
        XCTAssertNil(VoiceParser.parse("قهوة").amount)
    }

    func testMoneyParts() {
        let p = Currency.parts(12680.42, .sypNew, rate: 110, lang: .en)
        XCTAssertEqual(p.int, "12,680")
        XCTAssertEqual(p.frac, ".42")
        XCTAssertEqual(Currency.parts(1, .sypOld, rate: 110, lang: .ar).int, "100")
        XCTAssertEqual(Currency.format(220, .usd, rate: 110, lang: .en), "$2.00")
    }
}
