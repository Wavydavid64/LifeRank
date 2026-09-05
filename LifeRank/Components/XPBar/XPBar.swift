import SwiftUI

/// Progress toward a threshold, with the raw numbers underneath. Animates when
/// the value changes so earned XP visibly lands (DESIGN.md §38).
struct XPBar: View {
    let current: Int
    let total: Int
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(min(current, total)), total: Double(max(total, 1)))
                .animation(.smooth(duration: 0.4), value: current)

            HStack {
                Text("\(current) / \(total)")
                if let caption {
                    Spacer()
                    Text(caption).foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .monospacedDigit()
        }
    }
}
