import SwiftUI
import PDFKit


struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var inputText = ""
    @State private var showActionSheet = false
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false

    var body: some View {
        ZStack {
            themeManager.currentTheme.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    ScrollViewReader { scrollViewProxy in
                        VStack {
                            ForEach(viewModel.messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding()
                                            .background(Color.purpleGradient(for: themeManager.currentTheme))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(themeManager.currentTheme.elementBackground)
                                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                                            .cornerRadius(10)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentPurple))
                                    Text("Thinking...")
                                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .id(UUID()) // Use UUID instead of string
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            withAnimation {
                                if let lastMessage = viewModel.messages.last {
                                    scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Spacer()

                if let error = viewModel.error {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        Button("Dismiss") {
                            viewModel.clearError()
                        }
                        .foregroundColor(.red)
                    }
                }

                HStack {
                    Button(action: {
                        self.showActionSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .gradientText(for: themeManager.currentTheme)
                    }
                    .padding(.trailing, 4)
                    .disabled(viewModel.isLoading)

                    TextField("Ask a question...", text: $inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(themeManager.currentTheme.elementBackground)
                        .cornerRadius(10)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .disabled(viewModel.isLoading)
                    
                    Button(action: sendMessage) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                        }
                    }
                    .gradientText(for: themeManager.currentTheme)
                    .disabled(viewModel.isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Upload"), message: Text("Select a file or an image to upload."), buttons: [
                .default(Text("Upload Image")) {
                    self.showPhotoPicker = true
                },
                .default(Text("Upload File")) {
                    self.showFileImporter = true
                },
                .cancel()
            ])
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .plainText, .rtf, .jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task {
                    if let text = await extractTextFromFile(url) {
                        await MainActor.run {
                            viewModel.setDocumentContext(text)
                            viewModel.sendMessage("I've loaded the file '\(url.lastPathComponent)'. You can now ask questions about it.")
                        }
                    }
                }
            case .failure(let error):
                print("Error importing file: \(error.localizedDescription)")
                viewModel.sendMessage("Failed to import the file. Please try again.")
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { image in
                // Process the image with OCR and set as context
                Task {
                    if let text = await extractTextFromImage(image) {
                        await MainActor.run {
                            viewModel.setDocumentContext(text)
                            viewModel.sendMessage("I've processed the image text. You can now ask questions about it.")
                        }
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.sendMessage(inputText)
        inputText = ""
    }
    
    private func extractTextFromImage(_ image: UIImage) async -> String? {
        // Use OCR to extract text from image
        return await withCheckedContinuation { continuation in
            OCRProcessor.shared.createSearchablePDF(from: image) { pdfData in
                if let pdfData = pdfData,
                   let pdfDocument = PDFDocument(data: pdfData) {
                    let text = (0..<pdfDocument.pageCount).compactMap { index in
                        pdfDocument.page(at: index)?.string
                    }.joined(separator: "\n\n")
                    
                    continuation.resume(returning: text.isEmpty ? nil : text)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func extractTextFromFile(_ url: URL) async -> String? {
        do {
            // Check file type and extract text accordingly
            if url.pathExtension.lowercased() == "pdf" {
                return await PDFTextExtractor.shared.extractText(from: url)
            } else if ["txt", "rtf"].contains(url.pathExtension.lowercased()) {
                return try String(contentsOf: url, encoding: .utf8)
            }
        } catch {
            print("Error extracting text from file: \(error)")
        }
        return nil
    }
}

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView()
            .environmentObject(AIAssistantViewModel())
            .environmentObject(ThemeManager())
    }
}