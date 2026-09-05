import Foundation

/// Manually configured quests. DESIGN.md §16 rules out a procedural quest
/// generator for the MVP, so these are hand-written and easy to edit.
nonisolated enum QuestSeed {
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
        Quest(
            id: "daily-reading",
            title: "Read for 20 minutes",
            period: .daily,
            objective: QuestObjective(skillID: "reading", metric: .minutes, target: 20),
            bonusXP: 3
        ),
        Quest(
            id: "daily-stretching",
            title: "Stretch for 15 minutes",
            period: .daily,
            objective: QuestObjective(skillID: "stretching", metric: .minutes, target: 15),
            bonusXP: 3
        ),
        Quest(
            id: "weekly-cycling-distance",
            title: "Ride 20 miles this week",
            period: .weekly,
            objective: QuestObjective(skillID: "cycling", metric: .miles, target: 20),
            bonusXP: 25
        ),
        Quest(
            id: "weekly-yoga-sessions",
            title: "Practice yoga twice this week",
            period: .weekly,
            objective: QuestObjective(skillID: "yoga", metric: .sessions, target: 2),
            bonusXP: 12
        ),
        Quest(
            id: "weekly-music-sessions",
            title: "Practice music three times this week",
            period: .weekly,
            objective: QuestObjective(skillID: "music-practice", metric: .sessions, target: 3),
            bonusXP: 12
        ),
        Quest(
            id: "first-kayak",
            title: "Complete your first paddle",
            period: .oneTime,
            objective: QuestObjective(skillID: "kayaking", metric: .sessions, target: 1),
            bonusXP: 20
        ),
        Quest(
            id: "first-painting",
            title: "Complete your first painting session",
            period: .oneTime,
            objective: QuestObjective(skillID: "painting", metric: .sessions, target: 1),
            bonusXP: 10
        ),
    ]
}
