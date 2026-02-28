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
            return "Cuộc hội thoại đã bị rút gọn do giới hạn ngữ cảnh. Vui lòng gửi lại tin nhắn cuối."
        }
    }
}

actor LLMService {

#if canImport(FoundationModels)

    // MARK: - Generic chat session

    private var session: LanguageModelSession?

    private func getOrCreateSession() -> LanguageModelSession {
        if let existing = session { return existing }
        let new = LanguageModelSession(instructions: "You are a helpful assistant.")
        session = new
        return new
    }

    // MARK: - Tutor session (one per learning loop; recreated on "Chủ đề mới")

    private var tutorSession: LanguageModelSession?

    private func getOrCreateTutorSession(learnerName: String = "bạn") -> LanguageModelSession {
        if let existing = tutorSession { return existing }
        let instructions = """
        Bạn là một gia sư tiếng Anh thân thiện dành cho người Việt Nam học tiếng Anh ở trình độ A1–A2.
        Tên học viên là \(learnerName). Luôn giao tiếp bằng tiếng Việt trừ khi cần dùng tiếng Anh để dạy.
        Nhiệm vụ của bạn: dạy từ vựng, tạo thẻ học, ra bài tập và đưa ra phản hồi tích cực.
        Giữ câu ngắn gọn, rõ ràng, phù hợp với học viên A1–A2.
        """
        let new = LanguageModelSession(instructions: instructions)
        tutorSession = new
        return new
    }

#endif

    // MARK: - Availability

    /// Returns a localised description of why the model is unavailable, or nil if it is available.
    func availabilityReason() -> String? {
#if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Thiết bị này không đủ điều kiện cho Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence chưa được bật. Vào Cài đặt > Apple Intelligence & Siri để bật."
            case .modelNotReady:
                return "Mô hình AI đang tải xuống. Vui lòng thử lại sau."
            @unknown default:
                return "Mô hình ngôn ngữ on-device không khả dụng."
            }
        }
#else
        return "Foundation Models không khả dụng trong SDK hiện tại. Cần thiết bị thực chạy iOS 26 với Apple Intelligence."
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

    /// Reset the generic chat session (call when starting a new conversation).
    func resetSession() {
#if canImport(FoundationModels)
        session = nil
#endif
    }

    /// Reset the tutor session (call when starting a new topic loop).
    func resetTutorSession() {
#if canImport(FoundationModels)
        tutorSession = nil
#endif
    }

    // MARK: - Generic streaming (free chat)

    /// Stream a response for `prompt`. The session manages the transcript automatically.
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
        let words = "Đây là phản hồi mô phỏng. Framework Foundation Models cần thiết bị thực chạy iOS 26 với Apple Intelligence.".split(separator: " ")
        var accumulated = ""
        for word in words {
            try await Task.sleep(nanoseconds: 80_000_000)
            accumulated += (accumulated.isEmpty ? "" : " ") + word
            onPartial(accumulated)
        }
