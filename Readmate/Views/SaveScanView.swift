import SwiftUI

struct SaveScanView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var scannedImage: UIImage?
    @State private var documentName: String = "Scanned Document"

    var body: some View {
        ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)

            VStack {
                Text("Save Your Scan")
                    .font(.largeTitle).bold()
                    .gradientText(for: themeManager.currentTheme)
                    .padding()
                
                Image(uiImage: scannedImage ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .padding()

                TextField("Document Name", text: $documentName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(themeManager.currentTheme.elementBackground)
                    .cornerRadius(10)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                    .padding()
                
                Button(action: saveScan) {
                    Text("Save to Library")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purpleGradient(for: themeManager.currentTheme))
                        .foregroundColor(.white)
                        .cornerRadius(1E+1)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private func saveScan() {
        guard let image = scannedImage else { return }
        libraryViewModel.addBook(from: image, with: documentName)
        // Dismiss this view by setting the image back to nil
        scannedImage = nil
    }
}

struct SaveScanView_Previews: PreviewProvider {
    static var previews: some View {
        SaveScanView(scannedImage: .constant(UIImage(systemName: "doc.text.image")))
            .environmentObject(LibraryViewModel(forPreview: true))
            .environmentObject(ThemeManager())
    }
}