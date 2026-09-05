import Foundation

/// A complete, portable snapshot of a player's progression (DESIGN.md §30).
///
/// Carries the XP ledger verbatim rather than expecting it to be recomputed —
/// XPEvents are the source of truth (§10), and replaying activities through a
/// future version of the XP formula would silently rewrite history.
struct BackupDocument: Codable, Equatable {

    /// Bump when the shape changes in a way older readers cannot handle.
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date

    // State that cannot be derived from anything else.
    let rank: Rank
    let promotedAt: Date?
    let activities: [Activity]
    let xpEvents: [XPEvent]
    let manualCompletions: [String]
    let ignoredWorkouts: [String]

    /// Balance configuration in force when this export was made. Ignored on
    /// restore — it records what the numbers meant at the time, so an export
    /// opened years later can still be interpreted.
    let configuration: ConfigurationSnapshot

    struct ConfigurationSnapshot: Codable, Equatable {
        let skills: [Skill]
        let quests: [Quest]

        static var current: ConfigurationSnapshot {
            ConfigurationSnapshot(skills: SeedData.skills, quests: QuestSeed.quests)
        }
    }
}

enum BackupError: LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "This backup was made by a newer version of LifeRank (format \(version)). Update the app to restore it."
        }
    }
}

extension JSONEncoder {
    /// ISO-8601 dates and stable key order, so a backup stays readable and
    /// diffable years from now.
    static var backup: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var backup: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
