import SwiftUI

struct URLImportView: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadingStatus = ""
    @State private var importTask: Task<Void, Never>?
    @State private var timeoutCountdown = 30

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Webpage URL")) {
                    TextField("https://example.com/article", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Text("Tips for successful import:")
                        .font(.headline)
                    Text("• Works best with simple articles\n• May not work with dynamic content\n• Try URLs without login requirements\n• Max 30 seconds per import")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: importURL) {
                        HStack {
                            Spacer()
                            if isLoading {
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text(loadingStatus)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if timeoutCountdown > 0 {
                                        Text("⏱️ \(timeoutCountdown)s remaining")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            } else {
                                Text("Import")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || urlString.isEmpty)
                    
                    if isLoading {
                        Button("Cancel") {
                            cancelImport()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Import from Web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelImport()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // Clean up any running tasks when view disappears
                if isLoading {
                    cancelImport()
                }
            }
        }
    }
    
    private func importURL() {
        isLoading = true
        errorMessage = nil
        loadingStatus = "Validating URL..."
        
        importTask = Task {
            do {
                await MainActor.run {
                    loadingStatus = "Connecting to website..."
                }
                
                // Removed artificial delay for better performance
                
                await MainActor.run {
                    loadingStatus = "Downloading content..."
                }
                
                // Start the actual import with simpler progress tracking
                let progressTask = Task {
                    var countdown = 30
                    await MainActor.run {
                        timeoutCountdown = countdown
                        loadingStatus = "Starting import..."
                    }
                    
                    while !Task.isCancelled && countdown > 0 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        countdown -= 1
                        
                        await MainActor.run {
                            timeoutCountdown = countdown
                        }
                    }
                }
                
                // Start both tasks
                async let importResult: Void = viewModel.addBook(from: urlString)
                async let _: Void = progressTask.value
                
                // Wait for import to complete (progress will be cancelled automatically)
                try await importResult
                
                // Ensure progress task is cancelled
                progressTask.cancel()
                
                await MainActor.run {
                    loadingStatus = "Import completed!"
                }
                
                // Removed artificial delay for better performance
                
                // If successful, dismiss the view
                await MainActor.run {
                    dismiss()
                }
            } catch is CancellationError {
                // Handle cancellation specifically
                await MainActor.run {
                    errorMessage = "Import cancelled by user"
                    isLoading = false
                    loadingStatus = ""
                }
            } catch {
                // If an error is thrown, display it with more context
                await MainActor.run {
                    let errorText = error.localizedDescription
                    if errorText.contains("timed out") || errorText.contains("timeout") {
                        errorMessage = "⏱️ Website took too long to respond (max 8 seconds)\n\nTip: Try a simpler webpage or check if the URL works in your browser."
                    } else if errorText.contains("could not connect") || errorText.contains("network") {
                        errorMessage = "🌐 Connection failed\n\nTip: Check your internet connection and try again."
                    } else {
                        errorMessage = "❌ " + errorText + "\n\nTip: Try a different webpage URL."
                    }
                    isLoading = false
                    loadingStatus = ""
                }
            }
        }
    }
    
    private func cancelImport() {
        // Cancel and clean up the import task
        importTask?.cancel()
        importTask = nil
        
        // Reset UI state on main thread
        Task { @MainActor in
            isLoading = false
            loadingStatus = ""
            timeoutCountdown = 30
            errorMessage = "Import cancelled"
        }
    }
}

struct URLImportView_Previews: PreviewProvider {
    static var previews: some View {
        URLImportView()
            .environmentObject(LibraryViewModel(forPreview: true))
    }
}

