import SwiftUI

struct GradientText: ViewModifier {
    let gradient: LinearGradient
    
    func body(content: Content) -> some View {
        content
            .overlay(gradient)
            .mask(content)
    }
}

extension View {
    func gradientText(for theme: Theme) -> some View {
        self.modifier(GradientText(gradient: Color.purpleGradient(for: theme)))
    }
}
