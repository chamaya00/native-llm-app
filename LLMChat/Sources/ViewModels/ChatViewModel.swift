import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Existing (keep for Zone 1 thread bubbles)

    private(set) var messages: [Message] = []
    private(set) var isGenerating = false
    private(set) var isModelUnavailable = false
    private(set) var unavailabilityReason: String?
    private(set) var errorMessage: String?
    private(set) var streamingContent: String = ""

    // MARK: - Tutor State Machine

    private(set) var phase: SessionPhase = .greeting
    private(set) var learnerProfile: LearnerProfile?

    // Zone 2
    private(set) var topics: [Topic] = []
    private(set) var quickReplies: [QuickReply] = []
    private(set) var statusMessage: String?

    // Word selection
    private(set) var currentWords: [WordEntry] = []
    var selectedWords: [WordEntry] = []

    // Flashcards
    private(set) var flashcards: [Flashcard] = []
    private(set) var flashcardImages: [UUID: UIImage] = [:]

    // Practice
    private(set) var currentExerciseIndex: Int = 0
    private(set) var practiceRound: PracticeRound?
    private(set) var currentFeedback: RoundFeedback?

    // Zone 3 sheet/overlay visibility
    var isShowingWordGrid: Bool = false
    var isShowingFlashcards: Bool = false
    var isShowingExercise: Bool = false

    // MARK: - Private

    private let llmService = LLMService()
    private var currentTopic: Topic?

    // MARK: - Init

    init() {
        Task {
            let reason = await llmService.availabilityReason()
            isModelUnavailable = (reason != nil)
            unavailabilityReason = reason
        }
    }

    // MARK: - Name Capture Flow

    func setLearnerName(_ name: String) {
        learnerProfile = LearnerProfile(name: name)
        Task { await startGreeting() }
    }

    // MARK: - Learning Loop Step 1: Greeting + Topic Chips

    private func startGreeting() async {
        phase = .greeting
        isGenerating = true
        streamingContent = ""

        // STUB: simulate streaming greeting
        let name = learnerProfile?.name ?? "bạn"
        let greeting = "Xin chào \(name)! 👋 Tôi là gia sư tiếng Anh của bạn. Hôm nay bạn muốn học từ vựng về chủ đề gì?"
        await streamFake(greeting)

        messages.append(Message(role: .assistant, content: greeting))
        streamingContent = ""
        isGenerating = false

        phase = .topicSelection
        withAnimation(.tutorSpring) {
            topics = Topic.defaults
        }
    }

    // MARK: - Learning Loop Step 2: Word Generation

    func selectTopic(_ topic: Topic) async {
        currentTopic = topic
        withAnimation(.tutorSpring) {
            topics = []
            quickReplies = []
        }

        messages.append(Message(role: .user, content: "\(topic.emoji) \(topic.labelVi)"))

        phase = .wordGeneration
        statusMessage = "✦ Đang tạo từ vựng..."
        isGenerating = true
        streamingContent = ""

        let response = "Hay quá! Chủ đề \(topic.emoji) \(topic.labelVi). Để tôi tìm 10 từ tiếng Anh thú vị cho bạn..."
        await streamFake(response)
        messages.append(Message(role: .assistant, content: response))
        streamingContent = ""
        isGenerating = false

        // STUB: simulate word generation delay
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        currentWords = await llmService.streamWordsStub(for: topic)
        selectedWords = []
        statusMessage = nil

        withAnimation(.tutorSpring) {
            phase = .wordSelection
            isShowingWordGrid = true
        }
    }

    // MARK: - Learning Loop Step 3: Word Selection Confirmed

    func confirmWordSelection() async {
        guard !selectedWords.isEmpty else { return }

        isShowingWordGrid = false
        phase = .flashcardGeneration
        statusMessage = "✦ Đang tạo thẻ học..."

        let wordsText = selectedWords.map { $0.english }.joined(separator: ", ")
        messages.append(Message(
            role: .assistant,
            content: "Tuyệt vời! Bạn đã chọn: \(wordsText). Tôi đang tạo thẻ học cho bạn... 📚"
        ))

        // STUB: simulate flashcard generation
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        flashcards = await llmService.generateFlashcardsStub(for: selectedWords)
        statusMessage = nil

        withAnimation(.tutorSpring) {
            phase = .flashcardReview
            isShowingFlashcards = true
        }
    }

    // MARK: - Learning Loop Step 5: Flashcard Review Done

    func finishFlashcardReview() async {
        isShowingFlashcards = false
        statusMessage = "✦ Đang tạo bài tập..."

        messages.append(Message(
            role: .assistant,
            content: "Bạn đã xem hết thẻ học rồi! Bây giờ hãy luyện tập để ghi nhớ từ vựng nhé 💪"
        ))

        // STUB: simulate exercise generation
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let exercises = await llmService.generateExercisesStub(for: selectedWords)
        practiceRound = PracticeRound(exercises: exercises, results: [])
        currentExerciseIndex = 0
        currentFeedback = nil
        statusMessage = nil

        withAnimation(.tutorSpring) {
            phase = .practiceRound
            isShowingExercise = true
        }
    }

    // MARK: - Learning Loop Step 6: Exercise Answer Submitted

    func submitAnswer(_ answer: String) async {
        guard var round = practiceRound,
              currentExerciseIndex < round.exercises.count else { return }

        let exercise = round.exercises[currentExerciseIndex]
        let normalized = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = exercise.correctAnswer.lowercased()
        let isCorrect = normalized == correct

        round.results.append(ExerciseResult(
            exerciseId: exercise.id,
            userAnswer: answer,
            isCorrect: isCorrect
        ))
        practiceRound = round

        if isCorrect {
            Haptics.notification(.success)
            try? await Task.sleep(nanoseconds: 600_000_000)
        } else {
            Haptics.notification(.error)
            try? await Task.sleep(nanoseconds: 800_000_000)
        }

        if currentExerciseIndex + 1 < round.exercises.count {
            currentExerciseIndex += 1
        } else {
            isShowingExercise = false
            await generateFeedback()
        }
    }

    // MARK: - Learning Loop Step 7: Feedback

    private func generateFeedback() async {
        phase = .feedback
        statusMessage = "✦ Đang tạo nhận xét..."

        guard let round = practiceRound else { return }
        let score = round.results.filter { $0.isCorrect }.count

        // STUB: simulate feedback generation
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        statusMessage = nil

        let feedback = await llmService.generateFeedbackStub(
            score: score,
            results: round.results,
            exercises: round.exercises
        )
        currentFeedback = feedback

        let scoreEmoji = score == round.exercises.count ? "🎉" : score >= round.exercises.count / 2 ? "👍" : "📖"
        messages.append(Message(
            role: .assistant,
            content: "\(scoreEmoji) Điểm của bạn: \(score)/\(round.exercises.count)"
        ))

        withAnimation(.tutorSpring) {
            quickReplies = QuickReply.postFeedback
        }
    }

    // MARK: - Quick Reply Actions

    func handleQuickReply(_ reply: QuickReply) async {
        withAnimation(.tutorSpring) {
            quickReplies = []
        }
        currentFeedback = nil

        switch reply.action {
        case .newTopic:
            messages.append(Message(role: .user, content: reply.labelVi))
            await llmService.resetTutorSession()
            await startGreeting()

        case .addMoreWords:
            messages.append(Message(role: .user, content: reply.labelVi))
            if let topic = currentTopic {
                await selectTopic(topic)
            } else {
                phase = .topicSelection
                withAnimation(.tutorSpring) { topics = Topic.defaults }
            }

        case .tryAgain:
            messages.append(Message(role: .user, content: reply.labelVi))
            if let round = practiceRound {
                practiceRound = PracticeRound(exercises: round.exercises, results: [])
                currentExerciseIndex = 0
                withAnimation(.tutorSpring) {
                    phase = .practiceRound
                    isShowingExercise = true
                }
            }

        case .freeChat:
            messages.append(Message(role: .user, content: reply.labelVi))
            messages.append(Message(
                role: .assistant,
                content: "Tất nhiên! Bạn muốn hỏi gì thì cứ hỏi nhé 😊"
            ))
            phase = .freeChat
        }
    }

    // MARK: - Free Chat

    func sendMessage(_ text: String) async {
        guard !text.isEmpty, !isGenerating else { return }

        messages.append(Message(role: .user, content: text))
        isGenerating = true
        errorMessage = nil
        streamingContent = ""

        do {
            try await llmService.streamResponse(prompt: text) { [weak self] partial in
                Task { @MainActor [weak self] in
                    self?.streamingContent = partial
                }
            }
            messages.append(Message(role: .assistant, content: streamingContent))
        } catch LLMError.contextWindowExceeded {
            errorMessage = LLMError.contextWindowExceeded.errorDescription
        } catch {
            errorMessage = error.localizedDescription
            messages.append(Message(
                role: .assistant,
                content: "Xin lỗi, tôi gặp lỗi. Bạn hãy thử lại nhé."
            ))
        }

        streamingContent = ""
        isGenerating = false
    }

    // MARK: - Conversation Reset

    func clearConversation() {
        messages = []
        errorMessage = nil
        streamingContent = ""
        topics = []
        quickReplies = []
        statusMessage = nil
        currentWords = []
        selectedWords = []
        flashcards = []
        flashcardImages = [:]
        practiceRound = nil
        currentFeedback = nil
        currentTopic = nil
        isShowingWordGrid = false
        isShowingFlashcards = false
        isShowingExercise = false

        Task {
            await llmService.resetSession()
            await llmService.resetTutorSession()
            await startGreeting()
        }
    }

    // MARK: - Helpers

    var currentExercise: Exercise? {
        guard let round = practiceRound,
              currentExerciseIndex < round.exercises.count else { return nil }
        return round.exercises[currentExerciseIndex]
    }

    var exerciseProgress: Double {
        guard let round = practiceRound, !round.exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(round.exercises.count)
    }

    // Simulates character-by-character streaming for fake responses
    private func streamFake(_ text: String) async {
        var accumulated = ""
        for char in text {
            accumulated.append(char)
            streamingContent = accumulated
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms per char
        }
    }
}

// MARK: - UIImage placeholder (non-FoundationModels code)
import UIKit
