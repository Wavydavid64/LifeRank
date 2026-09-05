import Testing
@testable import LifeRank

struct SeedDataTests {

    @Test func allAttributesAreSeeded() {
        #expect(Set(SeedData.attributes) == Set(Attribute.allCases))
    }

    @Test func initialSkillsAreSeeded() {
        let ids = Set(SeedData.skills.map(\.id))
        #expect(ids == [
            "running", "cycling", "hiking", "kayaking",
            "strength-training", "yoga", "stretching",
            "chinese-calligraphy", "western-calligraphy", "painting", "music-practice",
            "reading",
        ])
    }

    @Test func skillIDsAreUnique() {
        let ids = SeedData.skills.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everySkillsWeightsSumToOne() {
        for skill in SeedData.skills {
            let total = skill.attributeWeights.reduce(0) { $0 + $1.weight }
            #expect(abs(total - 1.0) < 0.0001, "\(skill.name) weights sum to \(total), expected 1.0")
        }
    }

    @Test func noSkillWeightsAnAttributeTwice() {
        for skill in SeedData.skills {
            let attributes = skill.attributeWeights.map(\.attribute)
            #expect(Set(attributes).count == attributes.count, "\(skill.name) lists an attribute twice")
        }
    }

    /// Every attribute needs a skill that genuinely feeds it. Knowledge once had
    /// no source at all and Mobility only 5% of one skill, which made S rank —
    /// all 8 attributes at level 20 — impossible to reach no matter how much was
    /// logged. A weights table that looks reasonable can still strand a rank.
    @Test func everyAttributeIsReachableFromSomeSkill() {
        for attribute in Attribute.allCases {
            let best = SeedData.skills
                .flatMap(\.attributeWeights)
                .filter { $0.attribute == attribute }
                .map(\.weight)
                .max() ?? 0

            #expect(
                best >= 0.25,
                "\(attribute.displayName)'s best source is \(best) — too thin to reach the levels top ranks require"
            )
        }
    }

    /// Pins the configured weights. These were wrong once already — a
    /// summing-to-1.0 check alone does not catch a plausible-but-incorrect split.
    @Test func skillWeightsMatchConfiguration() {
        let expected: [Skill.ID: [Attribute: Double]] = [
            // DESIGN.md §8
            "running": [.endurance: 0.70, .discipline: 0.20, .exploration: 0.10],
            "strength-training": [.strength: 0.75, .discipline: 0.20, .mobility: 0.05],
            "hiking": [.endurance: 0.50, .exploration: 0.35, .discipline: 0.15],
            "chinese-calligraphy": [.dexterity: 0.55, .creativity: 0.30, .discipline: 0.15],
            "western-calligraphy": [.dexterity: 0.55, .creativity: 0.30, .discipline: 0.15],
            // Added to give every attribute a source.
            "cycling": [.endurance: 0.50, .exploration: 0.30, .discipline: 0.20],
            "kayaking": [.strength: 0.30, .endurance: 0.30, .exploration: 0.25, .discipline: 0.15],
            "yoga": [.mobility: 0.60, .discipline: 0.25, .endurance: 0.15],
            "stretching": [.mobility: 0.75, .discipline: 0.25],
            "painting": [.creativity: 0.55, .dexterity: 0.30, .discipline: 0.15],
            "music-practice": [.dexterity: 0.40, .creativity: 0.35, .discipline: 0.25],
            "reading": [.knowledge: 0.70, .discipline: 0.30],
        ]

        #expect(expected.count == SeedData.skills.count, "a skill is missing from the pinned weights")

        for skill in SeedData.skills {
            let actual = Dictionary(
                uniqueKeysWithValues: skill.attributeWeights.map { ($0.attribute, $0.weight) }
            )
            #expect(actual == expected[skill.id], "\(skill.name) weights drifted from configuration")
        }
    }
}
