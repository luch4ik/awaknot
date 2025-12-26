import SwiftUI

struct TypingChallengeView: View {
    let config: TypingChallengeConfig
    let onComplete: () -> Void

    @State private var challenge: TypingChallenge
    @State private var userInput = ""
    @State private var isError = false
    @State private var shouldShake = false

    init(config: TypingChallengeConfig, onComplete: @escaping () -> Void) {
        self.config = config
        self.onComplete = onComplete
        _challenge = State(initialValue: TypingChallengeGenerator.generate(difficulty: config.difficulty, wordCount: config.wordCount))
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Type this:")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)

            Text(challenge.targetText)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.accent)
                .multilineTextAlignment(.center)
                .padding()
                .background(Theme.surfaceElevated)
                .cornerRadius(16)

            TextField("Type here...", text: $userInput)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Theme.surfaceElevated)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isError ? Theme.error : Theme.accent, lineWidth: 2))
                .cornerRadius(16)
                .shake($shouldShake)

            Button(action: verify) {
                Text("SUBMIT")
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 32)
    }

    func verify() {
        if TypingChallengeGenerator.verify(challenge: challenge, answer: userInput) {
            HapticManager.shared.success()
            onComplete()
        } else {
            isError = true
            shouldShake = true
            HapticManager.shared.error()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { isError = false }
            }
        }
    }
}
