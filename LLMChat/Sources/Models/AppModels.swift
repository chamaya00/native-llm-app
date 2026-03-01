import Foundation
import UIKit

// MARK: - Session Phase

enum SessionPhase: Equatable {
    case greeting
    case topicSelection
    case wordGeneration
    case wordSelection
    case flashcardGeneration
    case flashcardReview
    case practiceRound
    case feedback
    case freeChat
}

// MARK: - Learner Profile

struct LearnerProfile {
    var name: String
}

// MARK: - Topic

struct Topic: Identifiable {
    let id: UUID
    let emoji: String
    let labelVi: String
    let labelEn: String

    static let defaults: [Topic] = [
        Topic(id: UUID(), emoji: "🍔", labelVi: "Đồ ăn", labelEn: "Food"),
        Topic(id: UUID(), emoji: "✈️", labelVi: "Du lịch", labelEn: "Travel"),
        Topic(id: UUID(), emoji: "💼", labelVi: "Công việc", labelEn: "Work"),
        Topic(id: UUID(), emoji: "🏠", labelVi: "Nhà cửa", labelEn: "Home"),
        Topic(id: UUID(), emoji: "🏥", labelVi: "Sức khỏe", labelEn: "Health"),
        Topic(id: UUID(), emoji: "🛍️", labelVi: "Mua sắm", labelEn: "Shopping"),
    ]
}

// MARK: - Word Entry

struct WordEntry: Identifiable {
    let id: UUID
    let english: String
    let vietnamese: String
    let partOfSpeech: String
    let exampleSentence: String

    // STUB: returns hardcoded words keyed by topic label
    static func stubWords(for topic: Topic) -> [WordEntry] {
        switch topic.labelEn {
        case "Food":
            return [
                WordEntry(id: UUID(), english: "delicious", vietnamese: "ngon", partOfSpeech: "adjective", exampleSentence: "This soup is delicious."),
                WordEntry(id: UUID(), english: "hungry", vietnamese: "đói", partOfSpeech: "adjective", exampleSentence: "I am very hungry."),
                WordEntry(id: UUID(), english: "cook", vietnamese: "nấu ăn", partOfSpeech: "verb", exampleSentence: "She loves to cook dinner."),
                WordEntry(id: UUID(), english: "recipe", vietnamese: "công thức", partOfSpeech: "noun", exampleSentence: "Can you share the recipe?"),
                WordEntry(id: UUID(), english: "ingredient", vietnamese: "nguyên liệu", partOfSpeech: "noun", exampleSentence: "Fresh ingredients make better food."),
                WordEntry(id: UUID(), english: "spicy", vietnamese: "cay", partOfSpeech: "adjective", exampleSentence: "This dish is too spicy for me."),
                WordEntry(id: UUID(), english: "taste", vietnamese: "mùi vị", partOfSpeech: "noun", exampleSentence: "The taste is wonderful."),
                WordEntry(id: UUID(), english: "meal", vietnamese: "bữa ăn", partOfSpeech: "noun", exampleSentence: "We enjoy every meal together."),
                WordEntry(id: UUID(), english: "restaurant", vietnamese: "nhà hàng", partOfSpeech: "noun", exampleSentence: "Let's go to a restaurant tonight."),
                WordEntry(id: UUID(), english: "dessert", vietnamese: "món tráng miệng", partOfSpeech: "noun", exampleSentence: "I always want dessert after dinner."),
            ]
        case "Travel":
            return [
                WordEntry(id: UUID(), english: "journey", vietnamese: "chuyến đi", partOfSpeech: "noun", exampleSentence: "Our journey was amazing."),
                WordEntry(id: UUID(), english: "passport", vietnamese: "hộ chiếu", partOfSpeech: "noun", exampleSentence: "Don't forget your passport!"),
                WordEntry(id: UUID(), english: "luggage", vietnamese: "hành lý", partOfSpeech: "noun", exampleSentence: "My luggage is very heavy."),
                WordEntry(id: UUID(), english: "departure", vietnamese: "khởi hành", partOfSpeech: "noun", exampleSentence: "The departure is at 8 AM."),
                WordEntry(id: UUID(), english: "arrival", vietnamese: "đến nơi", partOfSpeech: "noun", exampleSentence: "Our arrival time is 3 PM."),
                WordEntry(id: UUID(), english: "destination", vietnamese: "điểm đến", partOfSpeech: "noun", exampleSentence: "Paris is our destination."),
                WordEntry(id: UUID(), english: "explore", vietnamese: "khám phá", partOfSpeech: "verb", exampleSentence: "We love to explore new cities."),
                WordEntry(id: UUID(), english: "souvenir", vietnamese: "quà lưu niệm", partOfSpeech: "noun", exampleSentence: "I bought a souvenir for my mom."),
                WordEntry(id: UUID(), english: "hotel", vietnamese: "khách sạn", partOfSpeech: "noun", exampleSentence: "The hotel is near the beach."),
                WordEntry(id: UUID(), english: "ticket", vietnamese: "vé", partOfSpeech: "noun", exampleSentence: "I need two tickets please."),
            ]
        default:
            return [
                WordEntry(id: UUID(), english: "hello", vietnamese: "xin chào", partOfSpeech: "interjection", exampleSentence: "Hello, how are you?"),
                WordEntry(id: UUID(), english: "thank you", vietnamese: "cảm ơn", partOfSpeech: "phrase", exampleSentence: "Thank you for your help."),
                WordEntry(id: UUID(), english: "please", vietnamese: "xin", partOfSpeech: "adverb", exampleSentence: "Please pass the salt."),
                WordEntry(id: UUID(), english: "sorry", vietnamese: "xin lỗi", partOfSpeech: "interjection", exampleSentence: "I am sorry for being late."),
                WordEntry(id: UUID(), english: "understand", vietnamese: "hiểu", partOfSpeech: "verb", exampleSentence: "I understand the lesson."),
                WordEntry(id: UUID(), english: "practice", vietnamese: "luyện tập", partOfSpeech: "verb", exampleSentence: "We practice every day."),
                WordEntry(id: UUID(), english: "learn", vietnamese: "học", partOfSpeech: "verb", exampleSentence: "She learns English quickly."),
                WordEntry(id: UUID(), english: "speak", vietnamese: "nói", partOfSpeech: "verb", exampleSentence: "Can you speak more slowly?"),
                WordEntry(id: UUID(), english: "repeat", vietnamese: "nhắc lại", partOfSpeech: "verb", exampleSentence: "Please repeat that word."),
                WordEntry(id: UUID(), english: "correct", vietnamese: "đúng", partOfSpeech: "adjective", exampleSentence: "Your answer is correct!"),
            ]
        }
    }
}

