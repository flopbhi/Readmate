import SwiftUI

struct ReaderView: View {
    let book: Book
    @StateObject private var viewModel: ReaderViewModel
    @EnvironmentObject private var aiViewModel: AIAssistantViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var libraryViewModel: LibraryViewModel
    @State private var showingBookmarks = false
    @State private var showingAnnotations = false
    @State private var documentText: String?

    init(book: Book, libraryViewModel: LibraryViewModel) {
        self.book = book
        self.libraryViewModel = libraryViewModel
        _viewModel = StateObject(wrappedValue: ReaderViewModel(book: book, libraryViewModel: libraryViewModel))
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
            
            let url = book.url
            if FileManager.default.fileExists(atPath: url.path) {
                PDFReader(url: url, viewModel: viewModel)
                    .contextMenu {
                        if viewModel.selectedText != nil {
                            Button {
                                if let selection = viewModel.currentSelection {
                                    viewModel.addAnnotation(for: selection)
                                }
                            } label: {
                                Label("Highlight", systemImage: "highlighter")
                            }

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
                            
                            Button {
                                setDocumentContextForAI()
                            } label: {
                                Label("Use Document for AI", systemImage: "text.magnifyingglass")
                            }
                        }
                    }
                    .onAppear {
                        extractDocumentText()
                    }
                    .onDisappear {
                        aiViewModel.clearDocumentContext()
                    }
            } else {
                VStack {
                    Text("File Not Found")
                        .font(.title)
                        .gradientText(for: themeManager.currentTheme)
                        .padding(.bottom)
                    Text("The file '\(book.fileName)' could not be found in the app's documents.")
                        .foregroundColor(themeManager.currentTheme.accentPurple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(book.title)
                    .gradientText(for: themeManager.currentTheme)
                    .font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingBookmarks = true
                    } label: {
                        Image(systemName: "book.pages")
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }

                    Button {
                        viewModel.toggleBookmark(for: book, page: viewModel.currentPage)
                    } label: {
                        let isBookmarked = viewModel.book.bookmarks.contains(viewModel.currentPage)
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                    
                    Button(action: viewModel.toggleTTS) {
                        Image(systemName: viewModel.isSpeaking ? (viewModel.isPaused ? "play.fill" : "pause.fill") : "speaker.wave.2.fill")
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }

                    Button {
                        showingAnnotations = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarksView(bookmarks: book.bookmarks) { pageNumber in
                viewModel.pageToGoTo = pageNumber
            }
        }
        .sheet(isPresented: $showingAnnotations) {
            AnnotationsView(readerViewModel: viewModel, onSelectAnnotation: { annotation in
                viewModel.pageToGoTo = annotation.pageNumber
            })
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    setDocumentContextForAI()
                } label: {
                    Image(systemName: "text.magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
                .help("Use this document for AI context")
            }
        }
    }
    
    private func extractDocumentText() {
        guard book.fileType == .pdf else { return }
        
        Task {
            documentText = await PDFTextExtractor.shared.extractText(from: book.url)
        }
    }
    
    private func setDocumentContextForAI() {
        if let text = documentText {
            aiViewModel.setDocumentContext(text)
        } else {
            // Extract text immediately if not already done
            Task {
                if let text = await PDFTextExtractor.shared.extractText(from: book.url) {
                    await MainActor.run {
                        aiViewModel.setDocumentContext(text)
                        documentText = text
                    }
                }
            }
        }
    }
}

struct ReaderView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(id: UUID(), title: "Sample Book", author: "An Author", fileName: "nonexistentfile.pdf", fileType: .pdf)
        ReaderView(book: sampleBook, libraryViewModel: LibraryViewModel(forPreview: true))
            .environmentObject(AIAssistantViewModel())
            .environmentObject(ThemeManager())
    }
}