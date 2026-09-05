import Foundation
import SwiftData

/// SwiftData storage for one XP ledger entry. Keyed by `activityID` so that
/// deleting an activity can remove exactly the XP it produced (DESIGN.md §26).
@Model
final class XPEventRecord {
    var id: UUID
    var activityID: UUID
    var target: XPTarget
    var amount: Int
    var date: Date

    init(_ event: XPEvent) {
        self.id = event.id
        self.activityID = event.activityID
        self.target = event.target
        self.amount = event.amount
        self.date = event.date
    }

    var domain: XPEvent {
        XPEvent(id: id, activityID: activityID, target: target, amount: amount, date: date)
    }
}
