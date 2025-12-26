import Foundation

struct WakeUpCheckConfig: Codable {
    var isEnabled: Bool
    var delayMinutes: Int            // Time to wait after alarm before checking
    var responseTimeMinutes: Int     // Time user has to respond

    static let defaultConfig = WakeUpCheckConfig(
        isEnabled: false,
        delayMinutes: 10,
        responseTimeMinutes: 2
    )

    static let delayOptions = [5, 10, 15, 20, 30]
    static let responseTimeOptions = [1, 2, 3, 5]
}
