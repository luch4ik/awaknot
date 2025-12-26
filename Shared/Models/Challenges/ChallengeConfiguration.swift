import Foundation

// MARK: - Challenge Type and Difficulty

enum ChallengeType: String, Codable, CaseIterable {
    case math = "Math Puzzle"
    case bluetooth = "Bluetooth Connection"
    case typing = "Typing Challenge"
    case memory = "Memory Pattern"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case extreme = "Extreme"
}

// MARK: - Challenge Configuration Protocol

protocol ChallengeConfiguration: Codable, Identifiable {
    var id: UUID { get }
    var type: ChallengeType { get }
    var displayName: String { get }
}

// MARK: - Math Challenge Configuration

struct MathChallengeConfig: ChallengeConfiguration {
    var id: UUID = UUID()
    var type: ChallengeType { .math }
    var difficulty: Difficulty

    var displayName: String {
        "Math Puzzle (\(difficulty.rawValue))"
    }
}

// MARK: - Bluetooth Challenge Configuration

struct BluetoothChallengeConfig: ChallengeConfiguration {
    var id: UUID = UUID()
    var type: ChallengeType { .bluetooth }
    var deviceName: String
    var usePairedDevices: Bool

    var displayName: String {
        "Bluetooth: \(deviceName)"
    }
}

// MARK: - Typing Challenge Configuration

struct TypingChallengeConfig: ChallengeConfiguration {
    var id: UUID = UUID()
    var type: ChallengeType { .typing }
    var difficulty: Difficulty
    var wordCount: Int = 5 // Number of words in the challenge (3-10)

    var displayName: String {
        "Typing Challenge (\(difficulty.rawValue))"
    }
}

// MARK: - Memory/Pattern Challenge Configuration

struct MemoryChallengeConfig: ChallengeConfiguration {
    var id: UUID = UUID()
    var type: ChallengeType { .memory }
    var difficulty: Difficulty

    var displayName: String {
        "Memory Pattern (\(difficulty.rawValue))"
    }
}

// MARK: - Type-Erased Challenge Configuration Wrapper

struct AnyChallengeConfiguration: Codable, Identifiable {
    let id: UUID
    let type: ChallengeType
    private let _config: Data

    // MARK: - Initialization

    init<T: ChallengeConfiguration>(_ config: T) throws {
        self.id = config.id
        self.type = config.type
        self._config = try JSONEncoder().encode(config)
    }

    // MARK: - Decoding

    func decode<T: ChallengeConfiguration>(as type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: _config)
    }

    // MARK: - Convenience Decoders

    func asMath() throws -> MathChallengeConfig {
        try decode(as: MathChallengeConfig.self)
    }

    func asBluetooth() throws -> BluetoothChallengeConfig {
        try decode(as: BluetoothChallengeConfig.self)
    }

    func asTyping() throws -> TypingChallengeConfig {
        try decode(as: TypingChallengeConfig.self)
    }

    func asMemory() throws -> MemoryChallengeConfig {
        try decode(as: MemoryChallengeConfig.self)
    }

    // MARK: - Display Name

    var displayName: String {
        // Attempt to decode based on type
        switch type {
        case .math:
            if let config = try? asMath() {
                return config.displayName
            }
        case .bluetooth:
            if let config = try? asBluetooth() {
                return config.displayName
            }
        case .typing:
            if let config = try? asTyping() {
                return config.displayName
            }
        case .memory:
            if let config = try? asMemory() {
                return config.displayName
            }
        }
        return type.rawValue
    }
}
