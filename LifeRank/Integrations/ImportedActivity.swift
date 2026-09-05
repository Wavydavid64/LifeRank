import Foundation

/// A workout discovered in an external source, before it becomes progression.
/// Deliberately free of HealthKit types — normalization happens here so nothing
/// downstream of this boundary knows where the data came from (DESIGN.md §32).
nonisolated struct ImportedActivity: Identifiable, Hashable {
    /// Stable identifier from the source, used to reject repeat imports (§21).
    let id: String
    /// Nil when the workout type has no skill mapping.
    let skillID: Skill.ID?
    let name: String
    let startDate: Date
    let durationMinutes: Double
    let distanceMiles: Double?

    /// Converts to the app's own Activity representation, or nil when the
    /// workout could not be classified. An unclassified workout must not be
    /// given an arbitrary skill just to award it XP (§36).
    func normalized() -> Activity? {
        guard let skillID else { return nil }

        return Activity(
            skillID: skillID,
            name: name,
            date: startDate,
            durationMinutes: durationMinutes,
            distanceMiles: distanceMiles,
            externalIdentifier: id
        )
    }
}

/// The single seam external fitness sources plug into (§18).
protocol ActivityProvider {
    func requestAuthorization() async throws
    func fetchActivities(since date: Date) async throws -> [ImportedActivity]
}