#endif
    }

    // MARK: - Phase 2: Tutor structured methods

    /// Generate 10 vocabulary words for a topic using guided generation.
    func streamWords(topic: Topic, learnerName: String = "bạn") async throws -> [WordEntry] {
#if canImport(FoundationModels)
        guard isAvailable() else { throw LLMError.unsupportedDevice }
        let s = getOrCreateTutorSession(learnerName: learnerName)
        let prompt = "Hãy tạo 10 từ vựng tiếng Anh về chủ đề '\(topic.labelEn)' phù hợp với trình độ A1–A2."
        do {
            let response = try await s.respond(to: prompt, generating: WordSet.self)
            return response.content.words.map { w in
                WordEntry(
                    id: UUID(),
                    english: w.english,
                    vietnamese: w.vietnamese,
                    partOfSpeech: w.partOfSpeech,
                    exampleSentence: w.exampleSentence
                )
            }
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            tutorSession = nil
            throw LLMError.contextWindowExceeded
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        return WordEntry.stubWords(for: topic)
#endif
    }

    /// Generate a flashcard for a single word. Intended to be called concurrently via `async let`.
    func generateFlashcard(word: WordEntry, learnerName: String = "bạn") async throws -> Flashcard {
#if canImport(FoundationModels)
        guard isAvailable() else { throw LLMError.unsupportedDevice }
        let s = getOrCreateTutorSession(learnerName: learnerName)
        let prompt = "Tạo thẻ học cho từ '\(word.english)' (nghĩa tiếng Việt: \(word.vietnamese))."
        do {
            let response = try await s.respond(to: prompt, generating: GeneratedFlashcard.self)
            let fc = response.content
            return Flashcard(
                id: UUID(),
                wordEntry: word,
                mnemonicVi: fc.mnemonicVi,
                exampleEn: fc.exampleEn,
                exampleVi: fc.exampleVi
            )
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            tutorSession = nil
            throw LLMError.contextWindowExceeded
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        return Flashcard.stub(for: word)
#endif
    }

    /// Generate 6 exercises (2 per word) for a practice round.
    func generateExercises(words: [WordEntry], learnerName: String = "bạn") async throws -> [Exercise] {
#if canImport(FoundationModels)
        guard isAvailable() else { throw LLMError.unsupportedDevice }
        let s = getOrCreateTutorSession(learnerName: learnerName)
        let wordList = words.map { "\($0.english) (\($0.vietnamese))" }.joined(separator: ", ")
        let prompt = "Tạo 6 bài tập (2 cho mỗi từ) để luyện tập: \(wordList). Trộn các loại: fillBlank, multipleChoice, translate."
        do {
            let response = try await s.respond(to: prompt, generating: GeneratedPracticeRound.self)
            let limited = Array(words.prefix(3))
            return response.content.exercises.enumerated().map { i, ex in
                let word = limited[min(i / 2, limited.count - 1)]
                let type = ExerciseType(rawValue: ex.type) ?? .translate
                return Exercise(
                    id: UUID(),
                    type: type,
                    prompt: ex.prompt,
                    correctAnswer: ex.correctAnswer,
                    options: ex.options,
                    wordEntry: word
                )
            }
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            tutorSession = nil
            throw LLMError.contextWindowExceeded
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        return Exercise.stubExercises(for: words)
#endif
    }

    /// Generate feedback based on actual exercise results.
    func generateFeedback(
        results: [ExerciseResult],
        exercises: [Exercise],
        learnerName: String = "bạn"
    ) async throws -> RoundFeedback {
#if canImport(FoundationModels)
        guard isAvailable() else { throw LLMError.unsupportedDevice }
        let s = getOrCreateTutorSession(learnerName: learnerName)
        let score = results.filter { $0.isCorrect }.count
        let total = exercises.count
        let wrongItems = results.filter { !$0.isCorrect }.compactMap { r -> String? in
            guard let ex = exercises.first(where: { $0.id == r.exerciseId }) else { return nil }
            return "Câu '\(ex.prompt)': học viên trả lời '\(r.userAnswer)', đáp án đúng '\(ex.correctAnswer)'"
        }.joined(separator: "; ")
        let prompt = "Học viên \(learnerName) đạt \(score)/\(total) điểm. Sai: \(wrongItems.isEmpty ? "không có" : wrongItems). Đưa ra nhận xét và sửa lỗi."
        do {
            let response = try await s.respond(to: prompt, generating: GeneratedFeedback.self)
            let gf = response.content
            let corrections = gf.corrections.map { c in
                RoundFeedback.Correction(
                    prompt: c.prompt,
                    studentAnswer: c.studentAnswer,
                    correctedAnswer: c.correctedAnswer,
                    explanation: c.explanation
                )
            }
            return RoundFeedback(
                score: gf.score,
                total: total,
                commentVi: gf.commentVi,
                corrections: corrections
            )
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            tutorSession = nil
            throw LLMError.contextWindowExceeded
        } catch {
            throw LLMError.generationFailed(error.localizedDescription)
        }
#else
        let score = results.filter { $0.isCorrect }.count
        return RoundFeedback.stub(score: score, results: results, exercises: exercises)
#endif
    }

    // MARK: - Stub helpers (used while Phase 2 is not yet wired in ChatViewModel)

    func streamWordsStub(for topic: Topic) async -> [WordEntry] {
        return WordEntry.stubWords(for: topic)
    }

    func generateFlashcardsStub(for words: [WordEntry]) async -> [Flashcard] {
        return words.map { Flashcard.stub(for: $0) }
    }

    func generateExercisesStub(for words: [WordEntry]) async -> [Exercise] {
        return Exercise.stubExercises(for: words)
    }

    func generateFeedbackStub(
        score: Int,
        results: [ExerciseResult],
        exercises: [Exercise]
    ) async -> RoundFeedback {
        return RoundFeedback.stub(score: score, results: results, exercises: exercises)
    }
}
