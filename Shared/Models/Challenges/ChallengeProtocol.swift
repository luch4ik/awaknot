import Foundation

// MARK: - Challenge Protocol

/// Protocol for challenge generators
protocol ChallengeGenerator {
    associatedtype ChallengeType
    associatedtype AnswerType

    /// Generate a new challenge based on difficulty
    static func generate(difficulty: Difficulty) -> ChallengeType

    /// Verify if the given answer is correct
    static func verify(challenge: ChallengeType, answer: AnswerType) -> Bool
}

// MARK: - Challenge Result Types

/// Represents a math problem challenge
struct MathChallenge {
    let question: String
    let answer: Int
}

/// Represents a typing challenge
struct TypingChallenge {
    let targetText: String
    let wordCount: Int
}

/// Represents a memory/pattern challenge (Simon Says)
struct MemoryChallenge {
    let sequence: [MemoryColor]
    let sequenceLength: Int
}

/// Colors for memory pattern challenge
enum MemoryColor: Int, CaseIterable, Codable {
    case red = 0
    case green = 1
    case blue = 2
    case yellow = 3

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        }
    }
}
