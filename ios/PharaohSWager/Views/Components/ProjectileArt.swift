import SwiftUI

/// Every shot in the game, drawn in code in the Tomb Ink palette. Nothing here
/// is a shrunken picture of a die face — an arrow is a shaft with a head and
/// flights, a fireball churns, a frost shard is faceted crystal.
///
/// Each form draws itself pointing *right*; the flight layer rotates the whole
/// thing into its heading, so no drawing needs to know where it is going.
struct ProjectileArtView: View {
    let form: ProjectileForm
    let size: CGFloat
    let tint: Color
    /// 0 at the thrower's hand, 1 on impact — lets a form animate in flight.
    let progress: Double
    let isCrit: Bool
    var magnitude: Int = 1
    var sourceEnemyID: String? = nil

    var body: some View {
        Group {
            if let image = InkWorldArt.cell("ink_projectiles", index: InkWorldArt.projectileIndex(form, enemy: sourceEnemyID)) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(width: size * 1.45, height: size)
            } else {
            switch form {
            case .arrow: ArrowShot(size: size, tint: tint)
            case .crescent: CrescentShot(size: size, tint: tint, progress: progress)
            case .tumblingBlade: BladeShot(size: size, tint: tint)
            case .fireOrb: FireOrbShot(size: size, tint: tint, progress: progress)
            case .frostShard: FrostShardShot(size: size, tint: tint, progress: progress)
            case .lifeMotes: LifeMotesShot(size: size, tint: tint, progress: progress)
            case .arcaneBolt: ArcaneBoltShot(size: size, tint: tint, progress: progress)
            case .lightning: LightningShot(size: size, tint: tint, progress: progress)
            case .venomFlask: VenomFlaskShot(size: size, tint: tint)
            }
            }
        }
        .overlay {
            ComboProjectileCrown(form: form, size: size, tint: tint,
                                 progress: progress, magnitude: magnitude)
        }
        .shadow(color: Color(red: 0.035, green: 0.02, blue: 0.09), radius: 0, x: 1.5, y: 1.5)
        // A critical washes the whole shot gold on its way across, not just
        // when it lands.
        .overlay {
            if isCrit {
                Circle()
                    .fill(Theme.gold.opacity(0.28))
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: size * 0.3)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Arrow

/// A real arrow: tapered shaft, bronze head, fletching at the back.
private struct ArrowShot: View {
    let size: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            // Shaft
            Capsule()
                .fill(
                    LinearGradient(colors: [Theme.bronze.opacity(0.5), Theme.parchment],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: size, height: max(1.6, size * 0.055))

            // Head
            Triangle()
                .fill(
                    LinearGradient(colors: [Theme.parchment, Theme.bronze],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: size * 0.26, height: size * 0.2)
                .offset(x: size * 0.46)
                .shadow(color: tint.opacity(0.9), radius: size * 0.1)

            // Fletching — two short vanes swept back off the nock.
            ForEach([-1.0, 1.0], id: \.self) { side in
                Triangle()
                    .fill(tint.opacity(0.85))
                    .frame(width: size * 0.2, height: size * 0.13)
                    .rotationEffect(.degrees(side > 0 ? 150 : 210))
                    .offset(x: -size * 0.42, y: size * 0.06 * side)
            }
        }
        .frame(width: size, height: size * 0.3)
    }
}

// MARK: - Crescent slash

/// A wave of edge-light thrown off a blade, widening as it crosses.
private struct CrescentShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        let widen = 1 + progress * 0.5
        return Crescent()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.15), Theme.parchment.opacity(0.95), tint],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(width: size * 0.5, height: size * 1.05 * widen)
            .shadow(color: tint.opacity(0.9), radius: size * 0.22)
            .blendMode(.plusLighter)
    }
}

/// The arc of a swung edge: an outer curve with an inner one bitten out.
private struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.maxX * 1.6, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.maxX * 0.7, y: rect.midY)
        )
        return path
    }
}

// MARK: - Thrown blade

