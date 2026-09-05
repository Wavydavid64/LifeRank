import SwiftUI
import SwiftData

/// Active quests and their progress (DESIGN.md §16). Progress is derived from
/// logged activities, so logging a run advances a running quest with no
/// separate bookkeeping to fall out of sync.
struct QuestsView: View {
    @Query private var activityRecords: [ActivityRecord]

    private var activities: [Activity] {
        activityRecords.map(\.domain)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(QuestPeriod.allCases, id: \.self) { period in
                    let quests = QuestSeed.quests.filter { $0.period == period }
                    if !quests.isEmpty {
                        Section(period.displayName) {
                            ForEach(quests) { quest in
                                row(for: quest)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quests")
        }
    }

    private func row(for quest: Quest) -> some View {
        let progress = QuestEvaluator.progress(for: quest, activities: activities, now: .now)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(quest.title)
                Spacer()
                if progress.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            ProgressView(value: progress.fraction)
                .animation(.smooth(duration: 0.4), value: progress.fraction)
            HStack {
                Text(label(for: progress, metric: quest.objective.metric))
                if quest.bonusXP > 0 {
                    Spacer()
                    Text("+\(quest.bonusXP) XP")
                }
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }

    private func label(for progress: QuestProgress, metric: QuestMetric) -> String {
        switch metric {
        case .minutes:
            return "\(Int(progress.current)) / \(Int(progress.target)) min"
        case .miles:
            let current = progress.current.formatted(.number.precision(.fractionLength(1)))
            let target = progress.target.formatted(.number.precision(.fractionLength(1)))
            return "\(current) / \(target) mi"
        case .sessions:
            return "\(Int(progress.current)) / \(Int(progress.target))"
        }
    }
}
