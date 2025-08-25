import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    @State private var isVisible = false
    @State private var isImporterPresented = false
    @State private var isURLImportViewPresented = false // Renamed for clarity
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all)
                
                // Floating orbs background effect
                FloatingOrbsView(orbCount: 35, baseSize: 10, baseOpacity: 0.8, speed: 0.4)
                    .ignoresSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Library")
                            .font(.largeTitle)
                            .bold()
                            .gradientText()

                        Spacer()

                        Menu {
                            Button {
                                isImporterPresented = true
                            } label: {
                                Label("Import from File", systemImage: "doc")
                            }
                            
                            Button {
                                isURLImportViewPresented = true
                            } label: {
                                Label("Import from Web", systemImage: "globe")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    if viewModel.books.isEmpty {
                        EmptyLibraryView(isImporterPresented: $isImporterPresented)
                            .opacity(isVisible ? 1 : 0)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(Array(viewModel.books.enumerated()), id: \.element.id) { index, book in
                                    NavigationLink(destination: ReaderView(book: book)) {
                                        BookRowView(book: book)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteBook(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .opacity(isVisible ? 1 : 0)
                                    .offset(y: isVisible ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: isVisible)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    isVisible = true
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                // Definitive fix: Handle the result as [URL] and take the first element
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.addBook(from: url)
                    }
                case .failure(let error):
                    print("Error importing file: \(error.localizedDescription)")
                    alertMessage = "Failed to import file: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            .sheet(isPresented: $isURLImportViewPresented) {
                URLImportView()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            LibraryView()
                .environmentObject(LibraryViewModel(forPreview: true))
        }
    }
}



