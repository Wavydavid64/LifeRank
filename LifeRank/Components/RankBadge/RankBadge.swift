import SwiftUI

/// The rank letter, styled consistently wherever it appears. Strong monospaced
/// type in a bordered frame — prominent without decoration (DESIGN.md §37).
struct RankBadge: View {
    let rank: Rank
    var isProminent = false

    var body: some View {
        Text(rank.displayName)
            .font(.system(size: isProminent ? 46 : 15, weight: .heavy, design: .monospaced))
            .foregroundStyle(.tint)
            .padding(.horizontal, isProminent ? 22 : 9)
            .padding(.vertical, isProminent ? 8 : 3)
            .overlay(
                RoundedRectangle(cornerRadius: isProminent ? 14 : 6, style: .continuous)
                    .strokeBorder(.tint, lineWidth: isProminent ? 3 : 1.5)
            )
            .accessibilityLabel("\(rank.displayName) rank")
    }
}
