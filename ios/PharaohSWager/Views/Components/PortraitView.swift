import SwiftUI

/// A painted figure standing free of any frame, displayed by its real ink
/// rather than its canvas so a fighter's feet sit where the layout expects.
/// Falls back to an inked glyph when no drawing exists for that character.
struct PortraitView: View {
    let art: String?
    let fallbackSymbol: String
    let tint: Color
    var height: CGFloat
    /// Mirrors the glyph fallback only — the paintings already face the right way.
    var mirrorFallback: Bool = false

    var body: some View {
        Group {
            if let art, PharaohSWagerArt.exists(art) {
                PharaohSWagerImage(name: art, height: height, fit: .fit)
            } else {
                Image(systemName: fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .padding(height * 0.14)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.parchment, tint],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(x: mirrorFallback ? -1 : 1, y: 1)
            }
        }
        .frame(height: height)
    }
}

/// A portrait set into a round tomb-plaque: gold rule, painted glow behind the
/// figure, and the figure itself standing inside the disc.
struct PortraitMedallionView: View {
    let art: String?
    let fallbackSymbol: String
    let tint: Color
    var diameter: CGFloat
    var glow: Bool = true

    private var isPainted: Bool { PharaohSWagerArt.exists(art) }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.34), Theme.bg.opacity(0.95)],
                                     center: .center, startRadius: 1, endRadius: diameter * 0.62))

            PortraitView(art: art,
                         fallbackSymbol: fallbackSymbol,
                         tint: tint,
                         height: diameter * (isPainted ? 0.86 : 0.52))
                .shadow(color: tint.opacity(glow ? 0.55 : 0), radius: diameter * 0.14)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(.circle)
        .overlay(Circle().strokeBorder(tint.opacity(0.55), lineWidth: 1.5))
        .overlay(Circle().strokeBorder(Theme.gold.opacity(0.22), lineWidth: 3).blur(radius: 2))
    }
}

/// A god's sigil standing inside the painted trial halo — the plate the pack
/// drew for exactly this moment, with the sigil dropped into its open centre.
struct HaloedSigilView: View {
    let deity: Deity
    var diameter: CGFloat
    /// Slow breath on the halo, for the moment a god's trial is offered.
    var breathes: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: !breathes)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let breath = breathes ? 0.5 + 0.5 * sin(time * 0.9) : 0.5
            ZStack {
                PharaohSWagerImage(name: PharaohSWagerArt.trialHalo, height: diameter, fit: .fit)
                    .colorMultiply(deity.tint)
                    .opacity(0.75 + 0.25 * breath)
                    .scaleEffect(1 + 0.03 * breath)
                    .shadow(color: deity.tint.opacity(0.6), radius: diameter * 0.16)

                PharaohSWagerSymbol(art: deity.artName,
                           fallback: deity.symbol,
                           size: diameter * 0.34,
                           tint: deity.tint)
                    // The halo's feather pulls its ring below the canvas centre.
                    .offset(y: diameter * 0.04)
            }
            .frame(width: diameter, height: diameter)
        }
    }
}
