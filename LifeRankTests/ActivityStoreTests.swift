import Testing
import Foundation
import SwiftData
@testable import LifeRank

@MainActor
struct ActivityStoreTests {

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

    /// DESIGN.md §43, the workflow Stage 2 exists to prove: logging 30 minutes
    /// of Chinese Calligraphy raises the skill and its three attributes.
    ///
    /// 30 minutes also completes the daily calligraphy quest, so the total is
    /// 30 earned plus its 5 XP bonus. The two awards are distributed separately
    /// (17/9/4 then 3/1/1), which is why the attributes land on 20/10/5.
    @Test func loggingCalligraphyPersistsSkillAndAttributeXP() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: calligraphy.name, durationMinutes: 30),
            skill: calligraphy
        )

        let stats = try store.stats()
        #expect(stats.skillXP["chinese-calligraphy"] == 35)
        #expect(stats.attributeXP[.dexterity] == 20)
        #expect(stats.attributeXP[.creativity] == 10)
        #expect(stats.attributeXP[.discipline] == 5)
        #expect(stats.totalXP == 35)
    }

    /// Attribute XP must survive the round trip through SwiftData without loss —
    /// 17 + 9 + 4 still equals the 30 skill XP that was awarded (§12).
    @Test func persistedAttributeXPStillSumsToSkillXP() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: calligraphy.name, durationMinutes: 30),
            skill: calligraphy
        )

        let stats = try store.stats()
        let attributeTotal = stats.attributeXP.values.reduce(0, +)
        #expect(attributeTotal == stats.skillXP["chinese-calligraphy"])
    }

    @Test func loggingTwoActivitiesAccumulates() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        for _ in 0..<2 {
            try store.log(
                Activity(skillID: calligraphy.id, name: calligraphy.name, durationMinutes: 30),
                skill: calligraphy
            )
        }

        // 60 earned across the two sessions, plus the daily quest's 5 XP bonus,
        // paid once by the session that crossed 30 minutes.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 65)
    }

    /// XPTarget is an enum with associated values; this pins that it round-trips
    /// through SwiftData intact rather than collapsing to a single case.
    @Test func xpTargetSurvivesPersistence() throws {
        let store = try makeStore()
        let running = skill("running")

        try store.log(
            Activity(skillID: running.id, name: "Morning Run", durationMinutes: 42, distanceMiles: 5.1),
            skill: running
        )

        let events = try store.xpEvents()
        #expect(events.first { $0.target == .skill("running") }?.amount == 80)
        #expect(events.first { $0.target == .attribute(.endurance) }?.amount == 56)
        #expect(events.first { $0.target == .attribute(.discipline) }?.amount == 16)
        #expect(events.first { $0.target == .attribute(.exploration) }?.amount == 8)
    }

    @Test func everyXPEventIsKeyedToItsActivity() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let activity = Activity(skillID: calligraphy.id, name: calligraphy.name, durationMinutes: 30)

        try store.log(activity, skill: calligraphy)

        // Four for the session itself, four more for the quest bonus it
        // triggered — all of them keyed to the activity that earned them, so
        // removing it would reverse the whole lot (§26).
        let events = try store.xpEvents()
        #expect(events.count == 8)
        #expect(events.allSatisfy { $0.activityID == activity.id })
    }
}
