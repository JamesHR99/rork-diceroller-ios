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
            detail: "Arrow groups of 2+ fire two packets at 55% native damage each. Gods and statuses ride only the first.",
            example: "Hunter’s Volley 30 → 16 + 16; split or stack targets.",
            symbol: "square.split.2x1.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_siegeDraw", classID: "archer", name: "Siege Draw",
            detail: "Reserve one reroll pass for one Arrow combo: +25% damage and +30 points Pierce.",
            example: "A pass spent on power cannot also reroll dice.",
            symbol: "arrow.up.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_adjustableNock", classID: "archer", name: "Adjustable Nock",
            detail: "Once a round, shift one Prepared arrow one tier up or down before grouping.",
            example: "Arrow I → Arrow II visibly, preserving its critical result.",
            symbol: "chevron.up.chevron.down", isOptional: false
        ),

        // MARK: Warrior
        ChiselDef(
            id: "ch_crescentEdge", classID: "warrior", name: "Crescent Edge",
            detail: "Swing combos add 25% of native main damage as splash to a second foe. No copied gods or statuses.",
            example: "Crushing Blow 27 → 6 additional splash.",
            symbol: "moon.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_counterweight", classID: "warrior", name: "Counterweight",
            detail: "Spend up to 10 existing Shield at release for +2 main damage per Shield. The action’s new Shield cannot pay.",
            example: "8 remaining Shield → +16 damage; incoming hits can reduce this.",
            symbol: "plusminus.circle.fill", isOptional: true
        ),
        ChiselDef(
            id: "ch_relentless", classID: "warrior", name: "Relentless Advance",
            detail: "Resolve a swing combo: next round’s first swing combo gains +8 damage. Does not stack.",
            example: "A pair now strengthens a finisher next round.",
            symbol: "forward.fill", isOptional: false
        ),

        // MARK: Rogue
        ChiselDef(
            id: "ch_returningKnife", classID: "rogue", name: "Returning Knife",
            detail: "First Dagger action arms a returning blade: after your next separate Attack this round, deal 8 secondary damage.",
            example: "Dagger pair → Slash pair → one returning blade. No extra die.",
            symbol: "arrow.uturn.backward.circle.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_concealedBlade", classID: "rogue", name: "Concealed Blade",
            detail: "Once a round, convert one Evade to Swift Slash. It loses its Dodge and visibly becomes Slash.",
            example: "Long-press the die: two Slashes plus converted Evade make three Slashes.",
            symbol: "eye.slash.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_assassin", classID: "rogue", name: "Assassin's Commitment",
            detail: "Spend one unassigned Dodge at release for +30% damage and +30 points Pierce on a Slash or Dagger.",
            example: "The action’s own new Dodge cannot pay. Assigned Dodges are protected.",
            symbol: "bolt.fill", isOptional: true
        ),

        // MARK: Magician
        ChiselDef(
            id: "ch_prismatic", classID: "magician", name: "Prismatic Focus",
            detail: "Once a round, convert one Arcane result to Fire, Frost or Life before grouping.",
            example: "Long-press Arcane to choose its new visible face. No Arcane effect remains.",
            symbol: "diamond.fill", isOptional: false
        ),
        ChiselDef(
            id: "ch_echoingStaff", classID: "magician", name: "Echoing Staff",
            detail: "Reserve one reroll pass: a spell combo echoes 40% of native damage, healing and Shield next round.",
            example: "No status, Dodge, Focus, god or Chisel payload is copied.",
            symbol: "repeat", isOptional: true
        ),
        ChiselDef(
            id: "ch_current", classID: "magician", name: "Alternating Current",
            detail: "Once a round, consecutive different rune actions give the second +6 damage if offensive, otherwise +6 Shield.",
            example: "Channel → Fire qualifies; Fire → Fire does not. Wand Zap breaks the sequence.",
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


