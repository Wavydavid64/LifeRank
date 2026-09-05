import Foundation

/// Progression totals derived from the XP ledger. DESIGN.md §10: XPEvents are
/// the source of truth — totals are computed, never stored as mutable running
/// counters that could drift from the ledger.
struct CharacterStats: Equatable {
    let skillXP: [Skill.ID: Int]
    let attributeXP: [Attribute: Int]

    /// Overall character XP: the sum of XP earned by skills. Attribute XP is a
    /// redistribution of the same XP, so summing it too would double-count.
    var totalXP: Int { skillXP.values.reduce(0, +) }

    /// ponytail: folds the entire ledger, and views call it from `body`, so it
    /// runs on every render. Fine at ~8 events per activity; if the character
    /// screen ever feels sluggish this is the first thing to cache, keyed off
    /// the ledger count.
    static func derive(from events: [XPEvent]) -> CharacterStats {
        var skills: [Skill.ID: Int] = [:]
        var attributes: [Attribute: Int] = [:]

        for event in events {
            switch event.target {
            case .skill(let id):
                skills[id, default: 0] += event.amount
            case .attribute(let attribute):
                attributes[attribute, default: 0] += event.amount
            }
        }

        return CharacterStats(skillXP: skills, attributeXP: attributes)
    }
}
