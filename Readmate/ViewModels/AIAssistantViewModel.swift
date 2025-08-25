import Foundation

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []

    func sendMessage(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: true))

        // Mock AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.messages.append(ChatMessage(text: "This is a mock response to '\(text)'.", isUser: false))
            // TODO: Implement real AI API call here
        }
    }

    func askToExplain(_ text: String) {
        let prompt = """
        "\(text)"

        ---
        Explain the text above in simple terms.
        """
        sendMessage(prompt)
    }

    func askToSummarize(_ text: String) {
        let prompt = """
        "\(text)"

        ---
        Summarize the text above.
        """
        sendMessage(prompt)
    }
}
