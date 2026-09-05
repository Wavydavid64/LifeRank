import Testing
import Foundation
@testable import LifeRank

struct QuestEvaluatorTests {

    /// Fixed calendar and clock — quest windows must not depend on where or
    /// when the tests run.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Wednesday 2026-09-02, 12:00 UTC.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 12))!
    }

    private func date(_ day: Int, month: Int = 9, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func activity(
        skillID: Skill.ID = "chinese-calligraphy",
        on date: Date,
        minutes: Double? = 30,
        miles: Double? = nil
    ) -> Activity {
        Activity(
            skillID: skillID,
            name: "Session",
            date: date,
            durationMinutes: minutes,
            distanceMiles: miles
        )
    }

    private func quest(
        period: QuestPeriod,
        skillID: Skill.ID = "chinese-calligraphy",
        metric: QuestMetric = .minutes,
        target: Double = 30
    ) -> Quest {
        Quest(
            id: "test",
            title: "Test",
            period: period,
            objective: QuestObjective(skillID: skillID, metric: metric, target: target)
        )
    }

    private func progress(_ quest: Quest, _ activities: [Activity]) -> QuestProgress {
        QuestEvaluator.progress(for: quest, activities: activities, now: now, calendar: calendar)
    }

    // MARK: - Windows

    @Test func dailyQuestCountsOnlyToday() {
        let result = progress(quest(period: .daily), [
            activity(on: date(2)),   // today
            activity(on: date(1)),   // yesterday
        ])

        #expect(result.current == 30)
    }

    @Test func weeklyQuestCountsEarlierInTheSameWeek() {
        // Week runs Sun 30 Aug – Sat 5 Sep. 31 Aug is in it, 29 Aug is not.
        let result = progress(quest(period: .weekly, target: 90), [
            activity(on: date(2)),
            activity(on: date(31, month: 8)),
            activity(on: date(29, month: 8)),
        ])

        #expect(result.current == 60)
    }

    @Test func oneTimeQuestCountsEverythingUpToNow() {
        let result = progress(quest(period: .oneTime, target: 90), [
            activity(on: date(2)),
            activity(on: date(1, month: 3)),
        ])

        #expect(result.current == 60)
    }

    // MARK: - Metrics

    @Test func minutesAccumulateAcrossSessions() {
        let result = progress(quest(period: .daily, target: 60), [
            activity(on: date(2), minutes: 20),
            activity(on: date(2), minutes: 25),
        ])

        #expect(result.current == 45)
        #expect(!result.isComplete)
    }

    @Test func milesAccumulateAcrossSessions() {
        let running = quest(period: .weekly, skillID: "running", metric: .miles, target: 10)
        let result = progress(running, [
            activity(skillID: "running", on: date(2), minutes: 42, miles: 5.1),
            activity(skillID: "running", on: date(31, month: 8), minutes: 20, miles: 2.2),
        ])

        #expect(result.current == 7.3)
        #expect(!result.isComplete)
    }

    @Test func sessionsCountEntriesNotDuration() {
        let strength = quest(period: .weekly, skillID: "strength-training", metric: .sessions, target: 2)
        let result = progress(strength, [
            activity(skillID: "strength-training", on: date(2), minutes: 61),
        ])

        #expect(result.current == 1)
        #expect(!result.isComplete)
    }

    // MARK: - Filtering and completion

    @Test func otherSkillsDoNotAdvanceAQuest() {
        let result = progress(quest(period: .daily), [
            activity(skillID: "running", on: date(2), minutes: 60),
        ])

        #expect(result.current == 0)
    }

    @Test func questCompletesAtExactlyTheTarget() {
        let result = progress(quest(period: .daily, target: 30), [
            activity(on: date(2), minutes: 30),
        ])

        #expect(result.isComplete)
        #expect(result.fraction == 1)
    }

    @Test func overshootingDoesNotPushProgressPastFull() {
        let result = progress(quest(period: .daily, target: 30), [
            activity(on: date(2), minutes: 90),
        ])

        #expect(result.current == 90)
        #expect(result.fraction == 1)
    }

    @Test func noActivityMeansNoProgress() {
        let result = progress(quest(period: .daily), [])

        #expect(result.current == 0)
        #expect(result.fraction == 0)
        #expect(!result.isComplete)
    }

    // MARK: - Seed data

    @Test func everySeededQuestTargetsAKnownSkill() {
        for quest in QuestSeed.quests {
            #expect(
                SeedData.skills.contains { $0.id == quest.objective.skillID },
                "\(quest.id) targets unknown skill \(quest.objective.skillID)"
            )
            #expect(quest.objective.target > 0, "\(quest.id) has a target of zero")
        }
    }

    @Test func seededQuestIDsAreUnique() {
        let ids = QuestSeed.quests.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
