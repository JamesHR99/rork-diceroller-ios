import SwiftUI

/// PharaohSWager palette: black river water, dark papyrus and aged linen, gold leaf and
/// lapis, plus one accent colour per playable class. Everything is warmed
/// toward ink and papyrus so the interface reads as painted, not rendered.
enum Theme {
    static let bg = Color(red: 0.052, green: 0.042, blue: 0.034)
    static let bgElevated = Color(red: 0.105, green: 0.084, blue: 0.062)
    static let bgCard = Color(red: 0.145, green: 0.116, blue: 0.086)
    static let parchment = Color(red: 0.930, green: 0.880, blue: 0.760)
    static let parchmentDim = Color(red: 0.930, green: 0.880, blue: 0.760).opacity(0.55)
    static let ember = Color(red: 0.930, green: 0.470, blue: 0.150)
    static let emberDeep = Color(red: 0.640, green: 0.270, blue: 0.080)
    static let gold = Color(red: 0.930, green: 0.735, blue: 0.290)
    static let goldDeep = Color(red: 0.700, green: 0.500, blue: 0.150)
    static let blood = Color(red: 0.800, green: 0.215, blue: 0.170)
    static let forest = Color(red: 0.330, green: 0.630, blue: 0.420)
    static let steel = Color(red: 0.560, green: 0.620, blue: 0.700)
    /// Oxidised bronze — the metal armoured foes wear over their health.
    static let bronze = Color(red: 0.665, green: 0.480, blue: 0.290)
    static let venom = Color(red: 0.540, green: 0.780, blue: 0.290)
    static let shadowLine = Color.black.opacity(0.45)

    /// Class accents.
    static let steelBlue = Color(red: 0.380, green: 0.580, blue: 0.840)
    static let arcane = Color(red: 0.640, green: 0.450, blue: 0.900)
    static let frost = Color(red: 0.510, green: 0.780, blue: 0.900)

    /// Pantheon halos — one per Egyptian deity.
    static let sunGold = Color(red: 0.985, green: 0.790, blue: 0.245)
    static let nileGreen = Color(red: 0.235, green: 0.705, blue: 0.520)
    static let boneWhite = Color(red: 0.885, green: 0.875, blue: 0.815)
    static let ochre = Color(red: 0.855, green: 0.560, blue: 0.230)
    static let skyBlue = Color(red: 0.355, green: 0.720, blue: 0.940)
    static let duskViolet = Color(red: 0.665, green: 0.425, blue: 0.825)

    /// Ptah's cold hammered copper — the craftsman's own metal, set apart
    /// from the six gods' halos.
    static let ptahCopper = Color(red: 0.760, green: 0.480, blue: 0.300)
    /// Basalt grey — the dark stone Ptah's bench is cut from.
    static let basalt = Color(red: 0.135, green: 0.130, blue: 0.150)

    /// Materials, used for rarity: clay, copper, lapis, gold leaf.
    static let clay = Color(red: 0.720, green: 0.585, blue: 0.470)
    static let copper = Color(red: 0.855, green: 0.475, blue: 0.245)
    static let lapis = Color(red: 0.290, green: 0.420, blue: 0.855)
    static let goldLeaf = Color(red: 0.965, green: 0.790, blue: 0.330)

    /// Thin rule used to frame panels and cards.
    static let rule = Color(red: 0.930, green: 0.735, blue: 0.290).opacity(0.32)
}

extension Font {
    /// Hand-carved display face, used for every heading, name and label of
    /// ceremony. (All `fantasy` call sites become the carved face.)
    static func fantasy(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(PaperFonts.display, size: size)
    }

    /// Warm hand-drawn serif for body copy, flavour lines and log text.
    static func paper(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(PaperFonts.body, size: size).weight(weight)
    }
}
