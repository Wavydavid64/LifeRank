import Foundation

/// XP thresholds for individual skill ranks (DESIGN.md §7). Skills use the same
/// F–S vocabulary as the character, so a player can be advanced overall while
/// still a beginner in a freshly started skill.
///
/// XP alone never grants a skill rank — §13 requires a demonstrated challenge as
/// well. These thresholds only describe the XP half of that gate.
nonisolated enum SkillRankRequirements {

    /// Baseline thresholds, for a skill of average earning rate. The F→E figure
    /// of 500 comes from §25's worked example ("340 / 500 XP").
    ///
    /// Deliberately lower than the overall-rank table: §15 asks for several
    /// skills at a rank before the character reaches it, so N skills at a
    /// threshold must stay affordable within that rank's overall XP budget.
    static let baseXPRequired: [Rank: Int] = [
        .e: 500,
        .d: 1_000,
        .c: 3_000,
        .b: 8_000,
        .a: 20_000,
        .s: 50_000,
    ]

    /// Scales the baseline to how fast a skill actually earns XP.
    ///
    /// XP is minutes plus a distance bonus, so an hour of cycling pays roughly
    /// three times an hour of stretching — and stretching sessions are
    /// naturally a quarter the length of a gym session. Against one shared
    /// table that makes a stretching rank several times harder to reach than a
    /// lifting one for the same commitment, which is not what a rank should
    /// mean.
    ///
    /// Each value is the skill's expected weekly XP relative to strength
    /// training. The effect is that every skill reaches a rank after roughly
    /// the same number of weeks of characteristic practice: rank measures
    /// sustained practice, not accumulated minutes.
    ///
    /// Estimates, not measurements. Tune against real logged data — skill ranks
    /// derive from the ledger, so changes apply retroactively.
    static let effortMultiplier: [Skill.ID: Double] = [
        "cycling": 1.90,             // distance bonus dominates
        "running": 1.30,
        "hiking": 1.25,
        "strength-training": 1.00,   // the reference
        "reading": 0.75,
        "painting": 0.65,
        "kayaking": 0.60,
        "stretching": 0.60,          // short daily sessions
        "yoga": 0.50,
        "music-practice": 0.50,
        "chinese-calligraphy": 0.50,
        "western-calligraphy": 0.50,
    ]

    static func multiplier(for skillID: Skill.ID) -> Double {
        effortMultiplier[skillID] ?? 1.0
    }

    /// Nil for the starting rank, which every skill begins at.
    static func xpRequired(for rank: Rank, skillID: Skill.ID) -> Int? {
        guard let base = baseXPRequired[rank] else { return nil }
        return Int((Double(base) * multiplier(for: skillID)).rounded())
    }
}
