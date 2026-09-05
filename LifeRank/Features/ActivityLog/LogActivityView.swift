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
            }
            .navigationTitle("Log Activity")
            .alert("Could not save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
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
