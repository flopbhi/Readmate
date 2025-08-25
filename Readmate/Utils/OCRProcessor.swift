import Vision
import PDFKit

class OCRProcessor {
    // A singleton instance for easy access
    static let shared = OCRProcessor()

    func createSearchablePDF(from image: UIImage, completion: @escaping (Data?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(nil)
                return
            }

            let pdfData = self.drawPDF(from: image, with: observations)
            completion(pdfData)
        }
        
        // Use a background thread for the OCR processing
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private func drawPDF(from image: UIImage, with observations: [VNRecognizedTextObservation]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Readmate",
            kCGPDFContextTitle: "Scanned Document"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Draw the image first as the base layer
            image.draw(at: .zero)

            // Now, draw the invisible text on top
            for observation in observations {
                guard let bestCandidate = observation.topCandidates(1).first else { continue }
                
                let bounds = observation.boundingBox
                let textRect = self.transform(bounds, to: pageRect.size)
                
                let font = self.font(for: bestCandidate.string, in: textRect)
                let attributedString = NSAttributedString(
                    string: bestCandidate.string,
                    attributes: [
                        .font: font,
                        .foregroundColor: UIColor.clear // Make the text invisible
                    ]
                )
                
                attributedString.draw(in: textRect)
            }
        }
        return data
    }
    
    // Helper to convert Vision's normalized coordinates to UIKit coordinates
    private func transform(_ rect: CGRect, to size: CGSize) -> CGRect {
        var transformedRect = rect
        transformedRect.origin.y = 1 - transformedRect.origin.y
        transformedRect = VNImageRectForNormalizedRect(transformedRect, Int(size.width), Int(size.height))
        return transformedRect
    }
    
    // Helper to dynamically size the font to fit the recognized text box
    private func font(for text: String, in rect: CGRect) -> UIFont {
        var minFontSize: CGFloat = 1.0
        var maxFontSize: CGFloat = 128.0
        var bestFontSize: CGFloat = 1.0

        while maxFontSize - minFontSize > 1.0 {
            let midFontSize = (minFontSize + maxFontSize) / 2
            let font = UIFont.systemFont(ofSize: midFontSize)
            let attributes = [NSAttributedString.Key.font: font]
            let boundingRect = (text as NSString).boundingRect(
                with: CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            
            if boundingRect.height <= rect.height {
                bestFontSize = midFontSize
                minFontSize = midFontSize
            } else {
                maxFontSize = midFontSize
            }
        }
        return UIFont.systemFont(ofSize: bestFontSize)
    }
}

