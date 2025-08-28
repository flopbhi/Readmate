import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let bookmarks: [Int]
    let onSelectPage: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
                
                List(bookmarks, id: \.self) { pageNumber in
                    Button(action: {
                        onSelectPage(pageNumber)
                        dismiss()
                    }) {
                        HStack {
                            Text("Page \(pageNumber)")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.accentPurple)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(themeManager.currentTheme.authorText)
                        }
                    }
                }
                .listStyle(.plain)
                .onAppear() {
                    UITableView.appearance().backgroundColor = .clear
                    UITableViewCell.appearance().backgroundColor = .clear
                }
                .navigationTitle("Bookmarks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
            }
        }
    }
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksView(bookmarks: [5, 12, 28, 101]) { page in
            print("Selected page \(page)")
        }
        .environmentObject(ThemeManager())
    }
}