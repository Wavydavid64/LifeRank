import Foundation

/// The player's overall rank tier, ordered from lowest to highest.
enum Rank: Int, CaseIterable, Comparable, Codable, Identifiable {
    case f, e, d, c, b, a, s

    var id: Int { rawValue }

    /// Every character begins here (DESIGN.md §4).
    static let starting = Rank.f

    /// The next rank up, or nil at the top of the ladder. Ranks beyond S can be
    /// appended to the enum without touching this (§4).
    var next: Rank? { Rank(rawValue: rawValue + 1) }

    var displayName: String {
        switch self {
        case .f: return "F"
        case .e: return "E"
        case .d: return "D"
        case .c: return "C"
        case .b: return "B"
        case .a: return "A"
        case .s: return "S"
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
