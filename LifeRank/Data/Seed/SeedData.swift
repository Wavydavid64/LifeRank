import Foundation

/// The attributes and skills available at MVP launch. Weights for the original
/// five come from DESIGN.md §8 — starting tuning values, not final balance.
///
/// Between them the skills must give every attribute a real source. Knowledge
/// and Mobility once had none, which made S rank (all 8 attributes at level 20)
/// mathematically unreachable. `everyAttributeIsReachableFromSomeSkill` guards
/// against that returning.
nonisolated enum SeedData {
    static let attributes: [Attribute] = Attribute.allCases

    static let skills: [Skill] = [
        // Cardio and outdoors
        Skill(
            id: "running",
            name: "Running",
            attributeWeights: [
                AttributeWeight(attribute: .endurance, weight: 0.70),
                AttributeWeight(attribute: .discipline, weight: 0.20),
                AttributeWeight(attribute: .exploration, weight: 0.10),
            ]
        ),
        Skill(
            id: "cycling",
            name: "Cycling",
            attributeWeights: [
                AttributeWeight(attribute: .endurance, weight: 0.50),
                AttributeWeight(attribute: .exploration, weight: 0.30),
                AttributeWeight(attribute: .discipline, weight: 0.20),
            ]
        ),
        Skill(
            id: "hiking",
            name: "Hiking",
            attributeWeights: [
                AttributeWeight(attribute: .endurance, weight: 0.50),
                AttributeWeight(attribute: .exploration, weight: 0.35),
                AttributeWeight(attribute: .discipline, weight: 0.15),
            ]
        ),
        Skill(
            id: "kayaking",
            name: "Kayaking",
            attributeWeights: [
                AttributeWeight(attribute: .strength, weight: 0.30),
                AttributeWeight(attribute: .endurance, weight: 0.30),
                AttributeWeight(attribute: .exploration, weight: 0.25),
                AttributeWeight(attribute: .discipline, weight: 0.15),
            ]
        ),

        // Strength and mobility
        Skill(
            id: "strength-training",
            name: "Strength Training",
            attributeWeights: [
                AttributeWeight(attribute: .strength, weight: 0.75),
                AttributeWeight(attribute: .discipline, weight: 0.20),
                AttributeWeight(attribute: .mobility, weight: 0.05),
            ]
        ),
        Skill(
            id: "yoga",
            name: "Yoga",
            attributeWeights: [
                AttributeWeight(attribute: .mobility, weight: 0.60),
                AttributeWeight(attribute: .discipline, weight: 0.25),
                AttributeWeight(attribute: .endurance, weight: 0.15),
            ]
        ),
        Skill(
            id: "stretching",
            name: "Stretching",
            attributeWeights: [
                AttributeWeight(attribute: .mobility, weight: 0.75),
                AttributeWeight(attribute: .discipline, weight: 0.25),
            ]
        ),

        // Craft
        Skill(
            id: "chinese-calligraphy",
            name: "Chinese Calligraphy",
            attributeWeights: [
                AttributeWeight(attribute: .dexterity, weight: 0.55),
                AttributeWeight(attribute: .creativity, weight: 0.30),
                AttributeWeight(attribute: .discipline, weight: 0.15),
            ]
        ),
        Skill(
            id: "western-calligraphy",
            name: "Western Calligraphy",
            attributeWeights: [
                AttributeWeight(attribute: .dexterity, weight: 0.55),
                AttributeWeight(attribute: .creativity, weight: 0.30),
                AttributeWeight(attribute: .discipline, weight: 0.15),
            ]
        ),
        Skill(
            id: "painting",
            name: "Painting",
            attributeWeights: [
                AttributeWeight(attribute: .creativity, weight: 0.55),
                AttributeWeight(attribute: .dexterity, weight: 0.30),
                AttributeWeight(attribute: .discipline, weight: 0.15),
            ]
        ),
        Skill(
            id: "music-practice",
            name: "Music Practice",
            attributeWeights: [
                AttributeWeight(attribute: .dexterity, weight: 0.40),
                AttributeWeight(attribute: .creativity, weight: 0.35),
                AttributeWeight(attribute: .discipline, weight: 0.25),
            ]
        ),

        // Mind
        Skill(
            id: "reading",
            name: "Reading",
            attributeWeights: [
                AttributeWeight(attribute: .knowledge, weight: 0.70),
                AttributeWeight(attribute: .discipline, weight: 0.30),
            ]
        ),
    ]
}
