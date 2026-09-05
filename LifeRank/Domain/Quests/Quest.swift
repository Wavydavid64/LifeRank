import Foundation

/// How often a quest's window resets (DESIGN.md §16).
nonisolated enum QuestPeriod: String, Codable, CaseIterable {
    case daily
    case weekly
    case oneTime

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .oneTime: return "One-time"
        }
    }

    /// Whether an activity falls inside the window this quest is measured over.
    /// `now` and `calendar` are passed in rather than read from the environment
    /// so progression stays deterministic and testable (§32).
    func contains(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .daily:
            return calendar.isDate(date, inSameDayAs: now)
        case .weekly:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .oneTime:
            return date <= now
        }
    }
}

/// What a quest counts.
nonisolated enum QuestMetric: String, Codable {
    case minutes
    case miles
    case sessions
}

nonisolated struct QuestObjective: Codable, Hashable {
    let skillID: Skill.ID
    let metric: QuestMetric
    let target: Double
}

/// A short-term objective. Quests give direction; they never reward using the
/// app, only doing the activity (§3.1).
nonisolated struct Quest: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let period: QuestPeriod
    let objective: QuestObjective
    /// Awarded once when the quest crosses its target. Kept small — §16 warns
    /// bonus XP must not overwhelm the XP earned by doing the activity.
    var bonusXP: Int = 0
}

nonisolated struct QuestProgress: Equatable {
    let current: Double
    let target: Double

    var isComplete: Bool { current >= target }

    var fraction: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1)
    }
}
