import SwiftUI
import SwiftData

/// The character sheet: rank, radar chart, overall XP progress and attribute
/// levels (DESIGN.md §23). Rank is fixed at the starting rank until the
/// promotion system lands — XP never promotes on its own (§3.4).
struct CharacterView: View {
    @Query private var events: [XPEventRecord]

    private var stats: CharacterStats {
        CharacterStats.derive(from: events.map(\.domain))
    }

    private var rank: Rank { .starting }

    private var levels: [Attribute: Int] {
        Dictionary(uniqueKeysWithValues: Attribute.allCases.map { attribute in
            (attribute, AttributeProgression.level(forXP: stats.attributeXP[attribute] ?? 0))
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

                        RadarChartView(levels: levels)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Overall XP") {
                    overallProgress
                }

                Section("Attributes") {
                    ForEach(Attribute.allCases) { attribute in
                        attributeRow(attribute)
                    }
                }

                Section("Skills") {
                    ForEach(SeedData.skills) { skill in
                        LabeledContent(skill.name, value: "\(stats.skillXP[skill.id] ?? 0)")
                    }
                }
            }
            .navigationTitle("Character")
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
