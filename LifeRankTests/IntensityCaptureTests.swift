import Testing
import Foundation
import SwiftData
import HealthKit
@testable import LifeRank

/// Active energy and heart rate are recorded but deliberately unused (§11, §20).
/// These tests exist so the capture path cannot rot before a formula needs it —
/// a silently dropped field would only be noticed years later, by which point
/// the history is unrecoverable.
@MainActor
struct IntensityCaptureTests {

    private func makeStore() throws -> ActivityStore {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            CharacterRecord.self, ObjectiveCompletionRecord.self, IgnoredWorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ActivityStore(context: ModelContext(container))
    }

    private func skill(_ id: Skill.ID) -> Skill {
        SeedData.skills.first { $0.id == id }!
    }

    // MARK: - Mapping (§20 findings)

    @Test func bothStrengthTrainingTypesMapToTheSkill() {
        #expect(WorkoutMapping.skillID(for: .traditionalStrengthTraining) == "strength-training")
        #expect(WorkoutMapping.skillID(for: .functionalStrengthTraining) == "strength-training")
    }

    // MARK: - Import path

    @Test func importedWorkoutsCarryIntensityThroughNormalization() throws {
        let workout = ImportedActivity(
            id: "HK-1",
            skillID: "running",
            name: "Run",
            startDate: .now,
            durationMinutes: 42,
            distanceMiles: 5.1,
            activeCalories: 540,
            averageHeartRate: 152
        )

        let activity = try #require(workout.normalized())

        #expect(activity.activeCalories == 540)
        #expect(activity.averageHeartRate == 152)
    }

    @Test func intensitySurvivesPersistence() throws {
        let store = try makeStore()

        try ActivityImporter(store: store).import([
            ImportedActivity(
                id: "HK-1", skillID: "running", name: "Run",
                startDate: .now, durationMinutes: 42, distanceMiles: 5.1,
                activeCalories: 540, averageHeartRate: 152
            )
        ])

        let stored = try #require(try store.activities().first)
        #expect(stored.activeCalories == 540)
        #expect(stored.averageHeartRate == 152)
    }

    /// Hevy reports duration and energy but no distance (§20), so the absent
    /// field must stay absent rather than becoming zero.
    @Test func missingDistanceStaysNilWhileEnergyIsKept() throws {
        let store = try makeStore()

        try ActivityImporter(store: store).import([
            ImportedActivity(
                id: "HK-2", skillID: "strength-training", name: "Strength Training",
                startDate: .now, durationMinutes: 61, distanceMiles: nil,
                activeCalories: 310, averageHeartRate: 118
            )
        ])

        let stored = try #require(try store.activities().first)
        #expect(stored.distanceMiles == nil)
        #expect(stored.activeCalories == 310)
        #expect(stored.averageHeartRate == 118)
    }

    @Test func manualEntriesSimplyHaveNoIntensity() throws {
        let store = try makeStore()
        let calligraphy = skill("chinese-calligraphy")

        try store.log(
            Activity(skillID: calligraphy.id, name: "Practice", durationMinutes: 20),
            skill: calligraphy
        )

        let stored = try #require(try store.activities().first)
        #expect(stored.activeCalories == nil)
        #expect(stored.averageHeartRate == nil)
    }

    // MARK: - Not yet used

    /// Recording intensity must not quietly change progression. Two identical
    /// sessions, one with energy and heart rate, must still earn the same XP.
    @Test func intensityDoesNotAffectXPYet() throws {
        let running = skill("running")
        let base = Activity(skillID: running.id, name: "Run", durationMinutes: 42, distanceMiles: 5.1)
        let withIntensity = Activity(
            skillID: running.id, name: "Run", durationMinutes: 42, distanceMiles: 5.1,
            activeCalories: 900, averageHeartRate: 175
        )

        #expect(ProgressionEngine.skillXP(for: base) == ProgressionEngine.skillXP(for: withIntensity))
    }

    // MARK: - Correction and backup

    @Test func editingAnActivityKeepsItsIntensity() throws {
        let store = try makeStore()

        try ActivityImporter(store: store).import([
            ImportedActivity(
                id: "HK-3", skillID: "running", name: "Run",
                startDate: .now, durationMinutes: 42, distanceMiles: 5.1,
                activeCalories: 540, averageHeartRate: 152
            )
        ])

        let original = try #require(try store.activities().first)
        try store.update(
            Activity(
                id: original.id, skillID: original.skillID, name: "Corrected",
                date: original.date, durationMinutes: 30, distanceMiles: original.distanceMiles,
                notes: original.notes, externalIdentifier: original.externalIdentifier,
                activeCalories: original.activeCalories, averageHeartRate: original.averageHeartRate
            )
        )

        let corrected = try #require(try store.activities().first)
        #expect(corrected.durationMinutes == 30)
        #expect(corrected.activeCalories == 540)
        #expect(corrected.averageHeartRate == 152)
    }

    @Test func intensitySurvivesBackupAndRestore() throws {
        let source = try makeStore()
        try ActivityImporter(store: source).import([
            ImportedActivity(
                id: "HK-4", skillID: "running", name: "Run",
                startDate: .now, durationMinutes: 42, distanceMiles: 5.1,
                activeCalories: 540, averageHeartRate: 152
            )
        ])

        let data = try BackupService(context: source.context).export()

        let destination = try makeStore()
        try BackupService(context: destination.context).restore(from: data)

        let restored = try #require(try destination.activities().first)
        #expect(restored.activeCalories == 540)
        #expect(restored.averageHeartRate == 152)
    }

    /// A backup written before these fields existed must still restore — the
    /// keys are simply absent, and optionals decode as nil.
    @Test func olderBackupsWithoutIntensityStillRestore() throws {
        let source = try makeStore()
        let running = skill("running")
        try source.log(
            Activity(skillID: running.id, name: "Run", durationMinutes: 42, distanceMiles: 5.1),
            skill: running
        )

        var json = try #require(String(data: try BackupService(context: source.context).export(), encoding: .utf8))
        json = json.replacingOccurrences(of: "\"activeCalories\"", with: "\"removedKey\"")
        json = json.replacingOccurrences(of: "\"averageHeartRate\"", with: "\"removedKey2\"")

        let destination = try makeStore()
        try BackupService(context: destination.context).restore(from: Data(json.utf8))

        let restored = try #require(try destination.activities().first)
        #expect(restored.activeCalories == nil)
        #expect(restored.durationMinutes == 42)
    }
}
