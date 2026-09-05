import Foundation

/// The attributes and skills available at MVP launch. Weights come from
/// DESIGN.md §8 — starting tuning values, not final balance.
enum SeedData {
    static let attributes: [Attribute] = Attribute.allCases

    static let skills: [Skill] = [
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
            id: "strength-training",
            name: "Strength Training",
            attributeWeights: [
                AttributeWeight(attribute: .strength, weight: 0.75),
                AttributeWeight(attribute: .discipline, weight: 0.20),
                AttributeWeight(attribute: .mobility, weight: 0.05),
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
    ]
}
