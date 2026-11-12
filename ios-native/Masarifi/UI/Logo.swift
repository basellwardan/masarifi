import SwiftUI

/// The two-capsule diamond mark (same geometry as src/components/Logo.tsx),
/// drawn natively so it stays sharp at any size.
struct LogoMark: View {
    var size: CGFloat = 120
    var animated = false
    @State private var together = false

    private static let stops: [Gradient.Stop] = [
        .init(color: Color(hex: 0x5ED6DE), location: 0),
        .init(color: Color(hex: 0x2F8FD6), location: 0.38),
        .init(color: Color(hex: 0x0D2E7A), location: 0.66),
        .init(color: Color(hex: 0x3CC6D4), location: 1),
    ]

    private func piece(top: Bool) -> some View {
        // left bar: rounded inner end at the top; right bar: at the bottom
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: top ? 8 : 6,
            bottomLeadingRadius: top ? 8 : 20.5,
            bottomTrailingRadius: top ? 6 : 8,
            topTrailingRadius: top ? 20.5 : 8,
            style: .continuous
        )
        return shape
            .fill(LinearGradient(stops: Self.stops, startPoint: top ? .top : .bottom, endPoint: top ? .bottom : .top))
            .overlay(
                shape.fill(LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0)], startPoint: .leading, endPoint: UnitPoint(x: 0.6, y: 0.5)))
            )
            .frame(width: 43, height: 88)
    }

    var body: some View {
        let shift: CGFloat = animated && !together ? 22 : 0
        ZStack {
            piece(top: true)
                .position(x: 37.5, y: 60)
                .offset(y: -shift)
                .opacity(animated && !together ? 0 : 1)
            piece(top: false)
                .position(x: 82.5, y: 60)
                .offset(y: shift)
                .opacity(animated && !together ? 0 : 1)
        }
        .frame(width: 120, height: 120)
        .rotationEffect(.degrees(45))
        .scaleEffect(size / 120)
        .frame(width: size, height: size)
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            guard animated else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.15)) { together = true }
        }
    }
}