// MARK: - Flashcard

struct Flashcard: Identifiable {
    let id: UUID
    let wordEntry: WordEntry
    let mnemonicVi: String
    let exampleEn: String
    let exampleVi: String
    let phoneticVi: String  // pronunciation using Vietnamese phonemes
    let phoneticEn: String  // intuitive English phonetics with CAPS for stress
    var image: UIImage?

    // STUB
    static func stub(for word: WordEntry) -> Flashcard {
        let (pVi, pEn) = stubPhonetics[word.english.lowercased()] ?? (word.english, word.english.uppercased())
        return Flashcard(
            id: UUID(),
            wordEntry: word,
            mnemonicVi: "Nhớ từ \"\(word.english)\" giống như \"\(word.vietnamese)\" — hãy tưởng tượng hình ảnh!",
            exampleEn: word.exampleSentence,
            exampleVi: "Câu ví dụ bằng tiếng Việt cho \"\(word.vietnamese)\".",
            phoneticVi: pVi,
            phoneticEn: pEn
        )
    }

    private static let stubPhonetics: [String: (String, String)] = [
        // Food
        "delicious":    ("đề-li-shợs",          "deh-LIH-shus"),
        "hungry":       ("hăng-gri",             "HUNG-gree"),
        "cook":         ("cúc",                  "COOK"),
        "recipe":       ("re-si-pi",             "RES-ih-pee"),
        "ingredient":   ("in-gri-đi-ợt",         "in-GREE-dee-ent"),
        "spicy":        ("xờ-pai-si",            "SPY-see"),
        "taste":        ("tết",                  "TAYST"),
        "meal":         ("min",                  "MEEL"),
        "restaurant":   ("re-xờ-tơ-rần",         "RES-tuh-runt"),
        "dessert":      ("đi-zợt",               "deh-ZURT"),
        // Travel
        "journey":      ("dơ-ni",                "JUR-nee"),
        "passport":     ("pa-xờ-pót",            "PAS-port"),
        "luggage":      ("lắc-gịt",              "LUG-ij"),
        "departure":    ("đi-pa-chờ",            "deh-PAR-chur"),
        "arrival":      ("ờ-rai-vồl",            "uh-RY-vul"),
        "destination":  ("đe-xờ-ti-nê-shần",     "des-tih-NAY-shun"),
        "explore":      ("ex-ploa",              "ex-PLOR"),
        "souvenir":     ("xu-vờ-nia",            "soo-veh-NEER"),
        "hotel":        ("hô-ten",               "hoh-TEL"),
        "ticket":       ("tích-kịt",             "TIK-it"),
        // Default
        "hello":        ("hê-lô",                "heh-LOH"),
        "thank you":    ("theng-kiu",            "THANK-yoo"),
        "please":       ("pli",                  "PLEEZ"),
        "sorry":        ("xo-ri",                "SOR-ee"),
        "understand":   ("ăn-đơ-xtend",          "un-der-STAND"),
        "practice":     ("pre-tịt",              "PRAK-tis"),
        "learn":        ("lợn",                  "LURN"),
        "speak":        ("xờ-pik",               "SPEEK"),
        "repeat":       ("ri-pit",               "ree-PEET"),
        "correct":      ("cờ-rét",               "kuh-REKT"),
    ]
}

