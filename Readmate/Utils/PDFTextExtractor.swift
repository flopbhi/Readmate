import PDFKit
import Foundation

class PDFTextExtractor {
    static let shared = PDFTextExtractor()
    
    private init() {}
    
    /// Extracts all text from a PDF document
    func extractText(from url: URL) async -> String? {
        guard let document = PDFDocument(url: url) else {
            print("Failed to create PDFDocument from URL: \(url)")
            return nil
        }
        
        return await extractText(from: document)
    }
    
    /// Extracts all text from a PDF document
    func extractText(from document: PDFDocument) async -> String? {
        var fullText = ""
        let pageCount = document.pageCount
        
        // Process pages concurrently for better performance
        await withTaskGroup(of: String?.self) { group in
            for pageIndex in 0..<pageCount {
                group.addTask {
                    await self.extractText(from: document, page: pageIndex)
                }
            }
            
            for await pageText in group {
                if let text = pageText {
                    fullText += text + "\n\n"
                }
            }
        }
        
        return fullText.isEmpty ? nil : fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts text from a specific page
    func extractText(from document: PDFDocument, page index: Int) async -> String? {
        guard let page = document.page(at: index) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let pageText = page.string {
                    continuation.resume(returning: pageText)
                } else {
                    // Fallback: try to extract text using selection
                    let selection = page.selection(for: page.bounds(for: .cropBox))
                    let text = selection?.string ?? ""
                    continuation.resume(returning: text.isEmpty ? nil : text)
                }
            }
        }
    }
    
    /// Extracts text with page numbers for context
    func extractTextWithPageNumbers(from document: PDFDocument) async -> [Int: String] {
        var pageTexts: [Int: String] = [:]
        let pageCount = document.pageCount
        
        await withTaskGroup(of: (Int, String?).self) { group in
            for pageIndex in 0..<pageCount {
                group.addTask {
                    let pageNumber = pageIndex + 1
                    if let text = await self.extractText(from: document, page: pageIndex) {
                        return (pageNumber, text)
                    }
                    return (pageNumber, nil)
                }
            }
            
            for await (pageNumber, text) in group {
                if let text = text, !text.isEmpty {
                    pageTexts[pageNumber] = text
                }
            }
        }
        
        return pageTexts
    }
    
    /// Gets approximate word count for a document (useful for AI context limits)
    func getWordCount(from url: URL) async -> Int {
        guard let text = await extractText(from: url) else {
            return 0
        }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
}