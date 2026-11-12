import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID
    @State private var pastHero = false

    private static let maxBubbles = 6

    var body: some View {
        let t = store.t
        let month = store.txs(in: store.viewMonth)
        let total = AppStore.sum(month, .expense)
        let all = AppStore.byItem(month, .expense)
        let bubbles = Self.topItems(all, othersLabel: t.others)

        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(DateText.monthTitle(store.viewMonth, store.settings.lang))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .contentTransition(.opacity)
                        .padding(.top, 8)
                    BubbleField(items: bubbles, total: total, emptyText: t.noStats, fallbackLabel: t.expense)
                        .frame(height: 400)
                        .padding(.horizontal, 16)
                        .id(store.viewMonth)
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .background(Palette.screen)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36, style: .continuous))

                breakdown(all, total: total, t: t)
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .background(Palette.grouped)
        }
        .background {
            VStack(spacing: 0) { Palette.heroTop; Palette.grouped }.ignoresSafeArea()
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .onScrollGeometryChange(for: Bool.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top > 360
        } action: { _, past in
            pastHero = past
        }
        .toolbarColorScheme(pastHero ? nil : .dark, for: .navigationBar)
    }

    /// The five biggest things the money went on, plus one "Others" bubble for the rest.
    static func topItems(_ items: [SpendItem], othersLabel: String) -> [SpendItem] {
        guard items.count > maxBubbles else { return items }
        let rest = items.dropFirst(maxBubbles - 1).reduce(0) { $0 + $1.total }
        return Array(items.prefix(maxBubbles - 1)) + [SpendItem(id: "__others", label: othersLabel, total: rest, isOthers: true)]
    }

    /// Total and every item with its share, like Screen Time's list.
    private func breakdown(_ items: [SpendItem], total: Double, t: Strings) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(t.expenses).font(.title2.weight(.bold))
                Spacer()
                Button(t.viewAll) {
                    withAnimation { store.activityMode = .list }
                }
            }
            .padding(.horizontal, 4)
            MoneyText(total, size: 40, weight: .bold, relativeTo: .largeTitle)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    let share = total > 0 ? item.total / total : 0
                    HStack(spacing: 12) {
                        CategoryIcon(icon: IconHints.icon(for: item.label, type: .expense), size: 34)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.label.isEmpty ? t.expense : item.label)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                MoneyText(item.total, size: 15, weight: .semibold, relativeTo: .subheadline)
                            }
                            ProgressView(value: share)
                                .tint(Color(hex: IconHints.icon(for: item.label, type: .expense).hex))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    if i < items.count - 1 {
                        Divider().padding(.leading, 62)
                    }
                }
                if items.isEmpty {
                    ContentUnavailableView(t.noStats, systemImage: "chart.pie")
                }
            }
            .background(Palette.card, in: .rect(cornerRadius: 26, style: .continuous))
        }
    }
}

/// Up to six Liquid Glass bubbles in one blend group, placed like the
/// reference layout.
struct BubbleField: View {
    let items: [SpendItem]
    let total: Double
    let emptyText: String
    let fallbackLabel: String
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            if items.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white)
                        .frame(width: 150, height: 150)
                        .glassEffect(.clear, in: .circle)
                    Text(emptyText).font(.headline).foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let placed = BubbleLayout.place(count: items.count, in: size)
                GlassEffectContainer(spacing: 0) {
                    ZStack {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            let p = placed[index]
                            BubbleView(
                                item: item,
                                label: item.label.isEmpty ? fallbackLabel : item.label,
                                share: total > 0 ? item.total / total : 0,
                                diameter: p.size,
                                index: index
                            )
                            .position(x: p.x * size.width, y: p.y * size.height)
                        }
                    }
                    .frame(width: size.width, height: size.height)
                }
                // slot positions are absolute (left/top), like the Android CSS
                .environment(\.layoutDirection, .leftToRight)
            }
        }
    }
}

/// Glass circle with a lighter pie slice for its share and a thin white arc.
struct BubbleView: View {
    @Environment(AppStore.self) private var store
    let item: SpendItem
    let label: String
    let share: Double
    let diameter: CGFloat
    let index: Int
    @State private var popped = false
    @State private var filled = false

    var body: some View {
        let small = diameter < 110
        ZStack {
            Circle()
                .trim(from: 0, to: filled ? share : 0)
                .stroke(Color.white.opacity(0.16), lineWidth: diameter / 2)
                .frame(width: diameter / 2, height: diameter / 2)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: filled ? share : 0)
                .stroke(
                    LinearGradient(stops: [.init(color: .white.opacity(0.15), location: 0),
                                           .init(color: .white, location: 0.35)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: max(1.5, diameter * 0.016), lineCap: .round)
                )
                .frame(width: diameter * 1.06, height: diameter * 1.06)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: item.isOthers ? "ellipsis" : IconHints.icon(for: item.label, type: .expense).symbol)
                    .font(.system(size: max(15, diameter * 0.12), weight: .medium))
                Text(label)
                    .font(.system(size: small ? 11 : 12, weight: .medium))
                    .lineLimit(small ? 2 : 3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: diameter * 0.72)
                    .padding(.top, 4)
                Text(Self.percent(share * 100, store.settings.lang))
                    .font(.system(size: small ? 13 : 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .glassEffect(.clear.tint(.white.opacity(0.06)).interactive(), in: .circle)
        .glassEffectTransition(.materialize)
        .scaleEffect(popped ? 1 : 0.2)
        .opacity(popped ? 1 : 0)
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.05 + Double(index) * 0.06)) { popped = true }
            withAnimation(.easeOut(duration: 1).delay(0.3 + Double(index) * 0.06)) { filled = true }
        }
    }

    static func percent(_ v: Double, _ lang: Lang) -> String {
        let s = String(format: "%.1f", v)
        return (lang == .ar ? s : s.replacingOccurrences(of: ".", with: ",")) + "%"
    }
}

/// Places up to six bubbles at the reference positions, then pushes them apart
/// until each has room to breathe. Port of the Android layout.
enum BubbleLayout {
    struct Placed { var x: CGFloat; var y: CGFloat; var size: CGFloat }

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
