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
            detail: "Arrow combos fire two hits at 60% damage each. Send both at one foe or split them — each hit meets block separately. God effects land once, on the target you pick.",
            example: "Twin Shot 22 becomes two hits of 13 — at one foe or across the pack.",
            symbol: "square.split.2x1.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_siegeDraw", classID: "archer", name: "Siege Draw",
            detail: "Tap the copper mark, then tap any arrow in your turn plan to overdraw it for 1 extra stamina: +40% damage and half of block and armour ignored. If that arrow fuses into a chain, the whole chain is overdrawn.",
            example: "Overdraw a lone Arrow III and it hits 40% harder; overdraw an arrow that becomes Piercing Bolt and all 38 of it goes through the plate.",
            symbol: "arrow.up.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_adjustableNock", classID: "archer", name: "Adjustable Nock",
            detail: "Once a turn, one held arrow counts as one tier up or down when forming a recipe. It keeps its god, its critical state and its true identity for blessings; the forecast shows the substituted tier.",
            example: "A held Arrow I forms Perfect Shot as an Arrow II.",
            symbol: "chevron.up.chevron.down", isOptional: false
        ),

        // MARK: Warrior
        ChiselDef(
            id: "ch_crescentEdge", classID: "warrior", name: "Crescent Edge",
            detail: "Damaging weapon combos also strike a second foe for 35% of their damage. No healing, statuses or god triggers carry across.",
            example: "Crushing Blow 30 hits for 30 — and a second foe takes 10.",
            symbol: "moon.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_counterweight", classID: "warrior", name: "Counterweight",
            detail: "Before a damaging action, spend up to 10 of the shield you already hold — every point spent adds 2 damage. The forecast shows both the bigger swing and the thinner guard.",
            example: "Spend 10 shield, add 20 damage to the swing.",
            symbol: "plusminus.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_relentless", classID: "warrior", name: "Relentless Advance",
            detail: "Land a weapon combo and your first weapon combo next turn costs 1 less stamina, never below 1. Skip a turn without one and the momentum is gone.",
            example: "Crushing Blow this turn makes next turn's Wide Sweep cost 1 instead of 2.",
            symbol: "forward.fill", isOptional: false
        ),

        // MARK: Rogue
        ChiselDef(
            id: "ch_returningKnife", classID: "rogue", name: "Returning Knife",
            detail: "Once a turn, the first dagger you throw comes back as a held face next turn, keeping its god and critical state. It takes a hold slot, its die sits out the fresh draw, and it cannot return twice from the same appearance.",
            example: "Throw a Dagger Throw on turn 3 — the same knife, held, opens turn 4.",
            symbol: "arrow.uturn.backward.circle.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_concealedBlade", classID: "rogue", name: "Concealed Blade",
            detail: "Once a turn, an Evade face also counts as a Swift Slash in a weapon recipe while still granting its evasion. Its god still answers it as a defensive face, not an attack.",
            example: "Evade + Swift Slash forms Opening Cut — and you keep the 15% evade.",
            symbol: "eye.slash.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_assassin", classID: "rogue", name: "Assassin's Commitment",
            detail: "Before a damaging combo, burn one evade charge (15% evade) for +40% damage and half of block and armour ignored. Evasion made by that same combo cannot pay for it.",
            example: "With 30% evade banked, Hemorrhage 36 becomes 50 and mostly unblockable.",
            symbol: "bolt.fill", isOptional: true
        ),

        // MARK: Magician
        ChiselDef(
            id: "ch_prismatic", classID: "magician", name: "Prismatic Focus",
            detail: "Once a turn, an Arcane rune stands in for Fire, Frost or Life when a spell needs it. It keeps its god, its critical state and its blessing role; you choose the spell by the faces you place.",
            example: "Arcane + Fire forms Fireball as two Fires.",
            symbol: "diamond.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_echoingStaff", classID: "magician", name: "Echoing Staff",
            detail: "Before committing a spell, spend 1 extra stamina to echo it at the start of your next turn for half its damage, healing and shield. Statuses, stamina, evasion, god effects and further echoes do not repeat; the echo slides to a living foe if its target dies.",
            example: "Fireball 26 echoes for 13 at the start of your next turn.",
            symbol: "repeat", isOptional: true
        ),
        ChiselDef(
            id: "ch_current", classID: "magician", name: "Alternating Current",
            detail: "The staff remembers whether your last cast spell used matching or mixed runes. Cast the opposite kind and bank 1 stamina for next turn, once a turn. The first spell only sets the memory.",
            example: "Fireball (matching) then Ice Blast (matching) banks nothing — Meteor (mixed) after either banks 1.",
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
