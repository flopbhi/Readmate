import Foundation

struct Persistence {
    private static let booksFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("books.json")

    static func saveBooks(_ books: [Book]) {
        do {
            let data = try JSONEncoder().encode(books)
            try data.write(to: booksFileURL)
        } catch {
            print("Error saving books: \(error)")
        }
    }

    static func loadBooks() -> [Book] {
        do {
            let data = try Data(contentsOf: booksFileURL)
            let books = try JSONDecoder().decode([Book].self, from: data)
            return books
        } catch {
            print("Error loading books: \(error)")
            return []
        }
    }
}
