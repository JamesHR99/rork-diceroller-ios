import SwiftUI

/// Which fighter a measured frame belongs to.
enum FighterAnchorID: Hashable {
    case player
    case foe(UUID)
}

/// Every fighter on the deck reports the frame it actually occupies, so shots
/// can be launched from the thrower's hands and land on the body they were
/// aimed at rather than at guessed coordinates.
struct FighterAnchorKey: PreferenceKey {
    nonisolated static var defaultValue: [FighterAnchorID: Anchor<CGRect>] { [:] }

    nonisolated static func reduce(
        value: inout [FighterAnchorID: Anchor<CGRect>],
        nextValue: () -> [FighterAnchorID: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// The air above the deck. Arrows, slash waves, thrown blades, fireballs,
/// frost shards and arcane bolts cross it between the fighter who threw them
/// and the one they were aimed at — every one drawn in code.
struct ProjectileLayerView: View {
    let shots: [ProjectileShot]
    let anchors: [FighterAnchorID: Anchor<CGRect>]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(shots) { shot in
                    if let route = route(for: shot, proxy: proxy) {
                        ProjectileView(shot: shot, from: route.from, to: route.to)
                            .id(shot.id)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Where a shot starts and ends. Shots leave from the thrower's upper
    /// body — roughly where a hand or a staff head sits — and land on the
    /// target's chest.
    private func route(for shot: ProjectileShot, proxy: GeometryProxy) -> (from: CGPoint, to: CGPoint)? {
        guard let playerAnchor = anchors[.player],
              let foeAnchor = anchors[.foe(shot.foeID)] else { return nil }
        let playerFrame = proxy[playerAnchor]
        let foeFrame = proxy[foeAnchor]
        let thrower = shot.fromPlayer ? playerFrame : foeFrame
        let target = shot.fromPlayer ? foeFrame : playerFrame
        return (
            from: CGPoint(x: thrower.midX + (shot.fromPlayer ? thrower.width * 0.22 : -thrower.width * 0.22),
                          y: thrower.midY + thrower.height * 0.06),
            to: CGPoint(x: target.midX - (shot.fromPlayer ? target.width * 0.14 : -target.width * 0.14),
                        y: target.midY + target.height * 0.02)
        )
    }
}

/// One shot in flight: the drawn form crossing the deck, leaning into its
/// heading, lobbing over the water if it is heavy, and dragging its own wake.
private struct ProjectileView: View {
    let shot: ProjectileShot
    let from: CGPoint
    let to: CGPoint

    /// 0 at the thrower's hand, 1 on impact.
    @State private var progress: Double = 0
    @State private var landed = false

    private var style: ProjectileStyle { shot.style }
    private var size: CGFloat { shot.drawnSize }

    /// Which way the shot is travelling, in degrees.
    private var heading: Double {
        atan2(to.y - from.y, to.x - from.x) * 180 / .pi
    }

    private var position: CGPoint {
        let t = CGFloat(progress)
        let lift = style.arc * sin(CGFloat.pi * t)
        return CGPoint(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t - lift
        )
    }

    /// The nose-down lean a lobbed shot takes as it falls, so an arc looks
    /// thrown rather than slid along a curve.
    private var pitch: Double {
        guard style.arc != 0 else { return 0 }
        return Double(style.arc) * 0.4 * (2 * progress - 1)
    }

    private var spin: Double {
        style.spins ? progress * 540 : 0
    }

    /// Forms that should not be turned into their heading: a churning fireball
    /// and drifting motes have no nose to point.
    private var holdsUpright: Bool {
        switch style.form {
        case .fireOrb, .lifeMotes, .venomFlask: true
        default: false
        }
    }

    var body: some View {
        ZStack {
            wake
            ProjectileArtView(
                form: style.form,
                size: size,
                tint: shot.tint,
                progress: progress,
                isCrit: shot.isCrit
            )
            .rotationEffect(.degrees(holdsUpright ? spin : heading + pitch + spin))
        }
        .scaleEffect(landed ? 1.35 : 1)
        .opacity(landed ? 0 : 1)
        .position(position)
        .onAppear {
            withAnimation(.linear(duration: style.flight)) { progress = 1 }
            withAnimation(.easeOut(duration: 0.14).delay(style.flight * 0.92)) { landed = true }
        }
    }

    /// The wake behind a shot: a tapered streak for a shaft, a smear of its
    /// own colour for a cast rune, a puff for something tumbling.
    private var wake: some View {
        let length = size * (style.trail == .streak ? 2.4 : 1.7)
        return InkStreak()
            .fill(
                LinearGradient(
                    colors: [.clear, shot.tint.opacity(trailStrength)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: length, height: size * trailThickness)
            .overlay(InkStreak().stroke(shot.tint.opacity(0.8), lineWidth: 1))
            .offset(x: -length * 0.5)
            .rotationEffect(.degrees(heading), anchor: .center)
            .blendMode(.plusLighter)
            .opacity(progress > 0.02 ? 1 : 0)
    }

    private var trailStrength: Double {
        switch style.trail {
        case .streak: 0.55
        case .flame: 0.9
        case .frost: 0.7
        case .arcane: 0.85
        case .smoke: 0.4
        case .life: 0.5
        }
    }

    private var trailThickness: CGFloat {
        switch style.trail {
        case .streak: 0.16
        case .flame: 0.5
        case .frost: 0.34
        case .arcane: 0.44
        case .smoke: 0.55
        case .life: 0.4
        }
    }
}

// MARK: - Landing marks

/// The marks blows leave on the bodies they struck: gashes, punctures, impact
/// stars, scorches, ice crusts, arcane lattices and healing blooms. Drawn over
/// the fighter and fading out, so a hit can be read on the creature itself.
struct ImpactLayerView: View {
    let marks: [ImpactMark]
    let anchors: [FighterAnchorID: Anchor<CGRect>]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(marks) { mark in
                    if let anchor = anchors[mark.target] {
                        let frame = proxy[anchor]
                        ImpactMarkView(mark: mark, span: min(frame.width, frame.height) * 1.5)
                            .position(x: frame.midX, y: frame.midY)
                            .id(mark.id)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// One mark, blooming on and fading off the body it landed on.
private struct ImpactMarkView: View {
    let mark: ImpactMark
    let span: CGFloat

    @State private var shown = false

    /// A critical doubles the mark and washes everything gold.
    private var tint: Color { mark.isCrit ? Theme.gold : mark.tint }
    private var scale: CGFloat {
        let growth = 1 + CGFloat(max(0, mark.magnitude - 1)) * 0.16
        return growth * (mark.isCrit ? 1.35 : 1)
    }

    var body: some View {
        Group {
            switch mark.form {
            case .gashes(let count): gashes(count)
            case .puncture: puncture
            case .blunt: blunt
            case .scorch: scorch
            case .fireExplosion: fireExplosion
            case .frostCrust: frostCrust
            case .lattice: lattice
            case .bloom: bloom
            case .venom: venom
            case .bleedTick: bleedTick
            case .poisonTick: poisonTick
            case .burnTick: burnTick
            }
        }
        .frame(width: span, height: span)
        .overlay { InkImpactFlare(tint: tint, magnitude: mark.magnitude, isCrit: mark.isCrit) }
        .scaleEffect(shown ? scale : scale * 0.6)
        .opacity(shown ? 1 : 0)
        .blendMode(.plusLighter)
        .onAppear {
            withAnimation(.spring(response: 0.16, dampingFraction: 0.6)) { shown = true }
            withAnimation(.easeOut(duration: mark.lifetime * 0.7).delay(mark.lifetime * 0.3)) {
                shown = false
            }
        }
    }

    // MARK: Forms

    /// One glowing cut per strike, laid across the body at the angle the blow
    /// arrived from and fanned slightly so a flurry reads as several cuts.
    private func gashes(_ count: Int) -> some View {
        ZStack {
            ForEach(0..<max(1, count), id: \.self) { index in
                let fan = Double(index - (count - 1)) * 13
                InkStreak()
                    .fill(
                        LinearGradient(colors: [tint, Theme.parchment, Theme.parchment, tint],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: span * 0.62, height: max(2, span * 0.035))
                    .shadow(color: tint.opacity(0.8), radius: 1, x: 2, y: 2)
                    .rotationEffect(.degrees(mark.angle + 28 + fan))
                    .offset(x: span * 0.02 * CGFloat(index), y: span * 0.08 * CGFloat(index - count / 2))
            }
        }
    }

    /// A flash where the head went in, plus a shaft still standing in the body.
    private var puncture: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.parchment, tint, .clear],
                                   center: .center, startRadius: 0, endRadius: span * 0.16)
                )
                .frame(width: span * 0.3, height: span * 0.3)

            // The shaft, sticking out the way it came in.
            Capsule()
                .fill(Theme.parchment.opacity(0.9))
                .frame(width: span * 0.3, height: max(1.6, span * 0.028))
                .offset(x: -span * 0.14)
                .rotationEffect(.degrees(mark.angle))
        }
    }

    /// A white star and a ring of dust thrown out at the point of contact.
    private var blunt: some View {
        ZStack {
            // Star
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(colors: [Theme.parchment, .clear],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: span * 0.34, height: max(2, span * 0.03))
                    .offset(x: span * 0.17)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            // Dust ring
            Circle()
                .strokeBorder(Theme.clay.opacity(0.65), lineWidth: max(1.5, span * 0.02))
                .frame(width: span * (shown ? 0.58 : 0.2), height: span * (shown ? 0.58 : 0.2))
                .blur(radius: 1.5)
        }
    }

    /// A blackened scorch with flame still licking off it.
    private var scorch: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.basalt.opacity(0.8), tint.opacity(0.5), .clear],
                                   center: .center, startRadius: span * 0.04, endRadius: span * 0.28)
                )
                .frame(width: span * 0.5, height: span * 0.5)
                .blendMode(.normal)

            ForEach(0..<5, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(colors: [Theme.sunGold.opacity(0.9), .clear],
                                       startPoint: .bottom, endPoint: .top)
                    )
                    .frame(width: span * 0.1, height: span * (shown ? 0.26 : 0.1))
                    .offset(x: span * (0.1 * CGFloat(index) - 0.2), y: -span * 0.12)
            }
        }
    }

