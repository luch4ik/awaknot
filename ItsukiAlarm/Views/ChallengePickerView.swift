import SwiftUI

struct ChallengePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var challenges: [AnyChallengeConfiguration]

    @State private var selectedType: ChallengeType = .math
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var bluetoothDeviceName: String = ""
    @State private var typingWordCount: Int = 5
    @State private var showingBluetoothDevices = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.surfaceElevated.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Challenge Type Selection
                        challengeTypeSection

                        // Configuration based on selected type
                        configurationSection

                        // Add Button
                        addButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }
            }
        }
    }

    // MARK: - Sections

    var challengeTypeSection: some View {
        VStack(spacing: 16) {
            Text("Challenge Type")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: iconFor(type: type))
                                .font(.system(size: 24))
                                .foregroundColor(selectedType == type ? Theme.background : Theme.accent)
                                .frame(width: 50, height: 50)
                                .background(selectedType == type ? Theme.accent : Theme.surface)
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.rawValue)
                                    .font(Theme.body())
                                    .foregroundColor(Theme.textPrimary)

                                Text(descriptionFor(type: type))
                                    .font(Theme.caption())
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedType == type ? Theme.accent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }

    var configurationSection: some View {
        VStack(spacing: 16) {
            Text("Configuration")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                switch selectedType {
                case .math, .memory:
                    difficultyPicker

                case .typing:
                    VStack(spacing: 16) {
                        difficultyPicker
                        wordCountPicker
                    }

                case .bluetooth:
                    bluetoothConfiguration
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }

    var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(Theme.subheadline())
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button(action: {
                        selectedDifficulty = difficulty
                        HapticManager.shared.light()
                    }) {
                        Text(difficulty.rawValue)
                            .font(Theme.caption())
                            .foregroundColor(selectedDifficulty == difficulty ? Theme.background : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDifficulty == difficulty ? Theme.accent : Theme.surfaceElevated)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    var wordCountPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Word Count: \(typingWordCount)")
                .font(Theme.subheadline())
                .foregroundColor(Theme.textSecondary)

            Stepper("", value: $typingWordCount, in: 3...10)
                .labelsHidden()
        }
    }

    var bluetoothConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Name")
                .font(Theme.subheadline())
                .foregroundColor(Theme.textSecondary)

            TextField("Enter device name", text: $bluetoothDeviceName)
                .font(Theme.body())
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Theme.surfaceElevated)
                .cornerRadius(12)

            Text("The alarm will dismiss when you connect to this Bluetooth device")
                .font(Theme.caption())
                .foregroundColor(Theme.textTertiary)

            // Paired devices list
            if !BluetoothChecker.shared.pairedDevices.isEmpty {
                Divider()
                    .background(Theme.border)

                Text("Recently Paired Devices")
                    .font(Theme.subheadline())
                    .foregroundColor(Theme.textSecondary)

                ForEach(BluetoothChecker.shared.pairedDevices, id: \.self) { deviceName in
                    Button(action: {
                        bluetoothDeviceName = deviceName
                        HapticManager.shared.light()
                    }) {
                        HStack {
                            Image(systemName: "bluetooth")
                                .foregroundColor(Theme.accent)

                            Text(deviceName)
                                .font(Theme.body())
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            if bluetoothDeviceName == deviceName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .padding()
                        .background(Theme.surfaceElevated)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    var addButton: some View {
        Button(action: addChallenge) {
            Text("Add Challenge")
                .font(Theme.headline())
        }
        .buttonStyle(GradientButtonStyle())
        .disabled(!canAddChallenge)
        .opacity(canAddChallenge ? 1.0 : 0.5)
    }

    // MARK: - Logic

    var canAddChallenge: Bool {
        switch selectedType {
        case .bluetooth:
            return !bluetoothDeviceName.isEmpty
        default:
            return true
        }
    }

    func addChallenge() {
        HapticManager.shared.success()

        do {
            let config: AnyChallengeConfiguration

            switch selectedType {
            case .math:
                let mathConfig = MathChallengeConfig(difficulty: selectedDifficulty)
                config = try AnyChallengeConfiguration(mathConfig)

            case .typing:
                let typingConfig = TypingChallengeConfig(difficulty: selectedDifficulty, wordCount: typingWordCount)
                config = try AnyChallengeConfiguration(typingConfig)

            case .memory:
                let memoryConfig = MemoryChallengeConfig(difficulty: selectedDifficulty)
                config = try AnyChallengeConfiguration(memoryConfig)

            case .bluetooth:
                let bluetoothConfig = BluetoothChallengeConfig(
                    deviceName: bluetoothDeviceName,
                    usePairedDevices: false
                )
                config = try AnyChallengeConfiguration(bluetoothConfig)
            }

            challenges.append(config)
            dismiss()
        } catch {
            print("❌ Failed to create challenge configuration: \(error)")
        }
    }

    func iconFor(type: ChallengeType) -> String {
        switch type {
        case .math:
            return "function"
        case .bluetooth:
            return "bluetooth"
        case .typing:
            return "keyboard"
        case .memory:
            return "brain.head.profile"
        }
    }

    func descriptionFor(type: ChallengeType) -> String {
        switch type {
        case .math:
            return "Solve a math problem to dismiss"
        case .bluetooth:
            return "Connect to a Bluetooth device"
        case .typing:
            return "Type the displayed text correctly"
        case .memory:
            return "Remember and repeat a color pattern"
        }
    }
}
