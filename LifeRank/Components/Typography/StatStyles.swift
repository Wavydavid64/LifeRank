import SwiftUI

/// Shared type treatment for statistics (DESIGN.md §37: strong typography,
/// subtle RPG influence, no decoration). Monospaced throughout so columns of
/// numbers line up and the app reads as an instrument panel rather than a form.
extension View {

    /// Small tracked uppercase caption. Labels a value; never carries one.
    func statLabel() -> some View {
        font(.system(.caption2, design: .monospaced).weight(.semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    /// The number itself.
    func statValue(size: CGFloat = 26) -> some View {
        font(.system(size: size, weight: .heavy, design: .monospaced))
            .monospacedDigit()
    }

    /// A grouped block of stats. Slight lift off the background rather than a
    /// card with a border — §37 warns against clutter and gradients.
    func statPanel(padding amount: CGFloat = 14) -> some View {
        self
            .padding(amount)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.primary.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }
}
