import Foundation

/// The player's overall rank tier, ordered from lowest to highest.
enum Rank: Int, CaseIterable, Comparable, Codable, Identifiable {
    case f, e, d, c, b, a, s

    var id: Int { rawValue }

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
