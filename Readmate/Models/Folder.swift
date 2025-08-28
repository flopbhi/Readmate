import Foundation

struct Folder: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bookIds: [UUID] = []
}
