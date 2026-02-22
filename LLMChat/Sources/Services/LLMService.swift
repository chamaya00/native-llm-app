import Foundation

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
            return "The conversation was condensed due to context window limits. Please resend your last message."
        }
    }
}

actor LLMService {

#if canImport(FoundationModels)
    private var session: LanguageModelSession?

    private func getOrCreateSession() -> LanguageModelSession {
        if let existing = session { return existing }
        let new = LanguageModelSession(instructions: "You are a helpful assistant.")
        session = new
        return new
    }
#endif

    /// Returns a localised description of why the model is unavailable, or nil if it is available.
    func availabilityReason() -> String? {
#if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This device is not eligible for Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is not enabled. Enable it in Settings > Apple Intelligence & Siri."
            case .modelNotReady:
                return "The on-device AI model is not ready yet. It may still be downloading."
            @unknown default:
                return "The on-device language model is unavailable."
            }
        }
#else
        return "Foundation Models is not available in the current SDK. A physical device running iOS 26 with Apple Intelligence is required."
#endif
    }

    func isAvailable() -> Bool {
#if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
#else
        return false
#endif
    }

    /// Reset the session (call when starting a new conversation).
    func resetSession() {
#if canImport(FoundationModels)
        session = nil
#endif
    }

    /// Stream a response for `prompt`. The session manages the transcript automatically;
    /// do not pass conversation history — call this once per user turn, reusing the actor
    /// across the entire conversation.
    ///
    /// `onPartial` is called on each streamed chunk with the accumulated text so far.
    func streamResponse(
        prompt: String,
        onPartial: @Sendable @escaping (String) -> Void
    ) async throws {
#if canImport(FoundationModels)
        guard isAvailable() else { throw LLMError.unsupportedDevice }

        let s = getOrCreateSession()
        do {
            let stream = s.streamResponse(to: prompt)
            for try await partial in stream {
                onPartial(partial.content)
            }
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Recover: condense transcript to first entry (system instructions) + last entry,
            // then surface the error so the caller can ask the user to resend.
            let entries = Array(s.transcript)
            var condensed: [Transcript.Entry] = []
            if let first = entries.first { condensed.append(first) }
            if entries.count > 1, let last = entries.last { condensed.append(last) }
            session = LanguageModelSession(transcript: Transcript(entries: condensed))
            throw LLMError.contextWindowExceeded
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        // Simulator stub: emit words progressively so the streaming UI is exercisable.
        let words = "This is a simulated streaming response. The Apple Foundation Models framework requires a physical device running iOS 26 with Apple Intelligence capabilities.".split(separator: " ")
        var accumulated = ""
        for word in words {
            try await Task.sleep(nanoseconds: 80_000_000)  // ~80 ms per word
            accumulated += (accumulated.isEmpty ? "" : " ") + word
            onPartial(accumulated)
        }
#endif
    }
}
