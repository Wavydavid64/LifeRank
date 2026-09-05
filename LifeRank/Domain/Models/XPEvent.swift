import Foundation

/// The recipient of an XP award: a skill or an attribute.
enum XPTarget: Codable, Hashable {
    case skill(Skill.ID)
    case attribute(Attribute)
}

/// A single, immutable entry in the XP ledger, recording XP awarded as a
/// result of an Activity. Overall character progression is derived by
/// summing the ledger rather than stored redundantly.
struct XPEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let activityID: Activity.ID
    let target: XPTarget
    let amount: Int
    let date: Date

    init(
        id: UUID = UUID(),
        activityID: Activity.ID,
        target: XPTarget,
        amount: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.activityID = activityID
        self.target = target
        self.amount = amount
        self.date = date
    }
}
