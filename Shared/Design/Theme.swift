import SwiftUI

struct Theme {
    // MARK: - Background Colors
    static let background = Color(hex: "0A0A0A")           // OLED black
    static let surface = Color(hex: "1A1A1A")             // Card background
    static let surfaceElevated = Color(hex: "242424")     // Modal/sheet background
    static let border = Color(hex: "2A2A2A")              // Borders and dividers

    // MARK: - Text Colors
    static let textPrimary = Color(hex: "ECECEC")         // Primary text
    static let textSecondary = Color(hex: "A8A8A8")       // Secondary text
    static let textTertiary = Color(hex: "6E6E6E")        // Disabled/placeholder

    // MARK: - Accent Colors
    static let accent = Color(hex: "D97D5F")              // Primary accent (warm coral)
    static let accentLight = Color(hex: "E89B80")         // Lighter accent (for gradients)
    static let success = Color(hex: "4CAF8C")             // Success green
    static let error = Color(hex: "E57373")               // Error red
    static let warning = Color(hex: "FFB74D")             // Warning amber

    // MARK: - Shadow Colors
    static let shadowDark = Color.black.opacity(0.4)      // Heavy shadows
    static let shadowMedium = Color.black.opacity(0.2)    // Medium shadows
    static let shadowLight = Color.black.opacity(0.1)     // Light shadows

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let backgroundRadialGradient = RadialGradient(
        colors: [surface, background],
        center: .center,
        startRadius: 100,
        endRadius: 400
    )

    // MARK: - Typography
    static func largeTitle() -> Font { .system(size: 64, weight: .semibold) }
    static func title1() -> Font { .system(size: 34, weight: .bold) }
    static func title2() -> Font { .system(size: 28, weight: .semibold) }
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 17, weight: .regular) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func timeLarge() -> Font { .system(size: 80, weight: .medium, design: .monospaced) }
    static func timeMedium() -> Font { .system(size: 40, weight: .medium, design: .monospaced) }
    static func timeSmall() -> Font { .system(size: 24, weight: .regular, design: .monospaced) }

    // MARK: - Animation
    enum AnimationDuration {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.4
        static let spring: Double = 0.6
    }

    enum SpringConfig {
        static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let snappy = Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    }

    // MARK: - Elevation
    enum Elevation {
        case light, medium, heavy

        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .light:
                return (Theme.shadowLight, 8, 0, 2)
            case .medium:
                return (Theme.shadowMedium, 16, 0, 4)
            case .heavy:
                return (Theme.shadowDark, 24, 0, 8)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
