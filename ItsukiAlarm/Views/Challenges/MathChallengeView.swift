import SwiftUI

struct MathChallengeView: View {
    let config: MathChallengeConfig
    let onComplete: () -> Void

    @State private var problem: MathChallenge
    @State private var userAnswer = ""
    @State private var isError = false
    @State private var shouldShake = false

    init(config: MathChallengeConfig, onComplete: @escaping () -> Void) {
        self.config = config
        self.onComplete = onComplete
        _problem = State(initialValue: MathChallengeGenerator.generate(difficulty: config.difficulty))
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(problem.question)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Theme.textPrimary, Theme.accent], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(shouldShake ? 0.95 : 1.0)
                .animation(Theme.SpringConfig.snappy, value: shouldShake)

            TextField("", text: $userAnswer)
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundColor(Theme.textPrimary)
                .frame(width: 200, height: 70)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Theme.surfaceElevated)
                        if isError {
                            RoundedRectangle(cornerRadius: 16).fill(Theme.error.opacity(0.2))
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isError ? Theme.error : Theme.accent, lineWidth: 2))
                .shake($shouldShake)

            Button(action: verify) {
                Text("SOLVE")
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 40)
        }
    }

    func verify() {
        guard let answer = Int(userAnswer) else {
            triggerError()
            return
        }

        if MathChallengeGenerator.verify(challenge: problem, answer: answer) {
            HapticManager.shared.success()
            onComplete()
        } else {
            triggerError()
            userAnswer = ""
        }
    }

    func triggerError() {
        isError = true
        shouldShake = true
        HapticManager.shared.error()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { isError = false }
        }
    }
}
