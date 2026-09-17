import SwiftUI

/// One of the three great gates of the night. The twelve hours are divided
/// four apiece, and each gate paints the whole game a different colour.
enum Gate: Int, CaseIterable, Identifiable, Hashable {
    case reeds = 0
    case fire = 1
    case coils = 2

    var id: Int { rawValue }

    /// Which gate a given hour (1...12) belongs to.
    static func forHour(_ hour: Int) -> Gate {
        switch hour {
        case ..<5: .reeds
        case ..<9: .fire
        default: .coils
        }
    }

    var name: String {
        switch self {
        case .reeds: "Gate of Reeds"
        case .fire: "Gate of Fire"
        case .coils: "Gate of Coils"
        }
    }

    var ordinal: String {
        switch self {
        case .reeds: "The First Gate"
        case .fire: "The Second Gate"
        case .coils: "The Last Gate"
        }
    }

    var subtitle: String {
        switch self {
        case .reeds: "The shallow river and the things that live in it"
        case .fire: "The lake of flame and the furnace halls"
        case .coils: "The deep dark, where Apep waits"
        }
    }

    /// Spoken as the barque passes under the pylons.
    var arrival: String {
        switch self {
        case .reeds: "The reeds part. The night takes the barque."
        case .fire: "The water turns to flame. Ra's disc burns low."
        case .coils: "The stars go out one by one. Something enormous breathes."
        }
    }

    var hours: ClosedRange<Int> {
        switch self {
        case .reeds: 1...4
        case .fire: 5...8
        case .coils: 9...12
        }
    }

    var lastHour: Int { hours.upperBound }

    var firstHour: Int { hours.lowerBound }

    /// What the chart says about the water you are currently on.
    var region: String {
        switch self {
        case .reeds: "Shallow water, papyrus banks, drowned shrines"
        case .fire: "The lake of flame — the water itself burns"
        case .coils: "No stars, no bank. Only the breathing dark"
        }
    }

    var symbol: String {
        switch self {
        case .reeds: "leaf.fill"
        case .fire: "flame.fill"
        case .coils: "lizard.fill"
        }
    }

    // MARK: - Palette

    var skyTop: Color {
        switch self {
        case .reeds: Color(red: 0.035, green: 0.050, blue: 0.110)
        case .fire: Color(red: 0.075, green: 0.030, blue: 0.028)
        case .coils: Color(red: 0.028, green: 0.022, blue: 0.048)
        }
    }

    var skyHorizon: Color {
        switch self {
        case .reeds: Color(red: 0.090, green: 0.150, blue: 0.190)
        case .fire: Color(red: 0.380, green: 0.140, blue: 0.045)
        case .coils: Color(red: 0.150, green: 0.070, blue: 0.185)
        }
    }

    var waterTop: Color {
        switch self {
        case .reeds: Color(red: 0.050, green: 0.105, blue: 0.115)
        case .fire: Color(red: 0.140, green: 0.055, blue: 0.030)
        case .coils: Color(red: 0.040, green: 0.030, blue: 0.062)
        }
    }

    var waterBottom: Color {
        switch self {
        case .reeds: Color(red: 0.018, green: 0.035, blue: 0.048)
        case .fire: Color(red: 0.048, green: 0.020, blue: 0.016)
        case .coils: Color(red: 0.012, green: 0.010, blue: 0.022)
        }
    }

    /// The colour the water reflects back from the sun disc.
    var reflection: Color {
        switch self {
        case .reeds: Color(red: 0.560, green: 0.780, blue: 0.480)
        case .fire: Color(red: 0.980, green: 0.520, blue: 0.180)
        case .coils: Color(red: 0.720, green: 0.470, blue: 0.880)
        }
    }

    /// Silhouette colour for dunes, pylons and reeds.
    var bank: Color {
        switch self {
        case .reeds: Color(red: 0.075, green: 0.090, blue: 0.115)
        case .fire: Color(red: 0.115, green: 0.055, blue: 0.040)
        case .coils: Color(red: 0.055, green: 0.045, blue: 0.075)
        }
    }

    /// The accent used for chrome and highlights inside this gate.
    var accent: Color {
        switch self {
        case .reeds: Theme.nileGreen
        case .fire: Theme.ember
        case .coils: Theme.duskViolet
        }
    }

    /// How bright Ra's disc still burns here, 0 through 1.
    var discBrightness: Double {
        switch self {
        case .reeds: 1.0
        case .fire: 0.78
        case .coils: 0.48
        }
    }

    var discColor: Color {
        switch self {
        case .reeds: Theme.sunGold
        case .fire: Color(red: 0.960, green: 0.480, blue: 0.140)
        case .coils: Color(red: 0.760, green: 0.300, blue: 0.180)
        }
    }

    /// Embers only rise through the frame in the second gate.
    var hasEmbers: Bool { self == .fire }

    /// Reeds only sway at the frame edges in the first gate.
    var hasReeds: Bool { self == .reeds }

    /// An enormous coil turns beneath the water in the last gate.
    var hasSerpent: Bool { self == .coils }
}
