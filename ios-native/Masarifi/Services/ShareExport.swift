import SwiftUI
import UIKit

/// "مشاركة مصاريفي": a text summary with the remaining balance and every
/// transaction, plus a CSV file. Same content as src/lib/share.ts.
enum ShareExport {
    static func summary(_ store: AppStore, now: Date = Date()) -> String {
        let t = store.t
        let month = store.txs(in: .current)
        var lines: [String] = []
        let title = store.profile.name.isEmpty ? t.shareTitle : "\(t.shareTitle) — \(store.profile.name)"
        let c = Calendar.current.dateComponents([.year, .month], from: now)
        lines.append("📊 \(title)")
        lines.append("\(DateText.monthName(c.month ?? 1, store.settings.lang)) \(c.year ?? 2026)")
        lines.append("")
        lines.append("💰 \(t.remaining): \(store.money(store.balance))")
        lines.append("📉 \(t.monthSpend): \(store.money(AppStore.sum(month, .expense)))")
        lines.append("📈 \(t.monthIncome): \(store.money(AppStore.sum(month, .income)))")
        lines.append("🧾 \(t.totalExpenses): \(store.money(AppStore.sum(store.txs, .expense)))")

        let items = AppStore.byItem(store.txs, .expense)
        if !items.isEmpty {
            lines.append("")
            lines.append("— \(t.byItem) —")
            for item in items { lines.append("• \(item.label.isEmpty ? t.expense : item.label): \(store.money(item.total))") }
        }
        if !store.txs.isEmpty {
            lines.append("")
            lines.append("— \(t.allTransactions) —")
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_GB")
            f.dateFormat = "d/M/yyyy"
            for tx in store.txs {
                let amount = store.money(tx.type == .expense ? -tx.amount : tx.amount, signed: true)
                lines.append("\(f.string(from: tx.date))  \(store.title(of: tx))  \(amount)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func csvFile(_ store: AppStore) -> URL? {
        let esc: (String) -> String = { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let iso = ISO8601DateFormatter()
        var rows = [[store.t.amount, "note", "date", "type"].map(esc).joined(separator: ",")]
        for tx in store.txs {
            rows.append([
                store.money(tx.type == .expense ? -tx.amount : tx.amount),
                tx.note,
                iso.string(from: tx.date),
                tx.type.rawValue,
            ].map(esc).joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("masarifi.csv")
        do {
            try ("\u{FEFF}" + rows.joined(separator: "\n")).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// The system share sheet (Liquid Glass on iOS 26).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
