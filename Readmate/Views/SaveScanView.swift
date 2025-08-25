import SwiftUI

struct SaveScanView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @Binding var scannedImage: UIImage?
    @State private var documentName: String = "Scanned Document"

    var body: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)

            VStack {
                Text("Save Your Scan")
                    .font(.largeTitle).bold()
                    .gradientText()
                    .padding()
                
                Image(uiImage: scannedImage ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .padding()

                TextField("Document Name", text: $documentName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.elementBackground)
                    .cornerRadius(10)
                    .foregroundColor(.onboardingText)
                    .padding()
                
                Button(action: saveScan) {
                    Text("Save to Library")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purpleGradient)
                        .foregroundColor(.white)
                        .cornerRadius(15)
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
    }
}
