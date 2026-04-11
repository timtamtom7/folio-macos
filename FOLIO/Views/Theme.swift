import SwiftUI

struct Theme {
    // MARK: - Color
    static let accentColor = Color(hex: "#4A90D9")
    static let unreadColor = Color.blue
    static let favoriteColor = Color.orange
    static let readAlpha: Double = 0.6

    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
    static let articleListBackground = Color(nsColor: .windowBackgroundColor)
    static let readerBackground = Color(nsColor: .textBackgroundColor)

    // MARK: - Typography
    static let fontTitle = Font.headline
    static let fontBody = Font.body
    static let fontCaption = Font.caption

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusMedium: CGFloat = 8
    static let cornerRadiusLarge: CGFloat = 12
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
