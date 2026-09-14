import SwiftUI

/// One of the six gods who may claim a die and follow your run. Which gods
/// turn up is always random — a shrine is where they reliably make offers.
enum Deity: String, CaseIterable, Identifiable, Hashable {
    case ra
    case sobek
    case anubis
    case bes
    case horus
    case bastet

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ra: "Ra"
        case .sobek: "Sobek"
        case .anubis: "Anubis"
        case .bes: "Bes"
        case .horus: "Horus"
        case .bastet: "Bastet"
        }
    }

    var domain: String {
        switch self {
        case .ra: "The Sun"
        case .sobek: "The Nile Crocodile"
        case .anubis: "Judge of the Dead"
        case .bes: "Guardian of the Household"
        case .horus: "The Falcon"
        case .bastet: "The Cat"
        }
    }

    var symbol: String {
        switch self {
        case .ra: "sun.max.fill"
        case .sobek: "water.waves"
        case .anubis: "scalemass.fill"
        case .bes: "shield.checkered"
        case .horus: "bird.fill"
        case .bastet: "cat.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ra: Theme.sunGold
        case .sobek: Theme.nileGreen
        case .anubis: Theme.boneWhite
        case .bes: Theme.ochre
        case .horus: Theme.skyBlue
        case .bastet: Theme.duskViolet
        }
    }

    /// The line the god speaks when their sigil rises.
    var greeting: String {
        switch self {
        case .ra: "The sun does not forgive. Carry a little of it."
        case .sobek: "The river takes. Learn to take with it."
        case .anubis: "Every heart is weighed. Make yours heavy with theirs."
        case .bes: "Stand behind me and laugh. Nothing gets past a laugh."
        case .horus: "See it before you strike it. Then never miss."
        case .bastet: "Land on your feet. Then land on their throat."
        }
    }

    /// One-line pitch for offer cards and the codex.
    var pitch: String {
        switch self {
        case .ra: "Sets the world alight — burn that bites every turn, answers for every face you play."
        case .sobek: "Opens veins and feeds on them — bleed that refreshes, and health for every wound."
        case .anubis: "Weighs every blow — judgement that stores up and detonates against health."
        case .bes: "Stands in the doorway — shield that stays until it breaks, and the swing that follows."
        case .horus: "Never misses — piercing attacks, held-face rewards, and primed precision."
        case .bastet: "Lands on its feet — evade upon evade, and counters for every escape."
        }
    }
}
