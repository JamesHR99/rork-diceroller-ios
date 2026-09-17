import Foundation

/// A Chisel of Ptah: a craftsman's modification that changes how the whole
/// weapon works — split shots, overdraws, returning knives, echoing spells —
/// never a single die. Gods and their blessings are untouched. Two different
/// Chisels per run, maximum; both stay active and work together.
struct ChiselDef: Identifiable, Hashable {
    let id: String
    let classID: String
    let name: String
    /// What changes, exactly.
    let detail: String
    /// A worked example, shown before you commit.
    let example: String
    let symbol: String
    /// Optional Chisels arm per action from a small Ptah badge on the recipe's
    /// own chip; the rest reshape the weapon passively.
    let isOptional: Bool
}

enum ChiselCatalog {
    static let all: [ChiselDef] = [
        // MARK: Archer
        ChiselDef(
            id: "ch_twinBowstring", classID: "archer", name: "Twin Bowstring",
            detail: "Arrow combos fire 2 hits at 60% each. Split them or stack them.",
            example: "Twin Shot 22 → two hits of 13.",
            symbol: "square.split.2x1.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_siegeDraw", classID: "archer", name: "Siege Draw",
            detail: "Tap the mark, then an arrow: +1 stamina for +40% damage and 50% pierce. Carries to whatever combo that arrow joins.",
            example: "Overdraw an arrow inside Piercing Bolt and all 38 pierces.",
            symbol: "arrow.up.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_adjustableNock", classID: "archer", name: "Adjustable Nock",
            detail: "Once a turn, tap a held arrow to shift it one tier up or down. The die visibly changes. Tap again to put it back.",
            example: "Arrow I → Arrow II, forming Perfect Shot.",
            symbol: "chevron.up.chevron.down", isOptional: false
        ),

        // MARK: Warrior
        ChiselDef(
            id: "ch_crescentEdge", classID: "warrior", name: "Crescent Edge",
            detail: "Damaging weapon combos splash a second foe for 35%. Damage only.",
            example: "Crushing Blow 30 → second foe takes 10.",
            symbol: "moon.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_counterweight", classID: "warrior", name: "Counterweight",
            detail: "Spend up to 10 held shield for +2 damage each.",
            example: "10 shield → +20 damage.",
            symbol: "plusminus.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_relentless", classID: "warrior", name: "Relentless Advance",
            detail: "Land a weapon combo: next turn's first one costs 1 less, min 1.",
            example: "Wide Sweep costs 1 instead of 2.",
            symbol: "forward.fill", isOptional: false
        ),

        // MARK: Rogue
        ChiselDef(
            id: "ch_returningKnife", classID: "rogue", name: "Returning Knife",
            detail: "Once a turn, your first thrown dagger returns held next turn. Takes a hold slot.",
            example: "Throw it turn 3, it opens turn 4.",
            symbol: "arrow.uturn.backward.circle.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_concealedBlade", classID: "rogue", name: "Concealed Blade",
            detail: "Once a turn, an Evade also counts as a Swift Slash. You keep the evasion.",
            example: "Evade + Swift Slash → Opening Cut.",
            symbol: "eye.slash.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_assassin", classID: "rogue", name: "Assassin's Commitment",
            detail: "Burn 15% evade for +40% damage and 50% pierce.",
            example: "Hemorrhage 36 → 50, mostly unblockable.",
            symbol: "bolt.fill", isOptional: true
        ),

        // MARK: Magician
        ChiselDef(
            id: "ch_prismatic", classID: "magician", name: "Prismatic Focus",
            detail: "Once a turn, an Arcane rune stands in for Fire, Frost or Life.",
            example: "Arcane + Fire → Fireball.",
            symbol: "diamond.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_echoingStaff", classID: "magician", name: "Echoing Staff",
            detail: "+1 stamina: the spell repeats next turn for half its damage, healing and shield.",
            example: "Fireball 26 → echoes for 13.",
            symbol: "repeat", isOptional: true
        ),
        ChiselDef(
            id: "ch_current", classID: "magician", name: "Alternating Current",
            detail: "Alternate matched and mixed runes to bank 1 stamina, once a turn.",
            example: "Fireball then Meteor → +1 stamina.",
            symbol: "arrow.left.arrow.right", isOptional: false
        ),
    ]

    /// The three Chisels of one class.
    static func chisels(for classID: String) -> [ChiselDef] {
        all.filter { $0.classID == classID }
    }

    static func def(_ id: String) -> ChiselDef? {
        all.first { $0.id == id }
    }
}
