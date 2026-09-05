import SwiftUI
import SwiftData

/// Corrects a logged activity (DESIGN.md §26).
///
/// Manual entries only. An imported workout is a record of what Apple Health
/// holds, so editing it would put the two permanently out of step — delete and
/// re-log by hand instead.
struct EditActivityView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let activity: Activity

    @State private var skillID: Skill.ID
    @State private var name: String
    @State private var date: Date
    @State private var minutes: Double?
    @State private var miles: Double?
    @State private var notes: String
    @State private var errorMessage: String?

    init(activity: Activity) {
        self.activity = activity
        _skillID = State(initialValue: activity.skillID)
        _name = State(initialValue: activity.name)
        _date = State(initialValue: activity.date)
        _minutes = State(initialValue: activity.durationMinutes)
        _miles = State(initialValue: activity.distanceMiles)
        _notes = State(initialValue: activity.notes ?? "")
    }

    private var selectedSkill: Skill {
        SeedData.skills.first { $0.id == skillID } ?? SeedData.skills[0]
    }

    private var edited: Activity {
        Activity(
            id: activity.id,
            skillID: selectedSkill.id,
            name: name.isEmpty ? selectedSkill.name : name,
            date: date,
            durationMinutes: minutes,
            distanceMiles: miles,
            notes: notes.isEmpty ? nil : notes,
            externalIdentifier: activity.externalIdentifier
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

                TextField("Name", text: $name)

                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                LabeledContent("Duration") {
                    TextField("Minutes", value: $minutes, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent("Distance") {
                    TextField("Miles", value: $miles, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                TextField("Notes (optional)", text: $notes, axis: .vertical)

                Section {
                    LabeledContent("Earns", value: "\(ProgressionEngine.skillXP(for: edited)) XP")
                } footer: {
                    Text("Saving recalculates XP for every activity, so quest bonuses stay correct.")
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled((minutes ?? 0) <= 0)
                }
            }
            .alert("Could not save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        do {
            try ActivityStore(context: context).update(edited)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
