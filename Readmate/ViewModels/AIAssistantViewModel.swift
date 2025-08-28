import Foundation

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Document context for AI queries
    @Published var currentDocumentContext: String?
    
    private let baseURL = Config.openAIBaseURL
    
    func sendMessage(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: true))
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await sendToOpenAI(message: text)
                await MainActor.run {
                    self.messages.append(ChatMessage(text: response, isUser: false))
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    // Fallback to mock response for development
                    self.messages.append(ChatMessage(text: "I encountered an error but here's a mock response to '\(text)'.", isUser: false))
                }
            }
        }
    }
    
    private func sendToOpenAI(message: String) async throws -> String {
        guard Config.validateAPIKey() else {
            throw AIError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the prompt with document context if available
        let fullPrompt = buildPromptWithContext(userMessage: message)
        
        let requestBody: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                ["role": "user", "content": fullPrompt]
            ],
            "max_tokens": Config.openAIMaxTokens,
            "temperature": Config.openAITemperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponseFormat
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func askToExplain(_ text: String) {
        let prompt = """
        Please explain the following text in simple terms:
        
        "\(text)"
        
        Provide a clear and concise explanation that would help someone understand this content better.
        """
        sendMessage(prompt)
    }
    
    func askToSummarize(_ text: String) {
        let prompt = """
        Please provide a concise summary of the following text:
        
        "\(text)"
        
        Focus on the key points and main ideas. Keep it brief but informative.
        """
        sendMessage(prompt)
    }
    
    func setDocumentContext(_ context: String?) {
        currentDocumentContext = context
    }
    
    func clearDocumentContext() {
        currentDocumentContext = nil
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func buildPromptWithContext(userMessage: String) -> String {
        guard let context = currentDocumentContext, !context.isEmpty else {
            return userMessage
        }
        
        // Truncate context to avoid exceeding token limits
        let maxContextLength = 2000
        let truncatedContext = context.count > maxContextLength ?
            String(context.prefix(maxContextLength)) + "..." : context
        
        return """
        Context from the current document:
        \"\"\"
        \(truncatedContext)
        \"\"\"
        
        User question: \(userMessage)
        
        Please answer the user's question based on the document context provided above.
        If the context doesn't contain relevant information, please state that clearly.
        """
    }
}

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please add your API key to Config.swift or set the OPENAI_API_KEY environment variable."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .invalidResponseFormat:
            return "The response from the AI service was in an unexpected format."
        case .apiError(let statusCode):
            return "API error (status code: \(statusCode)). Please try again later."
        }
    }
}