    /// A magician's fire rune lands as an explosion, not a small scorch: the
    /// white-hot core collapses while a shock ring and embers throw outward.
    private var fireExplosion: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.parchment, Theme.sunGold, Theme.ember, .clear],
                                     center: .center, startRadius: 0, endRadius: span * 0.34))
                .frame(width: span * 0.72, height: span * 0.72)
                .blur(radius: shown ? 1 : 7)

            Circle()
                .strokeBorder(Theme.sunGold.opacity(0.9), lineWidth: max(2, span * 0.025))
                .frame(width: span * (shown ? 0.9 : 0.18), height: span * (shown ? 0.9 : 0.18))
                .opacity(shown ? 0.25 : 1)

            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [Theme.parchment, Theme.ember, .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: span * (shown ? 0.38 : 0.12), height: max(2, span * 0.028))
                    .offset(x: span * (shown ? 0.28 : 0.08))
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
        .shadow(color: Theme.ember.opacity(0.9), radius: span * 0.12)
    }

    /// Ice crusting over the body and cracking apart.
    private var frostCrust: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [tint.opacity(0.55), tint.opacity(0.2), .clear],
                                   center: .center, startRadius: 0, endRadius: span * 0.3)
                )
                .frame(width: span * 0.58, height: span * 0.58)

            // The cracks: short splinters radiating out of the point of impact.
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(Theme.parchment.opacity(0.85))
                    .frame(width: span * (shown ? 0.2 : 0.05), height: max(1.2, span * 0.018))
                    .offset(x: span * 0.14)
                    .rotationEffect(.degrees(Double(index) * 51 + mark.angle))
            }
        }
    }

    /// A hexagonal lattice bursting outward.
    private var lattice: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                LatticeHex()
                    .strokeBorder(tint.opacity(0.85 - Double(ring) * 0.22),
                                  lineWidth: max(1.2, span * 0.016))
                    .frame(width: span * (shown ? 0.28 + CGFloat(ring) * 0.16 : 0.1),
                           height: span * (shown ? 0.28 + CGFloat(ring) * 0.16 : 0.1))
                    .rotationEffect(.degrees(Double(ring) * 20 + mark.angle))
            }
        }
        .shadow(color: tint.opacity(0.8), radius: span * 0.04)
    }

    /// A soft green flare over whoever was mended.
    private var bloom: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.parchment.opacity(0.8), tint.opacity(0.5), .clear],
                                   center: .center, startRadius: 0, endRadius: span * 0.34)
                )
                .frame(width: span * 0.66, height: span * 0.66)

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(tint.opacity(0.85))
                    .frame(width: span * 0.05, height: span * 0.05)
                    .offset(y: span * (shown ? -0.3 : 0))
                    .rotationEffect(.degrees(Double(index) * 72))
            }
        }
    }

    /// A sickly wash where venom went in.
    private var venom: some View {
        Circle()
            .fill(
                RadialGradient(colors: [tint.opacity(0.7), tint.opacity(0.25), .clear],
                               center: .center, startRadius: 0, endRadius: span * 0.3)
            )
            .frame(width: span * 0.56, height: span * 0.56)
            .blur(radius: span * 0.02)
    }

    private var bleedTick: some View {
        ZStack {
            gashes(3)
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(Theme.blood)
                    .frame(width: span * 0.035, height: span * (shown ? 0.25 : 0.06))
                    .offset(x: span * (CGFloat(index) * 0.1 - 0.15), y: span * 0.23)
            }
        }
    }

    private var poisonTick: some View {
        ZStack {
            venom
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .strokeBorder(Theme.venom.opacity(0.9), lineWidth: max(1.5, span * 0.015))
                    .frame(width: span * (0.05 + CGFloat(index % 3) * 0.025),
                           height: span * (0.05 + CGFloat(index % 3) * 0.025))
                    .offset(x: span * (CGFloat(index % 4) * 0.12 - 0.18),
                            y: span * (shown ? -0.34 : 0.15) + CGFloat(index / 4) * 10)
            }
        }
    }

    private var burnTick: some View {
        ZStack {
            scorch
            ForEach(0..<7, id: \.self) { index in
                Ellipse()
                    .fill(LinearGradient(colors: [Theme.parchment, Theme.sunGold, Theme.ember, .clear],
                                         startPoint: .bottom, endPoint: .top))
                    .frame(width: span * 0.1, height: span * (shown ? 0.42 : 0.12))
                    .offset(x: span * (CGFloat(index) * 0.075 - 0.225), y: -span * 0.12)
                    .rotationEffect(.degrees(Double(index - 3) * 5))
            }
        }
    }
}

/// The hexagon an arcane burst shatters in.
private struct LatticeHex: InsettableShape {
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

    func inset(by amount: CGFloat) -> LatticeHex {
        LatticeHex(insetAmount: insetAmount + amount)
    }
}

