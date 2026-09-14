import SwiftUI

/// How a fighter's attack reads on screen. The drawn frames carry the pose;
/// this decides the timing and travel between them, so a bow snaps, an axe
/// falls heavy, blades flurry, and a staff detonates in place.
enum WeaponSignature {
    case bow
    case axe
    case blades
    case staff
    case natural

    static func forHero(_ classID: String) -> WeaponSignature {
        switch classID {
        case "archer": .bow
        case "warrior": .axe
        case "rogue": .blades
        case "magician": .staff
        default: .natural
        }
    }
}

/// One drawing held for a beat, plus the code-driven motion riding on top of
/// it. The drawings give the pose; these values give the weight — the coil of
/// an anticipation, the snap of an impact, the settle of a recovery.
struct FrameBeat: Equatable {
    var key: FrameKey
    /// Seconds this drawing stays on screen before the next one.
    var hold: Double = 0.08
    /// Travel toward the foe, in points.
    var lunge: CGFloat = 0
    var rise: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var rotation: Double = 0
    /// Motion smear: a ghost of the figure trailing the movement.
    var smear: Double = 0
    /// Snap in hard (an impact) rather than easing (a wind-up).
    var snap: Bool = false
}

/// The frame-by-frame score for every action a fighter can take. Each action
/// is anticipation, then a hard snap, then a settle — the timing that makes
/// drawn motion read as motion rather than a slide show.
enum FrameTimeline {
    /// The drawing a fighter rests on while holding a pose.
    static func rest(for pose: FighterPose) -> FrameBeat {
        switch pose {
        case .block: FrameBeat(key: .guardUp, hold: 0.2, lunge: -6, scaleY: 0.96)
        case .defeat: FrameBeat(key: .defeat, hold: 0.4, rise: 6, scaleY: 0.94)
        case .victory: FrameBeat(key: .victory, hold: 0.4, rise: -6)
        case .hurt: FrameBeat(key: .hurt, hold: 0.2, lunge: -10)
        case .dodge: FrameBeat(key: .dodge, hold: 0.2, lunge: -16)
        case .telegraph: FrameBeat(key: .windup, hold: 0.2, lunge: -16, scaleY: 1.04)
        default: FrameBeat(key: .idle, hold: 0.2)
        }
    }

    static func beats(for pose: FighterPose, weapon: WeaponSignature) -> [FrameBeat] {
        switch pose {
        case .attack: attack(weapon)
        case .block: guardUp()
        case .hurt: hurt()
        case .dodge: dodge()
        case .heal: heal()
        case .victory: victory()
        case .defeat: defeat()
        case .telegraph: telegraph()
        case .idle: [FrameBeat(key: .idle, hold: 0.18)]
        }
    }

    /// The tell a foe shows before it commits: it rears back and holds, so the
    /// blow is readable on the deck a beat before it lands.
    private static func telegraph() -> [FrameBeat] {
        [FrameBeat(key: .windup, hold: 0.12, lunge: -10, scaleY: 1.05, rotation: -3),
         FrameBeat(key: .windup, hold: 0.16, lunge: -20, scaleX: 0.95, scaleY: 1.08, rotation: -5),
         FrameBeat(key: .windup, hold: 0.2, lunge: -16, scaleY: 1.06, rotation: -4)]
    }

