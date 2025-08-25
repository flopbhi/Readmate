import UIKit
import PDFKit

class PDFGenerator {
    static func createPDF(from content: WebContent) -> Data? {
        let startTime = Date()
        print("[PDFGenerator] 📄 Starting PDF generation at \(startTime)")
        // 1. Set up the page layout and formatting
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 Size
        let margin: CGFloat = 40
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)
        
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let authorFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        
        // 2. Combine title, author, and body into a single attributed string
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        let authorAttributes: [NSAttributedString.Key: Any] = [.font: authorFont, .foregroundColor: UIColor.gray]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
        
        let attributedString = NSMutableAttributedString(string: content.title, attributes: titleAttributes)
        
        if let author = content.author, !author.isEmpty {
            attributedString.append(NSAttributedString(string: "\n"))
            attributedString.append(NSAttributedString(string: author, attributes: authorAttributes))
        }

        attributedString.append(NSAttributedString(string: "\n\n"))
        attributedString.append(NSAttributedString(string: content.content, attributes: bodyAttributes))
        
        // 3. Create a PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { (context) in
            // Use Core Text to lay out the attributed string
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            var currentRange = CFRange(location: 0, length: 0)
            var done = false
            
            repeat {
                // 4. Begin a new page for each chunk of text
                context.beginPage()
                
                let path = CGPath(rect: contentRect, transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
                
                // Draw the text on the current page
                CTFrameDraw(frame, context.cgContext)
                
                // 5. Check if there's more text to render on the next page
                currentRange = CTFrameGetVisibleStringRange(frame)
                currentRange.location += currentRange.length
                
                if currentRange.location >= attributedString.length {
                    done = true
                }
                
            } while !done
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("[PDFGenerator] ✅ PDF generation completed in \(String(format: "%.2f", duration)) seconds")
        return data
    }
}
