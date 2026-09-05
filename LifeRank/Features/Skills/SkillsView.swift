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
        let rank = ranks[skill.id] ?? .starting

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.name)
                Text(subtitle(xp: xp, rank: rank, skillID: skill.id))
                    .statLabel()
            }
            Spacer()
            RankBadge(rank: rank, progress: progress(xp: xp, rank: rank, skillID: skill.id))
        }
    }

    /// Fraction of the way to the next rank, which the badge draws as its own
    /// border. Nil at the top of the ladder, where there is nothing to fill.
    private func progress(xp: Int, rank: Rank, skillID: Skill.ID) -> Double? {
        guard let next = rank.next,
              let required = SkillRankRequirements.xpRequired(for: next, skillID: skillID),
              required > 0
        else { return nil }

        return min(Double(xp) / Double(required), 1)
    }

    private func subtitle(xp: Int, rank: Rank, skillID: Skill.ID) -> String {
        guard let next = rank.next,
              let required = SkillRankRequirements.xpRequired(for: next, skillID: skillID)
        else { return "\(xp) XP" }

        return "\(xp) / \(required) XP"
    }
}
