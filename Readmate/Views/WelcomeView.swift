import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var isFirstLaunch: Bool

    var body: some View {
        ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Welcome to Readmate")
                    .font(.largeTitle).bold()
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Read books, scan pages, and understand text with your AI companion.")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.authorText)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    withAnimation {
                        isFirstLaunch = false
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purpleGradient(for: themeManager.currentTheme))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
            .padding(30)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isFirstLaunch: .constant(true))
            .environmentObject(ThemeManager())
    }
}