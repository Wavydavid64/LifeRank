import SwiftUI
import SwiftData

/// Skills and their current rank (DESIGN.md §24).
struct SkillsView: View {
    @Query private var events: [XPEventRecord]
    @Query private var activityRecords: [ActivityRecord]
    @Query private var completions: [ObjectiveCompletionRecord]

    private var stats: CharacterStats {
        CharacterStats.derive(from: events.map(\.domain))
    }

    /// Derived from XP *and* cleared challenges — XP alone never advances a
    /// skill rank (§13).
    private var ranks: [Skill.ID: Rank] {
        SkillProgression.ranks(
            stats: stats,
            activities: activityRecords.map(\.domain),
            manualCompletions: Set(completions.map(\.objectiveID))
        )
    }

    var body: some View {
        NavigationStack {
            List(SeedData.skills) { skill in
                NavigationLink(value: skill.id) {
                    row(for: skill)
                }
            }
            .navigationTitle("Skills")
            .navigationDestination(for: Skill.ID.self) { id in
                if let skill = SeedData.skills.first(where: { $0.id == id }) {
                    SkillDetailView(skill: skill)
                }
            }
        }
    }

    private func row(for skill: Skill) -> some View {
        let xp = stats.skillXP[skill.id] ?? 0

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                Text("\(xp) XP")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text((ranks[skill.id] ?? .starting).displayName)
                .font(.headline.weight(.bold))
                .monospaced()
                .foregroundStyle(.secondary)
        }
    }
}
