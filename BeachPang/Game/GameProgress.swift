import Foundation

struct GameProgress: Codable {
    /// Highest stage the player may enter.
    var level: Int
    var bestScore: Int
    /// Best star rating per cleared stage (1-3).
    var stars: [Int: Int]

    static let fresh = GameProgress(level: 1, bestScore: 0, stars: [:])
}

enum ProgressStore {
    private static let progressKey = "tile-match-progress"
    private static let onboardingKey = "tile-match-onboarded"

    static func load(defaults: UserDefaults = .standard) -> GameProgress {
        guard let data = defaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode(GameProgress.self, from: data)
        else { return .fresh }
        var stars: [Int: Int] = [:]
        for (stage, raw) in decoded.stars where stage >= 1 {
            stars[stage] = min(3, max(1, raw))
        }
        return GameProgress(
            level: max(1, decoded.level),
            bestScore: max(0, decoded.bestScore),
            stars: stars
        )
    }

    static func save(_ progress: GameProgress, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }

    static func hasSeenOnboarding(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    static func markOnboardingSeen(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: onboardingKey)
    }
}
