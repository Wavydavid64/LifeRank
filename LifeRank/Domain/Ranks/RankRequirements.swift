import Foundation

/// Everything that must be true before a rank can be entered (DESIGN.md §15).
/// Meeting all of it makes the player *eligible*; it never promotes them (§3.4).
nonisolated struct RankDefinition: Hashable {
    let rank: Rank
    let xpRequired: Int
    let requiredSkillRank: Rank
    let requiredSkillCount: Int
    let minimumAttributeLevel: Int
    let requiredAttributeCount: Int
}

/// Rank configuration, kept out of UI code (§4, §15). Placeholder balance.
nonisolated enum RankRequirements {

    /// Attribute minimums deliberately depart from §15's 10/20/30/40/50/60.
    ///
    /// Those figures predate the level curve and are unreachable against it:
    /// level 10 costs 1,375 attribute XP, so E's "4 attributes ≥ 10" needs
    /// 5,500 XP against an XP gate of 1,000 — the attribute clause would
    /// silently become the real gate at every rank and the published XP
    /// thresholds would mean nothing.
    ///
    /// These are the levels a player actually holds at each XP threshold, given
    /// XP spreads unevenly across eight attributes.
    /// `attributeRequirementsFitTheirRankXPBudget` enforces that.
    static let definitions: [Rank: RankDefinition] = [
        .e: RankDefinition(rank: .e, xpRequired: 1_000, requiredSkillRank: .e,
                           requiredSkillCount: 2, minimumAttributeLevel: 2, requiredAttributeCount: 4),
        .d: RankDefinition(rank: .d, xpRequired: 5_000, requiredSkillRank: .d,
                           requiredSkillCount: 3, minimumAttributeLevel: 5, requiredAttributeCount: 5),
        .c: RankDefinition(rank: .c, xpRequired: 15_000, requiredSkillRank: .c,
                           requiredSkillCount: 3, minimumAttributeLevel: 8, requiredAttributeCount: 6),
        .b: RankDefinition(rank: .b, xpRequired: 40_000, requiredSkillRank: .b,
                           requiredSkillCount: 2, minimumAttributeLevel: 13, requiredAttributeCount: 6),
        .a: RankDefinition(rank: .a, xpRequired: 100_000, requiredSkillRank: .a,
                           requiredSkillCount: 2, minimumAttributeLevel: 18, requiredAttributeCount: 7),
        .s: RankDefinition(rank: .s, xpRequired: 250_000, requiredSkillRank: .s,
                           requiredSkillCount: 1, minimumAttributeLevel: 20, requiredAttributeCount: 8),
    ]

    static func definition(for rank: Rank) -> RankDefinition? {
        definitions[rank]
    }

    /// Nil for the starting rank, which has no entry requirement.
    static func overallXP(for rank: Rank) -> Int? {
        definitions[rank]?.xpRequired
    }

    /// The attribute level a rank's chart is scaled to — roughly where a
    /// primary attribute lands by the time that rank is cleared, with headroom.
    /// Attributes grow inside the band during a rank, and promotion widens the
    /// band, so progression stays visible instead of self-normalizing away.
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
