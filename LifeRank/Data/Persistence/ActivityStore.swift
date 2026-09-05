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
        let prior = try activities().filter { $0.date <= activity.date }

        context.insert(ActivityRecord(activity))
        for event in xpEvents(for: activity, skill: skill, prior: prior) {
            context.insert(XPEventRecord(event))
        }

        try saveOrRollback()
    }

    /// Removes an activity and every XPEvent it produced. Events are keyed by
    /// `activityID`, so this leaves no unexplained XP behind (§10, §26).
    ///
    /// An imported workout is also tombstoned, otherwise the next import would
    /// simply bring it back.
    func delete(activityID: Activity.ID) throws {
        let records = try context.fetch(FetchDescriptor<ActivityRecord>())
            .filter { $0.id == activityID }

        for record in records {
            if let identifier = record.externalIdentifier {
                context.insert(IgnoredWorkoutRecord(externalIdentifier: identifier))
            }
            context.delete(record)
        }

        let events = try context.fetch(FetchDescriptor<XPEventRecord>())
            .filter { $0.activityID == activityID }
        events.forEach(context.delete)

        try saveOrRollback()
    }

    /// Applies corrections to a logged activity and rebuilds the ledger.
    ///
    /// A full replay rather than a local patch: changing a duration can change
    /// whether a quest was crossed, and that shifts which *later* activity earns
    /// the bonus. Recomputing only this activity's events would leave the rest
    /// of the ledger describing a history that no longer happened (§26).
    func update(_ activity: Activity) throws {
        guard let record = try context.fetch(FetchDescriptor<ActivityRecord>())
            .first(where: { $0.id == activity.id })
        else { return }

        record.skillID = activity.skillID
        record.name = activity.name
        record.date = activity.date
        record.durationMinutes = activity.durationMinutes
        record.distanceMiles = activity.distanceMiles
        record.notes = activity.notes

        try recalculateXP()
    }

    /// Rebuilds the whole XP ledger from the activities that remain.
    ///
    /// Replays chronologically rather than patching in place, because quest
    /// bonuses depend on what came before — the same reason a partial fixup
    /// would drift. Balance changes to the XP formula are picked up here (§26).
    ///
    /// ponytail: O(n²) — every replayed activity re-evaluates quest progress
    /// over everything before it. At one activity a day that is ~50M operations
    /// after a decade, or a second or two on a button the user pressed. If it
    /// ever drags, carry a running per-quest tally through the loop instead of
    /// refiltering the prefix.
    func recalculateXP() throws {
        let ordered = try activities().sorted { $0.date < $1.date }

        try context.fetch(FetchDescriptor<XPEventRecord>()).forEach(context.delete)

        var replayed: [Activity] = []
        for activity in ordered {
            defer { replayed.append(activity) }
            guard let skill = SeedData.skills.first(where: { $0.id == activity.skillID }) else { continue }

            for event in xpEvents(for: activity, skill: skill, prior: replayed) {
                context.insert(XPEventRecord(event))
            }
        }

        try saveOrRollback()
    }

    /// Earned XP plus any quest bonus the activity triggers, given what was
    /// logged before it.
    private func xpEvents(for activity: Activity, skill: Skill, prior: [Activity]) -> [XPEvent] {
        ProgressionEngine.xpEvents(for: activity, skill: skill)
            + questBonusEvents(for: activity, existing: prior)
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

    private func saveOrRollback() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func activities() throws -> [Activity] {
        try context.fetch(FetchDescriptor<ActivityRecord>()).map(\.domain)
    }

    /// Whether this source workout has already been dealt with — either it is
    /// in the ledger, or the player deleted it and does not want it back.
    /// Guarding on this is what stops one HealthKit workout awarding XP twice,
    /// which DESIGN.md §21 treats as a correctness requirement.
    func hasImported(externalIdentifier: String) throws -> Bool {
        var activityDescriptor = FetchDescriptor<ActivityRecord>(
            predicate: #Predicate { $0.externalIdentifier == externalIdentifier }
        )
        activityDescriptor.fetchLimit = 1
        if try !context.fetch(activityDescriptor).isEmpty { return true }

        var ignoredDescriptor = FetchDescriptor<IgnoredWorkoutRecord>(
            predicate: #Predicate { $0.externalIdentifier == externalIdentifier }
        )
        ignoredDescriptor.fetchLimit = 1
        return try !context.fetch(ignoredDescriptor).isEmpty
    }

    func xpEvents() throws -> [XPEvent] {
        try context.fetch(FetchDescriptor<XPEventRecord>()).map(\.domain)
    }

    func stats() throws -> CharacterStats {
        CharacterStats.derive(from: try xpEvents())
    }
}
