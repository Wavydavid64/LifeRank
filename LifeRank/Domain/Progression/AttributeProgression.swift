import Foundation

/// Turns accumulated attribute XP into a level. Levels get progressively more
/// expensive (DESIGN.md §5): reaching level n costs `baseLevelCost * n`, so the
/// first level costs 25 XP, the second 50 more, the third 75 more.
nonisolated enum AttributeProgression {

    /// Balance constant (§34). Tuned so a year of steady training on a primary
    /// attribute (~8,400 XP) lands near level 25, matching the numeric range in
    /// §23's dashboard. Levels then decelerate: ~3 after a week, ~12 after three
    /// months, ~18 after six. Rebalancing is free — levels are derived from the
    /// XP ledger, so changing this recomputes history rather than migrating it.
    static let baseLevelCost = 25

    /// Total XP that must be accumulated to stand at `level`.
    static func cumulativeXP(forLevel level: Int) -> Int {
        guard level > 0 else { return 0 }
        return baseLevelCost * level * (level + 1) / 2
    }

    /// ponytail: counts up one level at a time — O(√xp), so ~20 iterations at
    /// realistic XP but ~28,000 at a billion. Kept because it is obviously
    /// correct and matches `cumulativeXP` by construction. The closed form
    /// `floor((-1 + sqrt(1 + 8·xp/base)) / 2)` replaces it if that ever matters.
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
