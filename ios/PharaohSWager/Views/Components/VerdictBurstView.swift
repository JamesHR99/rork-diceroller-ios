import SwiftUI

/// Anubis's scales tipping on one creature.
///
/// A verdict is unlike every other hit in the game: it ignores guard and armour
/// completely and it fires on its own schedule rather than as part of an action.
/// So it is drawn as its own event — jackal-dark rings thrown off the figure, a
/// pair of scales swinging open through them, and the amount struck across the
/// middle — rather than as another damage number that could be mistaken for a
/// normal blow.
struct VerdictBurstView: View {
    let burst: VerdictBurst

    @State private var ring: CGFloat = 0
    @State private var scalesIn = false
    @State private var glow: Double = 0
    @State private var settle = false

    private var tint: Color { Deity.anubis.tint }

    /// A heavy verdict — one that earned the stacking bonus — throws a wider,
    /// gold-edged burst, so the reward for letting the pile build is visible.
    private var reach: CGFloat { burst.heavy ? 1.32 : 1 }

    var body: some View {
        ZStack {
            rings
            scales
            amount
        }
        .allowsHitTesting(false)
        .onAppear { run() }
    }

    // MARK: - Pieces

    /// Three rings of the god's own colour, expanding and thinning out.
    private var rings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let delay = Double(index) * 0.11
                Circle()
                    .strokeBorder(
                        burst.heavy && index == 0 ? Theme.gold : tint,
                        lineWidth: max(0.8, 3.4 - CGFloat(index))
                    )
                    .frame(width: 66 + CGFloat(index) * 26, height: 66 + CGFloat(index) * 26)
                    .scaleEffect(0.35 + ring * (1.5 + CGFloat(index) * 0.36) * reach)
                    .opacity((1 - Double(ring)) * (index == 0 ? 0.95 : 0.6))
                    .blur(radius: CGFloat(index) * 0.7)
                    .animation(.easeOut(duration: 0.78).delay(delay), value: ring)
            }

            // The dark wash underneath, so the rings read against a bright
            // sprite as well as a dim one.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 104 * reach
                    )
                )
                .frame(width: 210 * reach, height: 210 * reach)
                .opacity(glow)
                .blendMode(.plusLighter)
        }
    }

    /// The scales themselves, swinging up through the rings and holding for a
    /// beat before they fade — the one image that names what just happened.
    private var scales: some View {
        PharaohSWagerSymbol(art: PharaohSWagerArt.Status.judgement,
                   fallback: "scalemass.fill",
                   size: burst.heavy ? 58 : 48,
                   tint: burst.heavy ? Theme.gold : Theme.parchment)
            .shadow(color: tint.opacity(0.9), radius: 14)
            .shadow(color: .black.opacity(0.7), radius: 3, y: 1)
            .scaleEffect(scalesIn ? (settle ? 1 : 1.18) : 0.3)
            .opacity(scalesIn ? (settle ? 0.9 : 1) : 0)
            .rotationEffect(.degrees(scalesIn ? 0 : -28))
            .offset(y: settle ? -6 : 0)
    }

    /// What the verdict took, struck across the burst in the god's colour.
    private var amount: some View {
        VStack(spacing: 1) {
            Text("-\(burst.amount)")
                .font(.fantasy(burst.heavy ? 34 : 28, weight: .black))
                .foregroundStyle(burst.heavy ? Theme.gold : Theme.parchment)
                .shadow(color: tint.opacity(0.95), radius: 10)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 1)

            Text(burst.heavy ? "HEAVY VERDICT" : "VERDICT")
                .font(.system(size: 8.5, weight: .black))
                .kerning(2)
                .foregroundStyle(Theme.bg)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(burst.heavy ? Theme.gold : tint, in: .capsule)
        }
        .offset(y: settle ? -44 : -30)
        .opacity(settle ? 0 : (scalesIn ? 1 : 0))
    }

    // MARK: - Motion

    private func run() {
        withAnimation(.easeOut(duration: 0.8)) { ring = 1 }
        withAnimation(.easeOut(duration: 0.16)) { glow = burst.heavy ? 0.9 : 0.68 }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.58)) { scalesIn = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.22)) { glow = 0 }
        withAnimation(.easeInOut(duration: 0.55).delay(0.45)) { settle = true }
    }
}
