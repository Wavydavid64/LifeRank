import Foundation

/// The multi-part test standing between the player and a rank (DESIGN.md §14).
/// It unlocks only once the rank's progression requirements are met, and
/// clearing it makes promotion available rather than automatic.
nonisolated struct PromotionTrial: Identifiable, Codable, Hashable {
    let rank: Rank
    let objectives: [Objective]

    var id: Rank { rank }
}
