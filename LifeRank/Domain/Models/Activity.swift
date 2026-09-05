import Foundation

/// Something the user actually did in the real world. Activities are the
/// source of truth that the ProgressionEngine converts into XPEvents.
nonisolated struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    let skillID: Skill.ID
    let name: String
    let date: Date
    let durationMinutes: Double?
    let distanceMiles: Double?
    let notes: String?
    /// Stable identifier of the source workout (e.g. a HealthKit UUID), used to
    /// guarantee an imported workout can never award XP twice. Nil for manual entries.
    let externalIdentifier: String?

    // Intensity signals, captured from Apple Health where available and nil for
    // manual entries. Nothing consumes these yet — DESIGN.md §11 says to tune
    // the XP formula against real usage, and recording them now is what makes
    // that tuning retroactive rather than future-only.
    let activeCalories: Double?
    let averageHeartRate: Double?

    init(
        id: UUID = UUID(),
        skillID: Skill.ID,
        name: String,
        date: Date = Date(),
        durationMinutes: Double? = nil,
        distanceMiles: Double? = nil,
        notes: String? = nil,
        externalIdentifier: String? = nil,
        activeCalories: Double? = nil,
        averageHeartRate: Double? = nil
    ) {
        self.id = id
        self.skillID = skillID
        self.name = name
        self.date = date
        self.durationMinutes = durationMinutes
        self.distanceMiles = distanceMiles
        self.notes = notes
        self.externalIdentifier = externalIdentifier
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
    }
}
