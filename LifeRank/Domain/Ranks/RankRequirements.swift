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

    /// The attribute level a rank's chart is scaled to — roughly where a
    /// primary attribute lands by the time that rank is cleared, with headroom.
    /// Attributes grow inside the band during a rank, and promotion widens the
    /// band, so progression stays visible instead of self-normalising away.
    ///
    /// Every rank must have a value: a missing one would collapse the scale.
    static func attributeCeiling(for rank: Rank) -> Int {
        switch rank {
        case .f: return 8
        case .e: return 15
        case .d: return 25
        case .c: return 40
        case .b: return 60
        case .a: return 90
        case .s: return 120
        }
    }
}
