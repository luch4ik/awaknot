import SwiftUI

struct BluetoothChallengeView: View {
    let config: BluetoothChallengeConfig
    let onComplete: () -> Void

    @StateObject private var bluetoothChecker = BluetoothChecker.shared
    @State private var isConnecting = false

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: isConnecting ? "checkmark.circle.fill" : "bluetooth")
                .font(.system(size: 80))
                .foregroundStyle(isConnecting ? Theme.success : Theme.accent)
                .pulse(minOpacity: 0.6, maxOpacity: 1.0, duration: 1.5)
                .scaleEffect(isConnecting ? 1.2 : 1.0)
                .animation(Theme.SpringConfig.bouncy, value: isConnecting)

            VStack(spacing: 12) {
                Text(isConnecting ? "Connected!" : "Connect to Wake Up")
                    .font(Theme.title1())
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    Text(config.deviceName)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.accent)

                    if !isConnecting {
                        Text("|")
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.accent)
                            .pulse(minOpacity: 0.0, maxOpacity: 1.0, duration: 0.8)
                    }
                }

                Text(isConnecting ? "Alarm dismissed!" : "Scanning for device...")
                    .font(Theme.body())
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .onAppear {
            bluetoothChecker.startScanning(for: config.deviceName, timeout: 30.0, usePairedOnly: config.usePairedDevices)
        }
        .onChange(of: bluetoothChecker.targetDeviceConnected) { oldValue, newValue in
            if newValue {
                isConnecting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
            }
        }
        .onDisappear {
            bluetoothChecker.cleanup()
        }
    }
}
