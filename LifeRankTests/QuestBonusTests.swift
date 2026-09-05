import Testing
import Foundation
import SwiftData
@testable import LifeRank

@MainActor
struct QuestBonusTests {

    private func makeStore() throws -> ActivityStore {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ActivityStore(context: ModelContext(container))
    }

    private func skill(_ id: Skill.ID) -> Skill {
        SeedData.skills.first { $0.id == id }!
    }

    /// A 30 minute calligraphy session completes the daily quest, so it earns
    /// its 30 XP plus the quest's 5 XP bonus.
    @Test func completingAQuestAwardsItsBonus() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30),
            skill: calligraphy
        )

        #expect(try store.stats().skillXP["chinese-calligraphy"] == 35)
    }

    @Test func fallingShortOfTheTargetAwardsNoBonus() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 20),
            skill: calligraphy
        )

        #expect(try store.stats().skillXP["chinese-calligraphy"] == 20)
    }

    /// The bonus is paid by the session that crosses the target, and only that
    /// one — later sessions in the same window earn their own XP and no more.
    @Test func bonusIsPaidOncePerWindow() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        for _ in 0..<3 {
            try store.log(
                Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30),
                skill: calligraphy
            )
        }

        // 90 XP earned across three sessions, 5 XP bonus paid once.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 95)
    }

    @Test func bonusIsPaidByTheSessionThatCrossesTheTarget() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: "Warm up", durationMinutes: 20),
            skill: calligraphy
        )
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 20)

        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 15),
            skill: calligraphy
        )
        // 35 earned, plus the 5 bonus for crossing 30 minutes.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 40)
    }

    /// Bonus XP is distributed like any other skill XP, so attribute totals
    /// stay a faithful redistribution rather than drifting below skill XP.
    @Test func bonusXPDistributesToAttributes() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30),
            skill: calligraphy
        )

        let stats = try store.stats()
        #expect(stats.attributeXP.values.reduce(0, +) == stats.skillXP["chinese-calligraphy"])
        #expect(stats.totalXP == 35)
    }

    @Test func aQuestForAnotherSkillPaysNothing() throws {
        let store = try makeStore()
        let running = skill("running")

        // Well past the calligraphy quest's 30 minute target, wrong skill.
        try store.log(
            Activity(skillID: running.id, name: "Long run", durationMinutes: 60),
            skill: running
        )

        #expect(try store.stats().skillXP["chinese-calligraphy"] == nil)
        #expect(try store.stats().skillXP["running"] == 60)
    }

    /// Imported workouts go through the same log path, so they pay quest
    /// bonuses too — a hike imported from Health completes "first hike".
    @Test func importedWorkoutsAlsoCompleteQuests() throws {
        let store = try makeStore()

        try ActivityImporter(store: store).import([
            ImportedActivity(
                id: "HK-hike",
                skillID: "hiking",
                name: "Hiking",
                startDate: .now,
                durationMinutes: 120,
                distanceMiles: 4
            )
        ])

        // 120 min + 4 mi * 7.5 = 150 earned, plus the 20 XP one-time bonus.
        #expect(try store.stats().skillXP["hiking"] == 170)
    }

    @Test func seededBonusesStaySmallRelativeToTheActivity() throws {
        // §16: bonus XP must not overwhelm the XP earned by doing the activity.
        for quest in QuestSeed.quests {
            #expect(quest.bonusXP >= 0, "\(quest.id) has a negative bonus")
            #expect(quest.bonusXP <= 30, "\(quest.id) bonus of \(quest.bonusXP) is too large")
        }
    }
}
