import SwiftUI

/// Eight-axis attribute chart drawn with Canvas and Path (DESIGN.md §6).
/// Takes levels already computed by the domain layer — no XP math here.
struct RadarChartView: View {
    let levels: [Attribute: Int]

    private let axes = Attribute.allCases
    private let ringCount = 4

    /// Scale the chart to the strongest attribute, with a floor so a new
    /// character's empty chart neither divides by zero nor reads as complete.
    private var scale: Double {
        Double(max(levels.values.max() ?? 0, 5))
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
                let fraction = Double(levels[attribute] ?? 0) / scale
                let vertex = point(center: center, radius: radius * fraction, index: index)
                index == 0 ? build.move(to: vertex) : build.addLine(to: vertex)
            }
            build.closeSubpath()
            context.fill(build, with: .color(.accentColor.opacity(0.30)))
            context.stroke(build, with: .color(.accentColor), lineWidth: 2)

            for (index, attribute) in axes.enumerated() {
                var label = context.resolve(Text(attribute.displayName).font(.caption2))
                label.shading = .color(.secondary)
                context.draw(label, at: point(center: center, radius: radius * 1.22, index: index))
            }
        }
        .accessibilityLabel("Attribute radar chart")
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
