import Foundation

struct Book: Identifiable, Codable, Equatable {
    var id = UUID()
    let title: String
    let author: String
    let fileName: String
    let fileType: FileType
    var bookmarks: [Int] = [] // Stores the page numbers of bookmarks

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
