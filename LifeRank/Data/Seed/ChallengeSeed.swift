import Foundation

/// Skill challenges (DESIGN.md §13). Quantifiable skills are detected from
/// logged activities; qualitative ones are marked complete by hand.
///
/// A 5K is 3.107 miles. Strength challenges are manual because Hevy may not
/// expose sets, reps or weight through Apple Health (§20).
enum ChallengeSeed {

    static let challenges: [SkillChallenge] =
        running + cycling + hiking + kayaking
        + strengthTraining + yoga + stretching
        + calligraphy + painting + musicPractice + reading

    private static let cycling: [SkillChallenge] = [
        challenge("cycling", .e, "cycle-e", "Ride 10 miles", ActivityCriterion(minimumMiles: 10)),
        challenge("cycling", .d, "cycle-d", "Ride 25 miles", ActivityCriterion(minimumMiles: 25)),
        challenge("cycling", .c, "cycle-c", "Ride 50 miles", ActivityCriterion(minimumMiles: 50)),
        challenge("cycling", .b, "cycle-b", "Ride a century", ActivityCriterion(minimumMiles: 100)),
        manualChallenge("cycling", .a, "cycle-a", "Complete a multi-day tour"),
        manualChallenge("cycling", .s, "cycle-s", "Complete a long-distance tour"),
    ]

    private static let kayaking: [SkillChallenge] = [
        challenge("kayaking", .e, "kayak-e", "Paddle 2 miles", ActivityCriterion(minimumMiles: 2)),
        challenge("kayaking", .d, "kayak-d", "Paddle 5 miles", ActivityCriterion(minimumMiles: 5)),
        challenge("kayaking", .c, "kayak-c", "Paddle 10 miles", ActivityCriterion(minimumMiles: 10)),
        challenge("kayaking", .b, "kayak-b", "Paddle 15 miles", ActivityCriterion(minimumMiles: 15)),
        manualChallenge("kayaking", .a, "kayak-a", "Complete an open-water crossing"),
        manualChallenge("kayaking", .s, "kayak-s", "Complete a multi-day expedition"),
    ]

    private static let yoga: [SkillChallenge] = [
        challenge("yoga", .e, "yoga-e", "Complete a 30 minute session",
                  ActivityCriterion(minimumMinutes: 30)),
        challenge("yoga", .d, "yoga-d", "Complete a 60 minute session",
                  ActivityCriterion(minimumMinutes: 60)),
        challenge("yoga", .c, "yoga-c", "Complete a 90 minute session",
                  ActivityCriterion(minimumMinutes: 90)),
        manualChallenge("yoga", .b, "yoga-b", "Hold an unsupported inversion"),
        manualChallenge("yoga", .a, "yoga-a", "Complete an advanced sequence unaided"),
        manualChallenge("yoga", .s, "yoga-s", "Lead a class"),
    ]

    /// Flexibility milestones are things you can see in a mirror, not things a
    /// duration can prove, so the upper ranks are marked by hand.
    private static let stretching: [SkillChallenge] = [
        challenge("stretching", .e, "stretch-e", "Complete a 15 minute session",
                  ActivityCriterion(minimumMinutes: 15)),
        challenge("stretching", .d, "stretch-d", "Complete a 30 minute session",
                  ActivityCriterion(minimumMinutes: 30)),
        manualChallenge("stretching", .c, "stretch-c", "Touch your toes cold"),
        manualChallenge("stretching", .b, "stretch-b", "Hold a full front split"),
        manualChallenge("stretching", .a, "stretch-a", "Hold a full middle split"),
        manualChallenge("stretching", .s, "stretch-s", "Hold a full bridge from standing"),
    ]

    private static let painting: [SkillChallenge] = [
        manualChallenge("painting", .e, "paint-e", "Complete a finished piece"),
        manualChallenge("painting", .d, "paint-d", "Complete a study from life"),
        manualChallenge("painting", .c, "paint-c", "Complete a full composition"),
        manualChallenge("painting", .b, "paint-b", "Complete a piece worth framing"),
        manualChallenge("painting", .a, "paint-a", "Complete a body of work"),
        manualChallenge("painting", .s, "paint-s", "Exhibit your work"),
    ]

    private static let musicPractice: [SkillChallenge] = [
        manualChallenge("music-practice", .e, "music-e", "Play a piece from memory"),
        manualChallenge("music-practice", .d, "music-d", "Perform for someone"),
        manualChallenge("music-practice", .c, "music-c", "Perform in public"),
        manualChallenge("music-practice", .b, "music-b", "Learn a full-length work"),
        manualChallenge("music-practice", .a, "music-a", "Perform a full recital"),
        manualChallenge("music-practice", .s, "music-s", "Compose and perform your own work"),
    ]

    private static let reading: [SkillChallenge] = [
        manualChallenge("reading", .e, "read-e", "Finish a book"),
        manualChallenge("reading", .d, "read-d", "Finish five books"),
        manualChallenge("reading", .c, "read-c", "Finish a demanding technical work"),
        manualChallenge("reading", .b, "read-b", "Finish twenty-five books"),
        manualChallenge("reading", .a, "read-a", "Finish a full-length work in a second language"),
        manualChallenge("reading", .s, "read-s", "Finish one hundred books"),
    ]

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
