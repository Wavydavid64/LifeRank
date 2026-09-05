import Foundation

/// A milestone that must be demonstrated before a skill reaches `rank`
/// (DESIGN.md §13).
nonisolated struct SkillChallenge: Identifiable, Codable, Hashable {
    let skillID: Skill.ID
    /// The rank this challenge unlocks.
    let rank: Rank
    let objective: Objective

    var id: String { objective.id }
}

/// Works out where a skill actually stands. XP alone never advances a skill
/// rank — the rank's challenge must be cleared too (§13).
nonisolated enum SkillProgression {

    static func rank(
        for skill: Skill,
        xp: Int,
        challenges: [SkillChallenge],
        activities: [Activity],
        manualCompletions: Set<String>
    ) -> Rank {
        var current = Rank.starting

        while let next = current.next {
            guard let requiredXP = SkillRankRequirements.xpRequired(for: next, skillID: skill.id),
                  xp >= requiredXP
            else { break }

            let challenge = challenges.first { $0.skillID == skill.id && $0.rank == next }
            // A rank with no challenge configured yet cannot be reached, so a
            // missing definition can never hand out a free promotion.
            guard let challenge,
                  ObjectiveEvaluator.isSatisfied(
                      challenge.objective,
                      activities: activities,
                      manualCompletions: manualCompletions
                  )
            else { break }

            current = next
        }

        return current
    }

    /// Current rank of every seeded skill.
    static func ranks(
        stats: CharacterStats,
        activities: [Activity],
        manualCompletions: Set<String>
    ) -> [Skill.ID: Rank] {
        Dictionary(uniqueKeysWithValues: SeedData.skills.map { skill in
            (
                skill.id,
                rank(
                    for: skill,
                    xp: stats.skillXP[skill.id] ?? 0,
                    challenges: ChallengeSeed.challenges,
                    activities: activities,
                    manualCompletions: manualCompletions
                )
            )
        })
    }

    /// The challenge standing between a skill and its next rank, if any.
    static func nextChallenge(
        for skill: Skill,
        currentRank: Rank,
        challenges: [SkillChallenge]
    ) -> SkillChallenge? {
        guard let next = currentRank.next else { return nil }
        return challenges.first { $0.skillID == skill.id && $0.rank == next }
    }
}
