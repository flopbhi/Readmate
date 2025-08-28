import Foundation

struct Persistence {
    private static let booksFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("books.json")
    private static let foldersFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("folders.json")

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

    static func saveFolders(_ folders: [Folder]) {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: foldersFileURL)
        } catch {
            print("Error saving folders: \(error)")
        }
    }

    static func loadFolders() -> [Folder] {
        do {
            let data = try Data(contentsOf: foldersFileURL)
            let folders = try JSONDecoder().decode([Folder].self, from: data)
            return folders
        } catch {
            print("Error loading folders: \(error)")
            return []
        }
    }
}