import Foundation
import UIKit

enum ImportError: LocalizedError {
    case invalidURL
    case scrapingFailed(Error)
    case pdfGenerationFailed
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL you entered is not valid. Please check it and try again."
        case .scrapingFailed:
            return "Could not retrieve content from this website. The site may be down, or it might block automated scraping."
        case .pdfGenerationFailed:
            return "An error occurred while converting the web content into a PDF."
        case .saveFailed:
            return "The PDF was created, but could not be saved to your library."
        }
    }
}

class LibraryViewModel: ObservableObject {
    @Published var books: [Book] {
        didSet {
            Persistence.saveBooks(books)
        }
    }

    // Main initializer for the live app
    init() {
        self.books = Persistence.loadBooks()
    }

    // A special, fast initializer for Xcode Previews
    init(forPreview: Bool) {
        if forPreview {
            self.books = [
                Book(id: UUID(), title: "The Hobbit (Preview)", author: "J.R.R. Tolkien", fileName: "sample1", fileType: .epub),
                Book(id: UUID(), title: "A Brief History of Time (Preview)", author: "Stephen Hawking", fileName: "sample2", fileType: .pdf)
            ]
        } else {
            self.books = Persistence.loadBooks()
        }
    }

    func addBook(from url: URL) {
        // Gain access to the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource.")
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let fileName = url.lastPathComponent
            let appDocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = appDocumentsDirectory.appendingPathComponent(fileName)

            // Copy the file from the source URL to the app's directory
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Create a new book instance
            let newBook = Book(
                id: UUID(),
                title: fileName.replacingOccurrences(of: ".pdf", with: ""),
                author: "Unknown Author",
                fileName: fileName,
                fileType: .pdf
            )

            // Add the new book to our library
            books.append(newBook)

        } catch {
            print("Error copying file: \(error.localizedDescription)")
        }
    }

    func addBook(from image: UIImage, with title: String) {
        // Use our new OCR processor to create a searchable PDF
        OCRProcessor.shared.createSearchablePDF(from: image) { pdfData in
            guard let pdfData = pdfData else { return }
            
            let fileName = "\(title).pdf"
            
            do {
                let appDocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = appDocumentsDirectory.appendingPathComponent(fileName)
                
                try pdfData.write(to: destinationURL)

                let newBook = Book(
                    id: UUID(),
                    title: title,
                    author: "Scanned Document",
                    fileName: fileName,
                    fileType: .scanned
                )
                
                // Ensure UI updates are on the main thread
                DispatchQueue.main.async {
                    self.books.append(newBook)
                }

            } catch {
                print("Error saving scanned PDF: \(error.localizedDescription)")
            }
        }
    }

    func deleteBook(_ book: Book) {
        // Remove the book from the array
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books.remove(at: index)
        }

        // Delete the associated file from the documents directory
        do {
            let appDocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = appDocumentsDirectory.appendingPathComponent(book.fileName)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
    
    // New function to handle web imports with strict timeout and cancellation support
    func addBook(from urlString: String) async throws {
        // Clean and validate the URL string
        var cleanURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Auto-prefix with https:// if no protocol is specified
        if !cleanURLString.hasPrefix("http://") && !cleanURLString.hasPrefix("https://") {
            cleanURLString = "https://" + cleanURLString
        }
        
        guard let url = URL(string: cleanURLString), 
              url.scheme != nil, 
              url.host != nil else {
            throw ImportError.invalidURL
        }
        
        // Implement a reasonable timeout of 30 seconds for the entire operation
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            // If we reach here, the operation timed out
        }
        
        let importTask = Task {
            // Check for cancellation before starting scraping
            try Task.checkCancellation()
            
            print("[LibraryViewModel] Starting web scraping for: \(url.absoluteString)")
            
            // Use SimpleWebScraper which now extracts readable text
            let simpleResult = await SimpleWebScraper.quickScrape(url: url)
            let webContent: WebContent
            
            switch simpleResult {
            case .success(let extractedContent):
                print("[LibraryViewModel] Simple scraping completed successfully")
                webContent = extractedContent
            case .failure(let error):
                print("[LibraryViewModel] Simple scraping failed: \(error)")
                throw ImportError.scrapingFailed(error)
            }
            
            // Check for cancellation before PDF generation
            try Task.checkCancellation()
            
            print("[LibraryViewModel] Starting PDF generation")
            guard let pdfData = PDFGenerator.createPDF(from: webContent) else {
                print("[LibraryViewModel] PDF generation failed")
                throw ImportError.pdfGenerationFailed
            }
            print("[LibraryViewModel] PDF generation completed")
            
            // Check for cancellation before file operations
            try Task.checkCancellation()
            
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // Sanitize the title for the filename
            let fileName = webContent.title.sanitizedFileName() + ".pdf"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                print("[LibraryViewModel] Saving PDF to: \(fileURL.path)")
                try pdfData.write(to: fileURL)
                print("[LibraryViewModel] PDF saved successfully")
            } catch {
                print("[LibraryViewModel] Failed to save PDF: \(error)")
                throw ImportError.saveFailed(error)
            }
                
            let newBook = Book(
                id: UUID(),
                title: webContent.title,
                author: webContent.author ?? url.host ?? "Web", // Use scraped author, fallback to host
                fileName: fileName,
                fileType: .pdf
            )
            
            // Final cancellation check before updating UI
            try Task.checkCancellation()
            
            // Switch back to the main thread to update the UI
            await MainActor.run {
                print("[LibraryViewModel] Adding book to library: \(newBook.title)")
                self.books.append(newBook)
            }
        }
        
        // Race between the import task and timeout - simplified approach
        let result = await withTaskGroup(of: Result<Void, Error>.self) { group in
            group.addTask {
                do {
                    try await importTask.value
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }
            
            group.addTask {
                do {
                    try await timeoutTask.value
                    // If timeout task completes, it means we timed out
                    return .failure(ImportError.scrapingFailed(NSError(domain: "TimeoutError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Import timed out after 30 seconds. The website is taking too long to respond."])))
                } catch {
                    // Timeout task was cancelled (which is normal)
                    return .failure(error)
                }
            }
            
            // Wait for the first task to complete
            let firstResult = await group.next()
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return firstResult ?? .failure(ImportError.scrapingFailed(NSError(domain: "UnknownError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."])))
        }
        
        // Handle the result
        switch result {
        case .success():
            // Import completed successfully
            break
        case .failure(let error):
            // Clean up and throw the error
            importTask.cancel()
            timeoutTask.cancel()
            throw error
        }
    }
    
    // MARK: - Bookmarks
    func toggleBookmark(for book: Book, page: Int) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        
        if books[index].bookmarks.contains(page) {
            books[index].bookmarks.removeAll { $0 == page }
        } else {
            books[index].bookmarks.append(page)
            books[index].bookmarks.sort() // Keep bookmarks sorted
        }
    }
}

// Helper to create a safe filename
extension String {
    func sanitizedFileName() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|").union(.newlines)
        return self.components(separatedBy: invalidCharacters).joined(separator: "")
    }
}
