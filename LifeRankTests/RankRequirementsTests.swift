import Testing
@testable import LifeRank

struct RankRequirementsTests {

    @Test func ranksAreOrderedLowestToHighest() {
        #expect(Rank.allCases == [.f, .e, .d, .c, .b, .a, .s])
        #expect(Rank.f < Rank.s)
    }

    @Test func charactersStartAtF() {
        #expect(Rank.starting == .f)
    }

    @Test func nextWalksTheLadderAndStopsAtTheTop() {
        #expect(Rank.f.next == .e)
        #expect(Rank.b.next == .a)
        #expect(Rank.a.next == .s)
        #expect(Rank.s.next == nil)
    }

    /// The starting rank is not something the player is promoted into, so it
    /// carries no XP requirement.
    @Test func startingRankHasNoXPRequirement() {
        #expect(RankRequirements.overallXP(for: .f) == nil)
    }

    /// Pins the DESIGN.md §15 placeholder table.
    @Test func thresholdsMatchSpec() {
        #expect(RankRequirements.overallXP(for: .e) == 1_000)
        #expect(RankRequirements.overallXP(for: .d) == 5_000)
        #expect(RankRequirements.overallXP(for: .c) == 15_000)
        #expect(RankRequirements.overallXP(for: .b) == 40_000)
        #expect(RankRequirements.overallXP(for: .a) == 100_000)
        #expect(RankRequirements.overallXP(for: .s) == 250_000)
    }

    @Test func thresholdsIncreaseWithRank() {
        let thresholds = [Rank.e, .d, .c, .b, .a, .s].compactMap(RankRequirements.overallXP(for:))

        #expect(thresholds.count == 6)
        #expect(zip(thresholds, thresholds.dropFirst()).allSatisfy { $0 < $1 })
    }
}
