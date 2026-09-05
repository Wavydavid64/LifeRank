import SwiftUI

/// Raw HealthKit workout dump, for answering DESIGN.md §20 on a real device.
///
/// ARCHIVED — not part of the app target. See README.md in this folder.
/// Awards no XP, persists nothing, does not touch the progression engine.
struct HealthKitDiagnosticView: View {
    private let health = HealthKitDiagnosticService()

    @State private var workouts: [WorkoutDiagnostic] = []
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var hasLoaded = false

    var body: some View {
        List {
            if let errorText {
                Section("HealthKit Error") {
                    Text(errorText)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }

            if isLoading {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Reading workouts…")
                    }
                }
            }

            if hasLoaded && workouts.isEmpty && errorText == nil {
                Section {
                    Text("No workouts returned. Either Health holds none, or read access was declined for workouts.")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(workouts) { workout in
                Section {
                    row("Type", workout.activityTypeName)
                    row("Raw value", "\(workout.activityTypeRawValue)")
                    row("Maps to", workout.mappedSkillID ?? "— unmapped —")
                    row("Source", workout.sourceName)
                    row("Start", workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    row("Duration", "\(workout.durationMinutes.formatted(.number.precision(.fractionLength(1)))) min")
                    row("Distance", distanceText(workout))
                    row("Active energy", energyText(workout))
                    row("Avg heart rate", heartRateText(workout))
                    row("UUID", workout.id)
                } header: {
                    HStack {
                        Text(workout.activityTypeName)
                        if !workout.isMapped {
                            Spacer()
                            Text("UNMAPPED")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("HealthKit Diagnostic")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Reload") { Task { await load() } }
                .disabled(isLoading)
        }
        .task {
            guard !hasLoaded else { return }
            await load()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func distanceText(_ workout: WorkoutDiagnostic) -> String {
        guard let miles = workout.distanceMiles else { return "— none —" }
        let value = miles.formatted(.number.precision(.fractionLength(2)))
        return "\(value) mi (\(workout.distanceQuantityUsed ?? "?"))"
    }

    private func energyText(_ workout: WorkoutDiagnostic) -> String {
        guard let calories = workout.activeCalories else { return "— none —" }
        return "\(calories.formatted(.number.precision(.fractionLength(0)))) kcal"
    }

    private func heartRateText(_ workout: WorkoutDiagnostic) -> String {
        guard let bpm = workout.averageHeartRate else { return "— none —" }
        return "\(bpm.formatted(.number.precision(.fractionLength(0)))) bpm"
    }

    /// Errors are shown on the page rather than thrown away, so a denied
    /// permission or an unavailable store is visible rather than looking like
    /// "no workouts" (§36).
    private func load() async {
        isLoading = true
        errorText = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            workouts = try await health.fetchDiagnostics()
        } catch {
            workouts = []
            errorText = "\(error.localizedDescription)\n\n\(String(describing: error))"
        }
    }
}
