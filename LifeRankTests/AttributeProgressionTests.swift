import Testing
@testable import LifeRank

struct AttributeProgressionTests {

    /// DESIGN.md §5: an early level costs roughly 100 XP.
    @Test func firstLevelCostsBaseAmount() {
        #expect(AttributeProgression.cumulativeXP(forLevel: 1) == 100)
    }

    @Test func levelsGetProgressivelyMoreExpensive() {
        let costs = (1...6).map {
            AttributeProgression.cumulativeXP(forLevel: $0) - AttributeProgression.cumulativeXP(forLevel: $0 - 1)
        }

        #expect(costs == [100, 200, 300, 400, 500, 600])
        #expect(zip(costs, costs.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test(arguments: [
        (0, 0), (1, 0), (99, 0),
        (100, 1), (299, 1),
        (300, 2), (599, 2),
        (600, 3),
    ])
    func levelBoundariesAreExact(xp: Int, expected: Int) {
        #expect(AttributeProgression.level(forXP: xp) == expected)
    }

    @Test func progressReportsPositionWithinCurrentLevel() {
        // Level 1 spans 100..<300, so 150 XP sits 50 into a 200 XP level.
        let progress = AttributeProgression.progress(forXP: 150)

        #expect(progress.level == 1)
        #expect(progress.xpIntoLevel == 50)
        #expect(progress.xpNeededForNextLevel == 200)
        #expect(progress.fraction == 0.25)
    }

    @Test func freshAttributeHasNoProgress() {
        let progress = AttributeProgression.progress(forXP: 0)

        #expect(progress.level == 0)
        #expect(progress.xpIntoLevel == 0)
        #expect(progress.fraction == 0)
    }

    @Test func levelStartExactlyMatchesCumulativeCost() {
        for level in 1...20 {
            let xp = AttributeProgression.cumulativeXP(forLevel: level)
            #expect(AttributeProgression.level(forXP: xp) == level)
            #expect(AttributeProgression.level(forXP: xp - 1) == level - 1)
        }
    }
}
