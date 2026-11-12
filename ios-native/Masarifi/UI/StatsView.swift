import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var sheetIn = false

    private static let maxBubbles = 6

    var body: some View {
        let t = store.t
        let month = store.txs(in: store.viewMonth)
        let total = AppStore.sum(month, .expense)
        let items = Self.topItems(month, othersLabel: t.others)

        VStack(spacing: 0) {
            GradHeader(title: DateText.monthTitle(store.viewMonth, store.settings.lang), action: AnyView(
                GlassCircleButton(icon: .calendar, label: t.pickMonth) { store.openSheet(.month) }
            ))

            GeometryReader { geo in
                BubbleField(items: items, total: total, size: geo.size, emptyText: t.noStats, fallbackLabel: t.expense)
                    .id(store.viewMonth)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            sheet(items: items, total: total, t: t)
                .offset(y: sheetIn ? 0 : 120)
        }
        .background(Palette.screen)
        .onAppear { withAnimation(.framer(200, 26)) { sheetIn = true } }
    }

    /// The five biggest things the money went on, plus one "Others" bubble for the rest.
    static func topItems(_ month: [Tx], othersLabel: String) -> [SpendItem] {
        var items = AppStore.byItem(month, .expense)
        if items.count > maxBubbles {
            let rest = items.dropFirst(maxBubbles - 1).reduce(0) { $0 + $1.total }
            items = Array(items.prefix(maxBubbles - 1))
            items.append(SpendItem(id: "__others", label: othersLabel, total: rest, isOthers: true))
        }
        return items
    }

    private func sheet(items: [SpendItem], total: Double, t: Strings) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(t.expenses).ui(23, .semibold).foregroundStyle(Palette.ink)
                Spacer()
                Button(t.viewAll) { store.setTab(.tx) }
                    .buttonStyle(.plain)
                    .ui(16)
                    .foregroundStyle(Palette.muted)
            }
            MoneyView(value: total, style: .big(metrics.width), countUp: true)
                .padding(.top, 14)
                .padding(.bottom, 18)
            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { i in
                    StatTile(item: i < items.count ? items[i] : nil, fallbackLabel: t.expense)
                        .modifier(Rise(index: i, distance: 14, delay: 0.25 + Double(i) * 0.08))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, metrics.bottom + 92)
        .background(
            WhiteSheetShape()
                .fill(.white)
                .shadow(color: Color(hex: 0x050F33, opacity: 0.18), radius: 15, y: -8)
        )
    }
}

struct StatTile: View {
    let item: SpendItem?
    let fallbackLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(item.map { $0.label.isEmpty ? fallbackLabel : $0.label } ?? "—")
                    .ui(13.5)
                    .foregroundStyle(Palette.ink2)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let item {
                    Icon(item.isOthers ? .ellipsis : IconHints.icon(for: item.label, type: .expense), size: 17, stroke: 1.6)
                        .foregroundStyle(Palette.tileIcon)
                }
            }
            Spacer(minLength: 14)
            MoneyView(value: item?.total ?? 0, style: .tile)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
    }
}

/// Up to six Liquid Glass bubbles placed like the reference layout.
struct BubbleField: View {
    let items: [SpendItem]
    let total: Double
    let size: CGSize
    let emptyText: String
    let fallbackLabel: String
    @State private var shown = false

    var body: some View {
        Group {
            if items.isEmpty {
                VStack(spacing: 18) {
                    Color.clear
                        .frame(width: 150, height: 150)
                        .darkGlass(Circle(), fill: 0.12)
                    Text(emptyText).ui(16).foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(shown ? 1 : 0.9)
                .opacity(shown ? 1 : 0)
            } else {
                let placed = BubbleLayout.place(count: items.count, in: size)
                GlassGroup {
                    ZStack {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            let p = placed[index]
                            BubbleView(
                                item: item,
                                label: item.label.isEmpty ? fallbackLabel : item.label,
                                share: total > 0 ? item.total / total : 0,
                                diameter: p.size,
                                index: index,
                                shown: shown
                            )
                            .position(x: p.x * size.width, y: p.y * size.height)
                        }
                    }
                    .frame(width: size.width, height: size.height)
                }
                // slot positions are absolute (left/top), like the CSS
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { shown = true } }
    }
}

/// A glass circle with a lighter pie slice for its share and a thin white arc
/// just outside the edge.
struct BubbleView: View {
    @Environment(\.appLang) private var lang
    let item: SpendItem
    let label: String
    let share: Double
    let diameter: CGFloat
    let index: Int
    let shown: Bool
    @State private var popped = false
    @State private var filled = false

