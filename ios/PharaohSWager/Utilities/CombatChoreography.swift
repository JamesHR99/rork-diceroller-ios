import SwiftUI

/// Presentation only: the resolved recipe supplies its faces and granted defences.
/// These cues never apply damage, spend dice, or invent additional attacks.
struct CombatChoreography: Equatable {
    var faces: [FaceKind] = []
    var grantsGuard = false
    var grantsEvade = false
    var moveID: String? = nil

    var face: FaceKind? { faces.first }
    var tint: Color {
        switch face {
        case .arrow1, .arrow2, .arrow3, .bowSmack: Color(red: 1, green: 0.24, blue: 0.12)
        case .overhead, .sideSwing: Color(red: 1, green: 0.78, blue: 0.08)
        case .swiftSlash, .daggerThrow: Color(red: 0, green: 0.86, blue: 0.95)
        default: face?.tint ?? Theme.gold
        }
    }

    func score(pose: FighterPose, weapon: WeaponSignature, power: Int) -> [FrameBeat] {
        let level = max(1, min(power, 6))
        var score = FrameTimeline.beats(for: pose, weapon: weapon, power: 1)
        if pose == .block {
            // Small parry, planted guard, then a held aegis for four-plus dice.
            score = [FrameBeat(key: .guardUp, hold: 0.10, lunge: -8, rotation: -3, snap: true),
                     FrameBeat(key: .guardUp, hold: 0.16 + Double(level) * 0.035,
                               lunge: level >= 4 ? 4 : -4, scaleY: level >= 4 ? 1.04 : 0.96),
                     FrameBeat(key: .guardUp, hold: 0.16, lunge: -4)]
            return score
        }
        guard pose == .attack else { return score }
        switch face {
        case .sideSwing:
            score = [FrameBeat(key: .windup, hold: 0.24, lunge: -18, rotation: -13),
                     FrameBeat(key: .strike, hold: 0.10, lunge: 55, scaleX: 1.07, rotation: 10, smear: 1, snap: true),
                     FrameBeat(key: .follow, hold: 0.18, lunge: 25, rotation: 4)]
        case .overhead:
            score = [FrameBeat(key: .windup, hold: 0.28, lunge: -12, rise: -12, rotation: -9),
                     FrameBeat(key: .strike, hold: 0.14, lunge: 48, rise: 4, scaleY: 0.94, rotation: 11, smear: 1, snap: true),
                     FrameBeat(key: .follow, hold: 0.20, lunge: 20)]
        case .bowSmack:
            score = [FrameBeat(key: .guardUp, hold: 0.16, lunge: -10),
                     FrameBeat(key: .strike, hold: 0.10, lunge: 42, rotation: 9, smear: 0.8, snap: true),
                     FrameBeat(key: .follow, hold: 0.16, lunge: 12)]
        case .daggerThrow, .poison:
            score = [FrameBeat(key: .windup, hold: 0.18, lunge: -12, rotation: -5),
                     FrameBeat(key: .strike, hold: 0.08, lunge: 20, rotation: 6, smear: 0.7, snap: true),
                     FrameBeat(key: .follow, hold: 0.18, lunge: 5)]
        case .runeFrost:
            score = [FrameBeat(key: .windup, hold: 0.25, rise: -5, scaleY: 1.04),
                     FrameBeat(key: .strike, hold: 0.14, lunge: 12, scaleY: 1.07, snap: true),
                     FrameBeat(key: .follow, hold: 0.20, lunge: 2)]
        case .wandZap:
            score = [FrameBeat(key: .windup, hold: 0.12, lunge: -5),
                     FrameBeat(key: .strike, hold: 0.06, lunge: 17, rotation: 4, snap: true),
                     FrameBeat(key: .follow, hold: 0.15)]
        default: break
        }
        if grantsGuard { score.insert(FrameBeat(key: .guardUp, hold: 0.09, lunge: -8), at: 0) }
        if grantsEvade { score.insert(FrameBeat(key: .dodge, hold: 0.08, lunge: -24, smear: 0.6), at: 0) }
        // Follow-up poses have recoil between strikes, rather than vibrating the same drawing.
        if level >= 2, let hit = score.first(where: { $0.key == .strike }) {
            let extra = min(3, level - 1)
            var followups: [FrameBeat] = []
            for index in 0..<extra {
                followups.append(FrameBeat(key: .windup, hold: 0.055, lunge: 8, rotation: -3))
                var strike = hit
                strike.hold = face == .overhead ? 0.10 : 0.065
                strike.rotation *= index.isMultiple(of: 2) ? -0.65 : 1
                strike.lunge *= 0.85
                followups.append(strike)
            }
            score.insert(contentsOf: followups, at: max(1, score.count - 1))
        }
        if level >= 4, let lastStrike = score.lastIndex(where: { $0.key == .strike }) {
            score[lastStrike].key = .finisher
            score[lastStrike].hold = level >= 5 ? 0.16 : 0.12
            score[lastStrike].rise = weapon == .staff ? -12 : -6
            score[lastStrike].smear = 1
        }
        return score
    }
}

/// Crisp class-coloured defensive glyphs. Quantity changes the silhouette, not
/// just its scale; Reduce Motion retains the cue without spinning or pulsing.
struct CombatGuardGlyph: View {
    let pose: FighterPose
    let power: Int
    let tint: Color
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if pose == .block || pose == .dodge,
               let image = InkWorldArt.cell("ink_impacts", index: pose == .block ? 13 : 14) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(width: height * 0.8, height: height * 0.65)
                    .offset(x: height * 0.15, y: height * 0.12)
                    .opacity(0.8)
            }
            if pose == .block {
                ForEach(0..<min(3, max(1, (power + 1) / 2)), id: \.self) { index in
                    RoundedRectangle(cornerRadius: height * 0.14)
                        .stroke(tint.opacity(0.85 - Double(index) * 0.16), lineWidth: index == 0 ? 3 : 1.5)
                        .frame(width: height * (0.72 + CGFloat(index) * 0.13), height: height * (0.90 + CGFloat(index) * 0.08))
                        .rotationEffect(.degrees(Double(index - 1) * (reduceMotion ? 0 : 9)))
                }
            } else if pose == .dodge {
                ForEach(0..<min(4, max(2, power)), id: \.self) { index in
                    InkStreak().fill(tint.opacity(0.6 - Double(index) * 0.12))
                        .frame(width: height * 0.38, height: 3)
                        .offset(x: -height * 0.22, y: CGFloat(index - 1) * height * 0.12)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
