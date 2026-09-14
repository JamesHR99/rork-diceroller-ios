import SwiftUI

/// A sheet of dark papyrus: a warm ink-brown base with real reed-fibre
/// texture blended over it. Every card and panel in the game sits on one.
struct PapyrusSurface: View {
    var tint: Color = Theme.bgCard
    /// How strongly the fibres read, 0 through 1.
    var strength: Double = 0.6

    var body: some View {
        tint
            .overlay {
                Image("papyrus_texture")
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity(strength)
            }
            .overlay {
                // A second, finer pass keeps the grain alive up close.
                Image("papyrus_texture")
                    .resizable(resizingMode: .tile)
                    .scaleEffect(2)
                    .blendMode(.softLight)
                    .opacity(strength * 0.5)
            }
    }
}

/// The whole game is painted on one long sheet — this washes a faint paper
/// grain across every screen, over the UI itself.
struct PaperGrain: View {
    var opacity: Double = 0.07

    var body: some View {
        Image("aged_papyrus_texture")
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

extension View {
    /// Wraps any view in a papyrus sheet with rounded edges.
    func papyrusPanel(
        tint: Color = Theme.bgCard,
        cornerRadius: CGFloat = 16,
        strength: Double = 0.6
    ) -> some View {
        background {
            PapyrusSurface(tint: tint, strength: strength)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
}