    /// Anticipation → impact → recovery, tuned per weapon.
    private static func attack(_ weapon: WeaponSignature) -> [FrameBeat] {
        switch weapon {
        case .bow:
            // A long draw, a held aim, then the loose — almost no travel, all
            // of the energy leaves with the arrow.
            [FrameBeat(key: .windup, hold: 0.20, lunge: -14, scaleX: 0.97, rotation: -3),
             FrameBeat(key: .windup, hold: 0.13, lunge: -18, scaleX: 0.96, rotation: -4),
             FrameBeat(key: .strike, hold: 0.09, lunge: 16, scaleX: 1.07, scaleY: 1.04,
                       rotation: 3, smear: 0.9, snap: true),
             FrameBeat(key: .follow, hold: 0.18, lunge: 8, scaleY: 0.99),
             FrameBeat(key: .follow, hold: 0.12, lunge: 2)]
        case .axe:
            // The heaviest swing on the deck: a deep coil, a long lunge, and a
            // hard stop at the bottom of the arc.
            [FrameBeat(key: .windup, hold: 0.22, lunge: -20, rise: -8, scaleY: 1.05, rotation: -8),
             FrameBeat(key: .strike, hold: 0.07, lunge: 72, scaleX: 1.12, scaleY: 0.92,
                       rotation: 12, smear: 1, snap: true),
             // Hit-stop: the blow hangs before the body catches up.
             FrameBeat(key: .strike, hold: 0.11, lunge: 66, scaleX: 1.06, scaleY: 0.95, rotation: 10),
             FrameBeat(key: .follow, hold: 0.20, lunge: 42, scaleY: 0.96, rotation: 5),
             FrameBeat(key: .follow, hold: 0.14, lunge: 14)]
        case .blades:
            // Three overlapping cuts, each faster than the last.
            [FrameBeat(key: .windup, hold: 0.14, lunge: -16, scaleX: 0.96, rotation: -5),
             FrameBeat(key: .strike, hold: 0.06, lunge: 54, scaleX: 1.10, scaleY: 0.95,
                       rotation: 8, smear: 1, snap: true),
             FrameBeat(key: .windup, hold: 0.05, lunge: 34, scaleX: 1.02, rotation: -3, smear: 0.7),
             FrameBeat(key: .strike, hold: 0.06, lunge: 66, scaleX: 1.11, scaleY: 0.94,
                       rotation: 10, smear: 1, snap: true),
             FrameBeat(key: .follow, hold: 0.17, lunge: 40, scaleY: 0.97),
             FrameBeat(key: .follow, hold: 0.12, lunge: 12)]
        case .staff:
            // No travel at all — the magician plants and the spell detonates.
            [FrameBeat(key: .windup, hold: 0.24, lunge: -10, rise: -6, scaleY: 1.06),
             FrameBeat(key: .windup, hold: 0.10, lunge: -14, scaleY: 1.08),
             FrameBeat(key: .strike, hold: 0.09, lunge: 22, scaleX: 1.14, scaleY: 1.10,
                       smear: 0.8, snap: true),
             FrameBeat(key: .strike, hold: 0.10, lunge: 18, scaleX: 1.06, scaleY: 1.04),
             FrameBeat(key: .follow, hold: 0.20, lunge: 6),
             FrameBeat(key: .follow, hold: 0.12)]
        case .natural:
            // Claws, jaws and coils: a short rear back and a long pounce.
            [FrameBeat(key: .windup, hold: 0.18, lunge: -22, scaleX: 0.94, scaleY: 1.06),
             FrameBeat(key: .strike, hold: 0.07, lunge: 64, scaleX: 1.14, scaleY: 0.90,
                       rotation: 6, smear: 1, snap: true),
             FrameBeat(key: .strike, hold: 0.09, lunge: 58, scaleX: 1.06, scaleY: 0.96),
             FrameBeat(key: .follow, hold: 0.18, lunge: 30),
             FrameBeat(key: .follow, hold: 0.12, lunge: 8)]
        }
    }

    private static func guardUp() -> [FrameBeat] {
        [FrameBeat(key: .guardUp, hold: 0.07, lunge: -14, scaleY: 1.04, snap: true),
         FrameBeat(key: .guardUp, hold: 0.14, lunge: -4, scaleY: 0.95),
         FrameBeat(key: .guardUp, hold: 0.18, lunge: -6, scaleY: 0.97)]
    }

    private static func hurt() -> [FrameBeat] {
        [FrameBeat(key: .hurt, hold: 0.06, lunge: -30, scaleX: 1.06, scaleY: 0.92,
                   rotation: -10, smear: 0.8, snap: true),
         FrameBeat(key: .hurt, hold: 0.12, lunge: -18, rotation: -6),
         FrameBeat(key: .hurt, hold: 0.16, lunge: -8, rotation: -2)]
    }

    private static func dodge() -> [FrameBeat] {
        [FrameBeat(key: .dodge, hold: 0.06, lunge: -46, scaleX: 1.08, scaleY: 0.94,
                   smear: 1, snap: true),
         FrameBeat(key: .dodge, hold: 0.14, lunge: -34, smear: 0.6),
         FrameBeat(key: .dodge, hold: 0.16, lunge: -18)]
    }

