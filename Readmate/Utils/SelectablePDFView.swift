import PDFKit

// A custom PDFView that notifies a view model about text selection
class SelectablePDFView: PDFView {
    var viewModel: ReaderViewModel

    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupNotifications()
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
    }
}
