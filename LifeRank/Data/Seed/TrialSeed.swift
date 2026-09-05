import Foundation

/// Promotion trials (DESIGN.md §14). Each is a small cross-skill test, so
/// ranking up means demonstrating breadth rather than grinding one activity.
nonisolated enum TrialSeed {

    static let trials: [PromotionTrial] = [
        PromotionTrial(rank: .e, objectives: [
            auto("trial-e-run", "Run 2 miles without stopping", "running",
                 ActivityCriterion(minimumMiles: 2)),
            manual("trial-e-craft", "Complete a focused practice session"),
        ]),
        PromotionTrial(rank: .d, objectives: [
            auto("trial-d-run", "Complete a continuous 5K", "running",
                 ActivityCriterion(minimumMiles: 3.107)),
            auto("trial-d-hike", "Complete a 5 mile hike", "hiking",
                 ActivityCriterion(minimumMiles: 5)),
            manual("trial-d-strength", "Strength benchmark"),
        ]),
        PromotionTrial(rank: .c, objectives: [
            auto("trial-c-run", "Run a sub-30-minute 5K", "running",
                 ActivityCriterion(minimumMiles: 3.107, maximumMinutes: 30)),
            auto("trial-c-endurance", "Complete a 90 minute session", nil,
                 ActivityCriterion(minimumMinutes: 90)),
            manual("trial-c-craft", "Calligraphy milestone"),
        ]),
        PromotionTrial(rank: .b, objectives: [
            auto("trial-b-run", "Run a half marathon", "running",
                 ActivityCriterion(minimumMiles: 13.1)),
            auto("trial-b-hike", "Complete a 10 mile hike", "hiking",
                 ActivityCriterion(minimumMiles: 10)),
            manual("trial-b-strength", "Strength benchmark"),
        ]),
        PromotionTrial(rank: .a, objectives: [
            auto("trial-a-run", "Run a marathon", "running",
                 ActivityCriterion(minimumMiles: 26.2)),
            manual("trial-a-strength", "Advanced strength benchmark"),
            manual("trial-a-craft", "Complete a body of work"),
        ]),
        PromotionTrial(rank: .s, objectives: [
            auto("trial-s-run", "Run a sub-4-hour marathon", "running",
                 ActivityCriterion(minimumMiles: 26.2, maximumMinutes: 240)),
            manual("trial-s-strength", "Competition total"),
            manual("trial-s-craft", "Exhibit or publish your work"),
        ]),
    ]

    private static func auto(
        _ id: String,
        _ title: String,
        _ skillID: Skill.ID?,
        _ criterion: ActivityCriterion
    ) -> Objective {
        Objective(id: id, title: title, skillID: skillID, criterion: .singleActivity(criterion))
    }

    private static func manual(_ id: String, _ title: String) -> Objective {
        Objective(id: id, title: title, skillID: nil, criterion: .manual)
    }
}
