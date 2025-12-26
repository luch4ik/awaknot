import SwiftUI

struct TriggerView: View {
    let alarm: ItsukiAlarm
    let onDismiss: () -> Void

    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var bluetoothChecker = BluetoothChecker.shared

    // Multi-challenge state
    @State private var currentChallengeIndex = 0
    @State private var completedChallenges: [UUID] = []
    @State private var showCelebration = false

    // Emergency escape hatch
    @State private var escapeTapCount = 0
    @State private var showEscapeHint = false

    var body: some View {
        ZStack {
            // Radial gradient background
            Theme.backgroundRadialGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 50) {
                    // Header with time and wake up label
                    VStack(spacing: 16) {
                        if let scheduledTime = alarm.scheduledTime {
                            Text("\(scheduledTime.hour):\(String(format: "%02d", scheduledTime.minute))")
                                .font(Theme.timeLarge())
                                .foregroundColor(Theme.textPrimary)
                                .shadow(color: Theme.accent.opacity(0.4), radius: 24, x: 0, y: 0)
                        }

                        Text(getTimeOfDayMessage())
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accent)
                            .tracking(6)
                            .pulse(minOpacity: 0.7, maxOpacity: 1.0, duration: 1.5)
                    }

                    // Progress indicator (if multiple challenges)
                    if alarm.challenges.count > 1 {
                        progressIndicator
                    }

                    // Challenge Area
                    if alarm.challenges.isEmpty {
                        // No challenges - show dismiss button
                        Button(action: {
                            HapticManager.shared.success()
                            onDismiss()
                        }) {
                            Text("DISMISS")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .buttonStyle(GradientButtonStyle())
                        .padding(.horizontal, 40)
                    } else if currentChallengeIndex < alarm.challenges.count {
                        currentChallengeView
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            // Celebration overlay
            if showCelebration {
                celebrationView
                    .transition(.scale.combined(with: .opacity))
            }

            // Emergency escape hatch (top-left corner)
            VStack {
                HStack {
                    Color.clear
                        .frame(width: 60, height: 60)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleEscapeTap()
                        }
                    Spacer()
                }
                Spacer()
            }

            // Escape hint
            if showEscapeHint {
                VStack {
                    HStack {
                        Text("\(10 - escapeTapCount) more taps...")
                            .font(Theme.caption())
                            .foregroundColor(Theme.textTertiary)
                            .padding(8)
                            .background(Theme.surface.opacity(0.8))
                            .cornerRadius(8)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .statusBarHidden(true)
        .onAppear {
            print("🎯 TriggerView appeared for alarm: \(alarm.title)")
            print("  - Challenges: \(alarm.challenges.count)")
            audioManager.startAlarm()
        }
        .onDisappear {
            audioManager.stopAlarm()
            bluetoothChecker.cleanup()
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Progress Indicator

    var progressIndicator: some View {
        VStack(spacing: 8) {
            Text("Challenge \(currentChallengeIndex + 1) of \(alarm.challenges.count)")
                .font(Theme.caption())
                .foregroundColor(Theme.textSecondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accent)
                        .frame(
                            width: geometry.size.width * CGFloat(currentChallengeIndex) / CGFloat(max(alarm.challenges.count, 1)),
                            height: 8
                        )
                        .animation(Theme.SpringConfig.gentle, value: currentChallengeIndex)
                }
            }
            .frame(height: 8)
            .frame(maxWidth: 200)
        }
    }

    // MARK: - Current Challenge View

    @ViewBuilder
    var currentChallengeView: some View {
        if currentChallengeIndex < alarm.challenges.count {
            let challenge = alarm.challenges[currentChallengeIndex]

            switch challenge.type {
            case .math:
                if let config = try? challenge.asMath() {
                    MathChallengeView(config: config, onComplete: completeCurrentChallenge)
                }
            case .bluetooth:
                if let config = try? challenge.asBluetooth() {
                    BluetoothChallengeView(config: config, onComplete: completeCurrentChallenge)
                }
            case .typing:
                if let config = try? challenge.asTyping() {
                    TypingChallengeView(config: config, onComplete: completeCurrentChallenge)
                }
            case .memory:
                if let config = try? challenge.asMemory() {
                    MemoryChallengeView(config: config, onComplete: completeCurrentChallenge)
                }
            }
        }
    }

    // MARK: - Celebration View

    var celebrationView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Theme.success)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)
                    .animation(Theme.SpringConfig.bouncy.delay(0.1), value: showCelebration)

                Text("All Challenges Complete!")
                    .font(Theme.title1())
                    .foregroundColor(Theme.textPrimary)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)
                    .animation(Theme.SpringConfig.bouncy.delay(0.2), value: showCelebration)
            }
        }
    }

    // MARK: - Logic

    func completeCurrentChallenge() {
        guard currentChallengeIndex < alarm.challenges.count else { return }

        // Mark challenge as completed
        let challengeID = alarm.challenges[currentChallengeIndex].id
        completedChallenges.append(challengeID)

        // Move to next challenge or finish
        if currentChallengeIndex + 1 < alarm.challenges.count {
            // More challenges remaining
            withAnimation(Theme.SpringConfig.gentle) {
                currentChallengeIndex += 1
            }
        } else {
            // All challenges complete - celebrate and dismiss
            withAnimation(Theme.SpringConfig.bouncy) {
                showCelebration = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }

    // MARK: - Time-of-Day Messages

    func getTimeOfDayMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9:
            return "GOOD MORNING"
        case 9..<12:
            return "RISE & SHINE"
        case 12..<17:
            return "WAKE UP"
        case 17..<21:
            return "GET UP"
        default:
            return "WAKE UP"
        }
    }

    // MARK: - Emergency Escape Hatch

    func handleEscapeTap() {
        escapeTapCount += 1

        if escapeTapCount == 1 {
            withAnimation {
                showEscapeHint = true
            }
        }

        if escapeTapCount >= 10 {
            HapticManager.shared.heavy()
            onDismiss()
        } else if escapeTapCount > 0 {
            HapticManager.shared.light()
        }

        // Reset counter after 3 seconds of inactivity
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if escapeTapCount < 10 {
                withAnimation {
                    escapeTapCount = 0
                    showEscapeHint = false
                }
            }
        }
    }
}
