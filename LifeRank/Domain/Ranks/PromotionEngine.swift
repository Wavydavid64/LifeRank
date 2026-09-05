import Foundation

/// One requirement row on the promotion screen (DESIGN.md §23, §27).
nonisolated struct RequirementProgress: Equatable {
    let current: Int
    let required: Int

    var isMet: Bool { current >= required }
    var fraction: Double {
        guard required > 0 else { return 1 }
        return min(Double(current) / Double(required), 1)
    }
}

/// Everything the player needs to know about their next promotion.
nonisolated struct PromotionStatus: Equatable {
    let currentRank: Rank
    let nextRank: Rank?
    let xp: RequirementProgress
    let skills: RequirementProgress
    let attributes: RequirementProgress
    /// Trial objectives with whether each is done, in configured order.
    let trial: [(objective: Objective, isComplete: Bool)]

    /// The progression gates, ignoring the trial. The trial stays locked until
    /// these are all met (§27).
    var progressionMet: Bool { xp.isMet && skills.isMet && attributes.isMet }

    var trialUnlocked: Bool { progressionMet }

    var trialComplete: Bool { !trial.isEmpty && trial.allSatisfy(\.isComplete) }

    /// Eligible to promote. Promotion still requires an explicit user action —
    /// nothing here changes rank on its own (§3.4, §14).
    var canPromote: Bool { nextRank != nil && progressionMet && trialComplete }

    static func == (lhs: PromotionStatus, rhs: PromotionStatus) -> Bool {
        lhs.currentRank == rhs.currentRank
            && lhs.nextRank == rhs.nextRank
            && lhs.xp == rhs.xp
            && lhs.skills == rhs.skills
            && lhs.attributes == rhs.attributes
            && lhs.trial.map(\.objective) == rhs.trial.map(\.objective)
            && lhs.trial.map(\.isComplete) == rhs.trial.map(\.isComplete)
    }
}

/// Evaluates promotion eligibility. Pure — no SwiftUI, SwiftData or HealthKit.
nonisolated enum PromotionEngine {

    static func status(
        currentRank: Rank,
        stats: CharacterStats,
        skillRanks: [Skill.ID: Rank],
        activities: [Activity],
        trials: [PromotionTrial],
        manualCompletions: Set<String>
    ) -> PromotionStatus {
        guard let nextRank = currentRank.next,
              let definition = RankRequirements.definition(for: nextRank) else {
            return PromotionStatus(
                currentRank: currentRank,
                nextRank: nil,
                xp: RequirementProgress(current: stats.totalXP, required: 0),
                skills: RequirementProgress(current: 0, required: 0),
                attributes: RequirementProgress(current: 0, required: 0),
                trial: []
            )
        }

        let qualifyingSkills = skillRanks.values.count { $0 >= definition.requiredSkillRank }

        let qualifyingAttributes = Attribute.allCases.count { attribute in
            AttributeProgression.level(forXP: stats.attributeXP[attribute] ?? 0) >= definition.minimumAttributeLevel
        }

        let objectives = trials.first { $0.rank == nextRank }?.objectives ?? []
        let trial = objectives.map { objective in
            (
                objective: objective,
                isComplete: ObjectiveEvaluator.isSatisfied(
                    objective,
                    activities: activities,
                    manualCompletions: manualCompletions
                )
            )
        }

        return PromotionStatus(
            currentRank: currentRank,
            nextRank: nextRank,
            xp: RequirementProgress(current: stats.totalXP, required: definition.xpRequired),
            skills: RequirementProgress(current: qualifyingSkills, required: definition.requiredSkillCount),
            attributes: RequirementProgress(current: qualifyingAttributes, required: definition.requiredAttributeCount),
            trial: trial
        )
    }
}
