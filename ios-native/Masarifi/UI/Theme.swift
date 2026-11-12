import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// The app's own colours; everything else uses system colours so light,
/// dark and increased-contrast modes work like Apple's apps.
enum Palette {
    static let navy = Color(hex: 0x071A4A)
    static let heroTop = Color(hex: 0x061541)
    static let brand = Color(hex: 0x1D56B0)
    static let teal = Color(hex: 0x3CC6D4)

    static let hero = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x061541), location: 0),
            .init(color: Color(hex: 0x0A2463), location: 0.3),
            .init(color: Color(hex: 0x12408F), location: 0.62),
            .init(color: Color(hex: 0x2B69BF), location: 0.86),
            .init(color: Color(hex: 0x5D95DC), location: 1),
        ],
        startPoint: .top, endPoint: .bottom
    )

    static let screen = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x061541), location: 0),
            .init(color: Color(hex: 0x0A2463), location: 0.38),
            .init(color: Color(hex: 0x12408F), location: 0.7),
            .init(color: Color(hex: 0x2763B9), location: 1),
        ],
        startPoint: .top, endPoint: .bottom
    )

    static let grouped = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
}

extension Animation {
    /// Spring with the given stiffness/damping (mass 1).
    static func framer(_ stiffness: Double, _ damping: Double) -> Animation {
        .interpolatingSpring(mass: 1, stiffness: stiffness, damping: damping)
    }
}

enum Haptic {
    private static let light: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private static let mediumGen: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    static func tap() { light.impactOccurred() }
    static func medium() { mediumGen.impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
