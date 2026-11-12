import SwiftUI

/// Lucide icons drawn natively (same outlines as the Android build).
/// Paths are parsed once from `LucideData.swift` and only scaled afterwards.
enum LucidePaths {
    static let all: [LucideIcon: Path] = Dictionary(
        uniqueKeysWithValues: LucideIcon.allCases.map { ($0, parse($0.pathData)) }
    )

    /// Parses absolute M/L/C/Z data ("M4 5L20 5C…Z").
    static func parse(_ d: String) -> Path {
        var path = Path()
        var cmd: Character = " "
        var nums: [CGFloat] = []
        var token = ""

        func flushNumber() {
            if !token.isEmpty, let v = Double(token) { nums.append(CGFloat(v)) }
            token = ""
        }

        func run() {
            switch cmd {
            case "M" where nums.count >= 2:
                path.move(to: CGPoint(x: nums[0], y: nums[1]))
            case "L" where nums.count >= 2:
                path.addLine(to: CGPoint(x: nums[0], y: nums[1]))
            case "C" where nums.count >= 6:
                path.addCurve(to: CGPoint(x: nums[4], y: nums[5]),
                              control1: CGPoint(x: nums[0], y: nums[1]),
                              control2: CGPoint(x: nums[2], y: nums[3]))
            case "Z":
                path.closeSubpath()
            default:
                break
            }
            nums.removeAll(keepingCapacity: true)
        }

        for ch in d {
            if ch.isLetter {
                flushNumber()
                run()
                cmd = ch
            } else if ch == " " || ch == "," {
                flushNumber()
            } else if ch == "-" && !token.isEmpty {
                flushNumber()
                token = "-"
            } else {
                token.append(ch)
            }
        }
        flushNumber()
        run()
        return path
    }
}

struct LucideShape: Shape {
    let icon: LucideIcon

    func path(in rect: CGRect) -> Path {
        let base = LucidePaths.all[icon] ?? Path()
        let s = min(rect.width, rect.height) / 24
        let dx = rect.minX + (rect.width - 24 * s) / 2
        let dy = rect.minY + (rect.height - 24 * s) / 2
        return base.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy))
    }
}

/// `<Icon size={…} strokeWidth={…} />`; colour comes from `.foregroundStyle`.
struct Icon: View {
    let icon: LucideIcon
    var size: CGFloat = 24
    var stroke: CGFloat = 2
    var filled = false

    init(_ icon: LucideIcon, size: CGFloat = 24, stroke: CGFloat = 2, filled: Bool = false) {
        self.icon = icon
        self.size = size
        self.stroke = stroke
        self.filled = filled
    }

    var body: some View {
        let shape = LucideShape(icon: icon)
        // Lucide scales the stroke with the icon (strokeWidth is in the 24px box)
        let style = StrokeStyle(lineWidth: stroke * size / 24, lineCap: .round, lineJoin: .round)
        ZStack {
            if filled { shape.fill() }
            shape.stroke(style: style)
        }
        .frame(width: size, height: size)
        // SVG icons are never mirrored in the APK, even in Arabic
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}
