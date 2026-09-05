import Testing
import Foundation
@testable import LifeRank

struct ProgressionEngineTests {

    // MARK: - XP calculation

    /// DESIGN.md §10's worked example: a 5.1 mile, 42 minute run earns 80 skill XP.
    @Test func workedExampleRunEarnsExpectedSkillXP() {
        let activity = Activity(
            skillID: "running",
            name: "Morning Run",
            durationMinutes: 42,
            distanceMiles: 5.1
        )

        #expect(ProgressionEngine.skillXP(for: activity) == 80)
    }

    @Test func durationOnlyActivityEarnsXPFromDuration() {
        let activity = Activity(skillID: "chinese-calligraphy", name: "Practice", durationMinutes: 32)

        #expect(ProgressionEngine.skillXP(for: activity) == 32)
    }

    // MARK: - Full pipeline

    /// DESIGN.md §12: the same run distributes 80 XP as 56 / 16 / 8.
    @Test func runningActivityDistributesXPExactly() {
        let running = skill("running")
        let activity = Activity(
            skillID: running.id,
            name: "Morning Run",
            durationMinutes: 42,
            distanceMiles: 5.1
        )

        let events = ProgressionEngine.xpEvents(for: activity, skill: running)

        #expect(events.count == 4)
        #expect(amount(for: .skill(running.id), in: events) == 80)
        #expect(amount(for: .attribute(.endurance), in: events) == 56)
        #expect(amount(for: .attribute(.discipline), in: events) == 16)
        #expect(amount(for: .attribute(.exploration), in: events) == 8)
    }

    @Test func chineseCalligraphyDistributesXPExactly() {
        let calligraphy = skill("chinese-calligraphy")
        let activity = Activity(skillID: calligraphy.id, name: "Practice Session", durationMinutes: 10)

        let events = ProgressionEngine.xpEvents(for: activity, skill: calligraphy)

        #expect(amount(for: .skill(calligraphy.id), in: events) == 10)
        #expect(attributeTotal(in: events) == 10)
    }

    @Test func zeroXPActivityProducesNoAttributeEvents() {
        let running = skill("running")
        let activity = Activity(skillID: running.id, name: "No-op", durationMinutes: 0)

        let events = ProgressionEngine.xpEvents(for: activity, skill: running)

        #expect(events.count == 1)
        #expect(events.first?.target == .skill(running.id))
    }

    // MARK: - Distribution correctness

    /// DESIGN.md §12: rounding must never silently lose or invent XP, for any
    /// skill at any amount.
    @Test(arguments: 0...200)
    func attributeXPAlwaysSumsToSkillXP(totalXP: Int) {
        for skill in SeedData.skills {
            let distributed = ProgressionEngine
                .distribute(total: totalXP, weights: skill.attributeWeights)
                .reduce(0) { $0 + $1.amount }

            #expect(distributed == totalXP, "\(skill.name) lost/gained XP at total \(totalXP)")
        }
    }

    @Test func distributeSplitsEvenlyWithNoRemainder() {
        let result = distribution(for: skill("running"), total: 100)

        #expect(result[.endurance] == 70)
        #expect(result[.discipline] == 20)
        #expect(result[.exploration] == 10)
    }

    @Test func distributeAllocatesRemainderByLargestFraction() {
        // 0.55/0.30/0.15 of 10 = 5.5/3.0/1.5 -> floors 5/3/1 (sum 9), remainder 1
        // goes to the largest fractional part: dexterity's 0.5 beats discipline's 0.5
        // on index tie-break, and creativity has no fraction at all.
        let result = distribution(for: skill("chinese-calligraphy"), total: 10)

        #expect(result[.dexterity] == 6)
        #expect(result[.creativity] == 3)
        #expect(result[.discipline] == 1)
    }

    // MARK: - Helpers

    private func skill(_ id: Skill.ID) -> Skill {
        SeedData.skills.first { $0.id == id }!
    }

    private func distribution(for skill: Skill, total: Int) -> [Attribute: Int] {
        Dictionary(uniqueKeysWithValues: ProgressionEngine.distribute(total: total, weights: skill.attributeWeights))
    }

    private func amount(for target: XPTarget, in events: [XPEvent]) -> Int? {
        events.first { $0.target == target }?.amount
    }

    private func attributeTotal(in events: [XPEvent]) -> Int {
        events.reduce(0) { sum, event in
            if case .attribute = event.target { return sum + event.amount }
            return sum
        }
    }
}
