import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isVisible = false
    @State private var isImporterPresented = false
    @State private var isURLImportViewPresented = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSettings = false
    @State private var showingCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(viewModel.selectedFolder?.name ?? "Library")
                            .font(.largeTitle)
                            .bold()
                            .gradientText(for: themeManager.currentTheme)

                        Spacer()

                        Menu {
                            Button {
                                showingCreateFolderAlert = true
                            } label: {
                                Label("Create Folder", systemImage: "folder.badge.plus")
                            }
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
                                .foregroundColor(themeManager.currentTheme.secondaryColor)
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.secondaryColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    TextField("Search books...", text: $searchText)
                        .padding(8)
                        .background(themeManager.currentTheme.elementBackground)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .padding(.horizontal)

                    List {
                        Section(header: Text("Folders").foregroundColor(themeManager.currentTheme.secondaryColor)) {
                            ForEach(viewModel.folders) { folder in
                                Button(action: {
                                    viewModel.selectedFolder = folder
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(themeManager.currentTheme.accentPurple)
                                        Text(folder.name)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.deleteFolder(folder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            Button(action: {
                                viewModel.selectedFolder = nil
                            }) {
                                HStack {
                                    Image(systemName: "books.vertical.fill")
                                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                                    Text("All Books")
                                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }

                        Section(header: Text("Books").foregroundColor(themeManager.currentTheme.secondaryColor)) {
                            if viewModel.filteredBooks.isEmpty {
                                EmptyLibraryView(isImporterPresented: $isImporterPresented)
                                    .opacity(isVisible ? 1 : 0)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(viewModel.filteredBooks) { book in
                                    NavigationLink(destination: ReaderView(book: book, libraryViewModel: viewModel)) {
                                        BookRowView(book: book)
                                    }
                                    .listRowBackground(Color.clear)
                                    .contextMenu {
                                        Menu("Move to Folder") {
                                            ForEach(viewModel.folders) { folder in
                                                Button(folder.name) {
                                                    viewModel.moveBook(book, to: folder)
                                                }
                                            }
                                            Button("Remove from Folder") {
                                                viewModel.moveBook(book, to: nil)
                                            }
                                        }
                                        Button(role: .destructive) {
                                            viewModel.deleteBook(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .opacity(isVisible ? 1 : 0)
                                    .offset(y: isVisible ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(Double(viewModel.filteredBooks.firstIndex(of: book) ?? 0) * 0.1), value: isVisible)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onAppear() {
                        UITableView.appearance().backgroundColor = .clear
                        UITableViewCell.appearance().backgroundColor = .clear
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
                print("File Importer result: \(result)")
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("New Folder", isPresented: $showingCreateFolderAlert, actions: {
                TextField("Folder Name", text: $newFolderName)
                Button("Create") {
                    viewModel.createFolder(with: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        let themeManager = ThemeManager()
        return ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
            LibraryView()
                .environmentObject(LibraryViewModel(forPreview: true))
                .environmentObject(themeManager)
        }
    }
}
