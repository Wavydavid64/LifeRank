import Foundation
import SwiftData

/// The player's rank. Stored rather than derived, because reaching a threshold
/// must never promote anyone on its own (DESIGN.md §3.4, §4).
@Model
final class CharacterRecord {
    var rank: Rank
    var promotedAt: Date?

    init(rank: Rank = .starting, promotedAt: Date? = nil) {
        self.rank = rank
        self.promotedAt = promotedAt
    }
}

/// A manually completed objective — the qualitative half of §13 and §14.
@Model
final class ObjectiveCompletionRecord {
    @Attribute(.unique) var objectiveID: String
    var completedAt: Date

    init(objectiveID: String, completedAt: Date = .now) {
        self.objectiveID = objectiveID
        self.completedAt = completedAt
    }
}
