import Foundation
import PDFKit
import Combine

class ReaderViewModel: ObservableObject {
    @Published var book: Book
    @Published var selectedText: String?
    @Published var currentSelection: PDFSelection?
    @Published var currentPage: Int = 1 {
        didSet {
            updateReadingProgress()
        }
    }
    @Published var pageToGoTo: Int? // The page to navigate to
    @Published var isSpeaking = false
    @Published var isPaused = false

    private var libraryViewModel: LibraryViewModel
    private let ttsManager = TextToSpeechManager()
    private var cancellables = Set<AnyCancellable>()

    init(book: Book, libraryViewModel: LibraryViewModel) {
        self.book = book
        self.libraryViewModel = libraryViewModel
        if let pdfDocument = PDFDocument(url: book.url) {
            self.book.totalPages = pdfDocument.pageCount
            self.currentPage = Int(book.readingProgress * Double(book.totalPages))
            if self.currentPage == 0 {
                self.currentPage = 1
            }
        }

        // Sink to the publisher for book updates
        $book
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] updatedBook in
                self?.saveBook(updatedBook)
            }
            .store(in: &cancellables)
        
        // Sink to the TTS manager's publishers
        ttsManager.$isSpeaking
            .assign(to: &$isSpeaking)
        ttsManager.$isPaused
            .assign(to: &$isPaused)
    }

    private func updateReadingProgress() {
        guard book.totalPages > 0 else { return }
        book.readingProgress = Double(currentPage) / Double(book.totalPages)
    }

    private func saveBook(_ book: Book) {
        libraryViewModel.updateBook(book)
    }

    func goToBookmark(_ page: Int) {
        self.pageToGoTo = page
    }

    func toggleBookmark(for book: Book, page: Int) {
        var mutableBook = book
        if mutableBook.bookmarks.contains(page) {
            mutableBook.bookmarks.removeAll { $0 == page }
        } else {
            mutableBook.bookmarks.append(page)
            mutableBook.bookmarks.sort() // Keep bookmarks sorted
        }
        self.book = mutableBook
    }

    // MARK: - Text to Speech
    func toggleTTS() {
        if ttsManager.isSpeaking {
            if ttsManager.isPaused {
                ttsManager.speak(text: "") // This will continue speaking
            } else {
                ttsManager.pause()
            }
        } else {
            if let pdfDocument = PDFDocument(url: book.url),
               let page = pdfDocument.page(at: currentPage - 1),
               let text = page.string {
                ttsManager.speak(text: text)
            }
        }
    }

    func stopTTS() {
        ttsManager.stop()
    }

    // MARK: - Annotations
    func addAnnotation(for selection: PDFSelection) {
        guard let text = selection.string else { return }
        
        let pages = selection.pages
        for page in pages {
            let pageNumber = page.pageRef?.pageNumber ?? 0
            let rects = selection.selectionsByLine().map { $0.bounds(for: page) }
            let annotation = Annotation(text: text, pageNumber: pageNumber, rects: rects)
            book.annotations.append(annotation)
        }
    }

    func deleteAnnotation(_ annotation: Annotation) {
        book.annotations.removeAll { $0.id == annotation.id }
    }

    func editAnnotation(_ annotation: Annotation, newText: String) {
        if let index = book.annotations.firstIndex(where: { $0.id == annotation.id }) {
            book.annotations[index].text = newText
        }
    }
}