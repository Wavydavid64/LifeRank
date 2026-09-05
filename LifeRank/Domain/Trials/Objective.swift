import Foundation

/// Thresholds a single activity must meet. All bounds are optional; those left
/// nil are not checked.
struct ActivityCriterion: Codable, Hashable {
    var minimumMiles: Double?
    var minimumMinutes: Double?
    var maximumMinutes: Double?

    func matches(_ activity: Activity) -> Bool {
        if let minimumMiles, (activity.distanceMiles ?? 0) < minimumMiles { return false }
        if let minimumMinutes, (activity.durationMinutes ?? 0) < minimumMinutes { return false }
        if let maximumMinutes, (activity.durationMinutes ?? .infinity) > maximumMinutes { return false }
        return true
    }
}

enum ObjectiveCriterion: Codable, Hashable {
    /// Satisfied by one activity clearing the thresholds — a continuous 5K, a
    /// sub-25-minute 5K (DESIGN.md §13).
    case singleActivity(ActivityCriterion)
    /// Qualitative work the app cannot measure, marked done by the user.
    /// §13 permits this for the MVP and rules out AI judging.
    case manual
}

/// One demonstrable requirement. Shared by skill challenges and promotion
/// trials so both are evaluated the same way.
struct Objective: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    /// Which skill's activities count. Nil means any skill.
    let skillID: Skill.ID?
    let criterion: ObjectiveCriterion

    var isManual: Bool {
        if case .manual = criterion { return true }
        return false
    }
}

enum ObjectiveEvaluator {

    static func isSatisfied(
        _ objective: Objective,
        activities: [Activity],
        manualCompletions: Set<String>
    ) -> Bool {
        switch objective.criterion {
        case .manual:
            return manualCompletions.contains(objective.id)

        case .singleActivity(let criterion):
            return activities.contains { activity in
                guard objective.skillID == nil || activity.skillID == objective.skillID else { return false }
                return criterion.matches(activity)
            }
        }
    }
}
