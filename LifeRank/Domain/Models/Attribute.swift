import Foundation

/// A character attribute that skills distribute XP into.
enum Attribute: String, CaseIterable, Codable, Identifiable {
    case strength = "Strength"
    case endurance = "Endurance"
    case dexterity = "Dexterity"
    case mobility = "Mobility"
    case knowledge = "Knowledge"
    case creativity = "Creativity"
    case discipline = "Discipline"
    case exploration = "Exploration"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