    private static func heal() -> [FrameBeat] {
        [FrameBeat(key: .idle, hold: 0.16, rise: -12, scaleY: 1.05),
         FrameBeat(key: .idle, hold: 0.20, rise: -6, scaleY: 1.02),
         FrameBeat(key: .idle, hold: 0.16)]
    }

    private static func victory() -> [FrameBeat] {
        [FrameBeat(key: .victory, hold: 0.10, rise: -18, scaleY: 1.10, snap: true),
         FrameBeat(key: .victory, hold: 0.22, rise: -8, scaleY: 1.02),
         FrameBeat(key: .victory, hold: 0.3, rise: -6)]
    }

    private static func defeat() -> [FrameBeat] {
        [FrameBeat(key: .defeat, hold: 0.12, lunge: -14, rise: -4, rotation: -6, snap: true),
         FrameBeat(key: .defeat, hold: 0.26, rise: 4, scaleY: 0.96, rotation: 4),
         FrameBeat(key: .defeat, hold: 0.4, rise: 8, scaleY: 0.94, rotation: 6)]
    }
}

/// A fighter drawn frame by frame. Holds the current beat of whatever action
/// is playing, cross-cuts to the next drawing on schedule, and layers the
/// code-driven motion — squash, lunge, smear, breathing — on top of the art.
struct AnimatedFighterSprite: View {
    let frames: FrameSet
    let pose: FighterPose
    let weapon: WeaponSignature
    /// +1 when the fighter faces right (the player), -1 for foes on the right.
    let facing: CGFloat
    let height: CGFloat
    let accent: Color
    let fallbackSymbol: String
    /// Mirrors the glyph fallback only — the drawings already face correctly.
    var mirrorFallback: Bool = false

    @State private var beat = FrameBeat(key: .idle)
    @State private var breathing = false

    var body: some View {
        figure(beat.key)
            .overlay { hurtWash }
            .background { smearGhost }
            .scaleEffect(x: beat.scaleX, y: beat.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(beat.rotation * facing), anchor: .bottom)
            .offset(x: beat.lunge * facing, y: beat.rise + breathDrift)
            .task(id: pose) { await play() }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
    }

    /// Nobody stands perfectly still — the idle drawing drifts on a slow breath.
    private var breathDrift: CGFloat {
        guard pose == .idle else { return 0 }
        return breathing ? -2.5 : 1.5
    }

    @ViewBuilder
    private func figure(_ key: FrameKey) -> some View {
        PortraitView(art: frames.art(key),
                     fallbackSymbol: fallbackSymbol,
                     tint: accent,
                     height: height,
                     mirrorFallback: mirrorFallback)
    }

    /// A ghost of the figure trailing behind fast movement, so a snap reads as
    /// speed instead of teleporting.
    @ViewBuilder
    private var smearGhost: some View {
        if beat.smear > 0 {
            figure(beat.key)
                .opacity(0.34 * beat.smear)
                .blur(radius: 5 * beat.smear)
                .offset(x: -22 * facing * CGFloat(beat.smear))
                .allowsHitTesting(false)
        }
    }

    /// Blood-red ink washing the figure on the frame a blow lands.
    @ViewBuilder
    private var hurtWash: some View {
        if beat.key == .hurt {
            figure(.hurt)
                .colorMultiply(Theme.blood)
                .opacity(0.7)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
    }

    /// Walks the score for the current pose, holding each drawing for its beat.
    /// `.task(id:)` cancels this the moment the pose changes, so a new action
    /// interrupts the old one cleanly instead of queueing behind it.
    private func play() async {
        let score = FrameTimeline.beats(for: pose, weapon: weapon)
        for step in score {
            let motion: Animation = step.snap
                ? .interpolatingSpring(stiffness: 620, damping: 16)
                : .spring(response: 0.22, dampingFraction: 0.7)
            withAnimation(motion) { beat = step }
            try? await Task.sleep(for: .seconds(step.hold))
            if Task.isCancelled { return }
        }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.75)) {
            beat = FrameTimeline.rest(for: pose)
        }
    }
}
