import Foundation
import SwiftData

/// Writes activities and the XP they generate, and reads progression back out.
/// The XP itself is calculated by the domain layer — this type only persists.
@MainActor
struct ActivityStore {
    let context: ModelContext

    /// Saves an activity together with every XPEvent it produces, as one
    /// transaction. A failed save rolls back rather than leaving an activity
    /// with partial or missing XP (DESIGN.md §36).
    func log(_ activity: Activity, skill: Skill) throws {
        context.insert(ActivityRecord(activity))
        for event in ProgressionEngine.xpEvents(for: activity, skill: skill) {
            context.insert(XPEventRecord(event))
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func xpEvents() throws -> [XPEvent] {
        try context.fetch(FetchDescriptor<XPEventRecord>()).map(\.domain)
    }

    func stats() throws -> CharacterStats {
        CharacterStats.derive(from: try xpEvents())
    }
}
