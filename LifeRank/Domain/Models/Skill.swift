import Foundation

/// The proportion of a skill's XP that flows into a given attribute.
/// A skill's full set of weights should sum to 1.0 (100%).
nonisolated struct AttributeWeight: Codable, Hashable {
    let attribute: Attribute
    let weight: Double
}

/// A trackable hobby or discipline. XP earned in a skill is distributed
/// to one or more attributes according to configurable weights.
nonisolated struct Skill: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let attributeWeights: [AttributeWeight]
}
