import Foundation

struct Config {
    // MARK: - API Keys
    static var openAIAPIKey: String {
        // Check for API key in environment variables first (for production)
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return apiKey
        }
        
        // Fallback to hardcoded key for development (should be removed in production)
        // TODO: Replace with your actual OpenAI API key for testing
        #if DEBUG
        return "your-openai-api-key-here" // Replace with actual key for development
        #else
        return ""
        #endif
    }
    
    // MARK: - API Configuration
    static let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
    static let openAIModel = "gpt-4-turbo-preview"
    static let openAIMaxTokens = 1000
    static let openAITemperature = 0.7
    
    // MARK: - Validation
    static func validateAPIKey() -> Bool {
        let key = openAIAPIKey
        return !key.isEmpty && key != "your-openai-api-key-here"
    }
    
    // MARK: - Security
    static func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        return "\(prefix)***\(suffix)"
    }
}