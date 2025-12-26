import Foundation

// MARK: - Typing Challenge Generator

class TypingChallengeGenerator: ChallengeGenerator {
    typealias ChallengeType = TypingChallenge
    typealias AnswerType = String

    // MARK: - Word Lists

    private static let easyWords = [
        "cat", "dog", "sun", "run", "big", "red", "hot", "yes",
        "car", "toy", "cup", "box", "hat", "pen", "key", "eye",
        "map", "bag", "bat", "can", "fox", "hen", "jam", "nut"
    ]

    private static let mediumWords = [
        "morning", "elephant", "bicycle", "rainbow", "kitchen",
        "computer", "umbrella", "sandwich", "dinosaur", "hospital",
        "birthday", "giraffe", "airplane", "princess", "treasure",
        "mountain", "football", "vegetable", "chocolate", "butterfly"
    ]

    private static let hardWords = [
        "extraordinary", "international", "revolutionary", "psychological",
        "sophisticated", "uncomfortable", "environmental", "unbelievable",
        "unconventional", "interdisciplinary", "transcontinental",
        "incomprehensible", "entrepreneurship", "electromagnetic",
        "transformation", "archaeologist", "philosophical", "unpredictable"
    ]

    private static let extremeWords = [
        "electroencephalography", "deoxyribonucleic", "institutionalization",
        "psychoneuroimmunology", "counterrevolutionary", "electromagnetism",
        "telecommunications", "compartmentalization", "internationalization",
        "pneumonoultramicroscopicsilicovolcanoconiosis", "floccinaucinihilipilification",
        "antidisestablishmentarianism", "supercalifragilisticexpialidocious"
    ]

    // MARK: - Generation

    static func generate(difficulty: Difficulty) -> TypingChallenge {
        return generate(difficulty: difficulty, wordCount: 5)
    }

    static func generate(difficulty: Difficulty, wordCount: Int) -> TypingChallenge {
        let words = getWordList(for: difficulty)
        let selectedWords = (0..<wordCount).map { _ in words.randomElement()! }
        let targetText = selectedWords.joined(separator: " ")

        return TypingChallenge(targetText: targetText, wordCount: wordCount)
    }

    private static func getWordList(for difficulty: Difficulty) -> [String] {
        switch difficulty {
        case .easy:
            return easyWords
        case .medium:
            return mediumWords
        case .hard:
            return hardWords
        case .extreme:
            return extremeWords
        }
    }

    // MARK: - Verification

    static func verify(challenge: TypingChallenge, answer: String) -> Bool {
        // Case-insensitive comparison, trimming whitespace
        let normalizedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedTarget = challenge.targetText.lowercased()

        return normalizedAnswer == normalizedTarget
    }
}
