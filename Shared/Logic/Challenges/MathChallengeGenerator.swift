import Foundation

// MARK: - Math Challenge Generator

class MathChallengeGenerator: ChallengeGenerator {
    typealias ChallengeType = MathChallenge
    typealias AnswerType = Int

    static func generate(difficulty: Difficulty) -> MathChallenge {
        switch difficulty {
        case .easy:
            let a = Int.random(in: 2...9)
            let b = Int.random(in: 2...9)
            return MathChallenge(question: "\(a) + \(b)", answer: a + b)

        case .medium:
            let a = Int.random(in: 11...99)
            let b = Int.random(in: 11...99)
            return MathChallenge(question: "\(a) + \(b)", answer: a + b)

        case .hard:
            let a = Int.random(in: 11...50)
            let b = Int.random(in: 2...9)
            let c = Int.random(in: 1...20)
            return MathChallenge(question: "\(a) × \(b) - \(c)", answer: (a * b) - c)

        case .extreme:
            let a = Int.random(in: 11...99)
            let b = Int.random(in: 11...99)
            let c = Int.random(in: 11...99)
            return MathChallenge(question: "\(a) + \(b) + \(c)", answer: a + b + c)
        }
    }

    static func verify(challenge: MathChallenge, answer: Int) -> Bool {
        return challenge.answer == answer
    }
}

// MARK: - Legacy Compatibility

/// Legacy wrapper for backward compatibility
struct MathProblem {
    let question: String
    let answer: Int
}

class MathGenerator {
    static func generate(difficulty: Difficulty) -> MathProblem {
        let challenge = MathChallengeGenerator.generate(difficulty: difficulty)
        return MathProblem(question: challenge.question, answer: challenge.answer)
    }
}
