import SwiftUI
import SwiftData

/// Chronological activity history with correction (DESIGN.md §26).
struct HistoryView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \ActivityRecord.date, order: .reverse) private var activities: [ActivityRecord]
    @Query private var events: [XPEventRecord]

    @State private var errorMessage: String?
    @State private var isRecalculating = false

    /// XP awarded per activity, counting skill XP only — attribute XP is the
    /// same XP redistributed, so adding both would double the figure.
    private var xpByActivity: [UUID: Int] {
        events.reduce(into: [:]) { totals, event in
            guard case .skill = event.target else { return }
            totals[event.activityID, default: 0] += event.amount
        }
    }

    private var days: [(date: Date, activities: [ActivityRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                if activities.isEmpty {
                    Text("No activities logged yet.")
                        .foregroundStyle(.secondary)
                }

                ForEach(days, id: \.date) { day in
                    Section(day.date.formatted(date: .abbreviated, time: .omitted)) {
                        ForEach(day.activities, id: \.id) { activity in
                            row(activity)
                        }
                        .onDelete { offsets in
                            delete(offsets.map { day.activities[$0] })
                        }
                    }
                }

                if !activities.isEmpty {
                    Section {
                        Button("Recalculate XP") { recalculate() }
                            .disabled(isRecalculating)
                    } footer: {
                        Text("Rebuilds the XP ledger from your activities. Use after changing XP balance.")
                    }
                }
            }
            .navigationTitle("History")
            .alert("Something went wrong", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func row(_ activity: ActivityRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(activity.name)
                Spacer()
                Text("+\(xpByActivity[activity.id] ?? 0) XP")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(subtitle(activity))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func subtitle(_ activity: ActivityRecord) -> String {
        var parts: [String] = []
        if let miles = activity.distanceMiles, miles > 0 {
            parts.append(miles.formatted(.number.precision(.fractionLength(1))) + " mi")
        }
        if let minutes = activity.durationMinutes, minutes > 0 {
            parts.append("\(Int(minutes)) min")
        }
        parts.append(activity.externalIdentifier == nil ? "Manual" : "Apple Health")
        return parts.joined(separator: " · ")
    }

    private func delete(_ records: [ActivityRecord]) {
        let store = ActivityStore(context: context)
        do {
            for record in records {
                try store.delete(activityID: record.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recalculate() {
        isRecalculating = true
        defer { isRecalculating = false }

        do {
            try ActivityStore(context: context).recalculateXP()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
