import Foundation

struct Book: Identifiable, Codable, Equatable {
    var id = UUID()
    let title: String
    let author: String
    let fileName: String
    let fileType: FileType
    var bookmarks: [Int] = [] // Stores the page numbers of bookmarks
    var readingProgress: Double = 0.0 // Stores the reading progress as a percentage
    var totalPages: Int = 0 // Stores the total number of pages
    var folderId: UUID? // The ID of the folder this book belongs to
    var annotations: [Annotation] = []

    enum FileType: String, Codable {
        case pdf
        case epub
        case scanned
    }

    var url: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
