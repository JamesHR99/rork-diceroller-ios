import Foundation

/// The fifteen named duos — one for every pair of gods. Two routes:
/// chained (both gods' gifts fire inside one chain → a taste of the duo) and
/// bound (a rite marries both gods into one face → the duo at full strength
/// every play).
struct DuoDef: Identifiable, Hashable {
    let id: String
    let name: String
    let flavor: String
    let first: Deity
    let second: Deity
    /// The weaker effect when the pair is chained together.
    let chained: DivineFaceEffect
    /// The full-strength effect a bound face fires every play.
    let bound: DivineFaceEffect

    var deities: [Deity] { [first, second] }
}

enum DuoContent {
    static let all: [DuoDef] = [
        DuoDef(id: "duo_ra_sobek", name: "Boiling Nile",
               flavor: "Scalding floodwater. It goes everywhere armour does not.",
               first: .ra, second: .sobek,
               chained: DivineFaceEffect(damage: 4, burnAmount: 5, burnTurns: 2, pierce: 0.3),
               bound: DivineFaceEffect(damage: 8, burnAmount: 8, burnTurns: 3, pierce: 0.6)),
        DuoDef(id: "duo_ra_anubis", name: "Flaming Rot",
               flavor: "Burning and rotting in the same wound.",
               first: .ra, second: .anubis,
               chained: DivineFaceEffect(damage: 4, burnAmount: 4, burnTurns: 2, poisonAmount: 4, poisonTurns: 2),
               bound: DivineFaceEffect(damage: 9, burnAmount: 7, burnTurns: 3, poisonAmount: 7, poisonTurns: 3)),
        DuoDef(id: "duo_ra_bes", name: "Forge Song",
               flavor: "A drumbeat and a furnace, in step.",
               first: .ra, second: .bes,
               chained: DivineFaceEffect(block: 10, stagger: 0.15),
               bound: DivineFaceEffect(block: 16, stagger: 0.3, reflect: 0.25)),
        DuoDef(id: "duo_ra_horus", name: "The Stoop Out of the Sun",
               flavor: "The falcon dives straight out of the sun itself.",
               first: .ra, second: .horus,
               chained: DivineFaceEffect(damage: 10, mark: 1.2, critBoost: 0.05),
               bound: DivineFaceEffect(damage: 18, pierce: 0.5, mark: 1.4, critBoost: 0.1)),
        DuoDef(id: "duo_ra_bastet", name: "Sunlight Through Reeds",
               flavor: "Warm where it lands, sharp where it slips.",
               first: .ra, second: .bastet,
               chained: DivineFaceEffect(damage: 7, bleedAmount: 3, bleedTurns: 2),
               bound: DivineFaceEffect(damage: 13, dodgeGain: 1, bleedAmount: 6, bleedTurns: 3)),

        DuoDef(id: "duo_sobek_anubis", name: "The Crossing",
               flavor: "The ferryman takes his toll where the water is deepest.",
               first: .sobek, second: .anubis,
               chained: DivineFaceEffect(heal: 4, poisonAmount: 5, poisonTurns: 2),
               bound: DivineFaceEffect(heal: 8, poisonAmount: 9, poisonTurns: 3, lifesteal: true)),
        DuoDef(id: "duo_sobek_bes", name: "The Hide Nothing Gets Through",
               flavor: "Scales over stone over a small god's stubbornness.",
               first: .sobek, second: .bes,
               chained: DivineFaceEffect(block: 12, reflect: 0.2, carryBlock: true),
               bound: DivineFaceEffect(block: 18, stagger: 0.2, reflect: 0.4, carryBlock: true)),
        DuoDef(id: "duo_sobek_horus", name: "Reed and Sky",
               flavor: "Seen from above, dragged under from below.",
               first: .sobek, second: .horus,
               chained: DivineFaceEffect(damage: 9, stagger: 0.2, mark: 1.15),
               bound: DivineFaceEffect(damage: 15, pierce: 0.4, stagger: 0.35, mark: 1.3)),
        DuoDef(id: "duo_sobek_bastet", name: "The Death Roll",
               flavor: "Take hold and spin. The river taught you this.",
               first: .sobek, second: .bastet,
               chained: DivineFaceEffect(damage: 6, dodgeGain: 1, bleedAmount: 5, bleedTurns: 2),
               bound: DivineFaceEffect(damage: 12, dodgeGain: 2, bleedAmount: 9, bleedTurns: 3)),
        DuoDef(id: "duo_anubis_bes", name: "The Funeral Feast",
               flavor: "Grief and laughter, sharing one table.",
               first: .anubis, second: .bes,
               chained: DivineFaceEffect(heal: 8, block: 8),
               bound: DivineFaceEffect(heal: 14, block: 14, cleanse: true)),
        DuoDef(id: "duo_anubis_horus", name: "The Weighing Eye",
               flavor: "Nothing is hidden from the judge, and nothing misses him.",
               first: .anubis, second: .horus,
               chained: DivineFaceEffect(damage: 7, critBoost: 0.04, scalesWithWounds: true),
               bound: DivineFaceEffect(damage: 13, pierce: 0.4, critBoost: 0.08, scalesWithWounds: true)),
        DuoDef(id: "duo_anubis_bastet", name: "Nine Candles",
               flavor: "One lit for every life she is owed.",
               first: .anubis, second: .bastet,
               chained: DivineFaceEffect(poisonAmount: 4, poisonTurns: 2, bleedAmount: 4, bleedTurns: 2),
               bound: DivineFaceEffect(dodgeGain: 1, poisonAmount: 7, poisonTurns: 3, bleedAmount: 7, bleedTurns: 3)),
        DuoDef(id: "duo_bes_horus", name: "The Watchdog's Door",
               flavor: "One god at the door, one already on the roof.",
               first: .bes, second: .horus,
               chained: DivineFaceEffect(block: 10, dodgeGain: 1),
               bound: DivineFaceEffect(block: 16, dodgeGain: 2, reflect: 0.25)),
        DuoDef(id: "duo_bes_bastet", name: "The Warm Doorstep",
               flavor: "The fire kept lit, the cat kept fed.",
               first: .bes, second: .bastet,
               chained: DivineFaceEffect(heal: 7, block: 6, dodgeGain: 1),
               bound: DivineFaceEffect(heal: 13, block: 10, dodgeGain: 2, reflect: 0.2)),
        DuoDef(id: "duo_horus_bastet", name: "Hunter's Harmony",
               flavor: "Seen from above, struck from the shadow.",
               first: .horus, second: .bastet,
               chained: DivineFaceEffect(damage: 7, dodgeGain: 1, critBoost: 0.05),
               bound: DivineFaceEffect(damage: 13, dodgeGain: 2, mark: 1.25, critBoost: 0.1)),
    ]

    /// The duo for an unordered pair of gods, if one exists.
    static func duo(_ a: Deity, _ b: Deity) -> DuoDef? {
        guard a != b else { return nil }
        return all.first { duo in
            (duo.first == a && duo.second == b) || (duo.first == b && duo.second == a)
        }
    }

    /// The best duo available for a set of gods present in one chain: the pair
    /// whose gods are most heavily represented among the faces played.
    static func bestDuo(among gods: Set<Deity>, weightedBy weights: [Deity: Int]) -> DuoDef? {
        all
            .filter { gods.contains($0.first) && gods.contains($0.second) }
            .max { score($0, weights) < score($1, weights) }
    }

    private static func score(_ duo: DuoDef, _ weights: [Deity: Int]) -> Int {
        (weights[duo.first] ?? 0) + (weights[duo.second] ?? 0)
    }
}
