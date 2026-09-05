import Foundation

/// Manually configured quests. DESIGN.md §16 rules out a procedural quest
/// generator for the MVP, so these are hand-written and easy to edit.
enum QuestSeed {
    static let quests: [Quest] = [
        Quest(
            id: "daily-calligraphy",
            title: "Practice Chinese Calligraphy",
            period: .daily,
            objective: QuestObjective(skillID: "chinese-calligraphy", metric: .minutes, target: 30),
            bonusXP: 5
        ),
        Quest(
            id: "weekly-running-distance",
            title: "Run 10 miles this week",
            period: .weekly,
            objective: QuestObjective(skillID: "running", metric: .miles, target: 10),
            bonusXP: 25
        ),
        Quest(
            id: "weekly-strength-sessions",
            title: "Strength train twice this week",
            period: .weekly,
            objective: QuestObjective(skillID: "strength-training", metric: .sessions, target: 2),
            bonusXP: 15
        ),
        Quest(
            id: "first-hike",
            title: "Complete your first hike",
            period: .oneTime,
            objective: QuestObjective(skillID: "hiking", metric: .sessions, target: 1),
            bonusXP: 20
        ),
    ]
}
