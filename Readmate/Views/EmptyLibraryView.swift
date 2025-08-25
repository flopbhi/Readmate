import SwiftUI

struct EmptyLibraryView: View {
    @Binding var isImporterPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Your library is empty.")
                .font(.title2).bold()
                .foregroundColor(.onboardingText)
            
            Text("Tap the button below to import your first book.")
                .font(.body)
                .foregroundColor(.authorText)
                .multilineTextAlignment(.center)
            
            Button(action: { isImporterPresented = true }) {
                Text("Import Book")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.purpleGradient)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 30)
    }
}

