import SwiftUI
import UIKit

// MARK: - Money

/// An amount in SF Pro Rounded: muted fraction, smaller currency, and digits
/// that roll when the value changes (numeric content transition).
struct MoneyText: View {
    @Environment(AppStore.self) private var store
    let value: Double
    var signed = false
    var weight: Font.Weight = .semibold
    @ScaledMetric private var size: CGFloat

    init(_ value: Double, size: CGFloat = 17, weight: Font.Weight = .semibold, signed: Bool = false,
         relativeTo style: Font.TextStyle = .body) {
        self.value = value
        self.weight = weight
        self.signed = signed
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    var body: some View {
        let s = store.settings
        let p = Currency.parts(value, s.currency, rate: s.usdRate, lang: s.lang, signed: signed)
        let number = Text("\u{2066}\(p.sign)\(p.symbolFirst ? p.symbol : "")\(p.int)")
            + Text(p.frac).foregroundStyle(.secondary)
            + Text("\u{2069}")
        let symbol = p.symbolFirst
            ? Text("")
            : Text(" \(p.symbol)").font(.system(size: max(11, size * 0.45), weight: .medium)).foregroundStyle(.secondary)
        (number + symbol)
            .font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(value: value))
            .animation(.snappy, value: value)
            .animation(.snappy, value: s.currency)
    }
}

// MARK: - Icons

/// White SF Symbol on a coloured circle, like Wallet's transaction rows.
struct CategoryIcon: View {
    let icon: TxIcon
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: icon.hex).gradient, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Rounded-square icon used in Settings rows (like the Settings app).
struct SettingsIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Avatar

struct AvatarView: View {
    @Environment(AppStore.self) private var store
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            if let data = store.profile.photo, let image = PhotoCache.image(data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Palette.teal, Palette.brand], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(initial)
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initial: String {
        store.profile.name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "م"
    }
}

/// Decodes the avatar photo once instead of on every redraw.
enum PhotoCache {
    private static var last: (Data, UIImage)?

    static func image(_ data: Data) -> UIImage? {
        if let last, last.0 == data { return last.1 }
        guard let img = UIImage(data: data) else { return nil }
        last = (data, img)
        return img
    }
}

// MARK: - Transaction row

struct TxRow: View {
    @Environment(AppStore.self) private var store
    let tx: Tx

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(icon: IconHints.icon(for: tx.note, type: tx.type))
            VStack(alignment: .leading, spacing: 2) {
                Text(store.title(of: tx))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(DateText.txDate(tx.date, store.t))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            MoneyText(tx.type == .expense ? -tx.amount : tx.amount, size: 17, signed: tx.type == .income)
                .foregroundStyle(tx.type == .income ? Color.green : Color.primary)
        }
        .contentShape(Rectangle())
    }
}

/// Edit / Delete menu for a transaction (long press).
struct TxMenu: View {
    @Environment(AppStore.self) private var store
    let tx: Tx
    let source: String

    var body: some View {
        let t = store.t
        Button(t.edit, systemImage: "pencil") {
            store.openSheet(.add(tx.type, editID: tx.id, prefill: nil), from: source)
        }
        Divider()
        Button(t.delete, systemImage: "trash", role: .destructive) {
            deleteWithUndo(tx, store)
        }
    }
}

/// Deletes with an Undo toast.
func deleteWithUndo(_ tx: Tx, _ store: AppStore) {
    Haptic.medium()
    let removed = withAnimation(.snappy) { store.deleteTx(tx.id) }
    if let removed { store.showToast(store.t.deleted, undo: removed) }
}

// MARK: - Glass

/// Glass chip on the navy gradient (change this month, income, …).
struct GlassChip<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) { content }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassEffect(.clear.tint(.white.opacity(0.08)), in: .capsule)
    }
}

// MARK: - Toast

/// Glass capsule that drops in from the top ("Saved", "Deleted · Undo").
struct ToastView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            if let toast = store.toast {
                HStack(spacing: 12) {
                    Image(systemName: toast.undo == nil ? "checkmark.circle.fill" : "trash.fill")
                        .foregroundStyle(toast.undo == nil ? Color.green : Color.secondary)
                    Text(toast.message).font(.subheadline.weight(.semibold))
                    if let undo = toast.undo {
                        Button(store.t.undo) {
                            withAnimation(.snappy) { store.restoreTx(undo) }
                            store.hideToast()
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, toast.undo == nil ? 18 : 8)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
                .id(toast.id)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.toast)
        .padding(.top, 4)
    }
}

// MARK: - Layout

/// Wraps chips onto centred lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(proposal.width ?? .infinity, subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in makeRows(bounds.width, subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for i in row.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func makeRows(_ maxWidth: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let last = rows.count - 1
            let extra = rows[last].items.isEmpty ? size.width : size.width + spacing
            if rows[last].width + extra > maxWidth && !rows[last].items.isEmpty {
                rows.append(Row())
            }
            let j = rows.count - 1
            rows[j].width += rows[j].items.isEmpty ? size.width : size.width + spacing
            rows[j].items.append(i)
            rows[j].height = max(rows[j].height, size.height)
        }
        return rows.filter { !$0.items.isEmpty }
    }
}

// MARK: - System bridges

/// System share sheet, presented from UIKit (text summary + CSV file).
enum ShareSheet {
    static func present(_ items: [Any]) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController else { return }
        var top = root
        while let next = top.presentedViewController { top = next }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = top.view
        top.present(vc, animated: true)
    }
}

enum PhotoTools {
    /// Square-crops and shrinks a picked photo for the avatar.
    static func square(_ data: Data, size: CGFloat = 192) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let side = min(image.size.width, image.size.height)
        let crop = CGRect(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2, width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let out = renderer.image { _ in
            image.draw(in: CGRect(x: -crop.minX * size / side, y: -crop.minY * size / side,
                                  width: image.size.width * size / side, height: image.size.height * size / side))
        }
        return out.jpegData(compressionQuality: 0.85)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
