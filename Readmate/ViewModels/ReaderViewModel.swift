import Foundation

class ReaderViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var currentPage: Int?
    @Published var pageToGoTo: Int? // The page to navigate to
}
