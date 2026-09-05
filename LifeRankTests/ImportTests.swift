import Testing
import Foundation
import SwiftData
import HealthKit
@testable import LifeRank

@MainActor
struct ImportTests {

    private func makeStore() throws -> ActivityStore {
        let container = try ModelContainer(
            for: ActivityRecord.self, XPEventRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ActivityStore(context: ModelContext(container))
    }

    private func workout(
        id: String = "HK-1",
        skillID: Skill.ID? = "running",
        minutes: Double = 42,
        miles: Double? = 5.1
    ) -> ImportedActivity {
        ImportedActivity(
            id: id,
            skillID: skillID,
            name: "Morning Run",
            startDate: .now,
            durationMinutes: minutes,
            distanceMiles: miles
        )
    }

    // MARK: - Mapping (§19)

    @Test func healthKitWorkoutTypesMapToSkills() {
        #expect(WorkoutMapping.skillID(for: .running) == "running")
        #expect(WorkoutMapping.skillID(for: .hiking) == "hiking")
        #expect(WorkoutMapping.skillID(for: .traditionalStrengthTraining) == "strength-training")
    }

    @Test func untrackedWorkoutTypesMapToNothing() {
        #expect(WorkoutMapping.skillID(for: .swimming) == nil)
        #expect(WorkoutMapping.skillID(for: .yoga) == nil)
    }

    @Test func everyMappedSkillExistsInSeedData() {
        for id in WorkoutMapping.skillIDsByWorkoutType.values {
            #expect(SeedData.skills.contains { $0.id == id }, "mapping points at unknown skill \(id)")
        }
    }

    // MARK: - Normalization (§32)

    @Test func normalizationCarriesTheSourceIdentifier() throws {
        let activity = try #require(workout(id: "HK-abc").normalized())

        #expect(activity.externalIdentifier == "HK-abc")
        #expect(activity.skillID == "running")
        #expect(activity.durationMinutes == 42)
        #expect(activity.distanceMiles == 5.1)
    }

    @Test func unclassifiedWorkoutDoesNotNormalize() {
        #expect(workout(skillID: nil).normalized() == nil)
    }

    // MARK: - Deduplication (§21)

    /// The correctness requirement: one HealthKit workout, one award, no matter
    /// how many times the importer runs.
    @Test func sameWorkoutCannotAwardXPTwice() throws {
        let store = try makeStore()
        let importer = ActivityImporter(store: store)

        let first = try importer.import([workout()])
        let second = try importer.import([workout()])

        #expect(first == .init(imported: 1, duplicates: 0, unclassified: 0))
        #expect(second == .init(imported: 0, duplicates: 1, unclassified: 0))
        #expect(try store.stats().skillXP["running"] == 80)
    }

    @Test func duplicatesInsideASingleBatchAreCaught() throws {
        let store = try makeStore()

        let summary = try ActivityImporter(store: store).import([workout(), workout()])

        #expect(summary == .init(imported: 1, duplicates: 1, unclassified: 0))
        #expect(try store.stats().skillXP["running"] == 80)
    }

    /// Short runs on purpose: two 5.1 mile imports would clear the weekly
    /// 10 mile quest and fold a bonus into the total, which has nothing to do
    /// with what this test is checking.
    @Test func distinctWorkoutsBothImport() throws {
        let store = try makeStore()

        let summary = try ActivityImporter(store: store)
            .import([workout(id: "HK-1", miles: 2), workout(id: "HK-2", miles: 2)])

        #expect(summary == .init(imported: 2, duplicates: 0, unclassified: 0))
        // 42 min + 2 mi * 7.5 = 57 XP each.
        #expect(try store.stats().skillXP["running"] == 114)
    }

    // MARK: - Unclassified workouts (§36)

    @Test func unclassifiedWorkoutAwardsNothing() throws {
        let store = try makeStore()

        let summary = try ActivityImporter(store: store).import([workout(skillID: nil)])

        #expect(summary == .init(imported: 0, duplicates: 0, unclassified: 1))
        #expect(try store.stats().totalXP == 0)
    }

    @Test func importedWorkoutsFlowThroughTheSameXPPipelineAsManualEntries() throws {
        let store = try makeStore()

        try ActivityImporter(store: store).import([workout()])

        // Identical to the manual-entry expectation for a 42 min / 5.1 mi run.
        let stats = try store.stats()
        #expect(stats.skillXP["running"] == 80)
        #expect(stats.attributeXP[.endurance] == 56)
        #expect(stats.attributeXP[.discipline] == 16)
        #expect(stats.attributeXP[.exploration] == 8)
    }
}
