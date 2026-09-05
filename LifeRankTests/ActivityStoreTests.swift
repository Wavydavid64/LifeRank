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
    @Test func loggingCalligraphyPersistsSkillAndAttributeXP() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: calligraphy.name, durationMinutes: 30),
            skill: calligraphy
        )

        let stats = try store.stats()
        #expect(stats.skillXP["chinese-calligraphy"] == 30)
        #expect(stats.attributeXP[.dexterity] == 17)
        #expect(stats.attributeXP[.creativity] == 9)
        #expect(stats.attributeXP[.discipline] == 4)
        #expect(stats.totalXP == 30)
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

        let attributeTotal = try store.stats().attributeXP.values.reduce(0, +)
        #expect(attributeTotal == 30)
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

        #expect(try store.stats().skillXP["chinese-calligraphy"] == 60)
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

        let events = try store.xpEvents()
        #expect(events.count == 4)
        #expect(events.allSatisfy { $0.activityID == activity.id })
    }
}
