import Foundation
import SwiftData

/// SwiftData storage for an Activity. Exists purely for persistence — the
/// domain layer never sees this type (DESIGN.md §32).
@Model
final class ActivityRecord {
    var id: UUID
    var skillID: String
    var name: String
    var date: Date
    var durationMinutes: Double?
    var distanceMiles: Double?
    var notes: String?
    /// Stable id of the source workout, used to reject double imports (§21).
    var externalIdentifier: String?
    /// Optional, so adding them stayed a lightweight migration under
    /// `LifeRankSchemaV1` — no stage needed.
    var activeCalories: Double?
    var averageHeartRate: Double?

    init(_ activity: Activity) {
        self.id = activity.id
        self.skillID = activity.skillID
        self.name = activity.name
        self.date = activity.date
        self.durationMinutes = activity.durationMinutes
        self.distanceMiles = activity.distanceMiles
        self.notes = activity.notes
        self.externalIdentifier = activity.externalIdentifier
        self.activeCalories = activity.activeCalories
        self.averageHeartRate = activity.averageHeartRate
    }

    var domain: Activity {
        Activity(
            id: id,
            skillID: skillID,
            name: name,
            date: date,
            durationMinutes: durationMinutes,
            distanceMiles: distanceMiles,
            notes: notes,
            externalIdentifier: externalIdentifier,
            activeCalories: activeCalories,
            averageHeartRate: averageHeartRate
        )
    }
}
