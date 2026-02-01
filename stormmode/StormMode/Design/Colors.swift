import SwiftUI

// MARK: - StormMode Color Palette
// Inspired by soft, warm aesthetic with pastel accents

extension Color {
    // MARK: - Backgrounds
    static let stormBackground = Color(hex: "F5EDE4")      // Soft peachy beige
    static let stormBackgroundSecondary = Color(hex: "FAF7F2")  // Lighter variant
    
    // MARK: - Card Colors (Pastel)
    static let cardLavender = Color(hex: "C8C3E3")         // Lavender purple
    static let cardMint = Color(hex: "C5DDD6")             // Mint green
    static let cardYellow = Color(hex: "EFE4A7")           // Soft yellow
    static let cardCoral = Color(hex: "E8C4B8")            // Coral/peach
    static let cardSage = Color(hex: "8B9E7E")             // Sage green
    static let cardBlue = Color(hex: "A8C5D9")             // Soft blue
    
    // MARK: - Status Colors
    static let statusOk = Color(hex: "7CB686")             // Green - completed/ok
    static let statusWarning = Color(hex: "E6C86E")        // Yellow - attention
    static let statusUrgent = Color(hex: "E07A5F")         // Coral red - urgent
    static let statusMissed = Color(hex: "D64545")         // Red - missed/critical
    
    // MARK: - Storm Mode Accent
    static let stormActive = Color(hex: "5C6BC0")          // Deep indigo for storm
    static let stormBanner = Color(hex: "7986CB")          // Lighter storm accent
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "2D3142")          // Dark charcoal
    static let textSecondary = Color(hex: "6B7280")        // Gray
    static let textLight = Color(hex: "9CA3AF")            // Light gray
    
    // MARK: - Priority Colors
    static let priorityHigh = Color(hex: "E07A5F")
    static let priorityMedium = Color(hex: "E6C86E")
    static let priorityLow = Color(hex: "7CB686")
    
    // MARK: - Navigation
    static let navActive = Color(hex: "2D3142")
    static let navInactive = Color(hex: "9CA3AF")
}

// MARK: - Hex Color Extension
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Color Array for Random Selection
extension Color {
    static let cardColors: [Color] = [
        .cardLavender,
        .cardMint,
        .cardYellow,
        .cardCoral,
        .cardSage,
        .cardBlue
    ]
    
    static func randomCardColor() -> Color {
        cardColors.randomElement() ?? .cardLavender
    }
}
