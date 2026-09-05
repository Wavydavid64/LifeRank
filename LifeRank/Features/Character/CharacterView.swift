import SwiftUI
import SwiftData

/// The character sheet: rank, radar chart, overall XP progress and attribute
/// levels (DESIGN.md §23). Rank comes from stored state and only changes when
/// the player promotes explicitly — XP never promotes on its own (§3.4).
struct CharacterView: View {
    @Query private var events: [XPEventRecord]
    @Query private var characters: [CharacterRecord]
    @Query private var activityRecords: [ActivityRecord]
    @Query private var completions: [ObjectiveCompletionRecord]

    private var status: PromotionStatus {
        let activities = activityRecords.map(\.domain)
        let manualCompletions = Set(completions.map(\.objectiveID))

        return PromotionEngine.status(
            currentRank: rank,
            stats: stats,
            skillRanks: SkillProgression.ranks(
                stats: stats,
                activities: activities,
                manualCompletions: manualCompletions
            ),
            activities: activities,
            trials: TrialSeed.trials,
            manualCompletions: manualCompletions
        )
    }

    private var stats: CharacterStats {
        CharacterStats.derive(from: events.map(\.domain))
    }

    private var rank: Rank { characters.first?.rank ?? .starting }

    /// Fractional levels, so the radar responds to every session instead of
    /// sitting still until a level boundary is crossed.
    private var radarValues: [Attribute: Double] {
        Dictionary(uniqueKeysWithValues: Attribute.allCases.map { attribute in
            let progress = AttributeProgression.progress(forXP: stats.attributeXP[attribute] ?? 0)
            return (attribute, Double(progress.level) + progress.fraction)
        })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Text("\(rank.displayName)-RANK")
                            .font(.largeTitle.weight(.bold))
                            .monospaced()

                        RadarChartView(
                            values: radarValues,
                            ceiling: Double(RankRequirements.attributeCeiling(for: rank))
                        )
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Overall XP") {
                    overallProgress
                }

                if let nextRank = status.nextRank {
                    Section("Next Promotion") {
                        requirement("XP", status.xp)
                        requirement("Skills at \(nextRank.displayName)", status.skills)
                        requirement("Attributes", status.attributes)

                        NavigationLink {
                            TrialsView()
                        } label: {
                            HStack {
                                Text("Promotion Trial")
                                Spacer()
                                Text(trialLabel)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Attributes") {
                    ForEach(Attribute.allCases) { attribute in
                        attributeRow(attribute)
                    }
                }

            }
            .navigationTitle("Character")
        }
    }

    private var trialLabel: String {
        if status.canPromote { return "Ready" }
        if !status.trialUnlocked { return "Locked" }
        let done = status.trial.count(where: \.isComplete)
        return "\(done) / \(status.trial.count)"
    }

    private func requirement(_ title: String, _ progress: RequirementProgress) -> some View {
        HStack {
            Image(systemName: progress.isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(progress.isMet ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Text(title)
            Spacer()
            Text("\(progress.current) / \(progress.required)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var overallProgress: some View {
        if let nextRank = rank.next, let required = RankRequirements.overallXP(for: nextRank) {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: Double(min(stats.totalXP, required)), total: Double(required))
                HStack {
                    Text("\(stats.totalXP) / \(required)")
                    Spacer()
                    Text("Next: \(nextRank.displayName)-Rank")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .monospacedDigit()
            }
        } else {
            LabeledContent("Total XP", value: "\(stats.totalXP)")
        }
    }

    private func attributeRow(_ attribute: Attribute) -> some View {
        let progress = AttributeProgression.progress(forXP: stats.attributeXP[attribute] ?? 0)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(attribute.displayName)
                Spacer()
                Text("\(progress.level)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress.fraction)
        }
    }
}
