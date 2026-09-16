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

/// The air above the deck. Arrows, daggers, runes and bombs cross it between
/// the fighter who threw them and the one they were aimed at, drawn from the
/// same painted face art the die showed.
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

/// One shot in flight: the painted face crossing the deck, leaning into its
/// heading, lobbing over the water if it is heavy, and dragging its own wake.
private struct ProjectileView: View {
    let shot: ProjectileShot
    let from: CGPoint
    let to: CGPoint

    /// 0 at the thrower's hand, 1 on impact.
    @State private var progress: Double = 0
    @State private var landed = false

    private var style: ProjectileStyle { shot.style }

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
        guard style.arc > 0 else { return 0 }
        return Double(style.arc) * 0.4 * (2 * progress - 1)
    }

    private var spin: Double {
        style.spins ? progress * 540 : 0
    }

    var body: some View {
        ZStack {
            wake
            DuatSymbol(art: shot.face.artName,
                       fallback: shot.face.symbol,
                       size: style.size,
                       tint: shot.tint)
                .rotationEffect(.degrees(style.baseAngle + heading + pitch + spin))
                .shadow(color: shot.tint.opacity(0.85), radius: style.size * 0.3)
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
        let length = style.size * (style.trail == .streak ? 2.4 : 1.7)
        return Capsule()
            .fill(
                LinearGradient(
                    colors: [.clear, shot.tint.opacity(trailStrength)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: length, height: style.size * trailThickness)
            .blur(radius: style.trail == .streak ? 1.6 : 5)
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
        }
    }

    private var trailThickness: CGFloat {
        switch style.trail {
        case .streak: 0.16
        case .flame: 0.5
        case .frost: 0.34
        case .arcane: 0.44
        case .smoke: 0.55
        }
    }
}
