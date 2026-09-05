import Testing
import Foundation
@testable import LifeRank

struct PromotionEngineTests {

    /// Everything E-rank asks for, so individual tests can knock out one clause
    /// at a time and check that clause alone blocks promotion.
    private func eligibleInputs() -> (
        stats: CharacterStats,
        skillRanks: [Skill.ID: Rank],
        activities: [Activity],
        completions: Set<String>
    ) {
        // 4 attributes at level 2 (75 XP each), skill XP summing to 1,000.
        let stats = CharacterStats(
            skillXP: ["running": 600, "chinese-calligraphy": 400],
            attributeXP: [.endurance: 400, .discipline: 300, .dexterity: 200, .creativity: 100]
        )

        let activities = [
            Activity(skillID: "running", name: "Run", durationMinutes: 25, distanceMiles: 2.5)
        ]

        return (
            stats: stats,
            skillRanks: ["running": .e, "chinese-calligraphy": .e],
            activities: activities,
            completions: ["trial-e-craft"]
        )
    }

    private func status(
        stats: CharacterStats? = nil,
        skillRanks: [Skill.ID: Rank]? = nil,
        activities: [Activity]? = nil,
        completions: Set<String>? = nil,
        currentRank: Rank = .f
    ) -> PromotionStatus {
        let base = eligibleInputs()
        return PromotionEngine.status(
            currentRank: currentRank,
            stats: stats ?? base.stats,
            skillRanks: skillRanks ?? base.skillRanks,
            activities: activities ?? base.activities,
            trials: TrialSeed.trials,
            manualCompletions: completions ?? base.completions
        )
    }

    // MARK: - The full gate (§15)

    @Test func meetingEverythingMakesPromotionAvailable() {
        let result = status()

        #expect(result.xp.isMet)
        #expect(result.skills.isMet)
        #expect(result.attributes.isMet)
        #expect(result.trialUnlocked)
        #expect(result.trialComplete)
        #expect(result.canPromote)
    }

    /// §35 and §3.4: reaching an XP threshold is not enough on its own.
    @Test func xpAloneDoesNotAllowPromotion() {
        let result = status(
            stats: CharacterStats(skillXP: ["running": 100_000], attributeXP: [.endurance: 100_000]),
            skillRanks: [:],
            activities: [],
            completions: []
        )

        #expect(result.xp.isMet)
        #expect(!result.skills.isMet)
        #expect(!result.canPromote)
    }

    @Test func missingXPBlocksPromotion() {
        let base = eligibleInputs()
        let result = status(
            stats: CharacterStats(skillXP: ["running": 10], attributeXP: base.stats.attributeXP)
        )

        #expect(!result.xp.isMet)
        #expect(!result.progressionMet)
        #expect(!result.canPromote)
    }

    @Test func missingSkillRanksBlockPromotion() {
        let result = status(skillRanks: ["running": .e])

        #expect(result.skills == RequirementProgress(current: 1, required: 2))
        #expect(!result.canPromote)
    }

    @Test func missingAttributeLevelsBlockPromotion() {
        let base = eligibleInputs()
        let result = status(
            stats: CharacterStats(skillXP: base.stats.skillXP, attributeXP: [.endurance: 1_000])
        )

        #expect(!result.attributes.isMet)
        #expect(!result.canPromote)
    }

    @Test func incompleteTrialBlocksPromotion() {
        let result = status(completions: [])

        #expect(result.progressionMet)
        #expect(result.trialUnlocked)
        #expect(!result.trialComplete)
        #expect(!result.canPromote)
    }

    // MARK: - Trial locking (§27)

    @Test func trialStaysLockedUntilProgressionIsComplete() {
        let result = status(
            stats: CharacterStats(skillXP: ["running": 10], attributeXP: [:]),
            skillRanks: [:],
            activities: [],
            completions: []
        )

        #expect(!result.trialUnlocked)
    }

    /// Trial objectives tick from logged activities, not only by hand.
    @Test func measuredTrialObjectivesCompleteFromActivity() {
        let withoutRun = status(activities: [])
        let withRun = status()

        let runObjective = { (s: PromotionStatus) in
            s.trial.first { $0.objective.id == "trial-e-run" }?.isComplete
        }

        #expect(runObjective(withoutRun) == false)
        #expect(runObjective(withRun) == true)
    }

    // MARK: - Top of the ladder

    @Test func sRankHasNothingLeftToPromoteTo() {
        let result = status(currentRank: .s)

        #expect(result.nextRank == nil)
        #expect(!result.canPromote)
        #expect(result.trial.isEmpty)
    }

    // MARK: - Balance feasibility

    /// The attribute clause must fit inside the rank's XP budget. Attribute XP
    /// is a redistribution of overall XP, so N attributes at a level cannot
    /// cost more than the rank's total XP requirement or the published XP
    /// threshold becomes meaningless. This is what rules out §15's original
    /// 10/20/30/40/50/60 minimums.
    @Test func attributeRequirementsFitTheirRankXPBudget() {
        for rank in Rank.allCases {
            guard let definition = RankRequirements.definition(for: rank) else { continue }

            let cost = definition.requiredAttributeCount
                * AttributeProgression.cumulativeXP(forLevel: definition.minimumAttributeLevel)

            #expect(
                cost <= definition.xpRequired,
                "\(rank.displayName) needs \(definition.requiredAttributeCount) attributes at level \(definition.minimumAttributeLevel) = \(cost) XP, but only budgets \(definition.xpRequired)"
            )
        }
    }

    @Test func everyRankAboveStartHasADefinitionAndATrial() {
        for rank in Rank.allCases where rank != .starting {
            #expect(RankRequirements.definition(for: rank) != nil, "\(rank.displayName) has no definition")
            #expect(TrialSeed.trials.contains { $0.rank == rank }, "\(rank.displayName) has no trial")
        }
    }

    @Test func requirementsGrowWithRank() {
        let definitions = Rank.allCases.compactMap(RankRequirements.definition(for:))

        #expect(definitions.count == 6)
        #expect(zip(definitions, definitions.dropFirst()).allSatisfy { $0.xpRequired < $1.xpRequired })
        #expect(zip(definitions, definitions.dropFirst()).allSatisfy { $0.minimumAttributeLevel < $1.minimumAttributeLevel })
    }
}
