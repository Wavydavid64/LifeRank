import Foundation

/// Turns imported workouts into progression, skipping anything already seen and
/// anything it cannot classify (DESIGN.md §21, §36).
@MainActor
struct ActivityImporter {
    let store: ActivityStore

    struct Summary: Equatable {
        var imported = 0
        /// Workouts whose source identifier was already in the ledger.
        var duplicates = 0
        /// Workouts whose type maps to no skill. These award nothing rather
        /// than being guessed at.
        var unclassified = 0
    }

    @discardableResult
    func `import`(_ workouts: [ImportedActivity]) throws -> Summary {
        var summary = Summary()

        for workout in workouts {
            guard let activity = workout.normalized() else {
                summary.unclassified += 1
                continue
            }

            guard try !store.hasImported(externalIdentifier: workout.id) else {
                summary.duplicates += 1
                continue
            }

            guard let skill = SeedData.skills.first(where: { $0.id == activity.skillID }) else {
                summary.unclassified += 1
                continue
            }

            try store.log(activity, skill: skill)
            summary.imported += 1
        }

        return summary
    }
}
