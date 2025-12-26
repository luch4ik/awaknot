import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var engine: AVAudioEngine
    private var player: AVAudioPlayerNode
    private var silentPlayer: AVAudioPlayerNode  // For background keep-alive
    private var playerFormat: AVAudioFormat  // Store the connection format
    private var isPlaying = false
    private var isBackgroundAudioActive = false

    init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        silentPlayer = AVAudioPlayerNode()

        engine.attach(player)
        engine.attach(silentPlayer)

        // Get the output node's format and store it
        playerFormat = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: playerFormat)
        engine.connect(silentPlayer, to: engine.mainMixerNode, format: playerFormat)

        print("🔊 AudioManager initialized - format: \(playerFormat.sampleRate)Hz, \(playerFormat.channelCount) channels")

        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            // Use .playback category to allow background audio
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]  // Allow mixing for background audio
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Audio session configured for background playback")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }

    func startBackgroundAudio() {
        guard !isBackgroundAudioActive else {
            print("⚠️ Background audio already active")
            return
        }

        print("🎵 Starting silent background audio to keep app alive...")

        // Create a silent buffer
        let silentDuration: Double = 10.0
        let frameCount = AVAudioFrameCount(playerFormat.sampleRate * silentDuration)

        guard let silentBuffer = AVAudioPCMBuffer(pcmFormat: playerFormat, frameCapacity: frameCount) else {
            print("❌ Failed to create silent buffer")
            return
        }

        silentBuffer.frameLength = frameCount
        // Buffer is already silent (all zeros by default)

        // Start engine if not running
        if !engine.isRunning {
            do {
                try engine.start()
                print("✓ Audio engine started for background audio")
            } catch {
                print("❌ Failed to start engine: \(error)")
                return
            }
        }

        // Set very low volume for silent player
        silentPlayer.volume = 0.01

        // Schedule silent buffer in loop
        silentPlayer.scheduleBuffer(silentBuffer, at: nil, options: .loops, completionHandler: nil)
        silentPlayer.play()

        isBackgroundAudioActive = true
        print("✓ Background audio active - app will stay alive")
    }

    func stopBackgroundAudio() {
        guard isBackgroundAudioActive else { return }

        silentPlayer.stop()
        isBackgroundAudioActive = false
        print("🔇 Background audio stopped")
    }

    func startAlarm() {
        print("🔊 AudioManager.startAlarm() called")

        guard !isPlaying else {
            print("⚠️ Alarm already playing, skipping")
            return
        }

        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Audio session activated")
        } catch {
            print("❌ Failed to activate audio session: \(error)")
            return
        }

        // Create a buffer using the SAME format as the player connection
        let sampleRate = playerFormat.sampleRate
        let duration: Double = 5.0 // Loop every 5 seconds
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: playerFormat, frameCapacity: frameCount) else {
            print("❌ Failed to create audio buffer with format: \(playerFormat)")
            return
        }

        print("✓ Created audio buffer: \(frameCount) frames at \(sampleRate)Hz, \(playerFormat.channelCount) channels")

        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else {
            print("❌ Failed to get float channel data")
            return
        }

        let channelCount = Int(playerFormat.channelCount)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Stutter effect: periodic silence to prevent "droning out"
            let stutter = sin(2.0 * .pi * 5.0 * t) > 0 ? 1.0 : 0.2

            // Frequency modulation (Siren)
            let frequency = 900.0 + 600.0 * sin(2.0 * .pi * 1.5 * t)

            // Harsh square wave
            let baseValue = sin(2.0 * .pi * frequency * t) > 0 ? 0.7 : -0.7

            let sampleValue = Float(baseValue * stutter)

            // Write to all channels (mono or stereo)
            for channel in 0..<channelCount {
                channels[channel][i] = sampleValue
            }
        }

        print("✓ Generated audio waveform for \(channelCount) channel(s)")

        // Start engine if not running
        if !engine.isRunning {
            do {
                try engine.start()
                print("✓ Audio engine started")
            } catch {
                print("❌ CRITICAL: Failed to start audio engine: \(error)")
                return
            }
        }

        // Force volume to max
        engine.mainMixerNode.outputVolume = 1.0
        print("✓ Set volume to maximum")

        // Schedule buffer
        player.scheduleBuffer(buffer, at: nil, options: .loops) { [weak self] in
            print("🔄 Audio buffer completed, rescheduling...")
            if self?.isPlaying == true {
                self?.player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            }
        }
        print("✓ Scheduled audio buffer")

        player.play()
        print("✓ Started audio playback")

        isPlaying = true
        print("🔊 Alarm audio is now RINGING")
    }

    func stopAlarm() {
        player.stop()
        engine.stop()
        isPlaying = false
    }
}
