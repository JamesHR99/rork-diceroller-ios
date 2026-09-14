import SwiftUI

/// Ra's solar barque drawn as a real object: a curved reed hull, a papyrus
/// bloom at the prow, a raised stern, oars dipping into the water and the sun
/// disc burning amidships inside its shrine.
///
/// The disc's glow is driven by `discGlow`, so the whole scene can dim when the
/// demigod is hurt and flare back when Ra is defended well.
struct BarqueView: View {
    let gate: Gate
    /// Hull width in points.
    var width: CGFloat = 260
    /// 0 through 1 — how brightly the disc burns.
    var discGlow: Double = 1
    /// Whether the oars stroke and the hull rocks.
    var animated: Bool = true

    private var height: CGFloat { width * 0.34 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let rock = animated ? sin(time * 0.9) : 0
            let stroke = animated ? sin(time * 1.4) : 0

            ZStack {
                oars(stroke: stroke)
                hull
                shrine
                disc(time: time)
            }
            .frame(width: width, height: height * 1.9)
            .rotationEffect(.degrees(rock * 1.6))
            .offset(y: CGFloat(rock * 2.4))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Pieces

    private var hull: some View {
        HullShape()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.clay.opacity(0.85),
                        Color(red: 0.30, green: 0.22, blue: 0.16),
                        Color(red: 0.14, green: 0.10, blue: 0.08),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                HullShape()
                    .strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1.4)
            )
            .overlay(
                // Lashing lines across the reed bundle.
                HStack(spacing: width * 0.075) {
                    ForEach(0..<9, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.gold.opacity(0.18))
                            .frame(width: 1)
                    }
                }
                .frame(height: height * 0.42)
                .offset(y: height * 0.28)
                .mask(HullShape())
            )
            .frame(width: width, height: height)
            .shadow(color: gate.discColor.opacity(0.35 * discGlow), radius: 20, y: 6)
    }

    /// The little naos amidships that carries the disc.
    private var shrine: some View {
        ZStack {
            TrapezoidShape(topInset: 0.22)
                .fill(
                    LinearGradient(colors: [Theme.goldDeep.opacity(0.9), Color(red: 0.20, green: 0.15, blue: 0.10)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    TrapezoidShape(topInset: 0.22)
                        .strokeBorder(Theme.gold.opacity(0.7), lineWidth: 1)
                )
                .frame(width: width * 0.30, height: height * 0.72)
        }
        .offset(y: -height * 0.52)
    }

    private func disc(time: TimeInterval) -> some View {
        let pulse = animated ? 0.5 + 0.5 * sin(time * 1.7) : 0.5
        let size = width * 0.155
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [gate.discColor.opacity(0.55 * discGlow), .clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 2.1
                    )
                )
                .frame(width: size * 4, height: size * 4)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.parchment, gate.discColor, gate.discColor.opacity(0.6)],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: gate.discColor.opacity(0.9 * discGlow), radius: 10 + pulse * 8)
                .opacity(0.55 + 0.45 * discGlow)
        }
        .offset(y: -height * 0.78)
    }

    private func oars(stroke: Double) -> some View {
        HStack(spacing: width * 0.11) {
            ForEach(0..<4, id: \.self) { index in
                let phase = stroke * (index % 2 == 0 ? 1 : -1)
                Capsule()
                    .fill(
                        LinearGradient(colors: [Theme.clay.opacity(0.7), Color(red: 0.12, green: 0.09, blue: 0.07)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 2.4, height: height * 1.05)
                    .rotationEffect(.degrees(18 + phase * 9), anchor: .top)
            }
        }
        .offset(y: height * 0.55)
        .opacity(0.85)
    }
}

/// The crescent reed hull: high curved prow and stern, low waist.
private struct HullShape: InsettableShape {
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> HullShape {
        var copy = self
        copy.inset += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var path = Path()
        // Deck line, curving up sharply at both ends.
        path.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.10))
        path.addQuadCurve(
            to: CGPoint(x: r.midX, y: r.minY + r.height * 0.46),
            control: CGPoint(x: r.minX + r.width * 0.22, y: r.minY + r.height * 0.50)
        )
        path.addQuadCurve(
            to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.10),
            control: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY + r.height * 0.50)
        )
        // Stern tip curls inward.
        path.addQuadCurve(
            to: CGPoint(x: r.maxX - r.width * 0.10, y: r.minY + r.height * 0.34),
            control: CGPoint(x: r.maxX - r.width * 0.005, y: r.minY + r.height * 0.30)
        )
        // Underside.
        path.addQuadCurve(
            to: CGPoint(x: r.minX + r.width * 0.10, y: r.minY + r.height * 0.34),
            control: CGPoint(x: r.midX, y: r.maxY)
        )
        // Prow tip curls inward.
        path.addQuadCurve(
            to: CGPoint(x: r.minX, y: r.minY + r.height * 0.10),
            control: CGPoint(x: r.minX + r.width * 0.005, y: r.minY + r.height * 0.30)
        )
        path.closeSubpath()
        return path
    }
}

/// A shrine box, narrower at the top.
private struct TrapezoidShape: InsettableShape {
    /// How far each top corner is pulled in, as a fraction of the width.
    var topInset: CGFloat = 0.2
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> TrapezoidShape {
        var copy = self
        copy.inset += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX + r.width * topInset, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX - r.width * topInset, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.closeSubpath()
        return path
    }
}
