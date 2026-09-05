import SwiftUI
import SwiftData

/// Fast manual logging: pick a skill, type a duration, save (DESIGN.md §22).
struct LogActivityView: View {
    @Environment(\.modelContext) private var context

    @State private var skillID: Skill.ID = SeedData.skills[0].id
    @State private var minutes: Double?
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var lastAward: Int?
    @State private var isImporting = false
    @State private var importSummary: String?

    private let health: ActivityProvider = HealthKitService()

    /// How far back an import looks. Workouts already in the ledger are skipped
    /// by identifier, so re-importing the same window is harmless (§21).
    private static let importWindowDays = 30

    private var selectedSkill: Skill {
        SeedData.skills.first { $0.id == skillID } ?? SeedData.skills[0]
    }

    /// Live preview of the XP this entry will earn. The number comes from the
    /// domain layer — the view performs no XP math of its own (§32).
    private var pendingXP: Int {
        ProgressionEngine.skillXP(for: draftActivity)
    }

    private var draftActivity: Activity {
        Activity(
            skillID: selectedSkill.id,
            name: selectedSkill.name,
            durationMinutes: minutes ?? 0,
            notes: notes.isEmpty ? nil : notes
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Skill", selection: $skillID) {
                    ForEach(SeedData.skills) { skill in
                        Text(skill.name).tag(skill.id)
                    }
                }

                LabeledContent("Duration") {
                    TextField("Minutes", value: $minutes, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                TextField("Notes (optional)", text: $notes, axis: .vertical)

                Section {
                    Button("Save") { save() }
                        .disabled((minutes ?? 0) <= 0)
                } footer: {
                    if (minutes ?? 0) > 0 {
                        Text("Earns \(pendingXP) XP")
                    }
                }

                if let lastAward {
                    Section("Last entry") {
                        Text("+\(lastAward) XP")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Import Workouts") { Task { await importFromHealth() } }
                        .disabled(isImporting)
                } header: {
                    Text("Apple Health")
                } footer: {
                    if let importSummary {
                        Text(importSummary)
                    } else {
                        Text("Garmin and Hevy workouts arrive through Apple Health.")
                    }
                }
            }
            .navigationTitle("Log Activity")
            .alert("Could not save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func importFromHealth() async {
        isImporting = true
        defer { isImporting = false }

        do {
            try await health.requestAuthorization()
            let since = Calendar.current.date(byAdding: .day, value: -Self.importWindowDays, to: .now) ?? .distantPast
            let workouts = try await health.fetchActivities(since: since)
            let summary = try ActivityImporter(store: ActivityStore(context: context)).import(workouts)

            importSummary = describe(summary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func describe(_ summary: ActivityImporter.Summary) -> String {
        var parts = ["Imported \(summary.imported)"]
        if summary.duplicates > 0 { parts.append("\(summary.duplicates) already imported") }
        if summary.unclassified > 0 { parts.append("\(summary.unclassified) unrecognised") }
        return parts.joined(separator: ", ") + "."
    }

    private func save() {
        let activity = draftActivity
        let award = pendingXP

        do {
            try ActivityStore(context: context).log(activity, skill: selectedSkill)
            lastAward = award
            minutes = nil
            notes = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
