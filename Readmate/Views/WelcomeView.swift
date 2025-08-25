import SwiftUI

struct WelcomeView: View {
    @Binding var isFirstLaunch: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Readmate")
                .font(.largeTitle).bold()
                .foregroundColor(.onboardingText)
                .multilineTextAlignment(.center)
            
            Text("Read books, scan pages, and understand text with your AI companion.")
                .font(.title3)
                .foregroundColor(.authorText)
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
                    .background(Color.purpleGradient)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
        .padding(30)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isFirstLaunch: .constant(true))
    }
}
