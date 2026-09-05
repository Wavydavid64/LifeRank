import SwiftUI

/// What a logged session just earned. Shown once, briefly, at the moment the
/// reward actually happens.
///
/// It shows the XP ledger and nothing else — no coins, no fanfare (DESIGN.md
/// §37). The weight comes from typography and the attributes arriving in
/// sequence rather than all at once.
struct XPAwardView: View {
    let award: XPAward

    @State private var revealed = false

    /// Largest contribution first — it reads as a ranking of what the session
    /// actually built.
    private var attributes: [(attribute: Attribute, amount: Int)] {
        award.stats.attributeXP
            .map { (attribute: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(award.skillName.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .tracking(3)
                .foregroundStyle(.secondary)

            Text("+\(award.stats.totalXP) XP")
                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                .foregroundStyle(.tint)
                .contentTransition(.numericText())

            if !attributes.isEmpty {
                Divider().padding(.horizontal, 24)

                VStack(spacing: 6) {
                    ForEach(Array(attributes.enumerated()), id: \.element.attribute) { index, entry in
                        HStack {
                            Text(entry.attribute.displayName)
                                .font(.system(.footnote, design: .monospaced))
                            Spacer()
                            Text("+\(entry.amount)")
                                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 8)
                        .animation(
                            .smooth(duration: 0.32).delay(0.12 + Double(index) * 0.07),
                            value: revealed
                        )
                    }
                }
                .padding(.horizontal, 28)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.tint.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 28)
        .scaleEffect(revealed ? 1 : 0.94)
        .onAppear { revealed = true }
        .sensoryFeedback(.impact(weight: .medium), trigger: revealed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(award.skillName) earned \(award.stats.totalXP) XP. "
            + attributes.map { "\($0.attribute.displayName) plus \($0.amount)" }.joined(separator: ", ")
        )
    }
}

/// One session's earnings, kept together so the view can be driven by a single
/// piece of state.
struct XPAward: Equatable, Identifiable {
    let id = UUID()
    let skillName: String
    let stats: CharacterStats

    init(skillName: String, events: [XPEvent]) {
        self.skillName = skillName
        self.stats = CharacterStats.derive(from: events)
    }
}
