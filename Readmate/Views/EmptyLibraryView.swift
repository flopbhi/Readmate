import SwiftUI

struct EmptyLibraryView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var isImporterPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Your library is empty.")
                .font(.title2).bold()
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            Text("Tap the button below to import your first book.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.authorText)
                .multilineTextAlignment(.center)
            
            Button(action: { isImporterPresented = true }) {
                Text("Import Book")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.purpleGradient(for: themeManager.currentTheme))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 30)
    }
}

struct EmptyLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyLibraryView(isImporterPresented: .constant(false))
            .environmentObject(ThemeManager())
    }
}