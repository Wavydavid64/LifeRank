import Testing
import Foundation
@testable import LifeRank

struct ConsistencyStatsTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// 2026-09-30, 12:00 UTC. The 30 day window is 1–30 September.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12))!
    }

    private func day(_ day: Int, month: Int = 9, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func activity(_ skillID: Skill.ID = "running", on date: Date) -> Activity {
        Activity(skillID: skillID, name: "Session", date: date, durationMinutes: 30)
    }

    private func rate(_ activities: [Activity], skillID: Skill.ID = "running") -> Double {
        ConsistencyStats.rate(skillID: skillID, activities: activities, now: now, calendar: calendar)
    }

    @Test func noActivityIsZeroPercent() {
        #expect(rate([]) == 0)
    }

    @Test func everyDayInTheWindowIsOneHundredPercent() {
        let everyDay = (1...30).map { activity(on: day($0)) }

        #expect(rate(everyDay) == 1.0)
    }

    /// Several sessions in one day still count as one day — this measures how
    /// often you show up, not how hard.
    @Test func multipleSessionsInADayCountOnce() {
        let sameDay = [
            activity(on: day(30, hour: 7)),
            activity(on: day(30, hour: 12)),
            activity(on: day(30, hour: 19)),
        ]

        #expect(rate(sameDay) == 1.0 / 30.0)
    }

    @Test func activityOutsideTheWindowIsIgnored() {
        // 31 August is the day before the window opens.
        #expect(rate([activity(on: day(31, month: 8))]) == 0)
    }

    @Test func theOldestDayInTheWindowStillCounts() {
        #expect(rate([activity(on: day(1))]) == 1.0 / 30.0)
    }

    @Test func otherSkillsDoNotCount() {
        #expect(rate([activity("hiking", on: day(30))]) == 0)
    }

    @Test func fifteenOfThirtyDaysIsFiftyPercent() {
        let alternating = stride(from: 1, through: 30, by: 2).map { activity(on: day($0)) }

        #expect(alternating.count == 15)
        #expect(rate(alternating) == 0.5)
    }

    /// §17: consistency is a statistic, never a mechanic. Missing a day nudges
    /// the number and nothing else — no XP, rank or level depends on it.
    @Test func missingADayOnlyMovesTheNumberSlightly() {
        let everyDay = (1...30).map { activity(on: day($0)) }
        let missedOne = everyDay.filter { !calendar.isDate($0.date, inSameDayAs: day(15)) }

        #expect(rate(everyDay) == 1.0)
        #expect(rate(missedOne) == 29.0 / 30.0)
    }
}
