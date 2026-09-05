import Foundation
import SwiftData

/// Writes activities and the XP they generate, and reads progression back out.
/// The XP itself is calculated by the domain layer — this type only persists.
@MainActor
struct ActivityStore {
    let context: ModelContext

    /// Saves an activity together with every XPEvent it produces, as one
    /// transaction. A failed save rolls back rather than leaving an activity
    /// with partial or missing XP (DESIGN.md §36).
    func log(_ activity: Activity, skill: Skill) throws {
        let existing = try activities()

        context.insert(ActivityRecord(activity))
        for event in ProgressionEngine.xpEvents(for: activity, skill: skill) {
            context.insert(XPEventRecord(event))
        }

        for event in questBonusEvents(for: activity, existing: existing) {
            context.insert(XPEventRecord(event))
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Bonus XP for any quest this activity pushes over its target. Evaluated
    /// against the activity's own date so a backdated entry is judged in the
    /// window it belongs to.
    private func questBonusEvents(for activity: Activity, existing: [Activity]) -> [XPEvent] {
        let completed = QuestEvaluator.questsCompleted(
            by: activity,
            existing: existing,
            quests: QuestSeed.quests,
            now: activity.date
        )

        return completed.flatMap { quest -> [XPEvent] in
            guard quest.bonusXP > 0,
                  let skill = SeedData.skills.first(where: { $0.id == quest.objective.skillID })
            else { return [] }

            return ProgressionEngine.xpEvents(
                activityID: activity.id,
                skill: skill,
                amount: quest.bonusXP,
                date: activity.date
            )
        }
    }

    func activities() throws -> [Activity] {
        try context.fetch(FetchDescriptor<ActivityRecord>()).map(\.domain)
    }

    /// Whether a workout with this source identifier has already been imported.
    /// Guarding on this is what stops one HealthKit workout awarding XP twice,
    /// which DESIGN.md §21 treats as a correctness requirement.
    func hasImported(externalIdentifier: String) throws -> Bool {
        var descriptor = FetchDescriptor<ActivityRecord>(
            predicate: #Predicate { $0.externalIdentifier == externalIdentifier }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func xpEvents() throws -> [XPEvent] {
        try context.fetch(FetchDescriptor<XPEventRecord>()).map(\.domain)
    }

    func stats() throws -> CharacterStats {
        CharacterStats.derive(from: try xpEvents())
    }
}
