import SwiftUI

/// A repeating band of carved glyph marks — the thin decorative rule that runs
/// under headings and along the top of panels. Each mark is inked with a
/// slightly different tilt and weight, so the row reads as hand-drawn.
struct HieroglyphBand: View {
    var tint: Color = Theme.gold
    var height: CGFloat = 9
    var opacity: Double = 0.5

    var body: some View {
        Canvas { context, size in
            let unit = height
            let step = unit * 1.35
            var x: CGFloat = 0
            var index = 0
            while x < size.width {
                let colour = GraphicsContext.Shading.color(
                    tint.opacity(opacity * inkStrength(index))
                )
                // A wobbly hand tilts and nudges every mark.
                var brush = context
                let midX = x + step * 0.5
                let midY = size.height / 2
                brush.translateBy(x: midX, y: midY)
                brush.rotate(by: .degrees(jitter(index) * 2.4))
                brush.translateBy(x: -midX, y: -midY)
                drawGlyph(
                    &brush,
                    kind: index % 5,
                    at: x + jitter(index + 3) * unit * 0.08,
                    midY: midY + jitter(index + 7) * unit * 0.10,
                    unit: unit,
                    colour: colour,
                    width: 0.85 + inkStrength(index + 2) * 0.5
                )
                x += step
                index += 1
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    /// Deterministic wobble in -1...1, so the band is identical every frame.
    private func jitter(_ index: Int) -> CGFloat {
        let value = sin(Double(index) * 12.9898) * 43758.5453
        return CGFloat((value - value.rounded(.down))) * 2 - 1
    }

    /// Ink weight varies stroke to stroke.
    private func inkStrength(_ index: Int) -> Double {
        0.72 + 0.28 * abs(jitter(index + 11))
    }

    private func drawGlyph(
        _ ctx: inout GraphicsContext,
        kind: Int,
        at x: CGFloat,
        midY: CGFloat,
        unit: CGFloat,
        colour: GraphicsContext.Shading,
        width: CGFloat
    ) {
        let stroke = StrokeStyle(lineWidth: width, lineCap: .round)
        switch kind {
        case 0:
            // Ankh-ish: a ring over a stem.
            let ring = CGRect(x: x, y: midY - unit * 0.45, width: unit * 0.38, height: unit * 0.38)
            ctx.stroke(Path(ellipseIn: ring), with: colour, style: stroke)
            var stem = Path()
            stem.move(to: CGPoint(x: x + unit * 0.19, y: midY - unit * 0.06))
            stem.addLine(to: CGPoint(x: x + unit * 0.19, y: midY + unit * 0.45))
            ctx.stroke(stem, with: colour, style: stroke)
        case 1:
            // Water: a small zigzag.
            var wave = Path()
            wave.move(to: CGPoint(x: x, y: midY))
            for step in 0..<3 {
                let dx = x + CGFloat(step) * unit * 0.22
                wave.addLine(to: CGPoint(x: dx + unit * 0.11, y: midY - unit * 0.18))
                wave.addLine(to: CGPoint(x: dx + unit * 0.22, y: midY))
            }
            ctx.stroke(wave, with: colour, style: stroke)
        case 2:
            // Eye: a lens with a pupil.
            var eye = Path()
            eye.move(to: CGPoint(x: x, y: midY))
            eye.addQuadCurve(to: CGPoint(x: x + unit * 0.5, y: midY),
                             control: CGPoint(x: x + unit * 0.25, y: midY - unit * 0.42))
            eye.addQuadCurve(to: CGPoint(x: x, y: midY),
                             control: CGPoint(x: x + unit * 0.25, y: midY + unit * 0.24))
            ctx.stroke(eye, with: colour, style: stroke)
        case 3:
            // Reed: a tall stroke with a tick.
            var reed = Path()
            reed.move(to: CGPoint(x: x + unit * 0.12, y: midY + unit * 0.45))
            reed.addLine(to: CGPoint(x: x + unit * 0.12, y: midY - unit * 0.45))
            reed.addLine(to: CGPoint(x: x + unit * 0.34, y: midY - unit * 0.26))
            ctx.stroke(reed, with: colour, style: stroke)
        default:
            // Disc.
            let disc = CGRect(x: x, y: midY - unit * 0.2, width: unit * 0.4, height: unit * 0.4)
            ctx.fill(Path(ellipseIn: disc), with: colour)
        }
    }
}

/// A carved heading: the hand-carved display face, gold leaf, with a glyph
/// rule inked beneath.
struct CarvedTitle: View {
    let text: String
    var size: CGFloat = 22
    var tint: Color = Theme.parchment
    var kerning: CGFloat = 4
    var showsRule: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text.uppercased())
                .font(.fantasy(size))
                .kerning(kerning)
                .foregroundStyle(
                    LinearGradient(colors: [tint, tint.opacity(0.72)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.65), radius: 0, x: 0, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if showsRule {
                HieroglyphBand(tint: Theme.gold, height: 7, opacity: 0.45)
            }
        }
    }
}

/// A god's or hero's name set inside a cartouche loop.
struct CartoucheView: View {
    let text: String
    var tint: Color = Theme.gold
    var size: CGFloat = 12

    var body: some View {
        Text(text.uppercased())
            .font(.fantasy(size))
            .kerning(2)
            .foregroundStyle(tint)
            .padding(.horizontal, size * 0.9)
            .padding(.vertical, size * 0.34)
            .background(
                Capsule().fill(Theme.bg.opacity(0.65))
            )
            .overlay(
                Capsule().strokeBorder(tint.opacity(0.75), lineWidth: 1.2)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(tint.opacity(0.75))
                    .frame(width: 1.2, height: size * 1.0)
                    .offset(x: size * 0.42)
            }
    }
}

/// The standard framed panel: dark papyrus with visible fibres, thin gold
/// rule, glyph band inked at the head. Used for every card-like surface.
struct DuatPanel<Content: View>: View {
    var tint: Color = Theme.gold
    var cornerRadius: CGFloat = 16
    var showsBand: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .papyrusPanel(cornerRadius: cornerRadius)
            .overlay(alignment: .top) {
                if showsBand {
                    HieroglyphBand(tint: tint, height: 8, opacity: 0.3)
                        .padding(.horizontal, cornerRadius * 0.6)
                        .padding(.top, 3)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(tint.opacity(0.38), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: 3)
                    .strokeBorder(tint.opacity(0.12), lineWidth: 0.75)
            )
    }
}

extension View {
    /// Wraps any view in the standard limestone-and-gold panel.
    func duatPanel(tint: Color = Theme.gold, cornerRadius: CGFloat = 16, showsBand: Bool = true) -> some View {
        DuatPanel(tint: tint, cornerRadius: cornerRadius, showsBand: showsBand) { self }
    }
}

/// The slim night-dial: twelve hours as a row of marks, filled in behind you,
/// with the gate boundaries called out. Replaces the old progress bar.
struct NightDialView: View {
    let currentHour: Int
    let hoursCleared: Int
    var compact: Bool = false

    private var gate: Gate { Gate.forHour(currentHour) }

    var body: some View {
        HStack(spacing: compact ? 7 : 9) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: compact ? 9 : 11, weight: .bold))
                .foregroundStyle(gate.discColor)
                .shadow(color: gate.discColor.opacity(0.8), radius: 6)

            HStack(spacing: compact ? 3 : 4) {
                ForEach(1...Voyage.totalHours, id: \.self) { hour in
                    mark(hour)
                }
            }

            if !compact {
                Text(Voyage.fullName(currentHour).uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 4 : 5)
        .background(Theme.bg.opacity(0.6), in: .capsule)
        .overlay(Capsule().strokeBorder(gate.accent.opacity(0.35), lineWidth: 1))
    }

    private func mark(_ hour: Int) -> some View {
        let cleared = hour <= hoursCleared
        let isNow = hour == currentHour
        let isGateEnd = hour % 4 == 0
        let tint = Gate.forHour(hour).accent

        return Group {
            if isGateEnd {
                Image(systemName: "lizard.fill")
                    .font(.system(size: compact ? 7 : 8, weight: .black))
                    .foregroundStyle(cleared ? tint : (isNow ? Theme.parchment : Theme.parchmentDim.opacity(0.4)))
            } else {
                Circle()
                    .fill(cleared ? tint : (isNow ? Theme.parchment : Theme.parchmentDim.opacity(0.22)))
                    .frame(width: compact ? 4 : 5, height: compact ? 4 : 5)
            }
        }
        .frame(width: compact ? 9 : 11)
        .scaleEffect(isNow ? 1.5 : 1)
        .shadow(color: isNow ? Theme.parchment.opacity(0.8) : .clear, radius: 5)
    }
}
