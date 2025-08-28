import PDFKit
import Combine

// A custom PDFView that notifies a view model about text selection
class SelectablePDFView: PDFView {
    var viewModel: ReaderViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupNotifications()
        
        viewModel.$book
            .sink { [weak self] _ in
                self?.drawHighlights()
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewSelectionDidChange),
            name: .PDFViewSelectionChanged,
            object: self
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewPageDidChange),
            name: .PDFViewPageChanged,
            object: self
        )
    }

    @objc private func pdfViewSelectionDidChange(_ notification: Notification) {
        // When the selection changes, update the view model
        viewModel.currentSelection = self.currentSelection
        if let selectedText = self.currentSelection?.string {
            viewModel.selectedText = selectedText.isEmpty ? nil : selectedText
        } else {
            viewModel.selectedText = nil
        }
    }

    @objc private func pdfViewPageDidChange(_ notification: Notification) {
        if let currentPage = self.currentPage, let pageNumber = self.document?.index(for: currentPage) {
            viewModel.currentPage = pageNumber + 1 // Page numbers are 0-indexed
        }
        drawHighlights()
    }

    private func drawHighlights() {
        guard let document = document else { return }
        
        // Remove all existing annotations to avoid duplicates
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                page.annotations.forEach { page.removeAnnotation($0) }
            }
        }

        for annotation in viewModel.book.annotations {
            guard let page = document.page(at: annotation.pageNumber - 1) else { continue }
            
            for rect in annotation.rects {
                let highlight = PDFAnnotation(bounds: rect, forType: .highlight, withProperties: nil)
                highlight.color = .yellow.withAlphaComponent(0.5)
                page.addAnnotation(highlight)
            }
        }
    }
}