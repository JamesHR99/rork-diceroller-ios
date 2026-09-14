import SwiftUI

/// The living Duat scene that sits behind every screen: a deep star field, a
/// far bank of dunes and broken pylons drifting past, and slow black water with
/// the sun disc's reflection rolling across it.
///
/// The layers scroll at different speeds so the barque always feels like it is
/// travelling, even while the player is reading a card.
struct DuatSceneView: View {
    let gate: Gate
    /// Where the water begins, as a fraction of the view's height.
    var waterline: CGFloat = 0.58
    /// How fast the world slides past. 0 stops the scene dead.
    var speed: Double = 1
    /// Extra darkness laid over the whole scene, 0 through 1.
    var dim: Double = 0
    /// 0 through 1 — how brightly Ra's disc is burning right now.
    var discGlow: Double = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed

            Canvas(rendersAsynchronously: true) { ctx, size in
                draw(ctx: &ctx, size: size, time: time)
            }
            .drawingGroup()
        }
        .overlay(Color.black.opacity(dim).allowsHitTesting(false))
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Drawing

    private func draw(ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let horizon = size.height * waterline

        drawSky(&ctx, size: size, horizon: horizon, time: time)
        drawStars(&ctx, size: size, horizon: horizon, time: time)
        drawHorizonGlow(&ctx, size: size, horizon: horizon)
        drawDunes(&ctx, size: size, horizon: horizon, time: time)
        drawPylons(&ctx, size: size, horizon: horizon, time: time)
        drawWater(&ctx, size: size, horizon: horizon, time: time)
        if gate.hasReeds { drawReeds(&ctx, size: size, horizon: horizon, time: time) }
        if gate.hasEmbers { drawEmbers(&ctx, size: size, horizon: horizon, time: time) }
        if gate.hasSerpent { drawSerpent(&ctx, size: size, horizon: horizon, time: time) }
    }

    /// The hand-painted papyrus sheet the whole river scene is brushed onto —
    /// its fibres and uneven ink stay faintly visible under every layer.
    private func drawPainting(_ ctx: inout GraphicsContext, size: CGSize) {
        let resolved = ctx.resolve(Image("solar_barque_duat_river"))
        let saved = ctx.opacity
        ctx.opacity = 0.32
        ctx.draw(resolved, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        ctx.opacity = saved
    }

    private func drawSky(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: horizon)
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [gate.skyTop, gate.skyTop, gate.skyHorizon]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: horizon)
            )
        )
    }

    private func drawStars(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        // The star field drifts a fraction of the speed of the bank.
        let drift = CGFloat((time * 3).truncatingRemainder(dividingBy: Double(size.width + 1)))
        for star in StarField.stars {
            let x = (star.x * size.width - drift).truncatingRemainder(dividingBy: size.width + 1)
            let px = x < 0 ? x + size.width : x
            let py = star.y * horizon
            let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(time * star.speed + star.phase))
            // Apep is eating the stars in the last gate.
            let gateFade = gate == .coils ? 0.35 : 1.0
            let radius = star.radius
            let rect = CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2)
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(Theme.parchment.opacity(twinkle * star.brightness * gateFade))
            )
        }
    }

    private func drawHorizonGlow(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let glowHeight = horizon * 0.45
        let rect = CGRect(x: 0, y: horizon - glowHeight, width: size.width, height: glowHeight)
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [.clear, gate.discColor.opacity(0.20 * discGlow)]),
                startPoint: CGPoint(x: 0, y: rect.minY),
                endPoint: CGPoint(x: 0, y: rect.maxY)
            )
        )
    }

    private func drawDunes(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        // Two ridges at different speeds give the far bank depth.
        drawRidge(&ctx, size: size, horizon: horizon, time: time,
                  speed: 6, amplitude: horizon * 0.09, base: horizon * 0.06,
                  wavelength: size.width * 0.7, color: gate.bank.opacity(0.65))
        drawRidge(&ctx, size: size, horizon: horizon, time: time,
                  speed: 13, amplitude: horizon * 0.055, base: horizon * 0.02,
                  wavelength: size.width * 0.4, color: gate.bank)
    }

    private func drawRidge(
        _ ctx: inout GraphicsContext,
        size: CGSize,
        horizon: CGFloat,
        time: Double,
        speed: Double,
        amplitude: CGFloat,
        base: CGFloat,
        wavelength: CGFloat,
        color: Color
    ) {
        var path = Path()
        let offset = CGFloat(time * speed)
        path.move(to: CGPoint(x: 0, y: horizon))
        var x: CGFloat = 0
        while x <= size.width {
            let theta = Double((x + offset) / max(wavelength, 1)) * 2 * .pi
            let y = horizon - base - amplitude * CGFloat(0.5 + 0.5 * sin(theta) + 0.25 * sin(theta * 2.3))
            path.addLine(to: CGPoint(x: x, y: y))
            x += 8
        }
        path.addLine(to: CGPoint(x: size.width, y: horizon))
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
    }

    private func drawPylons(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        let span = size.width * 1.5
        let offset = CGFloat((time * 11).truncatingRemainder(dividingBy: Double(span)))
        for ruin in Ruins.all {
            let x = ruin.x * span - offset
            guard x > -80, x < size.width + 80 else { continue }
            let height = horizon * ruin.height
            let width = height * ruin.widthRatio
            let baseY = horizon - horizon * 0.02

            var path = Path()
            path.move(to: CGPoint(x: x - width / 2, y: baseY))
            path.addLine(to: CGPoint(x: x - width * 0.34, y: baseY - height))
            path.addLine(to: CGPoint(x: x + width * 0.34, y: baseY - height))
            path.addLine(to: CGPoint(x: x + width / 2, y: baseY))
            path.closeSubpath()
            ctx.fill(path, with: .color(gate.bank.opacity(0.92)))

            // A thin lit edge where the disc catches the stone.
            var edge = Path()
            edge.move(to: CGPoint(x: x + width * 0.34, y: baseY - height))
            edge.addLine(to: CGPoint(x: x + width / 2, y: baseY))
            ctx.stroke(edge, with: .color(gate.discColor.opacity(0.16 * discGlow)), lineWidth: 1)
        }
    }

    private func drawWater(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        let rect = CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [gate.waterTop, gate.waterBottom]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // The reflected disc: a wobbling column of light straight down the middle.
        let columnWidth = size.width * 0.16
        let centre = size.width * 0.5
        var reflection = Path()
        reflection.move(to: CGPoint(x: centre - columnWidth * 0.18, y: horizon))
        reflection.addLine(to: CGPoint(x: centre - columnWidth, y: size.height))
        reflection.addLine(to: CGPoint(x: centre + columnWidth, y: size.height))
        reflection.addLine(to: CGPoint(x: centre + columnWidth * 0.18, y: horizon))
        reflection.closeSubpath()
        ctx.fill(
            reflection,
            with: .linearGradient(
                Gradient(colors: [gate.reflection.opacity(0.26 * discGlow), .clear]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Ripple lines, faster and wider the nearer the bottom of the frame.
        let waterHeight = size.height - horizon
        let lines = 16
        for index in 0..<lines {
            let progress = Double(index) / Double(lines)
            let y = horizon + waterHeight * CGFloat(pow(progress, 1.6)) + 2
            let phase = time * (0.6 + progress * 2.4) + Double(index) * 1.7
            let wobble = CGFloat(sin(phase)) * CGFloat(8 + progress * 44)
            let width = size.width * CGFloat(0.16 + progress * 0.5)
            let alpha = (0.05 + progress * 0.16) * (0.6 + 0.4 * (0.5 + 0.5 * sin(phase * 1.4)))

            var line = Path()
            let start = centre + wobble - width / 2
            line.move(to: CGPoint(x: start, y: y))
            line.addLine(to: CGPoint(x: start + width, y: y))
            ctx.stroke(
                line,
                with: .color(gate.reflection.opacity(alpha * discGlow)),
                style: StrokeStyle(lineWidth: 1 + CGFloat(progress) * 1.6, lineCap: .round)
            )

            // A faint counter-ripple away from the reflected column.
            var edgeLine = Path()
            let edgeY = y + 3
            edgeLine.move(to: CGPoint(x: 0, y: edgeY))
            edgeLine.addLine(to: CGPoint(x: size.width, y: edgeY))
            ctx.stroke(
                edgeLine,
                with: .color(Theme.parchment.opacity(0.018 + progress * 0.022)),
                lineWidth: 0.6
            )
        }
    }

    private func drawReeds(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        for reed in Reeds.all {
            let x = reed.leftSide ? reed.offset * size.width * 0.16 : size.width - reed.offset * size.width * 0.16
            let height = (size.height - horizon) * reed.height + horizon * 0.1
            let baseY = size.height * 0.98
            let sway = CGFloat(sin(time * reed.speed + reed.phase)) * 10

            var path = Path()
            path.move(to: CGPoint(x: x, y: baseY))
            path.addQuadCurve(
                to: CGPoint(x: x + sway, y: baseY - height),
                control: CGPoint(x: x + sway * 0.3, y: baseY - height * 0.55)
            )
            ctx.stroke(path, with: .color(gate.bank.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

            // A seed head at the tip.
            let tip = CGRect(x: x + sway - 2.4, y: baseY - height - 4, width: 4.8, height: 8)
            ctx.fill(Path(ellipseIn: tip), with: .color(gate.bank.opacity(0.9)))
        }
    }

    /// The last gate: something enormous turns just under the surface. Three
    /// arcs of a coil break the water at different phases, so it reads as one
    /// body rolling past rather than three separate shapes.
    private func drawSerpent(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        let waterHeight = size.height - horizon
        let scaleTint = Color(red: 0.180, green: 0.110, blue: 0.240)

        for index in 0..<3 {
            let lane = Double(index)
            let depth = 0.30 + lane * 0.26
            let baseY = horizon + waterHeight * CGFloat(depth)
            let travel = (time * (7 + lane * 4) + lane * 260)
                .truncatingRemainder(dividingBy: Double(size.width + 420)) - 210
            let x = CGFloat(travel)
            let span = size.width * CGFloat(0.30 + lane * 0.08)
            let rise = CGFloat(10 + lane * 7) * CGFloat(0.6 + 0.4 * sin(time * 0.7 + lane))

            var coil = Path()
            coil.move(to: CGPoint(x: x, y: baseY))
            coil.addQuadCurve(
                to: CGPoint(x: x + span, y: baseY),
                control: CGPoint(x: x + span * 0.5, y: baseY - rise * 2.6)
            )
            coil.addQuadCurve(
                to: CGPoint(x: x, y: baseY),
                control: CGPoint(x: x + span * 0.5, y: baseY + rise * 0.9)
            )
            coil.closeSubpath()
            ctx.fill(coil, with: .color(scaleTint.opacity(0.42 + lane * 0.10)))

            // A wet highlight along the crest where the disc catches the scales.
            var crest = Path()
            crest.move(to: CGPoint(x: x + span * 0.12, y: baseY - rise * 0.5))
            crest.addQuadCurve(
                to: CGPoint(x: x + span * 0.88, y: baseY - rise * 0.5),
                control: CGPoint(x: x + span * 0.5, y: baseY - rise * 2.2)
            )
            ctx.stroke(
                crest,
                with: .color(gate.reflection.opacity(0.16 * discGlow)),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
            )
        }
    }

    private func drawEmbers(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, time: Double) {
        for ember in Embers.all {
            let cycle = (time * ember.speed + ember.phase).truncatingRemainder(dividingBy: 1)
            let rise = CGFloat(1 - cycle)
            let y = size.height * rise
            let x = ember.x * size.width + CGFloat(sin(time * 1.6 + ember.phase * 6)) * 14
            let alpha = (1 - abs(cycle - 0.4) * 1.6) * 0.8
            guard alpha > 0 else { continue }
            let radius = ember.radius
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Theme.ember.opacity(alpha)))
        }
    }
}

// MARK: - Precomputed scenery

/// Deterministic star field so the sky is stable between redraws.
private enum StarField {
    struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let brightness: Double
        let phase: Double
        let speed: Double
    }

    static let stars: [Star] = {
        var generator = SeededGenerator(seed: 20260802)
        return (0..<110).map { _ in
            Star(
                x: CGFloat(Double.random(in: 0...1, using: &generator)),
                y: CGFloat(Double.random(in: 0.02...0.92, using: &generator)),
                radius: CGFloat(Double.random(in: 0.5...1.7, using: &generator)),
                brightness: Double.random(in: 0.25...0.95, using: &generator),
                phase: Double.random(in: 0...6.28, using: &generator),
                speed: Double.random(in: 0.4...1.8, using: &generator)
            )
        }
    }()
}

private enum Ruins {
    struct Ruin {
        let x: CGFloat
        let height: CGFloat
        let widthRatio: CGFloat
    }

    static let all: [Ruin] = {
        var generator = SeededGenerator(seed: 771233)
        return (0..<9).map { index in
            Ruin(
                x: CGFloat(Double(index) / 9.0 + Double.random(in: -0.03...0.03, using: &generator)),
                height: CGFloat(Double.random(in: 0.10...0.30, using: &generator)),
                widthRatio: CGFloat(Double.random(in: 0.35...0.75, using: &generator))
            )
        }
    }()
}

private enum Reeds {
    struct Reed {
        let leftSide: Bool
        let offset: CGFloat
        let height: CGFloat
        let phase: Double
        let speed: Double
    }

    static let all: [Reed] = {
        var generator = SeededGenerator(seed: 5150)
        return (0..<14).map { index in
            Reed(
                leftSide: index % 2 == 0,
                offset: CGFloat(Double.random(in: 0.05...1.0, using: &generator)),
                height: CGFloat(Double.random(in: 0.35...0.95, using: &generator)),
                phase: Double.random(in: 0...6.28, using: &generator),
                speed: Double.random(in: 0.5...1.3, using: &generator)
            )
        }
    }()
}

private enum Embers {
    struct Ember {
        let x: CGFloat
        let radius: CGFloat
        let phase: Double
        let speed: Double
    }

    static let all: [Ember] = {
        var generator = SeededGenerator(seed: 90210)
        return (0..<26).map { _ in
            Ember(
                x: CGFloat(Double.random(in: 0...1, using: &generator)),
                radius: CGFloat(Double.random(in: 0.8...2.2, using: &generator)),
                phase: Double.random(in: 0...1, using: &generator),
                speed: Double.random(in: 0.05...0.14, using: &generator)
            )
        }
    }()
}

/// Tiny deterministic PRNG so the scenery is identical every launch.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
