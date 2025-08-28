import Foundation
import SwiftUI

enum Theme: String, CaseIterable, Identifiable {
    case dark

    var id: String { self.rawValue }

    var primaryColor: Color {
        return Color.black
    }

    var secondaryColor: Color {
        return Color.white
    }

    var appBackground: Color {
        return Color(white: 0.12)
    }

    var gradientStart: Color {
        return Color(red: 0.8, green: 0.6, blue: 1.0)
    }

    var gradientEnd: Color {
        return Color(red: 0.6, green: 0.4, blue: 0.9)
    }

    var accentPurple: Color {
        return Color(red: 0.7, green: 0.5, blue: 0.95)
    }

    var authorText: Color {
        return Color.white.opacity(0.7)
    }

    var elementBackground: Color {
        return Color.white.opacity(0.1)
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .dark

    private let themeKey = "currentTheme"

    init() {
        // Always set to dark theme
        self.currentTheme = .dark
        UserDefaults.standard.set(Theme.dark.rawValue, forKey: themeKey)
    }

    func setTheme(_ theme: Theme) {
        // Only dark theme is available
        currentTheme = .dark
        UserDefaults.standard.set(Theme.dark.rawValue, forKey: themeKey)
    }
}