// MARK: - Exercise

enum ExerciseType: String {
    case fillBlank
    case multipleChoice
    case translate
}

struct Exercise: Identifiable {
    let id: UUID
    let type: ExerciseType
    let prompt: String
    let correctAnswer: String
    let options: [String]
    let wordEntry: WordEntry

    // STUB: generate 6 exercises (2 per word, up to 3 words) with mix of types
    static func stubExercises(for words: [WordEntry]) -> [Exercise] {
        var exercises: [Exercise] = []
        let limited = Array(words.prefix(3))
        for word in limited {
            // Exercise 1: multiple choice
            exercises.append(Exercise(
                id: UUID(),
                type: .multipleChoice,
                prompt: "'\(word.english)' nghĩa là gì?",
                correctAnswer: word.vietnamese,
                options: distractors(correct: word.vietnamese, pool: limited.map { $0.vietnamese }),
                wordEntry: word
            ))
            // Exercise 2: translate
            exercises.append(Exercise(
                id: UUID(),
                type: .translate,
                prompt: "Dịch sang tiếng Anh: \"\(word.vietnamese)\"",
                correctAnswer: word.english,
                options: [],
                wordEntry: word
            ))
        }
        return exercises
    }

    private static func distractors(correct: String, pool: [String]) -> [String] {
        var options = [correct]
        let others = pool.filter { $0 != correct }
        options += others.prefix(3)
        while options.count < 4 {
            options.append("---")
        }
        return options.shuffled()
    }
}

// MARK: - Exercise Result

struct ExerciseResult {
    let exerciseId: UUID
    let userAnswer: String
    let isCorrect: Bool
}

// MARK: - Practice Round

struct PracticeRound {
    var exercises: [Exercise]
    var results: [ExerciseResult]
}

// MARK: - Round Feedback

struct RoundFeedback {
    let score: Int
    let total: Int
    let commentVi: String
    let corrections: [Correction]

    struct Correction {
        let prompt: String
        let studentAnswer: String
        let correctedAnswer: String
        let explanation: String
    }

    // STUB
    static func stub(score: Int, results: [ExerciseResult], exercises: [Exercise]) -> RoundFeedback {
        let total = exercises.count
        let comment: String
        if score == total {
            comment = "Xuất sắc! Bạn trả lời đúng tất cả câu hỏi! 🎉"
        } else if score >= total / 2 {
            comment = "Tốt lắm! Bạn trả lời đúng \(score)/\(total) câu. Tiếp tục luyện tập nhé! 💪"
        } else {
            comment = "Cố lên! Bạn trả lời đúng \(score)/\(total) câu. Hãy ôn lại và thử lần nữa! 📖"
        }

        var corrections: [Correction] = []
        for result in results where !result.isCorrect {
            if let exercise = exercises.first(where: { $0.id == result.exerciseId }) {
                corrections.append(Correction(
                    prompt: exercise.prompt,
                    studentAnswer: result.userAnswer,
                    correctedAnswer: exercise.correctAnswer,
                    explanation: "Câu trả lời đúng là \"\(exercise.correctAnswer)\"."
                ))
            }
        }

        return RoundFeedback(score: score, total: total, commentVi: comment, corrections: corrections)
    }
}

// MARK: - Quick Reply

enum QuickReplyAction {
    case newTopic
    case addMoreWords
    case freeChat
    case tryAgain
}

struct QuickReply: Identifiable {
    let id: UUID
    let labelVi: String
    let action: QuickReplyAction

    static let postFeedback: [QuickReply] = [
        QuickReply(id: UUID(), labelVi: "Chủ đề mới", action: .newTopic),
        QuickReply(id: UUID(), labelVi: "Thêm từ mới", action: .addMoreWords),
        QuickReply(id: UUID(), labelVi: "Hỏi tự do", action: .freeChat),
    ]
}
