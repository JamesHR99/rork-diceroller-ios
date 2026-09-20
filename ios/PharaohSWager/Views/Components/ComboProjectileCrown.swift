import SwiftUI

/// Additional silhouettes at three and five dice. Bounded geometry keeps a
/// large combo readable on a phone, with no unbounded particle emitters.
struct ComboProjectileCrown: View {
    let form: ProjectileForm
    let size: CGFloat
    let tint: Color
    let progress: Double
    let magnitude: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tier: Int { magnitude >= 5 ? 2 : (magnitude >= 3 ? 1 : 0) }
    private var turn: Double { reduceMotion ? 0 : progress * 90 }

    var body: some View {
        ZStack {
            if tier > 0 {
                switch form {
                case .arrow:
                    // A long solar lance framed by feather-like vanes.
                    ForEach(0..<(tier * 2), id: \.self) { index in
                        InkStreak().fill(index.isMultiple(of: 2) ? Theme.gold : tint)
                            .frame(width: size * 0.54, height: 3)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -12 : 12))
                            .offset(x: -size * 0.18, y: CGFloat(index - tier) * 7)
                    }
                case .crescent, .tumblingBlade:
                    ForEach(0..<(tier + 1), id: \.self) { index in
                        InkStreak().fill(tint.opacity(0.75))
                            .frame(width: size * 0.7, height: 3)
                            .rotationEffect(.degrees(Double(index) * 45 - 45))
                            .offset(x: -size * 0.28)
                    }
                case .fireOrb:
                    radialShards(count: tier == 2 ? 8 : 5, colour: Theme.sunGold)
                case .frostShard:
                    radialShards(count: tier == 2 ? 6 : 3, colour: Theme.frost)
                case .arcaneBolt, .lightning:
                    ForEach(0..<(tier + 1), id: \.self) { index in
                        Rectangle().stroke(tint, lineWidth: 1.5)
                            .frame(width: size * (0.7 + CGFloat(index) * 0.22), height: size * (0.7 + CGFloat(index) * 0.22))
                            .rotationEffect(.degrees(45 + turn * (index.isMultiple(of: 2) ? 1 : -1)))
                    }
                case .venomFlask, .lifeMotes:
                    radialShards(count: tier == 2 ? 5 : 3, colour: tint)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func radialShards(count: Int, colour: Color) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                InkStreak().fill(index.isMultiple(of: 2) ? colour : Theme.parchment)
                    .frame(width: size * 0.24, height: 4)
                    .offset(x: size * 0.62)
                    .rotationEffect(.degrees(Double(index) * 360 / Double(count) + turn))
            }
        }
    }
}
