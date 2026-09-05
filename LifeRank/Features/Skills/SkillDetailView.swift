import SwiftUI
import SwiftData

/// One skill: rank, XP toward the next rank, what it feeds, and recent
/// sessions (DESIGN.md §25).
struct SkillDetailView: View {
    let skill: Skill

    @Query private var events: [XPEventRecord]
    @Query private var activities: [ActivityRecord]

    init(skill: Skill) {
        self.skill = skill
        let id = skill.id
        _activities = Query(
            filter: #Predicate<ActivityRecord> { $0.skillID == id },
            sort: \.date,
            order: .reverse
        )
    }

    /// Skills advance rank by clearing a challenge, never by XP alone (§13).
    private var rank: Rank { .starting }

    private var xp: Int {
        CharacterStats.derive(from: events.map(\.domain)).skillXP[skill.id] ?? 0
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text("\(rank.displayName)-RANK")
                        .font(.title.weight(.bold))
                        .monospaced()
                    Text("\(xp) XP")
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            if let nextRank = rank.next, let required = SkillRankRequirements.xpRequired(for: nextRank) {
                Section("Next Rank") {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: Double(min(xp, required)), total: Double(required))
                        HStack {
                            Text("\(xp) / \(required)")
                            Spacer()
                            Text("\(nextRank.displayName)-Rank")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        .monospacedDigit()
                    }
                }
            }

            Section("Contributes To") {
                ForEach(skill.attributeWeights, id: \.attribute) { weight in
                    LabeledContent(
                        weight.attribute.displayName,
                        value: weight.weight.formatted(.percent.precision(.fractionLength(0)))
                    )
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
    }

    private func activityRow(_ activity: ActivityRecord) -> some View {
        HStack {
            Text(activity.date.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Text(summary(of: activity))
                .monospacedDigit()
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
