import Testing
import Foundation
import SwiftData
@testable import LifeRank

struct SkillProgressionTests {

    private func running() -> Skill {
        SeedData.skills.first { $0.id == "running" }!
    }

    private func calligraphy() -> Skill {
        SeedData.skills.first { $0.id == "chinese-calligraphy" }!
    }

    private func rank(
        _ skill: Skill,
        xp: Int,
        activities: [Activity] = [],
        completions: Set<String> = []
    ) -> Rank {
        SkillProgression.rank(
            for: skill,
            xp: xp,
            challenges: ChallengeSeed.challenges,
            activities: activities,
            manualCompletions: completions
        )
    }

    private func fiveK(minutes: Double) -> Activity {
        Activity(skillID: "running", name: "5K", durationMinutes: minutes, distanceMiles: 3.2)
    }

    /// Thresholds are scaled per skill by earning rate, so these read the real
    /// requirement rather than hardcoding a number that retuning would break.
    /// The values themselves are pinned in `SkillRankRequirementsTests`.
    private func xpFor(_ rank: Rank, _ skillID: Skill.ID = "running") -> Int {
        SkillRankRequirements.xpRequired(for: rank, skillID: skillID)!
    }

    // MARK: - XP alone is never enough (§13)

    @Test func xpWithoutTheChallengeLeavesTheSkillAtF() {
        #expect(rank(running(), xp: 100_000) == .f)
    }

    @Test func challengeWithoutTheXPLeavesTheSkillAtF() {
        #expect(rank(running(), xp: 0, activities: [fiveK(minutes: 26)]) == .f)
    }

    @Test func xpPlusChallengeAdvancesOneRank() {
        #expect(rank(running(), xp: xpFor(.e), activities: [fiveK(minutes: 26)]) == .e)
    }

    @Test func oneXPShortOfTheThresholdDoesNotAdvance() {
        #expect(rank(running(), xp: xpFor(.e) - 1, activities: [fiveK(minutes: 26)]) == .f)
    }

    // MARK: - Walking the ladder

    /// A sub-30 5K clears both the E and D challenges, so with enough XP the
    /// skill climbs two ranks at once — but stops at C, whose challenge needs
    /// sub-25.
    @Test func rankStopsAtTheFirstUnclearedChallenge() {
        // Enough XP for C, so the sub-25 challenge is what actually blocks it.
        #expect(rank(running(), xp: xpFor(.c), activities: [fiveK(minutes: 26)]) == .d)
    }

    @Test func aFasterTimeClearsTheNextChallengeToo() {
        #expect(rank(running(), xp: xpFor(.c), activities: [fiveK(minutes: 24)]) == .c)
    }

