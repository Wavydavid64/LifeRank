import Foundation

/// Rolling consistency over a trailing window (DESIGN.md §17).
///
/// Deliberately not a streak. Missing one day lowers the figure slightly and
/// nothing else — it can never invalidate months of work, and no rank or XP
/// depends on it. It is a statistic, not a mechanic.
enum ConsistencyStats {

    static let windowDays = 30

    /// Fraction of the last `days` on which this skill was practiced at all,
    /// counting each day once no matter how many sessions it held.
    static func rate(
        skillID: Skill.ID,
        activities: [Activity],
        now: Date,
        calendar: Calendar = .current,
        days: Int = windowDays
    ) -> Double {
        guard days > 0 else { return 0 }

        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return 0
        }

        let activeDays = Set(
            activities
                .filter { $0.skillID == skillID }
                .map { calendar.startOfDay(for: $0.date) }
                .filter { $0 >= windowStart && $0 <= today }
        )

        return Double(activeDays.count) / Double(days)
    }
}
