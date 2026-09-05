import Foundation

/// Turns accumulated attribute XP into a level. Levels get progressively more
/// expensive (DESIGN.md §5): reaching level n costs `baseLevelCost * n`, so the
/// first level costs 100 XP, the second 200 more, the third 300 more.
enum AttributeProgression {

    /// Balance constant (§34). Tuning value, not final.
    static let baseLevelCost = 100

    /// Total XP that must be accumulated to stand at `level`.
    static func cumulativeXP(forLevel level: Int) -> Int {
        guard level > 0 else { return 0 }
        return baseLevelCost * level * (level + 1) / 2
    }

    static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 0 }
        var level = 0
        while cumulativeXP(forLevel: level + 1) <= xp {
            level += 1
        }
        return level
    }

    static func progress(forXP xp: Int) -> Progress {
        let level = level(forXP: xp)
        let reached = cumulativeXP(forLevel: level)
        let nextLevel = cumulativeXP(forLevel: level + 1)

        return Progress(
            level: level,
            xpIntoLevel: xp - reached,
            xpNeededForNextLevel: nextLevel - reached
        )
    }

    struct Progress: Equatable {
        let level: Int
        let xpIntoLevel: Int
        let xpNeededForNextLevel: Int

        var fraction: Double {
            guard xpNeededForNextLevel > 0 else { return 0 }
            return Double(xpIntoLevel) / Double(xpNeededForNextLevel)
        }
    }
}
