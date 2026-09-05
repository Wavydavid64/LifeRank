import Testing
@testable import LifeRank

struct SkillRankRequirementsTests {

    @Test func skillsStartAtFWithNoRequirement() {
        #expect(SkillRankRequirements.xpRequired(for: .f) == nil)
    }

    /// DESIGN.md §25's worked example shows a skill at "340 / 500 XP" toward E.
    @Test func firstSkillRankMatchesSpecExample() {
        #expect(SkillRankRequirements.xpRequired(for: .e) == 500)
    }

    @Test func everyRankAboveStartHasARisingThreshold() {
        let thresholds = [Rank.e, .d, .c, .b, .a, .s].compactMap(SkillRankRequirements.xpRequired(for:))

        #expect(thresholds.count == 6)
        #expect(zip(thresholds, thresholds.dropFirst()).allSatisfy { $0 < $1 })
    }

    /// A single skill must rank up faster than the whole character, otherwise
    /// §15's "N skills at this rank" gates could never be met.
    @Test func skillThresholdsSitBelowOverallThresholds() {
        for rank in Rank.allCases {
            guard let skillXP = SkillRankRequirements.xpRequired(for: rank),
                  let overallXP = RankRequirements.overallXP(for: rank) else { continue }

            #expect(skillXP < overallXP, "\(rank.displayName) skill threshold is not below the overall one")
        }
    }

    /// The balance constraint that ties the two tables together: §15 requires a
    /// number of skills at a rank before the character reaches it, and skill XP
    /// is drawn from the same pool as overall XP. If N skills at their threshold
    /// cost more than the rank's entire XP budget, that promotion is unreachable.
    @Test func skillRequirementsFitInsideTheirRankXPBudget() {
        // (rank, skills required at that rank) from DESIGN.md §15.
        let required: [(Rank, Int)] = [(.e, 2), (.d, 3), (.c, 3), (.b, 2), (.a, 2), (.s, 1)]

        for (rank, skillCount) in required {
            guard let skillXP = SkillRankRequirements.xpRequired(for: rank),
                  let overallXP = RankRequirements.overallXP(for: rank) else {
                Issue.record("\(rank.displayName) is missing a threshold")
                continue
            }

            #expect(
                skillCount * skillXP <= overallXP,
                "\(rank.displayName) needs \(skillCount) skills at \(skillXP) XP = \(skillCount * skillXP), but the rank only budgets \(overallXP)"
            )
        }
    }
}
