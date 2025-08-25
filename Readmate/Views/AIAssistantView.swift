import SwiftUI

enum AIAssistantSheet: Identifiable {
    case photoPicker
    case fileImporter
    
    var id: Int {
        hashValue
    }
}

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var inputText = ""
    @State private var showActionSheet = false
    @State private var activeSheet: AIAssistantSheet?

    var body: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    ScrollViewReader { scrollViewProxy in
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.purpleGradient)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.elementBackground)
                                        .foregroundColor(.accentPurple)
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id(message.id)
                        }
                        .onChange(of: viewModel.messages.count) {
                            withAnimation {
                                scrollViewProxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer()

                HStack {
                    Button(action: {
                        self.showActionSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .gradientText()
                    }
                    .padding(.trailing, 4)

                    TextField("Ask a question...", text: $inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color.elementBackground)
                        .cornerRadius(10)
                        .foregroundColor(.accentPurple)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .gradientText()
                    }
                }
                .padding()
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Upload"), message: Text("Select a file or an image to upload."), buttons: [
                .default(Text("Upload Image")) {
                    self.activeSheet = .photoPicker
                },
                .default(Text("Upload File")) {
                    self.activeSheet = .fileImporter
                },
                .cancel()
            ])
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .photoPicker:
                PhotoPicker { image in
                    viewModel.sendMessage("Received an image. What should I do with it?")
                }
            case .fileImporter:
                Text("").fileImporter(
                    isPresented: Binding<Bool>(
                        get: { activeSheet == .fileImporter },
                        set: { if !$0 { activeSheet = nil } }
                    ),
                    allowedContentTypes: [.pdf, .plainText, .jpeg, .png],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        viewModel.sendMessage("Received a file named '\(url.lastPathComponent)'. What should I do with it?")
                    case .failure(let error):
                        print("Error importing file: \(error.localizedDescription)")
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
}

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView()
            .environmentObject(AIAssistantViewModel())
    }
}
