import SwiftUI
import SwiftData

/// The character sheet: rank, radar chart, overall XP progress and attribute
/// levels (DESIGN.md §23). Rank comes from stored state and only changes when
/// the player promotes explicitly — XP never promotes on its own (§3.4).
///
/// Laid out as panels rather than a grouped `List` so the eight attributes fit
/// on one screen as a grid. §37 asks for high information density and a sheet
/// that can be taken in at a glance, which a column of scrolling rows is not.
struct CharacterView: View {
    @Query private var events: [XPEventRecord]
    @Query private var characters: [CharacterRecord]
    @Query private var activityRecords: [ActivityRecord]
    @Query private var completions: [ObjectiveCompletionRecord]

    private var stats: CharacterStats {
        CharacterStats.derive(from: events.map(\.domain))
    }

    private var rank: Rank { characters.first?.rank ?? .starting }

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
            ScrollView {
                VStack(spacing: 18) {
                    header
                    radar
                    attributeGrid
                    if status.nextRank != nil { promotion }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Character")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            RankBadge(rank: rank, isProminent: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Overall XP").statLabel()

                if let nextRank = rank.next,
                   let required = RankRequirements.overallXP(for: nextRank) {
                    XPBar(
                        current: stats.totalXP,
                        total: required,
                        caption: "Next: \(nextRank.displayName)"
                    )
                } else {
                    Text("\(stats.totalXP)").statValue(size: 22)
                }
            }
        }
        .statPanel()
    }

    // MARK: - Radar

    private var radar: some View {
        RadarChartView(
            values: radarValues,
            ceiling: Double(RankRequirements.attributeCeiling(for: rank)),
            tint: rank.color
        )
        // Height-capped rather than square. The chart sizes its radius off the
        // smaller dimension, so a full-width box leaves horizontal room for the
        // long axis names — square clipped "Discipline" and "Exploration".
        // The cap also keeps the attribute grid on the same screen.
        .frame(height: 260)
    }

    // MARK: - Attributes

    private var attributeGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attributes").statLabel()

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Attribute.allCases) { attribute in
                    attributeCell(attribute)
                }
            }
        }
    }

    private func attributeCell(_ attribute: Attribute) -> some View {
        let progress = AttributeProgression.progress(forXP: stats.attributeXP[attribute] ?? 0)

        return VStack(alignment: .leading, spacing: 6) {
            Text(attribute.displayName).statLabel()
            Text("\(progress.level)").statValue(size: 26)
            // Accent rather than the rank color: at F that is grey, and a row
            // of grey bars reads as disabled rather than as progress.
            ProgressView(value: progress.fraction)
                .animation(.smooth(duration: 0.4), value: progress.fraction)
        }
        .statPanel(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(attribute.displayName), level \(progress.level)")
    }

    // MARK: - Promotion

    @ViewBuilder
    private var promotion: some View {
        if let nextRank = status.nextRank {
            NavigationLink {
                TrialsView()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Next Promotion").statLabel()
                        Spacer()
                        Text("\(nextRank.displayName)-Rank")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundStyle(nextRank.color)
                    }

                    requirement("XP", status.xp)
                    requirement("Skills", status.skills)
                    requirement("Attributes", status.attributes)

                    HStack {
                        Text("Trial")
                        Spacer()
                        Text(trialLabel)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(status.canPromote ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                }
                .statPanel()
            }
            .buttonStyle(.plain)
        }
    }

    private var trialLabel: String {
        if status.canPromote { return "READY" }
        if !status.trialUnlocked { return "LOCKED" }
        return "\(status.trial.count(where: \.isComplete)) / \(status.trial.count)"
    }

    private func requirement(_ title: String, _ progress: RequirementProgress) -> some View {
        HStack {
            Image(systemName: progress.isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(progress.isMet ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Text(title)
            Spacer()
            Text("\(progress.current) / \(progress.required)")
                .foregroundStyle(.secondary)
        }
        .font(.system(.caption, design: .monospaced))
    }
}
