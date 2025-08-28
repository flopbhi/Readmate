import SwiftUI

extension Color {
    static func purpleGradient(for theme: Theme) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [theme.gradientStart, theme.gradientEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func subtlePurpleGradient(for theme: Theme) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [theme.gradientStart.opacity(0.5), theme.primaryColor]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}