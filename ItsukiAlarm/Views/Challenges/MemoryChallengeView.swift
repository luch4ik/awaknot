import SwiftUI

struct MemoryChallengeView: View {
    let config: MemoryChallengeConfig
    let onComplete: () -> Void

    @State private var challenge: MemoryChallenge
    @State private var userSequence: [MemoryColor] = []
    @State private var isShowingSequence = true
    @State private var currentDisplayIndex = 0
    @State private var isError = false

    init(config: MemoryChallengeConfig, onComplete: @escaping () -> Void) {
        self.config = config
        self.onComplete = onComplete
        _challenge = State(initialValue: MemoryChallengeGenerator.generate(difficulty: config.difficulty))
    }

    var body: some View {
        VStack(spacing: 32) {
            if isShowingSequence {
                sequenceDisplayView
            } else {
                inputView
            }
        }
        .onAppear {
            playSequence()
        }
    }

    var sequenceDisplayView: some View {
        VStack(spacing: 24) {
            Text("Remember this pattern")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)

            // Display grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(MemoryColor.allCases, id: \.self) { color in
                    colorButton(color: color, isActive: currentDisplayIndex < challenge.sequence.count && challenge.sequence[currentDisplayIndex] == color)
                        .disabled(true)
                }
            }
            .frame(maxWidth: 300)
        }
    }

    var inputView: some View {
        VStack(spacing: 24) {
            Text("Repeat the pattern")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)

            Text("\(userSequence.count) / \(challenge.sequenceLength)")
                .font(Theme.caption())
                .foregroundColor(Theme.textTertiary)

            // Input grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(MemoryColor.allCases, id: \.self) { color in
                    colorButton(color: color, isActive: false)
                        .onTapGesture {
                            addColor(color)
                        }
                }
            }
            .frame(maxWidth: 300)

            // User's current sequence
            if !userSequence.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(userSequence.enumerated()), id: \.offset) { index, color in
                        Circle()
                            .fill(swiftUIColor(for: color))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }

    func colorButton(color: MemoryColor, isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(swiftUIColor(for: color))
            .frame(height: 100)
            .opacity(isActive ? 1.0 : 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.white : Color.clear, lineWidth: 4)
            )
            .shadow(color: isActive ? swiftUIColor(for: color).opacity(0.6) : .clear, radius: 20)
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(Theme.SpringConfig.bouncy, value: isActive)
    }

    func swiftUIColor(for color: MemoryColor) -> Color {
        switch color {
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        }
    }

    func playSequence() {
        var delay: Double = 0.5

        for (index, _) in challenge.sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                currentDisplayIndex = index
                HapticManager.shared.light()
            }

            delay += 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
            isShowingSequence = false
        }
    }

    func addColor(_ color: MemoryColor) {
        HapticManager.shared.light()
        userSequence.append(color)

        if userSequence.count == challenge.sequenceLength {
            verify()
        }
    }

    func verify() {
        if MemoryChallengeGenerator.verify(challenge: challenge, answer: userSequence) {
            HapticManager.shared.success()
            onComplete()
        } else {
            isError = true
            HapticManager.shared.error()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                userSequence = []
                isError = false
            }
        }
    }
}
