import SwiftUI
import SwiftData

/// One skill: rank, XP toward the next rank, what it feeds, and recent
/// sessions (DESIGN.md §25).
struct SkillDetailView: View {
    let skill: Skill

    @Environment(\.modelContext) private var context

    @Query private var events: [XPEventRecord]
    @Query private var activities: [ActivityRecord]
    @Query private var allActivities: [ActivityRecord]
    @Query private var completions: [ObjectiveCompletionRecord]

    @State private var errorMessage: String?

    init(skill: Skill) {
        self.skill = skill
        let id = skill.id
        _activities = Query(
            filter: #Predicate<ActivityRecord> { $0.skillID == id },
            sort: \.date,
            order: .reverse
        )
    }

    private var xp: Int {
        CharacterStats.derive(from: events.map(\.domain)).skillXP[skill.id] ?? 0
    }

    private var manualCompletions: Set<String> {
        Set(completions.map(\.objectiveID))
    }

    /// Skills advance by clearing a challenge, never by XP alone (§13).
    private var rank: Rank {
        SkillProgression.rank(
            for: skill,
            xp: xp,
            challenges: ChallengeSeed.challenges,
            activities: allActivities.map(\.domain),
            manualCompletions: manualCompletions
        )
    }

    private var nextChallenge: SkillChallenge? {
        SkillProgression.nextChallenge(for: skill, currentRank: rank, challenges: ChallengeSeed.challenges)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    RankBadge(rank: rank, isProminent: true)
                    Text("\(xp) XP")
                        .statValue(size: 15)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            if let nextRank = rank.next,
               let required = SkillRankRequirements.xpRequired(for: nextRank, skillID: skill.id) {
                Section("Next Rank") {
                    XPBar(current: xp, total: required, caption: "\(nextRank.displayName)-Rank")

                    if let challenge = nextChallenge {
                        challengeRow(challenge)
                    }
                }
            }

            Section("Last 30 Days") {
                let rate = ConsistencyStats.rate(
                    skillID: skill.id,
                    activities: allActivities.map(\.domain),
                    now: .now
                )
                HStack {
                    Text("Days practiced")
                    Spacer()
                    Text(rate.formatted(.percent.precision(.fractionLength(0))))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Contributes To") {
                ForEach(skill.attributeWeights, id: \.attribute) { weight in
                    HStack {
                        Text(weight.attribute.displayName)
                        Spacer()
                        Text(weight.weight.formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Recent Activity") {
                if activities.isEmpty {
                    Text("No sessions logged yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activities.prefix(10), id: \.id) { activity in
                        activityRow(activity)
                    }
                }
            }
        }
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .light), trigger: manualCompletions)
        .alert("Could not save", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// Manual challenges are marked done by the user; measured ones clear
    /// themselves when a qualifying activity is logged (§13).
    @ViewBuilder
    private func challengeRow(_ challenge: SkillChallenge) -> some View {
        let isComplete = ObjectiveEvaluator.isSatisfied(
            challenge.objective,
            activities: allActivities.map(\.domain),
            manualCompletions: manualCompletions
        )

        let label = HStack(alignment: .firstTextBaseline) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            VStack(alignment: .leading, spacing: 2) {
                Text("Challenge").statLabel()
                Text(challenge.objective.title)
            }
        }

        if challenge.objective.isManual {
            Button {
                toggle(challenge.objective, to: !isComplete)
            } label: {
                label
            }
            .buttonStyle(.plain)
        } else {
            label
        }
    }

    private func toggle(_ objective: Objective, to isComplete: Bool) {
        do {
            try CharacterStore(context: context).setCompleted(isComplete, objectiveID: objective.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func activityRow(_ activity: ActivityRecord) -> some View {
        HStack {
            Text(activity.date.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Text(summary(of: activity))
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    private func summary(of activity: ActivityRecord) -> String {
        var parts: [String] = []
        if let miles = activity.distanceMiles, miles > 0 {
            parts.append(miles.formatted(.number.precision(.fractionLength(1))) + " mi")
        }
        if let minutes = activity.durationMinutes, minutes > 0 {
            parts.append("\(Int(minutes)) min")
        }
        return parts.joined(separator: " · ")
    }
}
