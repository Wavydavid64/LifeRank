import SwiftUI

/// Eight-axis attribute chart drawn with Canvas and Path (DESIGN.md §6).
/// Takes values already computed by the domain layer — no XP math here.
/// Values are fractional levels, so the shape moves on every session rather
/// than jumping only when a level is crossed.
struct RadarChartView: View {
    let values: [Attribute: Double]
    /// Attribute level the outer ring represents, supplied per rank so the
    /// polygon grows within a rank and the chart widens on promotion.
    let ceiling: Double
    /// Matches the rank badge, so promotion recolors the chart too.
    var tint: Color = .accentColor

    private let axes = Attribute.allCases
    private let ringCount = 4

    /// Canvas cannot tween a dictionary, so the polygon is drawn between the
    /// previous and current values with a single animated scalar across them.
    @State private var previous: [Attribute: Double] = [:]
    @State private var target: [Attribute: Double] = [:]
    @State private var blend: Double = 1

    private func displayed(_ attribute: Attribute) -> Double {
        let start = previous[attribute] ?? 0
        let end = target[attribute] ?? 0
        return start + (end - start) * blend
    }

    /// Normally the rank's ceiling, so growth is visible. Outgrowing your rank
    /// pushes the ring out to the strongest attribute instead of clipping the
    /// polygon outside the chart.
    private var scale: Double {
        max(ceiling, axes.map(displayed).max() ?? 0)
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.70
            let grid = Color.secondary.opacity(0.25)

            for ring in 1...ringCount {
                context.stroke(
                    polygon(center: center, radius: radius * Double(ring) / Double(ringCount)),
                    with: .color(grid),
                    lineWidth: 1
                )
            }

            for index in axes.indices {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: point(center: center, radius: radius, index: index))
                context.stroke(spoke, with: .color(grid), lineWidth: 1)
            }

            var build = Path()
            for (index, attribute) in axes.enumerated() {
                let fraction = displayed(attribute) / scale
                let vertex = point(center: center, radius: radius * fraction, index: index)
                index == 0 ? build.move(to: vertex) : build.addLine(to: vertex)
            }
            build.closeSubpath()
            context.fill(build, with: .color(tint.opacity(0.30)))
            context.stroke(build, with: .color(tint), lineWidth: 2)

            for (index, attribute) in axes.enumerated() {
                var label = context.resolve(Text(attribute.displayName).font(.caption2))
                label.shading = .color(.secondary)
                context.draw(label, at: point(center: center, radius: radius * 1.22, index: index))
            }
        }
        .accessibilityLabel("Attribute radar chart")
        .onAppear {
            previous = values
            target = values
            blend = 1
        }
        .onChange(of: values) { _, newValues in
            previous = Dictionary(uniqueKeysWithValues: axes.map { ($0, displayed($0)) })
            target = newValues
            blend = 0
            withAnimation(.smooth(duration: 0.5)) { blend = 1 }
        }
    }

    private func point(center: CGPoint, radius: Double, index: Int) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(axes.count)
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func polygon(center: CGPoint, radius: Double) -> Path {
        var path = Path()
        for index in axes.indices {
            let vertex = point(center: center, radius: radius, index: index)
            index == 0 ? path.move(to: vertex) : path.addLine(to: vertex)
        }
        path.closeSubpath()
        return path
    }
}
