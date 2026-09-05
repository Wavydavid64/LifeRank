import Foundation

/// Skill challenges (DESIGN.md §13). Quantifiable skills are detected from
/// logged activities; qualitative ones are marked complete by hand.
///
/// A 5K is 3.107 miles. Strength challenges are manual because Hevy may not
/// expose sets, reps or weight through Apple Health (§20).
enum ChallengeSeed {

    static let challenges: [SkillChallenge] = running + strengthTraining + hiking + calligraphy

    private static let running: [SkillChallenge] = [
        challenge("running", .e, "run-e", "Complete a continuous 5K",
                  ActivityCriterion(minimumMiles: 3.107)),
        challenge("running", .d, "run-d", "Run a sub-30-minute 5K",
                  ActivityCriterion(minimumMiles: 3.107, maximumMinutes: 30)),
        challenge("running", .c, "run-c", "Run a sub-25-minute 5K",
                  ActivityCriterion(minimumMiles: 3.107, maximumMinutes: 25)),
        challenge("running", .b, "run-b", "Run a half marathon",
                  ActivityCriterion(minimumMiles: 13.1)),
        challenge("running", .a, "run-a", "Run a marathon",
                  ActivityCriterion(minimumMiles: 26.2)),
        challenge("running", .s, "run-s", "Run a sub-4-hour marathon",
                  ActivityCriterion(minimumMiles: 26.2, maximumMinutes: 240)),
    ]

    private static let hiking: [SkillChallenge] = [
        challenge("hiking", .e, "hike-e", "Complete a 5 mile hike",
                  ActivityCriterion(minimumMiles: 5)),
        challenge("hiking", .d, "hike-d", "Complete a 10 mile hike",
                  ActivityCriterion(minimumMiles: 10)),
        challenge("hiking", .c, "hike-c", "Complete a 15 mile hike",
                  ActivityCriterion(minimumMiles: 15)),
        manualChallenge("hiking", .b, "hike-b", "Complete a multi-day hike"),
        manualChallenge("hiking", .a, "hike-a", "Summit a major peak"),
        manualChallenge("hiking", .s, "hike-s", "Complete a long-distance trail"),
    ]

    private static let strengthTraining: [SkillChallenge] = [
        manualChallenge("strength-training", .e, "strength-e", "Train consistently for a month"),
        manualChallenge("strength-training", .d, "strength-d", "Bodyweight bench press"),
        manualChallenge("strength-training", .c, "strength-c", "Bodyweight squat for reps"),
        manualChallenge("strength-training", .b, "strength-b", "1.5x bodyweight deadlift"),
        manualChallenge("strength-training", .a, "strength-a", "2x bodyweight deadlift"),
        manualChallenge("strength-training", .s, "strength-s", "Competition total"),
    ]

    private static let calligraphy: [SkillChallenge] = ["chinese-calligraphy", "western-calligraphy"]
        .flatMap { skillID -> [SkillChallenge] in
            [
                manualChallenge(skillID, .e, "\(skillID)-e", "Complete foundational practice requirements"),
                manualChallenge(skillID, .d, "\(skillID)-d", "Complete a defined practice milestone"),
                manualChallenge(skillID, .c, "\(skillID)-c", "Complete a full calligraphy work"),
                manualChallenge(skillID, .b, "\(skillID)-b", "Complete a piece worth displaying"),
                manualChallenge(skillID, .a, "\(skillID)-a", "Complete a body of work"),
                manualChallenge(skillID, .s, "\(skillID)-s", "Exhibit or publish your work"),
            ]
        }

    private static func challenge(
        _ skillID: Skill.ID,
        _ rank: Rank,
        _ id: String,
        _ title: String,
        _ criterion: ActivityCriterion
    ) -> SkillChallenge {
        SkillChallenge(
            skillID: skillID,
            rank: rank,
            objective: Objective(id: id, title: title, skillID: skillID, criterion: .singleActivity(criterion))
        )
    }

    private static func manualChallenge(
        _ skillID: Skill.ID,
        _ rank: Rank,
        _ id: String,
        _ title: String
    ) -> SkillChallenge {
        SkillChallenge(
            skillID: skillID,
            rank: rank,
            objective: Objective(id: id, title: title, skillID: skillID, criterion: .manual)
        )
    }
}
