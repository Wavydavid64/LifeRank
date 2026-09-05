import Foundation

/// Converts Activities into XPEvents. Pure Swift — no SwiftUI, SwiftData, or HealthKit.
enum ProgressionEngine {

    // MARK: - Balance constants
    // Game-balance values live here, not in views (DESIGN.md §34). These are
    // starting values to be tuned through real usage, not final balance.

    static let xpPerMinute = 1.0
    static let xpPerMile = 7.5

    /// XP an activity earns for its skill, before attribute distribution.
    /// Duration plus a distance bonus — intensity, heart rate and calories are
    /// deliberately absent until real Garmin/Hevy HealthKit payloads are
    /// inspected (DESIGN.md §20).
    static func skillXP(for activity: Activity) -> Int {
        let fromDuration = (activity.durationMinutes ?? 0) * xpPerMinute
        let fromDistance = (activity.distanceMiles ?? 0) * xpPerMile
        return Int((fromDuration + fromDistance).rounded())
    }

    /// Produces the XP ledger entries earned from a single activity: one event
    /// for the skill itself, plus one event per attribute the skill's weights
    /// distribute XP into. Attribute XP is split using a largest-remainder
    /// allocation so the distributed amounts always sum to exactly the skill XP,
    /// with no rounding loss.
    static func xpEvents(for activity: Activity, skill: Skill) -> [XPEvent] {
        precondition(activity.skillID == skill.id, "Activity/skill mismatch")

        let total = skillXP(for: activity)

        var events = [
            XPEvent(activityID: activity.id, target: .skill(skill.id), amount: total, date: activity.date)
        ]

        for (attribute, amount) in distribute(total: total, weights: skill.attributeWeights) where amount != 0 {
            events.append(
                XPEvent(activityID: activity.id, target: .attribute(attribute), amount: amount, date: activity.date)
            )
        }

        return events
    }

    /// Splits `total` across `weights` proportionally, using the largest-remainder
    /// method so the resulting integer amounts always sum to exactly `total`
    /// (assuming the weights sum to 1.0).
    static func distribute(total: Int, weights: [AttributeWeight]) -> [(attribute: Attribute, amount: Int)] {
        let shares = weights.enumerated().map { index, weight in
            (index: index, attribute: weight.attribute, exact: Double(total) * weight.weight)
        }

        var amounts = shares.map { Int($0.exact.rounded(.down)) }
        let remaining = total - amounts.reduce(0, +)

        let remainderOrder = shares.indices.sorted { lhsIndex, rhsIndex in
            let lhs = shares[lhsIndex].exact - shares[lhsIndex].exact.rounded(.down)
            let rhs = shares[rhsIndex].exact - shares[rhsIndex].exact.rounded(.down)
            if lhs != rhs { return lhs > rhs }
            return lhsIndex < rhsIndex
        }

        for i in 0..<remaining where i < remainderOrder.count {
            amounts[remainderOrder[i]] += 1
        }

        return shares.map { ($0.attribute, amounts[$0.index]) }
    }
}
