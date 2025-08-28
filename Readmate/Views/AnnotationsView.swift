import SwiftUI

struct AnnotationsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var readerViewModel: ReaderViewModel
    let onSelectAnnotation: (Annotation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditAnnotationAlert = false
    @State private var editingAnnotation: Annotation?
    @State private var editedAnnotationText = ""

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
                
                List(readerViewModel.book.annotations) { annotation in
                    Button(action: {
                        onSelectAnnotation(annotation)
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(annotation.text)
                                .font(.headline)
                                .lineLimit(2)
                                .foregroundColor(themeManager.currentTheme.secondaryColor)
                            Text("Page \(annotation.pageNumber)")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.authorText)
                        }
                    }
                    .contextMenu {
                        Button {
                            editingAnnotation = annotation
                            editedAnnotationText = annotation.text
                            showingEditAnnotationAlert = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            readerViewModel.deleteAnnotation(annotation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Annotations")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
            }
            .alert("Edit Annotation", isPresented: $showingEditAnnotationAlert, actions: {
                TextField("Annotation Text", text: $editedAnnotationText)
                Button("Save") {
                    if let annotation = editingAnnotation {
                        readerViewModel.editAnnotation(annotation, newText: editedAnnotationText)
                    }
                    editingAnnotation = nil
                    editedAnnotationText = ""
                }
                Button("Cancel", role: .cancel) {
                    editingAnnotation = nil
                    editedAnnotationText = ""
                }
            })
        }
    }
}

struct AnnotationsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(id: UUID(), title: "Sample Book", author: "An Author", fileName: "nonexistentfile.pdf", fileType: .pdf, annotations: [Annotation(text: "This is a sample annotation.", pageNumber: 1, rects: [])])
        let mockLibraryViewModel = LibraryViewModel(forPreview: true)
        let mockReaderViewModel = ReaderViewModel(book: sampleBook, libraryViewModel: mockLibraryViewModel)

        AnnotationsView(readerViewModel: mockReaderViewModel) { annotation in
            print("Selected annotation: \(annotation.text)")
        }
        .environmentObject(ThemeManager())
    }
}
