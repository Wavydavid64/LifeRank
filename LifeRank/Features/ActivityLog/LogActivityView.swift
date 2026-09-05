import SwiftUI
import SwiftData

/// Fast manual logging: pick a skill, type a duration, save (DESIGN.md §22).
struct LogActivityView: View {
    @Environment(\.modelContext) private var context

    @State private var skillID: Skill.ID = SeedData.skills[0].id
    @State private var minutes: Double?
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var award: XPAward?
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

                Section {
                    Button("Import Workouts") { Task { await importFromHealth() } }
                        .disabled(isImporting)

                    // TEMPORARY — §20 verification. Remove with the diagnostic.
                    NavigationLink("HealthKit Diagnostic") {
                        HealthKitDiagnosticView()
                    }
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
            .overlay {
                if let award {
                    XPAwardView(award: award)
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                        .onTapGesture { dismissAward() }
                }
            }
            .task(id: award) {
                guard award != nil else { return }
                try? await Task.sleep(for: .seconds(2.8))
                dismissAward()
            }
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
        if summary.unclassified > 0 { parts.append("\(summary.unclassified) unrecognized") }
        return parts.joined(separator: ", ") + "."
    }

    private func save() {
        let skill = selectedSkill

        do {
            let events = try ActivityStore(context: context).log(draftActivity, skill: skill)
            withAnimation(.smooth(duration: 0.3)) {
                award = XPAward(skillName: skill.name, events: events)
            }
            minutes = nil
            notes = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dismissAward() {
        withAnimation(.smooth(duration: 0.25)) { award = nil }
    }
}
