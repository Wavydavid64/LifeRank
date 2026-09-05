import Testing
@testable import LifeRank

struct SkillRankRequirementsTests {

    private var cheapestMultiplier: Double {
        SeedData.skills.map { SkillRankRequirements.multiplier(for: $0.id) }.min() ?? 1
    }

    @Test func skillsStartAtFWithNoRequirement() {
        for skill in SeedData.skills {
            #expect(SkillRankRequirements.xpRequired(for: .f, skillID: skill.id) == nil)
        }
    }

    /// DESIGN.md §25's worked example shows a skill at "340 / 500 XP" toward E.
    /// That is the baseline, before a skill's earning rate is applied.
    @Test func baselineFirstRankMatchesSpecExample() {
        #expect(SkillRankRequirements.baseXPRequired[.e] == 500)
        #expect(SkillRankRequirements.xpRequired(for: .e, skillID: "strength-training") == 500)
    }

    @Test func everyRankAboveStartHasARisingThreshold() {
        for skill in SeedData.skills {
            let thresholds = [Rank.e, .d, .c, .b, .a, .s]
                .compactMap { SkillRankRequirements.xpRequired(for: $0, skillID: skill.id) }

            #expect(thresholds.count == 6, "\(skill.name) is missing a threshold")
            #expect(
                zip(thresholds, thresholds.dropFirst()).allSatisfy { $0 < $1 },
                "\(skill.name) thresholds do not rise"
            )
        }
    }

    // MARK: - Earning-rate scaling

    @Test func everySeededSkillHasAnEffortMultiplier() {
        for skill in SeedData.skills {
            #expect(
                SkillRankRequirements.effortMultiplier[skill.id] != nil,
                "\(skill.name) has no multiplier and silently falls back to 1.0"
            )
        }
        #expect(SkillRankRequirements.effortMultiplier.count == SeedData.skills.count)
    }

    /// The point of the scaling: a skill whose sessions are short and carry no
    /// distance must not demand the same XP as one that earns three times as
    /// fast per hour. Stretching should rank up on less XP than lifting, and
    /// lifting on less than cycling.
    @Test func lowEarningSkillsNeedLessXPThanHighEarningOnes() {
        for rank in [Rank.e, .d, .c, .b, .a, .s] {
            let stretching = SkillRankRequirements.xpRequired(for: rank, skillID: "stretching")!
            let strength = SkillRankRequirements.xpRequired(for: rank, skillID: "strength-training")!
            let cycling = SkillRankRequirements.xpRequired(for: rank, skillID: "cycling")!

            #expect(stretching < strength, "\(rank.displayName): stretching is not cheaper than lifting")
            #expect(strength < cycling, "\(rank.displayName): lifting is not cheaper than cycling")
        }
    }

    /// Scaling corrects for earning rate; it must not become a way to trivialize
    /// or gate off a skill entirely.
    @Test func multipliersStayWithinASensibleBand() {
        for skill in SeedData.skills {
            let multiplier = SkillRankRequirements.multiplier(for: skill.id)
            #expect(multiplier >= 0.25, "\(skill.name) at \(multiplier) is close to free")
            #expect(multiplier <= 2.5, "\(skill.name) at \(multiplier) is punishing")
        }
    }

    @Test func anUnknownSkillFallsBackToTheBaseline() {
        #expect(SkillRankRequirements.multiplier(for: "not-a-skill") == 1.0)
        #expect(SkillRankRequirements.xpRequired(for: .e, skillID: "not-a-skill") == 500)
    }

    // MARK: - Coupling with the overall rank table

    /// A single skill must rank up faster than the whole character, otherwise
    /// §15's "N skills at this rank" gates could never be met.
    @Test func skillThresholdsSitBelowOverallThresholds() {
        for rank in Rank.allCases {
            guard let overallXP = RankRequirements.overallXP(for: rank) else { continue }

            for skill in SeedData.skills {
                let skillXP = SkillRankRequirements.xpRequired(for: rank, skillID: skill.id)!
                #expect(
                    skillXP < overallXP,
                    "\(skill.name) at \(rank.displayName) needs \(skillXP), no less than the overall \(overallXP)"
                )
            }
        }
    }

    /// The balance constraint tying the two tables together: §15 requires a
    /// number of skills at a rank before the character reaches it, and skill XP
    /// is drawn from the same pool as overall XP.
    ///
    /// Measured against the *cheapest* skills, since those are the ones a player
    /// would use to satisfy the requirement. If even those cost more than the
    /// rank's entire XP budget, that promotion is unreachable.
    @Test func skillRequirementsFitInsideTheirRankXPBudget() {
        // (rank, skills required at that rank) from DESIGN.md §15.
        let required: [(Rank, Int)] = [(.e, 2), (.d, 3), (.c, 3), (.b, 2), (.a, 2), (.s, 1)]

        for (rank, skillCount) in required {
            guard let base = SkillRankRequirements.baseXPRequired[rank],
                  let overallXP = RankRequirements.overallXP(for: rank) else {
                Issue.record("\(rank.displayName) is missing a threshold")
                continue
            }

            let cheapest = Int((Double(base) * cheapestMultiplier).rounded())

            #expect(
                skillCount * cheapest <= overallXP,
                "\(rank.displayName) needs \(skillCount) skills at \(cheapest) XP = \(skillCount * cheapest), but the rank only budgets \(overallXP)"
            )
        }
    }
}
