import SwiftUI

/// Which gear piece a combo belongs to — used to group the codex.
enum ComboSource: String, Hashable {
    case weapon
    case armor
    case item
    case divine

    var label: String {
        switch self {
        case .weapon: "Weapon Combos"
        case .armor: "Armour Combos"
        case .item: "Item Combos"
        case .divine: "Divine Combos"
        }
    }
}

/// A combo recipe. Faces must appear in the play bar in this exact order,
/// side by side, for the combo to fuse into a single step.
struct ComboDef: Identifiable, Hashable {
    let id: String
    let name: String
    /// Class that owns this combo; nil means every class can use it.
    let owner: String?
    let source: ComboSource
    /// God this combo belongs to, for tinting and the Pantheon codex.
    let deity: Deity?
    /// Faces of `deity` you must carry before this combo can be performed.
    let devotionRequired: Int
    let required: [FacePattern]
    /// All matched faces must be the same kind (Twin Shot).
    let sameKind: Bool
    /// All matched faces must be different kinds (Arcane Storm).
    let distinct: Bool
    /// All matched faces must be blessed by different gods (The Ennead).
    let distinctDeities: Bool

    let damage: Int
    let heal: Int
    let block: Int
    let dodge: Int
    /// Stamina refunded at the start of your next turn.
    let staminaNext: Int

    let bleedAmount: Int
    let bleedTurns: Int
    let poisonAmount: Int
    let poisonTurns: Int
    let burnAmount: Int
    let burnTurns: Int
    let regenAmount: Int
    let regenTurns: Int

    /// Fraction of the enemy's block this attack ignores (0–1).
    let pierce: Double
    /// Fraction the enemy's next attack is weakened by (0–1).
    let stagger: Double
    /// Extra damage multiplier applied to your next hit on this enemy.
    let mark: Double
    /// Fraction of blocked damage thrown back at the attacker.
    let reflect: Double

    let blocksAll: Bool
    let lifesteal: Bool
    let carryBlock: Bool
    let cleanseBleed: Bool
    /// Damage grows with the enemy's bleed stacks (Cutthroat).
    let scalesWithBleed: Bool
    /// Damage grows with how wounded the enemy already is (Executioner).
    let scalesWithWounds: Bool
    /// Damage grows with the burn already on the enemy (Sun Disc chains).
    let scalesWithBurn: Bool
    /// Healing grows with the block you are holding (Second Wind).
    let scalesWithBlock: Bool
    /// Damage carried into next turn's first swing (Cleaving Follow-Through).
    let momentumNext: Int
    /// This combo always crits, no matter which dice fed it.
    let guaranteedCrit: Bool

    let flavor: String

    init(
        id: String,
        name: String,
        owner: String?,
        source: ComboSource,
        deity: Deity? = nil,
        devotionRequired: Int = 0,
        required: [FacePattern],
        sameKind: Bool = false,
        distinct: Bool = false,
        distinctDeities: Bool = false,
        damage: Int = 0,
        heal: Int = 0,
        block: Int = 0,
        dodge: Int = 0,
        staminaNext: Int = 1,
        bleedAmount: Int = 0,
        bleedTurns: Int = 0,
        poisonAmount: Int = 0,
        poisonTurns: Int = 0,
        burnAmount: Int = 0,
        burnTurns: Int = 0,
        regenAmount: Int = 0,
        regenTurns: Int = 0,
        pierce: Double = 0,
        stagger: Double = 0,
        mark: Double = 0,
        reflect: Double = 0,
        blocksAll: Bool = false,
        lifesteal: Bool = false,
        carryBlock: Bool = false,
        cleanseBleed: Bool = false,
        scalesWithBleed: Bool = false,
        scalesWithWounds: Bool = false,
        scalesWithBurn: Bool = false,
        scalesWithBlock: Bool = false,
        momentumNext: Int = 0,
        guaranteedCrit: Bool = false,
        flavor: String
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.source = source
        self.deity = deity
        self.devotionRequired = devotionRequired
        self.required = required
        self.sameKind = sameKind
        self.distinct = distinct
        self.distinctDeities = distinctDeities
        self.damage = damage
        self.heal = heal
        self.block = block
        self.dodge = dodge
        self.staminaNext = staminaNext
        self.bleedAmount = bleedAmount
        self.bleedTurns = bleedTurns
        self.poisonAmount = poisonAmount
        self.poisonTurns = poisonTurns
        self.burnAmount = burnAmount
        self.burnTurns = burnTurns
        self.regenAmount = regenAmount
        self.regenTurns = regenTurns
        self.pierce = pierce
        self.stagger = stagger
        self.mark = mark
        self.reflect = reflect
        self.blocksAll = blocksAll
        self.lifesteal = lifesteal
        self.carryBlock = carryBlock
        self.cleanseBleed = cleanseBleed
        self.scalesWithBleed = scalesWithBleed
        self.scalesWithWounds = scalesWithWounds
        self.scalesWithBurn = scalesWithBurn
        self.scalesWithBlock = scalesWithBlock
        self.momentumNext = momentumNext
        self.guaranteedCrit = guaranteedCrit
        self.flavor = flavor
    }

