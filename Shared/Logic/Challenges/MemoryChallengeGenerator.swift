import Foundation

// MARK: - Memory Challenge Generator

class MemoryChallengeGenerator: ChallengeGenerator {
    typealias ChallengeType = MemoryChallenge
    typealias AnswerType = [MemoryColor]

    // MARK: - Generation

    static func generate(difficulty: Difficulty) -> MemoryChallenge {
        let sequenceLength = getSequenceLength(for: difficulty)
        let sequence = generateRandomSequence(length: sequenceLength)

        return MemoryChallenge(sequence: sequence, sequenceLength: sequenceLength)
    }

    private static func getSequenceLength(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:
            return 4
        case .medium:
            return 6
        case .hard:
            return 8
        case .extreme:
            return 12
        }
    }

    private static func generateRandomSequence(length: Int) -> [MemoryColor] {
        return (0..<length).map { _ in MemoryColor.allCases.randomElement()! }
    }

    // MARK: - Verification

    static func verify(challenge: MemoryChallenge, answer: [MemoryColor]) -> Bool {
        // Must match exactly - same length and same sequence
        guard challenge.sequence.count == answer.count else {
            return false
        }

        return zip(challenge.sequence, answer).allSatisfy { $0 == $1 }
    }
}
