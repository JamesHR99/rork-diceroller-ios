import SwiftUI

/// A painted figure standing free of any frame. Falls back to an inked glyph
/// when no illustration exists for that character.
struct PortraitView: View {
    let art: String?
    let fallbackSymbol: String
    let tint: Color
    var height: CGFloat
    /// Mirrors the glyph fallback only — the paintings already face the right way.
    var mirrorFallback: Bool = false

    var body: some View {
        Group {
            if let art {
                Image(art)
                    .resizable()
                    .scaledToFit()
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

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.34), Theme.bg.opacity(0.95)],
                                     center: .center, startRadius: 1, endRadius: diameter * 0.62))

            PortraitView(art: art,
                         fallbackSymbol: fallbackSymbol,
                         tint: tint,
                         height: diameter * (art == nil ? 0.52 : 0.94))
                .shadow(color: tint.opacity(glow ? 0.55 : 0), radius: diameter * 0.14)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(.circle)
        .overlay(Circle().strokeBorder(tint.opacity(0.55), lineWidth: 1.5))
        .overlay(Circle().strokeBorder(Theme.gold.opacity(0.22), lineWidth: 3).blur(radius: 2))
    }
}
