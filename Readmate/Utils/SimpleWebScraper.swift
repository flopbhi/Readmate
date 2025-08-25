import Foundation
import SwiftSoup

// A simplified, fast web scraper that extracts readable text
class SimpleWebScraper {
    static func quickScrape(url: URL) async -> Result<WebContent, Error> {
        print("[SimpleWebScraper] 🚀 Starting quick scrape for: \(url.absoluteString)")
        
        do {
            // More reasonable timeout for real-world websites
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10 // 10 seconds max
            configuration.timeoutIntervalForResource = 15 // 15 seconds max
            configuration.waitsForConnectivity = false
            configuration.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"]
            
            let session = URLSession(configuration: configuration)
            
            print("[SimpleWebScraper] 🌐 Making request...")
            let (data, response) = try await session.data(from: url)
            
            if data.count > 1_000_000 { // 1MB limit
                throw NSError(domain: "DataTooLarge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Website content is too large to import"])
            }
            
            // Quick validation
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not decode HTML"])
            }
            
            print("[SimpleWebScraper] ✅ Successfully scraped \(data.count) bytes")
            
            // Parse HTML and extract readable content
            do {
                let doc = try SwiftSoup.parse(html)
                
                // Extract title
                let title = try doc.title().isEmpty ? (url.host ?? "Web Content") : doc.title()
                
                // Find main content
                var mainContentElement: Element?
                if let article = try doc.select("article").first() {
                    mainContentElement = article
                } else if let main = try doc.select("main").first() {
                    mainContentElement = main
                } else if let contentDiv = try doc.select("#content").first() {
                    mainContentElement = contentDiv
                } else {
                    // Fallback to body
                    mainContentElement = try doc.body()
                }
                
                guard let contentElement = mainContentElement else {
                    throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find content"])
                }
                
                // Remove unwanted elements
                try contentElement.select("script, style, nav, header, footer, aside").remove()
                
                // Extract text content
                var contentText = ""
                let paragraphs = try contentElement.select("p")
                for p in paragraphs {
                    contentText += try p.text() + "\n\n"
                }
                
                if contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    contentText = try contentElement.text()
                }
                
                let trimmedContent = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedContent.isEmpty else {
                    throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No readable content found"])
                }

                if trimmedContent.count > 50000 { // About 10,000 words limit
                    throw NSError(domain: "ContentTooLong", code: -1, userInfo: [NSLocalizedDescriptionKey: "Website content is too long to import. Try a shorter article."])
                }
                
                print("[SimpleWebScraper] 📝 Extracted \(trimmedContent.count) characters of text")
                
                let webContent = WebContent(title: title, author: url.host, content: trimmedContent)
                return .success(webContent)
                
            } catch {
                print("[SimpleWebScraper] ❌ HTML parsing failed: \(error.localizedDescription)")
                return .failure(error)
            }
            
        } catch {
            print("[SimpleWebScraper] ❌ Error: \(error.localizedDescription)")
            
            // Provide more specific error messages
            let nsError = error as NSError
            let enhancedError: NSError
            
            if nsError.code == NSURLErrorTimedOut || error.localizedDescription.contains("timed out") {
                enhancedError = NSError(domain: "TimeoutError", code: -1001, userInfo: [
                    NSLocalizedDescriptionKey: "The website took too long to respond. Try a different website or check your internet connection."
                ])
            } else if nsError.code == NSURLErrorCannotConnectToHost || nsError.code == NSURLErrorNetworkConnectionLost {
                enhancedError = NSError(domain: "ConnectionError", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "Could not connect to the website. Please check if the URL is correct and your internet connection is working."
                ])
            } else if nsError.code == NSURLErrorSecureConnectionFailed {
                enhancedError = NSError(domain: "SSLError", code: -1200, userInfo: [
                    NSLocalizedDescriptionKey: "The website's security certificate is invalid. Try using 'http://' instead of 'https://' if appropriate."
                ])
            } else if nsError.code == NSURLErrorBadURL {
                enhancedError = NSError(domain: "URLError", code: -1000, userInfo: [
                    NSLocalizedDescriptionKey: "The URL format is invalid. Please enter a valid website URL starting with 'http://' or 'https://'."
                ])
            } else {
                enhancedError = NSError(domain: "GeneralError", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to import from this website: \(error.localizedDescription)"
                ])
            }
            
            return .failure(enhancedError)
        }
    }
}