/// A dagger, drawn side-on so tumbling reads properly.
private struct BladeShot: View {
    let size: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            // Blade
            Triangle()
                .fill(
                    LinearGradient(colors: [Theme.parchment, Theme.steel],
                                   startPoint: .topLeading, endPoint: .bottom)
                )
                .frame(width: size * 0.62, height: size * 0.2)
                .rotationEffect(.degrees(90))
                .offset(x: size * 0.16)

            // Guard
            Capsule()
                .fill(Theme.bronze)
                .frame(width: size * 0.06, height: size * 0.28)
                .offset(x: -size * 0.12)

            // Grip
            Capsule()
                .fill(Theme.basalt)
                .frame(width: size * 0.26, height: size * 0.1)
                .offset(x: -size * 0.28)
        }
        .frame(width: size, height: size * 0.4)
        .shadow(color: tint.opacity(0.7), radius: size * 0.12)
    }
}

// MARK: - Fire

/// A churning sphere of fire: a white-hot core, a body of flame, and licking
/// tongues that shift as it travels.
private struct FireOrbShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        ZStack {
            InkFlameStar()
                .fill(tint)
                .frame(width: size * 1.2, height: size)
                .rotationEffect(.degrees(progress * 75))
            InkFlameStar()
                .fill(Color(red: 1, green: 0.77, blue: 0.08))
                .frame(width: size * 0.78, height: size * 0.68)
                .rotationEffect(.degrees(-progress * 110 + 20))
            InkFlameStar()
                .fill(Theme.parchment)
                .frame(width: size * 0.38, height: size * 0.34)
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }
}

private struct InkFlameStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in 0..<18 {
            let angle = Double(index) * .pi / 9
            let radius = index.isMultiple(of: 2) ? 0.5 : 0.27
            let point = CGPoint(x: rect.midX + cos(angle) * rect.width * radius,
                                y: rect.midY + sin(angle) * rect.height * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Frost

/// A faceted crystal shard, spitting cold motes as it goes.
private struct FrostShardShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        ZStack {
            // Motes shaken loose behind the shard.
            ForEach(0..<4, id: \.self) { index in
                let drift = Double(index) * 0.27 + progress
                Circle()
                    .fill(tint.opacity(0.75))
                    .frame(width: size * 0.09, height: size * 0.09)
                    .offset(
                        x: -size * (0.3 + CGFloat(index) * 0.18),
                        y: size * 0.3 * CGFloat(sin(drift * 7))
                    )
                    .blur(radius: 0.6)
            }

            Shard()
                .fill(
                    LinearGradient(colors: [Theme.parchment, tint, tint.opacity(0.5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: size * 0.95, height: size * 0.42)
                .overlay {
                    Shard()
                        .strokeBorder(Theme.parchment.opacity(0.9), lineWidth: 1)
                        .frame(width: size * 0.95, height: size * 0.42)
                }
        }
        .frame(width: size, height: size * 0.55)
        .shadow(color: tint.opacity(0.9), radius: size * 0.28)
    }
}

/// A six-sided crystal splinter, longer than it is tall.
private struct Shard: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        path.move(to: CGPoint(x: r.maxX, y: r.midY))
        path.addLine(to: CGPoint(x: r.maxX - r.width * 0.3, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + r.width * 0.18, y: r.minY + r.height * 0.18))
        path.addLine(to: CGPoint(x: r.minX, y: r.midY))
        path.addLine(to: CGPoint(x: r.minX + r.width * 0.18, y: r.maxY - r.height * 0.18))
        path.addLine(to: CGPoint(x: r.maxX - r.width * 0.3, y: r.maxY))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> Shard {
        Shard(insetAmount: insetAmount + amount)
    }
}

// MARK: - Life

/// Slow green motes drifting to their mark, curling upward instead of falling.
private struct LifeMotesShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                let phase = Double(index) / 6
                let rise = sin((progress + phase) * .pi * 2)
                Circle()
                    .fill(
                        RadialGradient(colors: [Theme.parchment, tint, .clear],
                                       center: .center, startRadius: 0, endRadius: size * 0.16)
                    )
                    .frame(width: size * (0.2 + 0.1 * CGFloat(phase)),
                           height: size * (0.2 + 0.1 * CGFloat(phase)))
                    .offset(
                        x: size * CGFloat(0.34 * cos(phase * .pi * 2)),
                        y: size * CGFloat(0.3 * rise - progress * 0.3)
                    )
            }
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.8), radius: size * 0.3)
        .blendMode(.plusLighter)
    }
}

