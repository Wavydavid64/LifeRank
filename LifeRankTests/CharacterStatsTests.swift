import Testing
import Foundation
@testable import LifeRank

struct CharacterStatsTests {

    @Test func deriveSumsRepeatedEventsPerTarget() {
        let first = UUID()
        let second = UUID()
        let events = [
            XPEvent(activityID: first, target: .skill("running"), amount: 80),
            XPEvent(activityID: first, target: .attribute(.endurance), amount: 56),
            XPEvent(activityID: second, target: .skill("running"), amount: 20),
            XPEvent(activityID: second, target: .attribute(.endurance), amount: 14),
        ]

        let stats = CharacterStats.derive(from: events)

        #expect(stats.skillXP["running"] == 100)
        #expect(stats.attributeXP[.endurance] == 70)
    }

    /// Overall XP counts skill XP only — attribute XP is the same XP
    /// redistributed, so including it would double the total.
    @Test func totalXPDoesNotDoubleCountAttributeXP() {
        let activity = UUID()
        let events = [
            XPEvent(activityID: activity, target: .skill("running"), amount: 80),
            XPEvent(activityID: activity, target: .attribute(.endurance), amount: 56),
            XPEvent(activityID: activity, target: .attribute(.discipline), amount: 16),
            XPEvent(activityID: activity, target: .attribute(.exploration), amount: 8),
        ]

        #expect(CharacterStats.derive(from: events).totalXP == 80)
    }

    @Test func emptyLedgerHasNoProgression() {
        let stats = CharacterStats.derive(from: [])

        #expect(stats.totalXP == 0)
        #expect(stats.skillXP.isEmpty)
        #expect(stats.attributeXP.isEmpty)
    }
}
