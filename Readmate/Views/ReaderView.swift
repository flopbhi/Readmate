import SwiftUI

struct ReaderView: View {
    let book: Book
    @StateObject private var viewModel = ReaderViewModel()
    @EnvironmentObject private var aiViewModel: AIAssistantViewModel // Access the global AI view model
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @State private var showingBookmarks = false
    
    var body: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            let url = book.url
            if FileManager.default.fileExists(atPath: url.path) {
                PDFReader(url: url, viewModel: viewModel)
                    .contextMenu {
                        if viewModel.selectedText != nil {
                            Button {
                                aiViewModel.askToExplain(viewModel.selectedText!)
                            } label: {
                                Label("Explain This", systemImage: "text.bubble")
                            }
                            
                            Button {
                                aiViewModel.askToSummarize(viewModel.selectedText!)
                            } label: {
                                Label("Summarize", systemImage: "list.bullet.clipboard")
                            }
                        }
                    }
            } else {
                VStack {
                    Text("File Not Found")
                        .font(.title)
                        .gradientText()
                        .padding(.bottom)
                    Text("The file '\(book.fileName)' could not be found in the app's documents.")
                        .foregroundColor(.accentPurple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(book.title)
                    .gradientText()
                    .font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingBookmarks = true
                    } label: {
                        Image(systemName: "book.pages")
                    }

                    Button {
                        if let page = viewModel.currentPage {
                            libraryViewModel.toggleBookmark(for: book, page: page)
                        }
                    } label: {
                        let isBookmarked = book.bookmarks.contains(viewModel.currentPage ?? -1)
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarksView(bookmarks: book.bookmarks) { pageNumber in
                viewModel.pageToGoTo = pageNumber
            }
        }
    }
}

struct ReaderView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(id: UUID(), title: "Sample Book", author: "An Author", fileName: "nonexistentfile.pdf", fileType: .pdf)
        ReaderView(book: sampleBook)
            .environmentObject(AIAssistantViewModel())
    }
}
