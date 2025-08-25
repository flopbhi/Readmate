import SwiftUI

struct BookmarksView: View {
    let bookmarks: [Int]
    let onSelectPage: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(bookmarks, id: \.self) { pageNumber in
                Button(action: {
                    onSelectPage(pageNumber)
                    dismiss()
                }) {
                    HStack {
                        Text("Page \(pageNumber)")
                            .font(.headline)
                            .foregroundColor(Color.accentPurple)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.authorText)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        }
    }
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksView(bookmarks: [5, 12, 28, 101]) { page in
            print("Selected page \(page)")
        }
    }
}
