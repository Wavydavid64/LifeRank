import Foundation
import SwiftData

/// Reads and writes the state that progression cannot derive: the player's
/// rank, and which manual objectives they have marked done.
@MainActor
struct CharacterStore {
    let context: ModelContext

    /// Fetch-or-create. A character always exists, starting at F (§4).
    func character() throws -> CharacterRecord {
        if let existing = try context.fetch(FetchDescriptor<CharacterRecord>()).first {
            return existing
        }

        let created = CharacterRecord()
        context.insert(created)
        try context.save()
        return created
    }

    func rank() throws -> Rank {
        try character().rank
    }

    func manualCompletions() throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<ObjectiveCompletionRecord>()).map(\.objectiveID))
    }

    func setCompleted(_ isComplete: Bool, objectiveID: String) throws {
        let existing = try context.fetch(FetchDescriptor<ObjectiveCompletionRecord>())
            .filter { $0.objectiveID == objectiveID }

        if isComplete {
            guard existing.isEmpty else { return }
            context.insert(ObjectiveCompletionRecord(objectiveID: objectiveID))
        } else {
            existing.forEach(context.delete)
        }

        try context.save()
    }

    /// Moves the player up one rank. Refuses unless `status` says they are
    /// eligible, so the only way to rank up is to have met every requirement
    /// and cleared the trial (§14).
    @discardableResult
    func promote(using status: PromotionStatus) throws -> Bool {
        guard status.canPromote, let nextRank = status.nextRank else { return false }

        let character = try character()
        character.rank = nextRank
        character.promotedAt = .now
        try context.save()
        return true
    }
}
