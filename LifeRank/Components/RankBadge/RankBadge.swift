import SwiftUI
import UIKit

extension Rank {
    /// One colour per rank, climbing a familiar cool-to-hot ramp so a glance at
    /// the badge reads as progress before the letter is even parsed.
    ///
    /// All system colours, so both appearances are handled for free. Presentation
    /// only — it lives here rather than on the model, because the domain layer
    /// must not import SwiftUI (DESIGN.md §32).
    var color: Color {
        switch self {
        case .f: return .secondary
        case .e: return .brown
        case .d: return .green
        case .c: return .blue
        case .b: return .purple
        case .a: return .red
        case .s: return .rankGold
        }
    }
}

private extension Color {
    /// Gold for S rank. Plain `.yellow` is close to invisible on a white
    /// background, so this darkens to a readable gold in light appearance and
    /// keeps the bright yellow in dark.
    static let rankGold = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemYellow
            : UIColor(red: 0.70, green: 0.52, blue: 0.00, alpha: 1)
    })
}

/// The rank letter, styled consistently wherever it appears. Strong monospaced
/// type in a bordered frame — prominent without decoration (DESIGN.md §37).
///
/// Colour is never the only cue: the letter is always shown alongside it.
struct RankBadge: View {
    let rank: Rank
    var isProminent = false

    var body: some View {
        Text(rank.displayName)
            .font(.system(size: isProminent ? 46 : 15, weight: .heavy, design: .monospaced))
            .foregroundStyle(rank.color)
            .padding(.horizontal, isProminent ? 22 : 9)
            .padding(.vertical, isProminent ? 8 : 3)
            .overlay(
                RoundedRectangle(cornerRadius: isProminent ? 14 : 6, style: .continuous)
                    .strokeBorder(rank.color, lineWidth: isProminent ? 3 : 1.5)
            )
            .accessibilityLabel("\(rank.displayName) rank")
    }
}
