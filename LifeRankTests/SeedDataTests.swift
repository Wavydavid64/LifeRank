import Testing
@testable import LifeRank

struct SeedDataTests {

    @Test func allAttributesAreSeeded() {
        #expect(Set(SeedData.attributes) == Set(Attribute.allCases))
    }

    @Test func initialSkillsAreSeeded() {
        let ids = Set(SeedData.skills.map(\.id))
        #expect(ids == ["running", "strength-training", "hiking", "chinese-calligraphy", "western-calligraphy"])
    }

    @Test func everySkillsWeightsSumToOne() {
        for skill in SeedData.skills {
            let total = skill.attributeWeights.reduce(0) { $0 + $1.weight }
            #expect(abs(total - 1.0) < 0.0001, "\(skill.name) weights sum to \(total), expected 1.0")
        }
    }

    /// Pins the DESIGN.md §8 values. These were wrong once already — a summing-to-1.0
    /// check alone does not catch a plausible-but-incorrect split.
    @Test func skillWeightsMatchSpec() {
        let expected: [Skill.ID: [Attribute: Double]] = [
            "running": [.endurance: 0.70, .discipline: 0.20, .exploration: 0.10],
            "strength-training": [.strength: 0.75, .discipline: 0.20, .mobility: 0.05],
            "hiking": [.endurance: 0.50, .exploration: 0.35, .discipline: 0.15],
            "chinese-calligraphy": [.dexterity: 0.55, .creativity: 0.30, .discipline: 0.15],
            "western-calligraphy": [.dexterity: 0.55, .creativity: 0.30, .discipline: 0.15],
        ]

        for skill in SeedData.skills {
            let actual = Dictionary(
                uniqueKeysWithValues: skill.attributeWeights.map { ($0.attribute, $0.weight) }
            )
            #expect(actual == expected[skill.id], "\(skill.name) weights drifted from spec")
        }
    }
}
