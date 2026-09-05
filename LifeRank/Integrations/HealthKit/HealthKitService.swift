import Foundation
import HealthKit

nonisolated enum HealthKitError: LocalizedError {
    case unavailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health is not available on this device. You can continue logging activities manually."
        case .authorizationDenied:
            return "Apple Health access is disabled. You can continue logging activities manually."
        }
    }
}

/// Reads workouts from Apple Health and hands back plain ImportedActivity
/// values. Garmin and Hevy already sync into Health, so LifeRank never talks to
/// them directly (DESIGN.md §2, §18, §20).
nonisolated struct HealthKitService: ActivityProvider {
    private let store = HKHealthStore()

    /// Distance drives running XP. Active energy and heart rate are recorded
    /// rather than used — §20 confirmed both arrive reliably from Garmin and
    /// Hevy, and capturing them now is what lets a future intensity term apply
    /// to history instead of only to sessions logged after it ships.
    private static let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate),
    ]

    /// Adds the distance types the import path does not need, so the diagnostic
    /// can report which one a given source actually populates.
    ///
    /// TEMPORARY — collapses back into `readTypes` with the diagnostic screen.
    private static let diagnosticReadTypes: Set<HKObjectType> = readTypes.union([
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
    ])

    func requestAuthorization() async throws {
        try await requestAuthorization(for: Self.readTypes)
    }

    private func requestAuthorization(for types: Set<HKObjectType>) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: types)
    }

    func fetchActivities(since date: Date) async throws -> [ImportedActivity] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: date, end: nil))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return try await descriptor.result(for: store).map(Self.imported(from:))
    }

    /// HKWorkout stops here — everything past this call is HealthKit-free (§32).
    static func imported(from workout: HKWorkout) -> ImportedActivity {
        let miles = workout
            .statistics(for: HKQuantityType(.distanceWalkingRunning))?
            .sumQuantity()?
            .doubleValue(for: .mile())

        return ImportedActivity(
            id: workout.uuid.uuidString,
            skillID: WorkoutMapping.skillID(for: workout.workoutActivityType),
            name: WorkoutMapping.name(for: workout.workoutActivityType),
            startDate: workout.startDate,
            durationMinutes: workout.duration / 60,
            distanceMiles: (miles ?? 0) > 0 ? miles : nil,
            activeCalories: activeCalories(of: workout),
            averageHeartRate: averageHeartRate(of: workout)
        )
    }

    static func activeCalories(of workout: HKWorkout) -> Double? {
        workout
            .statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie())
    }

    /// Averaged over the workout, in beats per minute.
    static func averageHeartRate(of workout: HKWorkout) -> Double? {
        workout
            .statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute()))
    }

    // MARK: - §20 diagnostic
    //
    // TEMPORARY. Reads workouts and reports what HealthKit actually holds,
    // without awarding XP, persisting anything, or touching progression.

    func fetchDiagnostics(limit: Int = 20) async throws -> [WorkoutDiagnostic] {
        try await requestAuthorization(for: Self.diagnosticReadTypes)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: nil, end: nil))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: limit
        )

        return try await descriptor.result(for: store).map(Self.diagnostic(from:))
    }

    /// Distance lives under a different quantity type per workout, so each
    /// candidate is tried and the one that answered is reported alongside the
    /// value — knowing *which* type carried it is the point of the exercise.
    private static let distanceCandidates: [(label: String, type: HKQuantityType)] = [
        ("distanceWalkingRunning", HKQuantityType(.distanceWalkingRunning)),
        ("distanceCycling", HKQuantityType(.distanceCycling)),
        ("distanceSwimming", HKQuantityType(.distanceSwimming)),
    ]

    static func diagnostic(from workout: HKWorkout) -> WorkoutDiagnostic {
        let distance = distanceCandidates.lazy
            .compactMap { candidate -> (String, Double)? in
                guard let miles = workout.statistics(for: candidate.type)?
                    .sumQuantity()?
                    .doubleValue(for: .mile()),
                      miles > 0
                else { return nil }
                return (candidate.label, miles)
            }
            .first

        let type = workout.workoutActivityType

        return WorkoutDiagnostic(
            id: workout.uuid.uuidString,
            activityTypeName: type.diagnosticName,
            activityTypeRawValue: type.rawValue,
            startDate: workout.startDate,
            durationMinutes: workout.duration / 60,
            sourceName: workout.sourceRevision.source.name,
            distanceMiles: distance?.1,
            distanceQuantityUsed: distance?.0,
            activeCalories: activeCalories(of: workout),
            averageHeartRate: averageHeartRate(of: workout),
            mappedSkillID: WorkoutMapping.skillID(for: type)
        )
    }
}
