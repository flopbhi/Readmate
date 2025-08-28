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
        
        let targetPageNumber = viewModel.pageToGoTo ?? viewModel.currentPage
        
        if let page = uiView.document?.page(at: targetPageNumber - 1) {
            uiView.go(to: page)
        }
        
        // Reset the pageToGoTo to prevent re-navigation
        if viewModel.pageToGoTo != nil {
            DispatchQueue.main.async {
                viewModel.pageToGoTo = nil
            }
        }
    }
}
