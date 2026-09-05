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

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
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
}
