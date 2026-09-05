import Foundation
import SwiftData

/// A workout the player removed and does not want back. Without this, deleting
/// an imported activity would achieve nothing — the next import would find the
/// same workout and add it again (DESIGN.md §26's "ignore imported workout").
@Model
final class IgnoredWorkoutRecord {
    @Attribute(.unique) var externalIdentifier: String
    var ignoredAt: Date

    init(externalIdentifier: String, ignoredAt: Date = .now) {
        self.externalIdentifier = externalIdentifier
        self.ignoredAt = ignoredAt
    }
}
