import Testing
import Foundation
import SwiftData
@testable import LifeRank

@MainActor
struct ActivityEditTests {

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

    private func edited(_ activity: Activity, minutes: Double? = nil, miles: Double? = nil) -> Activity {
        Activity(
            id: activity.id,
            skillID: activity.skillID,
            name: activity.name,
            date: activity.date,
            durationMinutes: minutes ?? activity.durationMinutes,
            distanceMiles: miles ?? activity.distanceMiles,
            notes: activity.notes,
            externalIdentifier: activity.externalIdentifier
        )
    }

    /// The mistyped-duration case: 300 minutes corrected to 30.
    @Test func correctingDurationCorrectsTheXP() throws {
        let store = try makeStore()
        let running = skill("running")
        let activity = Activity(skillID: running.id, name: "Run", durationMinutes: 300)

        try store.log(activity, skill: running)
        #expect(try store.stats().skillXP["running"] == 300)

        try store.update(edited(activity, minutes: 30))

        #expect(try store.stats().skillXP["running"] == 30)
        #expect(try store.activities().count == 1)
    }

    @Test func editingLeavesNoOrphanedXPBehind() throws {
        let store = try makeStore()
        let running = skill("running")
        let activity = Activity(skillID: running.id, name: "Run", durationMinutes: 60)

        try store.log(activity, skill: running)
        try store.update(edited(activity, minutes: 20))

        let stats = try store.stats()
        #expect(stats.skillXP["running"] == 20)
        #expect(stats.attributeXP.values.reduce(0, +) == 20)
        #expect(try store.xpEvents().allSatisfy { $0.activityID == activity.id })
    }

    /// An edit can change whether a quest was crossed, so the bonus has to move
    /// with it rather than being stranded on the old numbers.
    @Test func editingBelowAQuestTargetWithdrawsItsBonus() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let activity = Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 30)

        try store.log(activity, skill: calligraphy)
        // 30 earned plus the daily quest's 5 XP bonus.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 35)

        try store.update(edited(activity, minutes: 20))

        // Under the 30 minute target now, so no bonus survives.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 20)
    }

    @Test func editingUpToAQuestTargetAwardsTheBonus() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let activity = Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 10)

        try store.log(activity, skill: calligraphy)
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 10)

        try store.update(edited(activity, minutes: 30))

        #expect(try store.stats().skillXP["chinese-calligraphy"] == 35)
    }

    /// The bonus must follow the activity that genuinely crosses the target,
    /// even when an earlier edit changes which one that is.
    @Test func editingMovesAQuestBonusToTheRightActivity() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")
        let start = Date.now

        let first = Activity(skillID: calligraphy.id, name: "First", date: start, durationMinutes: 30)
        let second = Activity(
            skillID: calligraphy.id, name: "Second",
            date: start.addingTimeInterval(3600), durationMinutes: 10
        )

        try store.log(first, skill: calligraphy)
        try store.log(second, skill: calligraphy)
        // 40 earned, bonus paid once by the first session.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 45)

        // Shrink the first below the target; the second now carries the day over.
        try store.update(edited(first, minutes: 25))

        // 35 earned, and the bonus is still paid exactly once.
        #expect(try store.stats().skillXP["chinese-calligraphy"] == 40)
    }

    /// Deliberately 15 minutes: the daily reading quest targets 20, and a bonus
    /// folded into the total would obscure what this test is checking.
    @Test func changingSkillMovesTheXPToTheNewSkill() throws {
        let store = try makeStore()
        let running = skill("running")
        let activity = Activity(skillID: running.id, name: "Session", durationMinutes: 15)

        try store.log(activity, skill: running)
        #expect(try store.stats().skillXP["running"] == 15)

        let moved = Activity(
            id: activity.id, skillID: "reading", name: "Session",
            date: activity.date, durationMinutes: 15
        )
        try store.update(moved)

        let stats = try store.stats()
        #expect(stats.skillXP["running"] == nil)
        #expect(stats.skillXP["reading"] == 15)
        // 15 XP at .70/.30 = 10.5/4.5; the odd point goes to knowledge on the tie.
        #expect(stats.attributeXP[.knowledge] == 11)
        #expect(stats.attributeXP[.discipline] == 4)
        #expect(stats.attributeXP[.endurance] == nil)
    }

    @Test func updatingAnUnknownActivityDoesNothing() throws {
        let store = try makeStore()
        let running = skill("running")
        let activity = Activity(skillID: running.id, name: "Run", durationMinutes: 40)
        try store.log(activity, skill: running)

        let stranger = Activity(skillID: running.id, name: "Ghost", durationMinutes: 999)
        try store.update(stranger)

        #expect(try store.stats().skillXP["running"] == 40)
        #expect(try store.activities().count == 1)
    }
}
