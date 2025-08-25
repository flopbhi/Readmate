import SwiftUI

struct BookRowView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
                .gradientText(gradient: Color.subtlePurpleGradient)
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.authorText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

