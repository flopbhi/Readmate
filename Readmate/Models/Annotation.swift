import Foundation
import PDFKit

struct Annotation: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var pageNumber: Int
    var rects: [CGRect]

    // Custom coding keys to handle CGRect, which is not directly Codable.
    enum CodingKeys: String, CodingKey {
        case id, text, pageNumber, rects
    }

    init(id: UUID = UUID(), text: String, pageNumber: Int, rects: [CGRect]) {
        self.id = id
        self.text = text
        self.pageNumber = pageNumber
        self.rects = rects
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        let rectStrings = try container.decode([String].self, forKey: .rects)
        rects = rectStrings.map { NSCoder.cgRect(for: $0) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(pageNumber, forKey: .pageNumber)
        let rectStrings = rects.map { NSCoder.string(for: $0) }
        try container.encode(rectStrings, forKey: .rects)
    }
}
