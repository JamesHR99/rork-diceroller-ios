import SwiftUI

/// Ra's solar barque, painted: the reed hull riding the water with the sun
/// disc burning above it inside its halo.
///
/// The disc's glow is driven by `discGlow`, so the whole scene can dim when the
/// demigod is hurt and flare back when Ra is defended well. The plates are
/// single stills, so the roll, the lean and the halo's breath are all code.
struct BarqueView: View {
    let gate: Gate
    /// Hull width in points.
    var width: CGFloat = 260
    /// 0 through 1 — how brightly the disc burns.
    var discGlow: Double = 1
    /// Whether the hull rocks and the halo breathes.
    var animated: Bool = true
    /// Whether this hull carries its own disc. Off by default: the river scene
    /// behind every screen already hangs Ra's disc over the water, and two
    /// discs on one screen read as a mistake.
    var showsDisc: Bool = false

    private var height: CGFloat { width * 0.34 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !animated)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let rock = animated ? sin(time * 0.9) : 0
            let breath = animated ? 0.5 + 0.5 * sin(time * 1.1) : 0.5

            ZStack {
                if showsDisc { disc(breath: breath) }

                PharaohSWagerImage(name: InkArt.image("ink.barque") != nil ? "ink.barque" : "duat_environment_barque", width: width, fit: .fit)
                    .shadow(color: gate.discColor.opacity(0.32 * discGlow), radius: 22, y: 6)
                    .rotationEffect(.degrees(rock * 1.4))
                    .offset(y: CGFloat(rock * 2.4))
            }
            .frame(width: width, height: height * 1.9)
        }
        .allowsHitTesting(false)
    }

    /// The disc and its halo, hanging over the shrine amidships. The halo has
    /// an open centre, so the disc is drawn at about half its width to fill it.
    private func disc(breath: Double) -> some View {
        let size = width * 0.17
        return ZStack {
            PharaohSWagerImage(name: "duat_environment_sun_halo", height: size * 2.1, fit: .fit)
                .opacity((0.28 + 0.22 * breath) * discGlow)
                .scaleEffect(1 + 0.05 * breath)

            PharaohSWagerImage(name: gate.sunArt, height: size, fit: .fit)
                .shadow(color: gate.discColor.opacity(0.85 * discGlow), radius: 10 + breath * 9)
                .opacity(0.55 + 0.45 * discGlow)
                .id(gate)
                .transition(.opacity)
        }
        .offset(y: -height * 0.86)
        .animation(.easeInOut(duration: 1.2), value: gate)
    }
}

/// The broad, slightly top-down barque used only for combat. Its deck is kept
/// steady under the fighters while the river shadow breathes beneath it, so
/// feet read as planted rather than floating over a rocking background prop.
struct BattleBarqueView: View {
    let gate: Gate
    var width: CGFloat
    var discGlow: Double = 1

    private var height: CGFloat { width / 3 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let tide = 0.5 + 0.5 * sin(time * 1.1)
            ZStack(alignment: .bottom) {
                Ellipse()
                    .stroke(gate.discColor.opacity(0.18 + tide * 0.12), lineWidth: 2)
                    .frame(width: width * (0.7 + tide * 0.08), height: height * 0.2)
                    .blur(radius: 3)
                    .offset(y: 5)

                PharaohSWagerImage(name: InkArt.image("ink.barque") != nil ? "ink.barque" : "duat_environment_battle_barque", width: width, fit: .fit)
                    .shadow(color: Color.black.opacity(0.65), radius: 12, y: 9)
                    .shadow(color: gate.discColor.opacity(0.26 * discGlow), radius: 24, y: 2)
            }
            .frame(width: width, height: height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

