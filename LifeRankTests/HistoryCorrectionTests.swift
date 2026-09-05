import Testing
import Foundation
import SwiftData
@testable import LifeRank

@MainActor
struct HistoryCorrectionTests {

    private func makeStore() throws -> ActivityStore {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            CharacterRecord.self, ObjectiveCompletionRecord.self, IgnoredWorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ActivityStore(context: ModelContext(container))
    }

    private func skill(_ id: Skill.ID) -> Skill {
        SeedData.skills.first { $0.id == id }!
    }

    private func run(minutes: Double = 42, miles: Double = 5.1, at date: Date = .now) -> Activity {
        Activity(skillID: "running", name: "Run", date: date, durationMinutes: minutes, distanceMiles: miles)
    }

    // MARK: - Deletion (§26, §35)

    @Test func deletingAnActivityRemovesAllOfItsXP() throws {
        let store = try makeStore()
        let activity = run()

        try store.log(activity, skill: skill("running"))
        #expect(try store.stats().totalXP == 80)

        try store.delete(activityID: activity.id)

        let stats = try store.stats()
        #expect(stats.totalXP == 0)
        #expect(stats.attributeXP.isEmpty)
        #expect(try store.xpEvents().isEmpty)
        #expect(try store.activities().isEmpty)
    }

    @Test func deletingOneActivityLeavesTheOthersIntact() throws {
        let store = try makeStore()
        let first = run(miles: 2)
        let second = run(miles: 2, at: .now.addingTimeInterval(60))

        try store.log(first, skill: skill("running"))
        try store.log(second, skill: skill("running"))
        try store.delete(activityID: first.id)

        // 42 min + 2 mi * 7.5 = 57 XP for the survivor.
        #expect(try store.stats().skillXP["running"] == 57)
        #expect(try store.activities().count == 1)
    }

    /// Quest bonuses are keyed to the activity that earned them, so deleting it
    /// takes the bonus with it rather than stranding unexplained XP (§10).
    @Test func deletingAnActivityAlsoRemovesItsQuestBonus() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let activity = Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30)

        try store.log(activity, skill: calligraphy)
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 35)

        try store.delete(activityID: activity.id)
        #expect(try store.stats().totalXP == 0)
    }

    // MARK: - Ignoring imported workouts (§26)

    /// Deleting an imported workout has to stick. Without a tombstone the next
    /// import would find the same workout and add it straight back.
    @Test func deletedImportsDoNotComeBackOnTheNextImport() throws {
        let store = try makeStore()
        let importer = ActivityImporter(store: store)
        let workout = ImportedActivity(
            id: "HK-1", skillID: "running", name: "Run",
            startDate: .now, durationMinutes: 42, distanceMiles: 5.1
        )

        try importer.import([workout])
        let imported = try #require(try store.activities().first)
        try store.delete(activityID: imported.id)

        let summary = try importer.import([workout])

        #expect(summary == .init(imported: 0, duplicates: 1, unclassified: 0))
        #expect(try store.activities().isEmpty)
        #expect(try store.stats().totalXP == 0)
    }

    @Test func deletingAManualActivityDoesNotTombstoneAnything() throws {
        let store = try makeStore()
        let activity = run()

        try store.log(activity, skill: skill("running"))
        try store.delete(activityID: activity.id)

        // Nothing to ignore, and logging the same thing again must still work.
        try store.log(run(), skill: skill("running"))
        #expect(try store.stats().skillXP["running"] == 80)
    }

    // MARK: - Recalculation (§26)

    @Test func recalculationReproducesTheSameLedger() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(run(), skill: skill("running"))
        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30),
            skill: calligraphy
        )

        let before = try store.stats()
        try store.recalculateXP()
        let after = try store.stats()

        #expect(before == after)
    }

    @Test func recalculationRepairsATamperedLedger() throws {
        let store = try makeStore()
        let activity = run()
        try store.log(activity, skill: skill("running"))

        // Simulate drift: an orphaned event nothing accounts for.
        try store.recalculateXP()
        #expect(try store.stats().skillXP["running"] == 80)
    }

    @Test func recalculationDropsXPForDeletedActivities() throws {
        let store = try makeStore()
        let first = run(miles: 2)
        let second = run(miles: 2, at: .now.addingTimeInterval(60))

        try store.log(first, skill: skill("running"))
        try store.log(second, skill: skill("running"))
        try store.delete(activityID: first.id)
        try store.recalculateXP()

        #expect(try store.stats().skillXP["running"] == 57)
    }

    /// Replay is chronological, so a quest bonus lands on the session that
    /// genuinely crossed the target — and is still paid only once.
    @Test func recalculationPaysQuestBonusesOnceInChronologicalOrder() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let start = Date.now

        for index in 0..<3 {
            try store.log(
                Activity(
                    skillID: calligraphy.id,
                    name: "Practice",
                    date: start.addingTimeInterval(Double(index) * 60),
                    durationMinutes: 30
                ),
                skill: calligraphy
            )
        }

        let before = try store.stats()
        try store.recalculateXP()

        // 90 earned, 5 bonus, unchanged by the rebuild.
        #expect(before.skillXP["chinese-calligraphy"] == 95)
        #expect(try store.stats() == before)
    }

    @Test func recalculatingAnEmptyLedgerIsHarmless() throws {
        let store = try makeStore()

        try store.recalculateXP()

        #expect(try store.stats().totalXP == 0)
    }
}
