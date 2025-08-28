import SwiftUI

struct BookRowView: View {
    let book: Book
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(book.title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.authorText)
            
            if book.totalPages > 0 {
                ProgressView(value: book.readingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentPurple))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.currentTheme.elementBackground)
        .cornerRadius(10)
    }
}