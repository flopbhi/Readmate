import SwiftUI

enum ScanSheet: Identifiable {
    case scanner
    case photoPicker
    
    var id: Int {
        hashValue
    }
}

struct ScannerView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var activeSheet: ScanSheet?
    @State private var scannedImage: UIImage?

    var body: some View {
        ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
            
            // Floating orbs background effect
            FloatingOrbsView(orbCount: 30, baseSize: 10, baseOpacity: 0.8, speed: 0.3)
                .ignoresSafeArea(.all)
            
            if scannedImage != nil {
                SaveScanView(scannedImage: $scannedImage)
                    .environmentObject(libraryViewModel)
                    .environmentObject(themeManager)
            } else {
                VStack(spacing: 30) {
                    Text("Create a New Scan")
                        .font(.largeTitle).bold()
                        .gradientText(for: themeManager.currentTheme)

                    Button(action: { self.activeSheet = .scanner }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan with Camera")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purpleGradient(for: themeManager.currentTheme))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }

                    Button(action: { self.activeSheet = .photoPicker }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Import from Photos")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentTheme.elementBackground)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .cornerRadius(15)
                    }
                }
                .padding(30)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .scanner:
                DocumentScanner { image in
                    self.scannedImage = image
                    self.activeSheet = nil
                }
            case .photoPicker:
                PhotoPicker { image in
                    self.scannedImage = image
                    self.activeSheet = nil
                }
            }
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
            .environmentObject(LibraryViewModel(forPreview: true))
            .environmentObject(ThemeManager())
    }
}