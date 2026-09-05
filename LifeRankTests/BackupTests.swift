import Testing
import Foundation
import SwiftData
@testable import LifeRank

@MainActor
struct BackupTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            CharacterRecord.self, ObjectiveCompletionRecord.self, IgnoredWorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func skill(_ id: Skill.ID) -> Skill {
        SeedData.skills.first { $0.id == id }!
    }

    /// A context holding a bit of everything a backup has to survive.
    private func populated() throws -> ModelContext {
        let context = try makeContext()
        let store = ActivityStore(context: context)
        let characters = CharacterStore(context: context)

        try store.log(
            Activity(skillID: "running", name: "Run", durationMinutes: 42, distanceMiles: 5.1),
            skill: skill("running")
        )
        try ActivityImporter(store: store).import([
            ImportedActivity(
                id: "HK-1", skillID: "hiking", name: "Hiking",
                startDate: .now, durationMinutes: 120, distanceMiles: 6
            )
        ])
        try characters.setCompleted(true, objectiveID: "trial-e-craft")

        // An ignored workout, produced by deleting an import.
        try store.log(
            Activity(skillID: "running", name: "Bad import", durationMinutes: 10, externalIdentifier: "HK-junk"),
            skill: skill("running")
        )
        let junk = try #require(try store.activities().first { $0.externalIdentifier == "HK-junk" })
        try store.delete(activityID: junk.id)

        return context
    }

    // MARK: - Document shape (§30)

    @Test func exportIsVersionedAndCarriesEveryUnderivableThing() throws {
        let document = try BackupService(context: try populated()).makeDocument()

        #expect(document.version == BackupDocument.currentVersion)
        #expect(document.activities.count == 2)
        #expect(!document.xpEvents.isEmpty)
        #expect(document.manualCompletions == ["trial-e-craft"])
        #expect(document.ignoredWorkouts == ["HK-junk"])
        #expect(document.rank == .f)
    }

    @Test func exportRecordsTheConfigurationItWasMadeUnder() throws {
        let document = try BackupService(context: try makeContext()).makeDocument()

        #expect(document.configuration.skills == SeedData.skills)
        #expect(document.configuration.quests == QuestSeed.quests)
    }

    @Test func exportedJSONUsesReadableDatesAndStableKeyOrder() throws {
        let data = try BackupService(context: try populated()).export()
        let text = try #require(String(data: data, encoding: .utf8))

        #expect(text.contains("\"version\" : 1"))
        // ISO-8601, not a floating-point reference date.
        #expect(text.contains("\"exportedAt\" : \"20"))
    }

    // MARK: - Round trip

    @Test func restoringAnExportReproducesProgressionExactly() throws {
        let source = try populated()
        let data = try BackupService(context: source).export()
        let before = try ActivityStore(context: source).stats()

        let destination = try makeContext()
        try BackupService(context: destination).restore(from: data)

        #expect(try ActivityStore(context: destination).stats() == before)
        #expect(try CharacterStore(context: destination).manualCompletions() == ["trial-e-craft"])
    }

    /// The tombstone has to survive, or restoring would let a deleted workout
    /// walk back in on the next import (§21, §26).
    @Test func restoredBackupStillRefusesAnIgnoredWorkout() throws {
        let data = try BackupService(context: try populated()).export()

        let destination = try makeContext()
        try BackupService(context: destination).restore(from: data)

        #expect(try ActivityStore(context: destination).hasImported(externalIdentifier: "HK-junk"))
    }

    @Test func restoredRankSurvives() throws {
        let source = try makeContext()
        let characters = CharacterStore(context: source)
        let character = try characters.character()
        character.rank = .d

        let data = try BackupService(context: source).export()

        let destination = try makeContext()
        try BackupService(context: destination).restore(from: data)

        #expect(try CharacterStore(context: destination).rank() == .d)
    }

    // MARK: - Restore semantics

    /// Restore replaces rather than merges — merging two ledgers that share
    /// history would double-count it.
    @Test func restoreReplacesExistingData() throws {
        let empty = try BackupService(context: try makeContext()).export()

        let destination = try populated()
        #expect(try ActivityStore(context: destination).stats().totalXP > 0)

        try BackupService(context: destination).restore(from: empty)

        #expect(try ActivityStore(context: destination).activities().isEmpty)
        #expect(try ActivityStore(context: destination).stats().totalXP == 0)
        #expect(try CharacterStore(context: destination).manualCompletions().isEmpty)
    }

    @Test func restoreIsIdempotent() throws {
        let data = try BackupService(context: try populated()).export()

        let destination = try makeContext()
        try BackupService(context: destination).restore(from: data)
        let once = try ActivityStore(context: destination).stats()

        try BackupService(context: destination).restore(from: data)

        #expect(try ActivityStore(context: destination).stats() == once)
        #expect(try ActivityStore(context: destination).activities().count == 2)
    }

    @Test func aBackupFromANewerAppIsRefused() throws {
        var json = try #require(
            String(data: try BackupService(context: try makeContext()).export(), encoding: .utf8)
        )
        json = json.replacingOccurrences(of: "\"version\" : 1", with: "\"version\" : 99")

        let destination = try makeContext()

        #expect(throws: BackupError.self) {
            try BackupService(context: destination).restore(from: Data(json.utf8))
        }
    }

    @Test func garbledJSONIsRejectedWithoutTouchingExistingData() throws {
        let destination = try populated()
        let before = try ActivityStore(context: destination).stats()

        #expect(throws: (any Error).self) {
            try BackupService(context: destination).restore(from: Data("not json".utf8))
        }

        #expect(try ActivityStore(context: destination).stats() == before)
    }
}
