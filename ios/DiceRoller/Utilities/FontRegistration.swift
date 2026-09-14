import CoreText
import SwiftUI

/// The two hand-drawn faces every screen is set in: a carved, glyph-like
/// display face for headings, and a warm wobbly serif for body copy. Both ship
/// in the bundle and are registered once at launch.
enum PaperFonts {
    /// Carved display face, used through `Font.fantasy`.
    static let display = "Caesar Dressing"
    /// Hand-drawn serif, used through `Font.paper`.
    static let body = "Averia Serif Libre"

    private static let files = [
        "CaesarDressing-Regular",
        "AveriaSerifLibre-Regular",
        "AveriaSerifLibre-Bold"
    ]

    static func registerBundled() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
