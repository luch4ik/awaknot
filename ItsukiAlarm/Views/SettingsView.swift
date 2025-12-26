//
//  SettingsView.swift
//  ItsukiAlarm
//
//  Created by Claude Code on 2025/12/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("defaultDifficulty") private var defaultDifficulty: String = "medium"
    @AppStorage("enableHaptics") private var enableHaptics: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                Theme.surfaceElevated.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // App Info Section
                        appInfoSection

                        // Preferences Section
                        preferencesSection

                        // About Section
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.light()
                        dismiss()
                    }) {
                        Text("Done")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    var appInfoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.accent)

            Text("ItsukiAlarm")
                .font(Theme.title1())
                .foregroundColor(Theme.textPrimary)

            Text("Wake up with challenges")
                .font(Theme.body())
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    var preferencesSection: some View {
        VStack(spacing: 16) {
            Text("Preferences")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                // Default Difficulty
                HStack {
                    Image(systemName: "gauge")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)

                    Text("Default Difficulty")
                        .font(Theme.body())
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Picker("", selection: $defaultDifficulty) {
                        Text("Easy").tag("easy")
                        Text("Medium").tag("medium")
                        Text("Hard").tag("hard")
                        Text("Extreme").tag("extreme")
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                }
                .padding()

                Divider()
                    .background(Theme.border)

                // Haptics Toggle
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)

                    Text("Haptic Feedback")
                        .font(Theme.body())
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Toggle("", isOn: $enableHaptics)
                        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                }
                .padding()
            }
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }

    var aboutSection: some View {
        VStack(spacing: 16) {
            Text("About")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                // Version
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)

                    Text("Version")
                        .font(Theme.body())
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text("1.0.0")
                        .font(Theme.body())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()

                Divider()
                    .background(Theme.border)

                // AlarmKit Version
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)

                    Text("AlarmKit")
                        .font(Theme.body())
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text("iOS 18+")
                        .font(Theme.body())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()

                Divider()
                    .background(Theme.border)

                // Credits
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)

                    Text("Built with")
                        .font(Theme.body())
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text("SwiftUI & AlarmKit")
                        .font(Theme.body())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()
            }
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }
}

#Preview {
    SettingsView()
}
