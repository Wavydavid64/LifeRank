import Foundation

/// Overall XP thresholds per rank, kept as configuration rather than scattered
/// through UI code (DESIGN.md §4, §15). Placeholder balance values.
///
/// XP is only one of the promotion gates. Skill ranks, attribute levels and a
/// promotion trial are also required, and reaching a threshold never promotes
/// the player on its own (§3.4) — those gates arrive with the trials system.
enum RankRequirements {

    static let overallXP: [Rank: Int] = [
        .e: 1_000,
        .d: 5_000,
        .c: 15_000,
        .b: 40_000,
        .a: 100_000,
        .s: 250_000,
    ]

    /// Nil for the starting rank, which has no entry requirement.
    static func overallXP(for rank: Rank) -> Int? {
        overallXP[rank]
    }
}
