import SwiftUI

enum DDTheme {
    // Orange accent (insulin syringe cap)
    static let accent       = Color(hex: "#FF6B00")
    static let accentLight  = Color(hex: "#FF8C33")
    static let accentTint   = Color(hex: "#FFF3EB")

    // Surfaces
    static let canvas       = Color(hex: "#FAFAFA")
    static let card         = Color.white
    static let cardBorder   = Color(hex: "#E5E5E5")

    // Text
    static let textPrimary   = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#6B6B6B")
    static let textTertiary  = Color(hex: "#999999")

    // Status
    static let statusTaken   = Color(hex: "#22C55E")
    static let statusSkipped = Color(hex: "#9CA3AF")
    static let statusPending = Color(hex: "#FF6B00")

    static let divider = Color(hex: "#EBEBEB")

    // Angular corners (4-8px max)
    static let radiusSmall: CGFloat = 4
    static let radiusMedium: CGFloat = 6
    static let radiusLarge: CGFloat = 8
}
