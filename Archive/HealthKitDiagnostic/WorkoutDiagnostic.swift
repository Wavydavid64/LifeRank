import Foundation
import HealthKit

// ARCHIVED — not part of the app target. See Archive/HealthKitDiagnostic/README.md.
//
// Self-contained on purpose: it owns its HKHealthStore and authorization request
// rather than reaching into HealthKitService, so restoring it is a file move and
// nothing else. Nothing here awards XP, persists anything, or touches the
// progression engine.

/// A raw read of one HealthKit workout, for answering DESIGN.md §20: what do
/// Garmin, Hevy and friends actually put into Apple Health?
///
/// Every stored property is a plain value, so the screen showing this never
/// imports HealthKit (§32).
nonisolated struct WorkoutDiagnostic: Identifiable, Hashable {
    let id: String
    let activityTypeName: String
    /// The raw enum value. This is the part that actually settles a mapping
    /// question — names are for reading, this is for `WorkoutMapping`.
    let activityTypeRawValue: UInt
    let startDate: Date
    let durationMinutes: Double
    let sourceName: String
    let distanceMiles: Double?
    let distanceQuantityUsed: String?
    let activeCalories: Double?
    let averageHeartRate: Double?
    /// Which skill this would import as today, or nil if nothing maps it.
    let mappedSkillID: Skill.ID?

    var isMapped: Bool { mappedSkillID != nil }
}

/// Reads recent workouts and reports what HealthKit actually holds.
nonisolated struct HealthKitDiagnosticService {
    private let store = HKHealthStore()

    /// Wider than the import path needs, so the report can say which distance
    /// type a given source populates.
    private static let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate),
    ]

    /// Distance lives under a different quantity type per workout, so each
    /// candidate is tried and the one that answered is reported alongside the
    /// value — knowing *which* type carried it is the point of the exercise.
    private static let distanceCandidates: [(label: String, type: HKQuantityType)] = [
        ("distanceWalkingRunning", HKQuantityType(.distanceWalkingRunning)),
        ("distanceCycling", HKQuantityType(.distanceCycling)),
        ("distanceSwimming", HKQuantityType(.distanceSwimming)),
    ]

    func fetchDiagnostics(limit: Int = 20) async throws -> [WorkoutDiagnostic] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: nil, end: nil))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: limit
        )

        return try await descriptor.result(for: store).map(Self.diagnostic(from:))
    }

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
            activeCalories: workout
                .statistics(for: HKQuantityType(.activeEnergyBurned))?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()),
            averageHeartRate: workout
                .statistics(for: HKQuantityType(.heartRate))?
                .averageQuantity()?
                .doubleValue(for: .count().unitDivided(by: .minute())),
            mappedSkillID: WorkoutMapping.skillID(for: type)
        )
    }
}

extension HKWorkoutActivityType {
    /// Readable names for the types plausibly produced by Garmin, Hevy and the
    /// Fitness app. Anything else falls back to its raw value, which is all
    /// that is needed to extend `WorkoutMapping`.
    nonisolated var diagnosticName: String {
        switch self {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .hiking: return "hiking"
        case .traditionalStrengthTraining: return "traditionalStrengthTraining"
        case .functionalStrengthTraining: return "functionalStrengthTraining"
        case .coreTraining: return "coreTraining"
        case .highIntensityIntervalTraining: return "highIntensityIntervalTraining"
        case .yoga: return "yoga"
        case .flexibility: return "flexibility"
        case .preparationAndRecovery: return "preparationAndRecovery"
        case .paddleSports: return "paddleSports"
        case .rowing: return "rowing"
        case .swimming: return "swimming"
        case .elliptical: return "elliptical"
        case .stairClimbing: return "stairClimbing"
        case .mixedCardio: return "mixedCardio"
        case .crossTraining: return "crossTraining"
        case .other: return "other"
        default: return "unnamed"
        }
    }
}
