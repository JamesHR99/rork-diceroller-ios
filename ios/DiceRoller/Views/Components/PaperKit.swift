import SwiftUI

/// A sheet of painted papyrus. The large panel plate is stretched from its
/// centre so the inked border keeps its weight at any size; the warm ink-brown
/// base shows through wherever the paper thins. Every card and panel in the
/// game sits on one.
struct PapyrusSurface: View {
    /// Which painted sheet to stretch — the large panel or the small card.
    var sheet: String = DuatArt.panelLarge
    var tint: Color = Theme.bgCard
    /// How strongly the painted paper reads over the base tint, 0 through 1.
    var strength: Double = 1

    var body: some View {
        tint
            .overlay {
                DuatSheet(name: sheet, opacity: strength)
            }
    }
}

/// The whole game is painted on one long sheet — this washes a faint carved
/// grain across every screen, over the UI itself.
struct PaperGrain: View {
    var opacity: Double = 0.06

    var body: some View {
        GeometryReader { proxy in
            let stripHeight = max(proxy.size.height / 7, 40)
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    DuatImage(name: DuatArt.hieroglyphStrip, height: stripHeight, fit: .stretch)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: row.isMultiple(of: 2) ? 1 : -1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .blendMode(.overlay)
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Wraps any view in a painted papyrus sheet with rounded edges.
    func papyrusPanel(
        tint: Color = Theme.bgCard,
        cornerRadius: CGFloat = 16,
        strength: Double = 1,
        sheet: String = DuatArt.panelLarge
    ) -> some View {
        background {
            PapyrusSurface(sheet: sheet, tint: tint, strength: strength)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
}
