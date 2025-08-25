import Foundation
import SwiftSoup

enum ScraperError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
}

struct WebContent {
    let title: String
    let author: String?
    let content: String
}

class WebScraper {
    static func scrape(url: URL) async -> Result<WebContent, ScraperError> {
        let startTime = Date()
        print("[WebScraper] ⏱️ Starting scrape for URL: \(url.absoluteString) at \(startTime)")
        
        // Implement an additional timeout wrapper for the entire scraping operation
        let scrapingTask = Task {
            return await performScraping(url: url)
        }
        
        let timeoutTask = Task {
            do {
                try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds - much more aggressive
                scrapingTask.cancel()
                return Result<WebContent, ScraperError>.failure(ScraperError.networkError(NSError(domain: "ScrapingTimeout", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Website scraping timed out after 15 seconds. The site is too slow or blocking requests."])))
            } catch {
                // If sleep is cancelled, return cancellation error
                return Result<WebContent, ScraperError>.failure(ScraperError.networkError(NSError(domain: "CancellationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout task was cancelled."])))
            }
        }
        
        // Race between scraping and timeout
        let result = await withTaskGroup(of: Result<WebContent, ScraperError>.self) { group in
            group.addTask { await scrapingTask.value }
            group.addTask { await timeoutTask.value }
            
            guard let firstResult = await group.next() else {
                return Result<WebContent, ScraperError>.failure(ScraperError.networkError(NSError(domain: "TaskGroupError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected error in task group"])))
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            return firstResult
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("[WebScraper] ⏱️ Scraping completed in \(String(format: "%.2f", duration)) seconds")
        return result
    }
    
    private static func performScraping(url: URL) async -> Result<WebContent, ScraperError> {
        print("[WebScraper] 🔄 Starting performScraping at \(Date())")
        do {
            // Check for cancellation before starting
            try Task.checkCancellation()
            
            // Configure a URLSession with very aggressive timeouts
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10 // seconds - very aggressive
            configuration.timeoutIntervalForResource = 15 // seconds - very aggressive  
            configuration.waitsForConnectivity = false // Don't wait for connectivity
            configuration.allowsCellularAccess = true // Allow cellular but don't wait
            let session = URLSession(configuration: configuration)
            
            // Fetch HTML content from the URL using the custom session
            print("[WebScraper] 🌐 Starting network request at \(Date())")
            let (data, response) = try await session.data(from: url)
            print("[WebScraper] ✅ Network request completed at \(Date()), received \(data.count) bytes")
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    return .failure(ScraperError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): Failed to fetch content"])))
                }
            }
            
            print("[WebScraper] HTML data downloaded successfully.")
            
            // Check for cancellation before parsing
            try Task.checkCancellation()
            
            // The parsing and extraction can be slow, so move it to a background task
            // to avoid blocking the main thread.
            let parsingTask = Task.detached(priority: .userInitiated) { () -> Result<WebContent, ScraperError> in
                do {
                    // Check for cancellation in the parsing task
                    try Task.checkCancellation()
                    
                    guard let html = String(data: data, encoding: .utf8) else {
                        return .failure(ScraperError.parsingError("Could not decode HTML content."))
                    }
                    
                    // Parse the HTML using SwiftSoup
                    print("[WebScraper] 🔍 Starting HTML parsing with SwiftSoup at \(Date())...")
                    let doc = try SwiftSoup.parse(html)
                    print("[WebScraper] ✅ HTML parsing completed at \(Date())")
                    
                    // Check for cancellation after parsing
                    try Task.checkCancellation()
                    
                    // Extract the raw title and clean it
                    let rawTitle = try doc.title()
                    let cleaned = Self.cleanTitle(rawTitle)
                    
                    // Attempt to find the main content of the article.
                    var mainContentElement: Element?
                    if let article = try doc.select("article").first() {
                        mainContentElement = article
                    } else if let main = try doc.select("main").first() {
                        mainContentElement = main
                    } else if let contentDiv = try doc.select("#content").first() {
                        mainContentElement = contentDiv
                    } else {
                        // As a fallback, use the whole body
                        mainContentElement = try doc.body()
                    }
                    
                    guard let contentElement = mainContentElement else {
                        return .failure(ScraperError.parsingError("Could not find main content element."))
                    }
                    
                    // Check for cancellation before content extraction
                    try Task.checkCancellation()
                    
                    // Clean up the content by removing script and style tags
                    try contentElement.select("script, style, nav, header, footer, aside").remove()
                    
                    // Get the text, preserving paragraphs
                    var contentText = ""
                    let paragraphs = try contentElement.select("p")
                    for p in paragraphs {
                        contentText += try p.text() + "\n\n"
                    }
                    
                    if contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // If no paragraphs were found, fall back to getting all text
                        contentText = try contentElement.text()
                    }
                    
                    // Validate that we actually got some content
                    let trimmedContent = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedContent.isEmpty else {
                        return .failure(ScraperError.parsingError("No readable content found on this page."))
                    }
                    
                    print("[WebScraper] Content extraction finished.")
                    let webContent = WebContent(title: cleaned.title, author: cleaned.author, content: trimmedContent)
                    return .success(webContent)
                } catch is CancellationError {
                    return .failure(ScraperError.parsingError("Import was cancelled."))
                } catch {
                    print("[WebScraper] Encountered a parsing error: \(error.localizedDescription)")
                    return .failure(ScraperError.parsingError("Failed to parse the website's content: \(error.localizedDescription)"))
                }
            }
            
            return await parsingTask.value

        } catch is CancellationError {
            return .failure(ScraperError.networkError(NSError(domain: "CancellationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Import was cancelled."])))
        } catch {
            print("[WebScraper] Encountered a network error: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if error.localizedDescription.contains("timed out") {
                return .failure(ScraperError.networkError(NSError(domain: "TimeoutError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "The website took too long to respond. Please try again or check if the URL is accessible."])))
            } else if error.localizedDescription.contains("could not connect") {
                return .failure(ScraperError.networkError(NSError(domain: "ConnectionError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Could not connect to the website. Please check your internet connection and try again."])))
            } else {
                return .failure(ScraperError.networkError(error))
            }
        }
    }
    
    private static func cleanTitle(_ rawTitle: String) -> (title: String, author: String?) {
        var title = rawTitle
        var author: String?

        // 1. Look for author information " by " first. This is more reliable than trying to parse site names.
        if let byRange = title.range(of: " by ", options: [.caseInsensitive, .backwards]) {
            let authorPart = String(title[byRange.upperBound...])
            let potentialAuthor = authorPart.trimmingCharacters(in: .whitespaces)
            
            // Check for a site separator within the potential author string
            let siteSeparators: [Character] = ["|", "—", "-"]
            if let separatorIndex = potentialAuthor.firstIndex(where: { siteSeparators.contains($0) }) {
                // The author is the part before the separator
                author = String(potentialAuthor[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            } else {
                author = potentialAuthor
            }

            // The rest is the title
            title = String(title[..<byRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        
        // 2. Now, remove website/extra info from the remaining title (if it wasn't handled by author parsing)
        let siteSeparators: [Character] = ["|", "—", "-"]
        if let firstSeparatorIndex = title.firstIndex(where: { siteSeparators.contains($0) }) {
            title = String(title[..<firstSeparatorIndex]).trimmingCharacters(in: .whitespaces)
        }
        
        // 3. If cleaning resulted in an empty title, fall back to the original to be safe
        if title.isEmpty {
            return (rawTitle.trimmingCharacters(in: .whitespaces), nil)
        }

        return (title, author)
    }
}
