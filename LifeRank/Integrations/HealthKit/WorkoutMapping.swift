import Foundation
import HealthKit

/// The one place HealthKit workout types turn into LifeRank skills
/// (DESIGN.md §19). Keeping this centralized stops workout-type switches
/// spreading through the app.
nonisolated enum WorkoutMapping {

    static let skillIDsByWorkoutType: [HKWorkoutActivityType: Skill.ID] = [
        .running: "running",
        .cycling: "cycling",
        .hiking: "hiking",
        .paddleSports: "kayaking",
        // Hevy reports traditional; Apple Watch and several other apps report
        // functional for the same activity (§20).
        .traditionalStrengthTraining: "strength-training",
        .functionalStrengthTraining: "strength-training",
        .yoga: "yoga",
        .flexibility: "stretching",
    ]

    /// Nil for workout types LifeRank does not track. Unmapped workouts are
    /// left alone rather than being forced into a skill (§36).
    static func skillID(for type: HKWorkoutActivityType) -> Skill.ID? {
        skillIDsByWorkoutType[type]
    }

    /// Display name for an imported workout, taken from the mapped skill so
    /// history reads in the app's own vocabulary.
    static func name(for type: HKWorkoutActivityType) -> String {
        guard let id = skillID(for: type),
              let skill = SeedData.skills.first(where: { $0.id == id }) else {
            return "Workout"
        }
        return skill.name
    }
}
