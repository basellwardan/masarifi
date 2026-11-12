import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @Namespace private var glass
    @State private var shown = false

    private static let maxBubbles = 6

    var body: some View {
        let t = store.t
        let month = store.txs(in: store.viewMonth)
        let total = AppStore.sum(month, .expense)
        let items = Self.topItems(month, othersLabel: t.others)

        NavigationStack {
            ZStack(alignment: .bottom) {
                Palette.screen.ignoresSafeArea()
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        bubbles(items: items, total: total, size: geo.size, t: t)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    sheet(items: items, total: total, t: t)
                }
            }
            .navigationTitle(DateText.monthTitle(store.viewMonth, store.settings.lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.sheet = .month } label: { Image(systemName: "calendar") }
                        .accessibilityLabel(t.pickMonth)
                }
            }
            .onAppear {
                shown = false
                withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.05)) { shown = true }
            }
            .onChange(of: store.viewMonth) {
                shown = false
                withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.05)) { shown = true }
            }
        }
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

    @ViewBuilder
    private func bubbles(items: [SpendItem], total: Double, size: CGSize, t: Strings) -> some View {
        if items.isEmpty {
            VStack(spacing: 18) {
                Circle().fill(.clear).frame(width: 150, height: 150).liquidGlass(Circle(), clear: true)
                Text(t.noStats).foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let placed = BubbleLayout.place(count: items.count, in: size)
            // one container: neighbouring glass bubbles blend and morph together
            GlassGroup(spacing: 18) {
                ZStack {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let p = placed[index]
                        BubbleView(
                            item: item,
                            label: item.label.isEmpty ? t.expense : item.label,
                            share: total > 0 ? item.total / total : 0,
                            diameter: p.size,
                            shown: shown
                        )
                        .glassID(item.id, in: glass)
                        .scaleEffect(shown ? 1 : 0.2)
                        .opacity(shown ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.68).delay(Double(index) * 0.06), value: shown)
                        .position(x: p.x * size.width, y: p.y * size.height)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        }
    }

    private func sheet(items: [SpendItem], total: Double, t: Strings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(t.expenses).font(.system(size: 23, weight: .semibold))
                Spacer()
                Button(t.viewAll) { store.tab = .tx }.foregroundStyle(Palette.muted)
            }
            MoneyText(value: total, size: 44, weight: .medium, fracColor: Color(hex: 0xB9BABE))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { i in
                    let item = i < items.count ? items[i] : nil
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            Text(item.map { $0.label.isEmpty ? t.expense : $0.label } ?? "—")
                                .font(.system(size: 13.5))
                                .lineLimit(2)
                            Spacer()
                            if let item {
                                Image(systemName: item.isOthers ? "ellipsis" : IconHints.symbol(for: item.label, type: .expense))
                                    .foregroundStyle(Color(hex: 0x8D8E93))
                            }
                        }
                        Spacer(minLength: 12)
                        MoneyText(value: item?.total ?? 0, size: 18, weight: .medium)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                    .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 100)
        .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }
}

/// A glass circle with a lighter pie slice for its share and a thin white arc
/// just outside the edge (the reference design), in real Liquid Glass.
struct BubbleView: View {
    let item: SpendItem
    let label: String
    let share: Double
    let diameter: CGFloat
    let shown: Bool

    var body: some View {
        let small = diameter < 110
        ZStack {
            Circle()
                .trim(from: 0, to: shown ? share : 0)
                .stroke(Color.white.opacity(0.16), lineWidth: diameter / 2)
                .frame(width: diameter / 2, height: diameter / 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.1).delay(0.3), value: shown)
            Circle()
                .trim(from: 0, to: shown ? share : 0)
                .stroke(
                    AngularGradient(colors: [.white.opacity(0.15), .white, .white], center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(360 * max(share, 0.01))),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
                .frame(width: diameter * 1.06, height: diameter * 1.06)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.1).delay(0.3), value: shown)
            VStack(spacing: 3) {
                Image(systemName: item.isOthers ? "ellipsis" : IconHints.symbol(for: item.label, type: .expense))
                    .font(.system(size: max(15, diameter * 0.13)))
                Text(label)
                    .font(.system(size: small ? 10.5 : 12))
                    .lineLimit(small ? 2 : 3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: diameter * 0.78)
                Text(String(format: "%.1f%%", share * 100))
                    .font(.system(size: small ? 13 : 15, weight: .semibold))
                    .monospacedDigit()
                    .environment(\.layoutDirection, .leftToRight)
            }
            .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .liquidGlass(Circle(), tint: .white.opacity(0.04), interactive: true, clear: true)
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
