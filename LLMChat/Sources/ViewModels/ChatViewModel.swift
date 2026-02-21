import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [Message] = []
    private(set) var isGenerating = false
    private(set) var isModelUnavailable = false
    private(set) var errorMessage: String?
    private(set) var isContextWindowExceeded = false

    private let llmService = LLMService()

    init() {
        Task {
            isModelUnavailable = !(await llmService.isAvailable())
            if isModelUnavailable {
                return
            }
            appendGreeting()
        }
    }

    func clearConversation() {
        messages = []
        errorMessage = nil
        isContextWindowExceeded = false
        appendGreeting()
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty, !isGenerating, !isContextWindowExceeded else { return }

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isGenerating = true
        errorMessage = nil

        do {
            let response = try await llmService.generateResponse(prompt: text, history: messages.dropLast())
            let assistantMessage = Message(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch LLMError.contextWindowExceeded {
            isContextWindowExceeded = true
            errorMessage = LLMError.contextWindowExceeded.errorDescription
            messages.append(Message(
                role: .assistant,
                content: "This conversation has reached the model's context window limit. Start a new chat to continue."
            ))
        } catch {
            errorMessage = error.localizedDescription
            messages.append(Message(
                role: .assistant,
                content: "Sorry, I encountered an error: \(error.localizedDescription). Please try again."
            ))
        }

        isGenerating = false
    }

    private func appendGreeting() {
        messages.append(Message(
            role: .assistant,
            content: "Hello! I'm your on-device AI assistant. How can I help you today?"
        ))
    }
}
