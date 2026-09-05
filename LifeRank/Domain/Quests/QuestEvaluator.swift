import Foundation

/// Derives quest progress from logged activities (DESIGN.md §16 — completion
/// comes from Activity data, not from a separate tracker that could drift).
nonisolated enum QuestEvaluator {

    static func progress(
        for quest: Quest,
        activities: [Activity],
        now: Date,
        calendar: Calendar = .current
    ) -> QuestProgress {
        let counted = activities.filter { activity in
            activity.skillID == quest.objective.skillID
                && quest.period.contains(activity.date, now: now, calendar: calendar)
        }

        let current: Double
        switch quest.objective.metric {
        case .minutes:
            current = counted.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        case .miles:
            current = counted.reduce(0) { $0 + ($1.distanceMiles ?? 0) }
        case .sessions:
            current = Double(counted.count)
        }

        return QuestProgress(current: current, target: quest.objective.target)
    }

    /// Quests that cross their target because `activity` was logged — those
    /// already complete beforehand are excluded, so a bonus is paid once.
    ///
    /// `existing` must not contain `activity`.
    static func questsCompleted(
        by activity: Activity,
        existing: [Activity],
        quests: [Quest],
        now: Date,
        calendar: Calendar = .current
    ) -> [Quest] {
        quests.filter { quest in
            let before = progress(for: quest, activities: existing, now: now, calendar: calendar)
            guard !before.isComplete else { return false }

            let after = progress(for: quest, activities: existing + [activity], now: now, calendar: calendar)
            return after.isComplete
        }
    }
}
