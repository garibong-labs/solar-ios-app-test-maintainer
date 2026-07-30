import Foundation

enum LevelRules {
    static let movesPerLevel = 20
    static let tileScore = 60
    static let moveBonus = 100
    static let maxCascadeMultiplier = 5

    /// Score required to clear the level. Grows steadily but stays beatable.
    static func levelTarget(_ level: Int) -> Int {
        1000 + (max(1, level) - 1) * 750
    }

    /// Cascade 0 is the direct match; each chain reaction raises the multiplier.
    static func cascadeMultiplier(_ cascade: Int) -> Int {
        min(cascade + 1, maxCascadeMultiplier)
    }

    static func clearScore(clearedCount: Int, cascade: Int) -> Int {
        clearedCount * tileScore * cascadeMultiplier(cascade)
    }

    /// 1★ for reaching the target, 2★ at 1.5x, 3★ at 2x.
    static func starsForScore(_ score: Int, target: Int) -> Int {
        if score >= target * 2 { return 3 }
        if Double(score) >= Double(target) * 1.5 { return 2 }
        return score >= target ? 1 : 0
    }
}
