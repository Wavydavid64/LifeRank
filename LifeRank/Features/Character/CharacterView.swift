import SwiftUI
import SwiftData

/// Minimal character sheet: raw XP totals derived from the ledger. The radar
/// chart, rank badge and promotion progress are Stage 3 (DESIGN.md §41).
struct CharacterView: View {
    @Query private var events: [XPEventRecord]

    private var stats: CharacterStats {
        CharacterStats.derive(from: events.map(\.domain))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overall") {
                    LabeledContent("Total XP", value: "\(stats.totalXP)")
                }

                Section("Skills") {
                    ForEach(SeedData.skills) { skill in
                        LabeledContent(skill.name, value: "\(stats.skillXP[skill.id] ?? 0)")
                    }
                }

                Section("Attributes") {
                    ForEach(Attribute.allCases) { attribute in
                        LabeledContent(attribute.displayName, value: "\(stats.attributeXP[attribute] ?? 0)")
                    }
                }
            }
            .navigationTitle("Character")
        }
    }
}
