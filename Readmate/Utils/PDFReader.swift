import SwiftUI
import PDFKit

struct PDFReader: UIViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: ReaderViewModel

    func makeUIView(context: Context) -> SelectablePDFView {
        let pdfView = SelectablePDFView(viewModel: viewModel)
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        
        let colorInvertFilter = CIFilter(name: "CIColorInvert")
        pdfView.layer.filters = [colorInvertFilter as Any]
        
        return pdfView
    }

    func updateUIView(_ uiView: SelectablePDFView, context: Context) {
        // This is where we react to state changes from SwiftUI
        
        if let pageNumber = viewModel.pageToGoTo,
           let page = uiView.document?.page(at: pageNumber - 1) { // Page numbers are 1-based, index is 0-based
            uiView.go(to: page)
            
            // Reset the state to nil to prevent re-navigation on other view updates
            DispatchQueue.main.async {
                viewModel.pageToGoTo = nil
            }
        }
    }
}
