import SwiftUI
import SwiftData

/// Promotion requirements and the trial that follows them (DESIGN.md §27).
/// The trial stays locked until every progression requirement is met, and
/// promotion is an explicit button rather than something that happens quietly.
struct TrialsView: View {
    @Environment(\.modelContext) private var context

    @Query private var events: [XPEventRecord]
    @Query private var activityRecords: [ActivityRecord]
    @Query private var characters: [CharacterRecord]
    @Query private var completions: [ObjectiveCompletionRecord]

    @State private var errorMessage: String?
    @State private var promotedTo: Rank?

    private var rank: Rank { characters.first?.rank ?? .starting }
    private var activities: [Activity] { activityRecords.map(\.domain) }
    private var manualCompletions: Set<String> { Set(completions.map(\.objectiveID)) }

    private var status: PromotionStatus {
        let stats = CharacterStats.derive(from: events.map(\.domain))
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

    var body: some View {
        NavigationStack {
            List {
                if let nextRank = status.nextRank {
                    Section("\(nextRank.displayName)-Rank Promotion") {
                        requirement("XP", status.xp)
                        requirement("Skills at \(nextRank.displayName)", status.skills)
                        requirement("Attributes", status.attributes)
                    }

                    Section {
                        if status.trialUnlocked {
                            ForEach(status.trial, id: \.objective.id) { entry in
                                objectiveRow(entry.objective, isComplete: entry.isComplete)
                            }
                        } else {
                            Label("Locked", systemImage: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Promotion Trial")
                    } footer: {
                        if !status.trialUnlocked {
                            Text("Unlocks when the requirements above are complete.")
                        }
                    }

                    if status.canPromote {
                        Section {
                            Button("Promote to \(nextRank.displayName)-Rank") { promote() }
                                .font(.headline)
                        }
                    }
                } else {
                    Section {
                        Text("You have reached the highest rank.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("\(rank.displayName)-Rank")
            .sheet(item: $promotedTo) { rank in
                PromotionView(rank: rank) { promotedTo = nil }
                    .interactiveDismissDisabled()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: manualCompletions)
            .alert("Could not save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func requirement(_ title: String, _ progress: RequirementProgress) -> some View {
        HStack {
            Image(systemName: progress.isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(progress.isMet ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Text(title)
            Spacer()
            Text("\(progress.current) / \(progress.required)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    /// Manual objectives are tappable; measured ones tick themselves when a
    /// qualifying activity is logged, so they are not editable by hand (§13).
    @ViewBuilder
    private func objectiveRow(_ objective: Objective, isComplete: Bool) -> some View {
        if objective.isManual {
            Button {
                toggle(objective, to: !isComplete)
            } label: {
                objectiveLabel(objective, isComplete: isComplete)
            }
            .buttonStyle(.plain)
        } else {
            objectiveLabel(objective, isComplete: isComplete)
        }
    }

    private func objectiveLabel(_ objective: Objective, isComplete: Bool) -> some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Text(objective.title)
            Spacer()
            if objective.isManual {
                Text("Manual").statLabel()
            }
        }
    }

    private func toggle(_ objective: Objective, to isComplete: Bool) {
        do {
            try CharacterStore(context: context).setCompleted(isComplete, objectiveID: objective.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func promote() {
        let target = status.nextRank
        do {
            if try CharacterStore(context: context).promote(using: status) {
                promotedTo = target
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
