import Foundation
import HealthKit

/// A raw read of one HealthKit workout, for answering DESIGN.md §20: what do
/// Garmin and Hevy actually put into Apple Health?
///
/// TEMPORARY — diagnostic only. Nothing here awards XP, is persisted, or feeds
/// the progression engine. Delete this file and its screen once the mappings
/// and XP formula have been settled against real data.
///
/// Every stored property is a plain value, so the screen that shows this never
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
