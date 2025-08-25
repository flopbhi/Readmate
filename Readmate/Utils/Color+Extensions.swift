import SwiftUI

extension Color {
    // A shade lighter than midnight black
    static let appBackground = Color(white: 0.12)
    
    // Main gradient for titles
    static let gradientStart = Color(red: 0.8, green: 0.6, blue: 1.0)
    static let gradientEnd = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let purpleGradient = LinearGradient(
        gradient: Gradient(colors: [gradientStart, gradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Subtle gradient for book list
    static let subtleGradientStart = Color(red: 0.9, green: 0.85, blue: 1.0)
    static let subtlePurpleGradient = LinearGradient(
        gradient: Gradient(colors: [subtleGradientStart, .white]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Solid colors
    static let accentPurple = Color(red: 0.7, green: 0.5, blue: 0.95)
    static let authorText = Color.white.opacity(0.7)
    static let onboardingText = Color(red: 0.9, green: 0.85, blue: 1.0) // A very light purple for onboarding
    static let elementBackground = Color.white.opacity(0.1)
}
