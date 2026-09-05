import Foundation

/// XP thresholds for individual skill ranks (DESIGN.md §7). Skills use the same
/// F–S vocabulary as the character, so a player can be advanced overall while
/// still a beginner in a freshly started skill.
///
/// XP alone never grants a skill rank — §13 requires a demonstrated challenge as
/// well. These thresholds only describe the XP half of that gate.
enum SkillRankRequirements {

    /// Placeholder balance values. The F→E figure of 500 comes from §25's
    /// worked example ("340 / 500 XP").
    ///
    /// Deliberately lower than the overall-rank table: §15 asks for several
    /// skills at a rank before the character reaches it, so N skills at a
    /// threshold must stay affordable within that rank's overall XP budget.
    static let xpRequired: [Rank: Int] = [
        .e: 500,
        .d: 1_000,
        .c: 3_000,
        .b: 8_000,
        .a: 20_000,
        .s: 50_000,
    ]

    /// Nil for the starting rank, which every skill begins at.
    static func xpRequired(for rank: Rank) -> Int? {
        xpRequired[rank]
    }
}
