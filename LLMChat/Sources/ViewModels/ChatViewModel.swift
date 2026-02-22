import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [Message] = []
    private(set) var isGenerating = false
    private(set) var isModelUnavailable = false
    private(set) var unavailabilityReason: String?
    private(set) var errorMessage: String?
    private(set) var streamingContent: String = ""

    private let llmService = LLMService()

    init() {
        Task {
            let reason = await llmService.availabilityReason()
            isModelUnavailable = (reason != nil)
            unavailabilityReason = reason
            if !isModelUnavailable {
                appendGreeting()
            }
        }
    }

    func clearConversation() {
        messages = []
        errorMessage = nil
        streamingContent = ""
        Task { await llmService.resetSession() }
        appendGreeting()
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty, !isGenerating else { return }

        messages.append(Message(role: .user, content: text))
        isGenerating = true
        errorMessage = nil
        streamingContent = ""

        do {
            // The session manages the transcript automatically; pass only the current prompt.
            try await llmService.streamResponse(prompt: text) { [weak self] partial in
                Task { @MainActor [weak self] in
                    self?.streamingContent = partial
                }
            }
            messages.append(Message(role: .assistant, content: streamingContent))
        } catch LLMError.contextWindowExceeded {
            // Service has already condensed the transcript and is ready to continue.
            // Inform the user so they can resend their last message.
            errorMessage = LLMError.contextWindowExceeded.errorDescription
        } catch {
            errorMessage = error.localizedDescription
            messages.append(Message(
                role: .assistant,
                content: "Sorry, I encountered an error. Please try again."
            ))
        }

        streamingContent = ""
        isGenerating = false
    }

    private func appendGreeting() {
        messages.append(Message(
            role: .assistant,
            content: "Hello! I'm your on-device AI assistant. How can I help you today?"
        ))
    }
}
