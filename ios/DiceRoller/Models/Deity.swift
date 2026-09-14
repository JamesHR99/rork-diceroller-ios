import SwiftUI

/// One of the six gods who may visit your run. Which god turns up is always
/// random — depth only changes the quality of the boons they lay out.
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

    /// What following this god closely does for you, by devotion tier.
    var passives: [(threshold: Int, text: String)] {
        switch self {
        case .ra:
            [(2, "Kindling unlocked — burns last one turn longer."),
             (3, "Solar Wind unlocked — burns also tick for 2 more."),
             (5, "Procession of Ra unlocked.")]
        case .sobek:
            [(2, "Rising Water unlocked — recover 3 health whenever you deal damage."),
             (3, "The Drowning unlocked — recover 6 instead."),
             (5, "Jaws of the Nile unlocked.")]
        case .anubis:
            [(2, "The First Toll unlocked — your poison ticks for 2 more."),
             (3, "Weighing of Hearts unlocked — for 4 more, and a turn longer."),
             (5, "The Final Verdict unlocked.")]
        case .bes:
            [(2, "The Loud House unlocked — begin every battle behind 8 block."),
             (3, "Drums in the Dark unlocked — begin behind 16 instead."),
             (5, "House of Joy unlocked.")]
        case .horus:
            [(2, "The Perch unlocked — +4% crit chance on every face you roll."),
             (3, "The Stooping Falcon unlocked — +8% instead."),
             (5, "Eye of the Falcon unlocked.")]
        case .bastet:
            [(2, "Whisker-Twitch unlocked — begin every battle with a free evade."),
             (3, "The Prowl unlocked — two evades and +1 stamina."),
             (5, "Nine Lives Unbound unlocked.")]
        }
    }
}

/// Devotion is how much of yourself you have given a god, tallied across every
/// die in your loadout. A face carrying their gift counts its depth — one face
/// carried to its final form is worth as much as three lightly touched faces —
/// and a rite partner counts one.
enum Devotion {
    static let passiveTier = 2
    static let deeperTier = 3
    static let signatureTier = 5

    static func counts(_ loadout: Loadout?) -> [Deity: Int] {
        guard let loadout else { return [:] }
        var tally: [Deity: Int] = [:]
        for die in loadout.allDice {
            for face in die.faces {
                if let mark = face.mark {
                    tally[mark.deity, default: 0] += mark.depth.rawValue
                    if let rite = mark.rite {
                        tally[rite, default: 0] += 1
                    }
                }
            }
        }
        return tally
    }

    /// Highest tier reached, 0 when the god is not being followed.
    static func tier(_ count: Int) -> Int {
        if count >= signatureTier { return 3 }
        if count >= deeperTier { return 2 }
        if count >= passiveTier { return 1 }
        return 0
    }
}
