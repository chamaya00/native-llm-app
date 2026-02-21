import Foundation

// NOTE: FoundationModels is available in iOS 26+. The import and API usage below
// follows the Apple Foundation Models framework design. When Xcode 26 SDK is
// available, ensure the import resolves correctly.
//
// STUB: If FoundationModels is not yet available in your SDK, replace the body
// of generateResponse() with a mock implementation for testing.

#if canImport(FoundationModels)
import FoundationModels
#endif

enum LLMError: LocalizedError {
    case modelUnavailable
    case generationFailed(String)
    case unsupportedDevice
    case contextWindowExceeded

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "The on-device language model is not available."
        case .generationFailed(let reason):
            return "Response generation failed: \(reason)"
        case .unsupportedDevice:
            return "This device does not support on-device AI. iOS 26+ with compatible hardware is required."
        case .contextWindowExceeded:
            return "The conversation has reached the model's context window limit."
        }
    }
}

final class LLMService: Sendable {

    func isAvailable() async -> Bool {
#if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
#else
        // Simulator / SDK pre-iOS 26: return false so UI shows unavailability banner
        return false
#endif
    }

    /// Generate a response for the given prompt with optional conversation history.
    /// - Parameters:
    ///   - prompt: The latest user message.
    ///   - history: Prior messages for context (all but the last user message).
    /// - Returns: The assistant's response string.
    func generateResponse(prompt: String, history: some Collection<Message>) async throws -> String {
#if canImport(FoundationModels)
        guard case .available = SystemLanguageModel.default.availability else {
            throw LLMError.unsupportedDevice
        }

        // Build a LanguageModelSession and send the conversation.
        // FoundationModels uses a prompt / context API; we concatenate history
        // as a structured transcript to give the model conversational context.
        let session = LanguageModelSession()

        // Format conversation history as a context string prepended to the prompt.
        let contextLines = history.map { msg -> String in
            let roleLabel = msg.role == .user ? "User" : "Assistant"
            return "\(roleLabel): \(msg.content)"
        }

        let fullPrompt: String
        if contextLines.isEmpty {
            fullPrompt = prompt
        } else {
            let context = contextLines.joined(separator: "\n")
            fullPrompt = "\(context)\nUser: \(prompt)\nAssistant:"
        }

        do {
            let response = try await session.respond(to: fullPrompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // FoundationModels throws a specific error when the prompt exceeds the
            // model's context window. Check by description until the SDK stabilises.
            let description = error.localizedDescription.lowercased()
            let isContextError = description.contains("context") &&
                (description.contains("length") || description.contains("limit") ||
                 description.contains("window") || description.contains("exceed"))
            if isContextError {
                throw LLMError.contextWindowExceeded
            }
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        // --- STUB: FoundationModels not available in current SDK ---
        // Replace this block with real implementation once iOS 26 SDK is available.
        // For now, returns a mock response so the UI is testable in simulator.
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second simulated delay
        return "This is a simulated response. The Apple Foundation Models framework requires a physical device running iOS 26 with Apple Intelligence capabilities. Please test on supported hardware."
#endif
    }
}
