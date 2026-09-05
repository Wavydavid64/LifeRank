import SwiftUI

/// Shown once, immediately after a promotion. Deliberately plain — a big rank
/// letter and nothing else. §37 rules out confetti and childish gamification;
/// the weight comes from the typography and the haptic, not decoration.
struct PromotionView: View {
    let rank: Rank
    let onDismiss: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("PROMOTED")
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .tracking(6)
                .foregroundStyle(.secondary)

            RankBadge(rank: rank, isProminent: true)
                .scaleEffect(hasAppeared ? 1 : 0.7)
                .opacity(hasAppeared ? 1 : 0)

            Text("You are now \(rank.displayName)-Rank.")
                .font(.headline)

            Spacer()

            Button("Continue", action: onDismiss)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
        }
        .padding()
        .onAppear {
            withAnimation(.smooth(duration: 0.5)) { hasAppeared = true }
        }
        .sensoryFeedback(.success, trigger: hasAppeared)
    }
}