// MARK: - Arcane

/// A hard geometric bolt inside rotating glyph rings — all structure, no smoke.
private struct ArcaneBoltShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        ZStack {
            // Two rings turning against each other.
            ForEach([1.0, -1.0], id: \.self) { direction in
                Hexagon()
                    .strokeBorder(tint.opacity(0.85), lineWidth: max(1, size * 0.045))
                    .frame(width: size * (direction > 0 ? 1.1 : 0.78),
                           height: size * (direction > 0 ? 1.1 : 0.78))
                    .rotationEffect(.degrees(progress * 360 * direction))
            }

            // The bolt itself.
            Hexagon()
                .fill(
                    LinearGradient(colors: [Theme.parchment, tint],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: size * 0.46, height: size * 0.46)
                .shadow(color: tint, radius: size * 0.3)
        }
        .frame(width: size, height: size)
        .blendMode(.plusLighter)
    }
}

private struct Hexagon: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = min(r.width, r.height) / 2
        let center = CGPoint(x: r.midX, y: r.midY)
        var path = Path()
        for index in 0..<6 {
            let angle = Double(index) / 6 * 2 * Double.pi
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> Hexagon {
        Hexagon(insetAmount: insetAmount + amount)
    }
}

// MARK: - Lightning

/// A jagged bolt that redraws itself as it snaps across, rather than flying.
private struct LightningShot: View {
    let size: CGFloat
    let tint: Color
    let progress: Double

    var body: some View {
        // Re-seeded a few times over the flight so the bolt visibly crackles.
        let seed = Int(progress * 6)
        return ZStack {
            Bolt(seed: seed, length: size * 2.4)
                .stroke(tint.opacity(0.6), style: .init(lineWidth: max(2, size * 0.16), lineCap: .round))
                .blur(radius: size * 0.12)
            Bolt(seed: seed, length: size * 2.4)
                .stroke(Theme.parchment, style: .init(lineWidth: max(1, size * 0.06), lineCap: .round))
        }
        .frame(width: size * 2.4, height: size * 0.7)
        .shadow(color: tint, radius: size * 0.35)
        .blendMode(.plusLighter)
    }
}

/// A zig-zag whose kinks are decided by a seed, so it can be re-struck.
private struct Bolt: Shape {
    let seed: Int
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var generator = BoltGenerator(seed: UInt64(seed) &+ 977)
        var path = Path()
        let steps = 6
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for step in 1...steps {
            let x = rect.minX + rect.width * CGFloat(step) / CGFloat(steps)
            let spread = step == steps ? 0 : Double.random(in: -0.42...0.42, using: &generator)
            path.addLine(to: CGPoint(x: x, y: rect.midY + rect.height * CGFloat(spread)))
        }
        return path
    }
}

/// A tiny deterministic generator, so a bolt with the same seed is the same
/// bolt — SwiftUI may redraw a shape several times per frame.
private struct BoltGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x4d59_5df4_d0f3_3173 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Venom

/// A lobbed flask of venom, stoppered and slopping.
private struct VenomFlaskShot: View {
    let size: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [tint.opacity(0.95), Theme.basalt.opacity(0.9)],
                                   center: .init(x: 0.35, y: 0.3),
                                   startRadius: 0, endRadius: size * 0.5)
                )
                .frame(width: size * 0.78, height: size * 0.78)

            // Neck and stopper.
            Capsule()
                .fill(Theme.bronze)
                .frame(width: size * 0.2, height: size * 0.26)
                .offset(y: -size * 0.44)

            Circle()
                .fill(tint.opacity(0.7))
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: -size * 0.12, y: size * 0.1)
                .blur(radius: size * 0.08)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.8), radius: size * 0.22)
    }
}

// MARK: - Shared primitives

/// A plain triangle pointing right — arrow heads, blades, fletching.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