    /// Fused combos cost less than their faces played apart: 3 faces cost 2,
    /// 4 cost 3, 5 cost 4.
    var staminaCost: Int { GameData.comboStaminaCost(faces: required.count) }

    var isDivine: Bool { source == .divine }

    /// How specific this recipe is — exact slots beat wildcards when two
    /// recipes of the same length could both match.
    var specificity: Int { required.filter(\.isExact).count }

    /// Does this exact run of faces satisfy the recipe? (Codex path; no marks.)
    func matches(_ faces: [FaceKind]) -> Bool {
        matches(faces, marks: Array(repeating: nil, count: faces.count))
    }

    /// Does this run of rolled faces satisfy the recipe, with marks in play?
    /// Marked faces keep satisfying every kind-based slot they fed before and
    /// additionally fill their god's divine slots.
    func matches(_ faces: [FaceKind], marks: [FaceMark?]) -> Bool {
        guard faces.count == required.count, marks.count == faces.count else { return false }
        for (index, pattern) in required.enumerated() where !pattern.matches(faces[index], mark: marks[index]) {
            return false
        }
        if sameKind, Set(faces).count != 1 { return false }
        if distinct, Set(faces).count != faces.count { return false }
        if distinctDeities {
            // The god of a face is its gift's god (a rite partner never stands
            // for the face here). Every slot must name a different one.
            let gods = zip(faces, marks).map { $1?.deity ?? $1?.rite }
            if gods.contains(where: { $0 == nil }) { return false }
            if Set(gods.compactMap { $0 }).count != faces.count { return false }
        }
        return true
    }

    /// One-line effect readout for the codex and play bar.
    var effectSummary: String {
        var parts: [String] = []
        if blocksAll { parts.append("blocks everything this turn") }
        if damage > 0 { parts.append("\(damage) dmg") }
        if scalesWithBleed { parts.append("+2 dmg per bleed stack") }
        if scalesWithWounds { parts.append("+dmg vs wounded") }
        if scalesWithBurn { parts.append("+3 dmg per burn stack") }
        if pierce > 0 { parts.append("ignores \(Int(pierce * 100))% block") }
        if stagger > 0 { parts.append("staggers \(Int(stagger * 100))%") }
        if mark > 0 { parts.append("marks +\(Int((mark - 1) * 100))%") }
        if reflect > 0 { parts.append("reflects \(Int(reflect * 100))%") }
        if bleedAmount > 0 { parts.append("bleed \(bleedAmount)×\(bleedTurns)") }
        if poisonAmount > 0 { parts.append("poison \(poisonAmount)×\(poisonTurns)") }
        if burnAmount > 0 { parts.append("burn \(burnAmount)×\(burnTurns)") }
        if heal > 0 { parts.append("heal \(heal)") }
        if scalesWithBlock { parts.append("+heal per block held") }
        if regenAmount > 0 { parts.append("regen \(regenAmount)×\(regenTurns)") }
        if lifesteal { parts.append("heals for damage dealt") }
        if block > 0 { parts.append("\(block) block") }
        if carryBlock { parts.append("block carries over") }
        if dodge > 0 { parts.append("\(dodge) evade\(dodge > 1 ? "s" : "")") }
        if cleanseBleed { parts.append("clears bleed") }
        if momentumNext > 0 { parts.append("+\(momentumNext) next swing") }
        if guaranteedCrit { parts.append("always crits") }
        // Recipes pay no printed refund any more — only the length of the
        // chain banks stamina, and only from three faces up.
        let bank = GameData.comboStaminaBank(faces: required.count)
        if bank > 0 { parts.append("+\(bank) stamina next turn") }
        return parts.joined(separator: ", ")
    }

    var tint: Color {
        if let deity { return deity.tint }
        if guaranteedCrit { return Theme.gold }
        switch owner {
        case "archer": return Theme.ember
        case "warrior": return Theme.steelBlue
        case "rogue": return Theme.venom
        case "magician": return Theme.arcane
        default: return Theme.gold
        }
    }
}