    /// Stretching earns far less per session than lifting, so its thresholds
    /// are scaled down — the same weeks of practice should reach the same rank.
    @Test func aLowEarningSkillRanksUpOnLessXP() {
        let stretchingE = xpFor(.e, "stretching")
        let strengthE = xpFor(.e, "strength-training")

        #expect(stretchingE < strengthE)

        // stretch-e is measured, not manual: a 15 minute session clears it.
        let stretching = SeedData.skills.first { $0.id == "stretching" }!
        let session = Activity(skillID: "stretching", name: "Stretch", durationMinutes: 20)

        #expect(
            rank(stretching, xp: stretchingE, activities: [session]) == .e,
            "stretching should reach E at its own scaled threshold"
        )
        #expect(
            rank(stretching, xp: stretchingE, activities: []) == .f,
            "and still not without clearing the challenge"
        )
    }

    /// Ranks are consecutive: clearing a later challenge cannot skip an earlier
    /// one that is still outstanding.
    @Test func rankCannotSkipAnUnclearedLowerRank() {
        // A marathon clears the A challenge, but E's continuous 5K is the gate
        // and this activity satisfies it too, so the ladder is walked in order.
        let marathon = Activity(skillID: "running", name: "Marathon", durationMinutes: 230, distanceMiles: 26.3)

        // Plenty of XP, but D needs a sub-30 5K which 230 minutes is not.
        #expect(rank(running(), xp: 50_000, activities: [marathon]) == .e)
    }

    // MARK: - Manual challenges

    @Test func manualChallengeNeedsExplicitCompletion() {
        #expect(rank(calligraphy(), xp: 500) == .f)
        #expect(rank(calligraphy(), xp: 500, completions: ["chinese-calligraphy-e"]) == .e)
    }

    @Test func anotherSkillsCompletionDoesNotCount() {
        #expect(rank(calligraphy(), xp: 500, completions: ["western-calligraphy-e"]) == .f)
    }

    // MARK: - Seed integrity

    @Test func everySkillHasAChallengeForEveryRank() {
        for skill in SeedData.skills {
            for rank in Rank.allCases where rank != .starting {
                let challenge = ChallengeSeed.challenges.first { $0.skillID == skill.id && $0.rank == rank }
                #expect(challenge != nil, "\(skill.name) has no challenge for \(rank.displayName)")
            }
        }
    }

    @Test func challengeAndTrialObjectiveIDsAreUnique() {
        let ids = ChallengeSeed.challenges.map(\.objective.id) + TrialSeed.trials.flatMap { $0.objectives.map(\.id) }
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyChallengeTargetsAKnownSkill() {
        for challenge in ChallengeSeed.challenges {
            #expect(SeedData.skills.contains { $0.id == challenge.skillID })
        }
    }
}

@MainActor
struct PromotionStoreTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            CharacterRecord.self, ObjectiveCompletionRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func charactersStartAtFAndPersist() throws {
        let store = CharacterStore(context: try makeContext())

        #expect(try store.rank() == .f)
        // Second call must reuse the existing record, not create another.
        #expect(try store.rank() == .f)
    }

    @Test func manualCompletionsToggleAndPersist() throws {
        let store = CharacterStore(context: try makeContext())

        try store.setCompleted(true, objectiveID: "trial-e-craft")
        #expect(try store.manualCompletions() == ["trial-e-craft"])

        // Marking it again must not duplicate the record.
        try store.setCompleted(true, objectiveID: "trial-e-craft")
        #expect(try store.manualCompletions().count == 1)

        try store.setCompleted(false, objectiveID: "trial-e-craft")
        #expect(try store.manualCompletions().isEmpty)
    }

    /// §3.4: the store refuses to move rank unless every gate is cleared, so
    /// no code path can quietly promote the player.
    @Test func promotionIsRefusedWhenNotEligible() throws {
        let store = CharacterStore(context: try makeContext())

        let ineligible = PromotionEngine.status(
            currentRank: .f,
            stats: CharacterStats(skillXP: ["running": 1_000_000], attributeXP: [.endurance: 1_000_000]),
            skillRanks: [:],
            activities: [],
            trials: TrialSeed.trials,
            manualCompletions: []
        )

        #expect(try store.promote(using: ineligible) == false)
        #expect(try store.rank() == .f)
    }

    @Test func promotionMovesRankExactlyOneStep() throws {
        let store = CharacterStore(context: try makeContext())

        let eligible = PromotionEngine.status(
            currentRank: .f,
            stats: CharacterStats(
                skillXP: ["running": 600, "chinese-calligraphy": 400],
                attributeXP: [.endurance: 400, .discipline: 300, .dexterity: 200, .creativity: 100]
            ),
            skillRanks: ["running": .e, "chinese-calligraphy": .e],
            activities: [Activity(skillID: "running", name: "Run", durationMinutes: 25, distanceMiles: 2.5)],
            trials: TrialSeed.trials,
            manualCompletions: ["trial-e-craft"]
        )

        #expect(eligible.canPromote)
        #expect(try store.promote(using: eligible) == true)
        #expect(try store.rank() == .e)
    }
}
