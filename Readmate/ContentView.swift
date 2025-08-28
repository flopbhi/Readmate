import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }

            ScannerView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scanner")
                }

            AIAssistantView()
                .tabItem {
                    Image(systemName: "message")
                    Text("AI Assistant")
                }
        }
        .accentColor(Theme.dark.accentPurple)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LibraryViewModel(forPreview: true))
            .environmentObject(ThemeManager())
    }
}