    var body: some View {
        let small = diameter < 110
        ZStack {
            // lighter pie sector for the share
            Circle()
                .trim(from: 0, to: filled ? share : 0)
                .stroke(Color.white.opacity(0.16), lineWidth: diameter / 2)
                .frame(width: diameter / 2, height: diameter / 2)
                .rotationEffect(.degrees(-90))
            // thin white arc just outside the edge
            Circle()
                .trim(from: 0, to: filled ? share : 0)
                .stroke(
                    LinearGradient(stops: [.init(color: .white.opacity(0.15), location: 0),
                                           .init(color: .white, location: 0.35)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: diameter * 0.016, lineCap: .round)
                )
                .frame(width: diameter * 1.06, height: diameter * 1.06)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Icon(item.isOthers ? .ellipsis : IconHints.icon(for: item.label, type: .expense),
                     size: max(18, diameter * 0.13), stroke: 1.5)
                Text(label)
                    .font(AppFont.ui(small ? 10.5 : 12, .regular, lang))
                    .lineLimit(small ? 2 : 3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .opacity(0.95)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: diameter * 0.8)
                    .padding(.top, 6)
                Text(Self.percent(share * 100, lang))
                    .font(AppFont.num(15, .semibold))
                    .tracking(-0.3)
                    .padding(.top, 2)
            }
            .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .darkGlass(Circle(), fill: 0.12, interactive: true)
        .scaleEffect(popped ? 1 : 0.01)
        .opacity(popped ? 1 : 0)
        .onAppear {
            withAnimation(.framer(160, 15).delay(0.08 + Double(index) * 0.07)) { popped = true }
            withAnimation(.easeOutApp(1.1).delay(0.35 + Double(index) * 0.07)) { filled = true }
        }
    }

    /// "14.4%" in Arabic, "14,4%" in English (same locales as the Android build).
    static func percent(_ v: Double, _ lang: Lang) -> String {
        let s = String(format: "%.1f", v)
        return (lang == .ar ? s : s.replacingOccurrences(of: ".", with: ",")) + "%"
    }
}

/// Places up to six bubbles at the reference positions, then pushes them apart
/// until each has room to breathe. Port of the Android layout.
enum BubbleLayout {
    struct Placed { var x: CGFloat; var y: CGFloat; var size: CGFloat }

    // biggest first; the last (smallest) slot is where "Others" lands
    private static let slots: [(x: CGFloat, y: CGFloat, d: CGFloat)] = [
        (0.70, 0.52, 0.47), (0.29, 0.25, 0.43), (0.30, 0.80, 0.37),
        (0.72, 0.15, 0.30), (0.71, 0.85, 0.29), (0.23, 0.53, 0.27),
    ]
    private static let gap: CGFloat = 16

    static func place(count: Int, in size: CGSize) -> [Placed] {
        let w = max(size.width, 1), h = max(size.height, 1)
        let unit = min(w, h * 0.8)
        let n = min(count, slots.count)
        var scale: CGFloat = 0.94
        let outer: (CGFloat) -> CGFloat = { $0 * 1.06 + 2 }
        for _ in 0..<12 {
            var b = slots.prefix(n).map { (x: $0.x * w, y: $0.y * h, r: $0.d * unit * scale / 2) }
            for _ in 0..<300 {
                var moved = false
                for i in 0..<b.count {
                    for j in (i + 1)..<max(b.count, i + 1) where j < b.count {
                        let dx = b[j].x - b[i].x, dy = b[j].y - b[i].y
                        let dist = max(hypot(dx, dy), 0.01)
                        let need = outer(b[i].r) + outer(b[j].r) + gap
                        if dist < need {
                            let push = (need - dist) / 2
                            b[i].x -= dx / dist * push; b[i].y -= dy / dist * push
                            b[j].x += dx / dist * push; b[j].y += dy / dist * push
                            moved = true
                        }
                    }
                }
                for k in 0..<b.count {
                    let m = outer(b[k].r) + 4
                    b[k].x = min(max(b[k].x, m), w - m)
                    b[k].y = min(max(b[k].y, m), h - m)
                }
                if !moved { break }
            }
            var ok = true
            for i in 0..<b.count {
                for j in (i + 1)..<max(b.count, i + 1) where j < b.count {
                    if hypot(b[i].x - b[j].x, b[i].y - b[j].y) < outer(b[i].r) + outer(b[j].r) + gap - 0.5 { ok = false }
                }
            }
            if ok { return b.map { Placed(x: $0.x / w, y: $0.y / h, size: $0.r * 2) } }
            scale *= 0.94
        }
        return slots.prefix(n).map { Placed(x: $0.x, y: $0.y, size: $0.d * unit * scale) }
    }
}
