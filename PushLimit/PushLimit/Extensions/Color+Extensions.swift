import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let customBackground = Color(.systemBackground)  // Adapts to light/dark mode
    static let customSecondaryBackground = Color(.secondarySystemBackground)  // Adapts to light/dark mode
    static let customLabel = Color(.label)  // Adapts to light/dark mode (black in light, white in dark)
    static let customSecondaryLabel = Color(.secondaryLabel)  // Already adaptive
    static let customTertiaryLabel = Color(.tertiaryLabel)  // Already adaptive
    static let customHighlight = Color.orange
    static let customError = Color.red
    static let customOrange = Color.orange
    static let customRed = Color.red
} 
