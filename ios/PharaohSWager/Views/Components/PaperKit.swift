import SwiftUI

/// Which painted ground a panel is laid on.
enum PapyrusGround {
    /// The wide sooty sheet — for bars, trays and full-width panels.
    case panel
    /// The tall sheet — for cards that stand upright, like an offer.
    case card

    var art: String {
        switch self {
        case .panel: PharaohSWagerArt.groundPanel
        case .card: PharaohSWagerArt.groundCard
        }
    }
}

/// A sheet of darkened papyrus for anything the game writes on.
///
/// The ground plates carry no border and no ornament, only paper: that is
/// deliberate. A framed plate stretched to a wide tray smears its border and
/// drowns the text sitting on it, so panels get plain paper here and draw
/// their own crisp edge on top.
struct PapyrusSurface: View {
    var ground: PapyrusGround = .panel
    var tint: Color = Theme.bgCard
    /// How strongly the paper reads over the base tint, 0 through 1.
    var strength: Double = 1
    /// Extra darkening laid over the paper. Panels that carry a lot of small
    /// type turn this up so every label keeps its contrast.
    var shade: Double = 0.34

    var body: some View {
        // The tint is the size anchor: a `.fill` image reports a frame wider
        // than the box it is handed, and a background draws at its own size
        // without clipping, so putting the paper in a stack would spill a dark
        // sheet out past the panel and over its neighbours. Anchoring to the
        // flexible colour and laying the paper on top keeps the surface exactly
        // the size it was asked for.
        tint
            .overlay {
                Image(ground.art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(strength)
                    .allowsHitTesting(false)
            }
            .overlay { Color.black.opacity(shade) }
            .compositingGroup()
            .clipped()
    }
}

/// The whole game is painted on one long sheet — this washes a faint carved
/// grain across every screen, over the UI itself.
struct PaperGrain: View {
    var opacity: Double = 0.05

    var body: some View {
        // Same anchoring rule as the surface above — the grain must never grow
        // the layout it washes over.
        Color.clear
            .overlay {
                Image(PharaohSWagerArt.groundPanel)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .clipped()
            .blendMode(.overlay)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

extension View {
    /// Wraps any view in a painted papyrus ground with rounded edges and a
    /// thin inked rule around it, so the panel has a real edge without a
    /// stretched painted border.
    func papyrusPanel(
        tint: Color = Theme.bgCard,
        cornerRadius: CGFloat = 16,
        strength: Double = 1,
        shade: Double = 0.34,
        ground: PapyrusGround = .panel
    ) -> some View {
        background {
            PapyrusSurface(ground: ground, tint: tint, strength: strength, shade: shade)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
}
