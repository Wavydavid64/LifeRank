import Testing
@testable import LifeRank

struct AttributeProgressionTests {

    @Test func firstLevelCostsBaseAmount() {
        #expect(AttributeProgression.cumulativeXP(forLevel: 1) == AttributeProgression.baseLevelCost)
    }

    /// DESIGN.md §5: each level must cost more than the one before it.
    @Test func levelsGetProgressivelyMoreExpensive() {
        let costs = (1...6).map {
            AttributeProgression.cumulativeXP(forLevel: $0) - AttributeProgression.cumulativeXP(forLevel: $0 - 1)
        }

        #expect(costs == [25, 50, 75, 100, 125, 150])
        #expect(zip(costs, costs.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test(arguments: [
        (0, 0), (1, 0), (24, 0),
        (25, 1), (74, 1),
        (75, 2), (149, 2),
        (150, 3), (249, 3),
        (250, 4),
    ])
    func levelBoundariesAreExact(xp: Int, expected: Int) {
        #expect(AttributeProgression.level(forXP: xp) == expected)
    }

    @Test func progressReportsPositionWithinCurrentLevel() {
        // Level 3 spans 150..<250, so 200 XP sits 50 into a 100 XP level.
        let progress = AttributeProgression.progress(forXP: 200)

        #expect(progress.level == 3)
        #expect(progress.xpIntoLevel == 50)
        #expect(progress.xpNeededForNextLevel == 100)
        #expect(progress.fraction == 0.5)
    }

    @Test func freshAttributeHasNoProgress() {
        let progress = AttributeProgression.progress(forXP: 0)

        #expect(progress.level == 0)
        #expect(progress.xpIntoLevel == 0)
        #expect(progress.fraction == 0)
    }

    @Test func levelStartExactlyMatchesCumulativeCost() {
        for level in 1...30 {
            let xp = AttributeProgression.cumulativeXP(forLevel: level)
            #expect(AttributeProgression.level(forXP: xp) == level)
            #expect(AttributeProgression.level(forXP: xp - 1) == level - 1)
        }
    }

    /// Pins the balance intent: roughly a year of steady training on a primary
    /// attribute should land near level 25, and must not overshoot early.
    @Test func aYearOfPrimaryTrainingLandsNearLevel25() {
        // ~168 XP/week to a primary attribute over 50 weeks.
        #expect(AttributeProgression.level(forXP: 8_400) == 25)

        // And progression decelerates rather than racing there.
        #expect(AttributeProgression.level(forXP: 168) == 3)      // one week
        #expect(AttributeProgression.level(forXP: 2_016) == 12)   // three months
    }

    /// The radar plots level plus position within the level, so a single
    /// session has to move the value even when no level is crossed.
    @Test func fractionAdvancesWithoutCrossingALevel() {
        let before = AttributeProgression.progress(forXP: 160)
        let after = AttributeProgression.progress(forXP: 200)

        #expect(before.level == after.level)
        #expect(Double(after.level) + after.fraction > Double(before.level) + before.fraction)
    }
}
