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
    func gradientText(gradient: LinearGradient = Color.purpleGradient) -> some View {
        self.modifier(GradientText(gradient: gradient))
    }
}
