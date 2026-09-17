import SwiftUI

/// Which character slot a power occupies. Three Attack, two Defence, two
/// Utility, and one Legendary kept apart from them — powers from any number
/// of gods may share an action.
enum BoonSlot: String, CaseIterable, Hashable, Identifiable {
    case attack
    case defence
    case utility
    case legendary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .attack: "Attack"
        case .defence: "Defence"
        case .utility: "Utility"
        case .legendary: "Legendary"
        }
    }

    /// How many of this slot a character carries. The legendary slot holds one
    /// and never competes with an ordinary power for room.
    var capacity: Int {
        switch self {
        case .attack: 3
        case .defence: 2
        case .utility: 2
        case .legendary: 1
        }
    }

    var symbol: String {
        switch self {
        case .attack: "burst.fill"
        case .defence: "shield.lefthalf.filled"
        case .utility: "sparkles"
        case .legendary: "crown.fill"
        }
    }

    var tint: Color {
        switch self {
        case .attack: Theme.ember
        case .defence: Theme.steelBlue
        case .utility: Theme.gold
        case .legendary: Theme.goldLeaf
        }
    }
}

/// A boon's quality, rolled and shown *before* you choose it. Separate from
/// level: rarity sets the ceiling, level climbs within it.
enum BoonRarity: Int, CaseIterable, Hashable, Comparable, Codable {
    case common = 0
    case rare = 1
    case epic = 2

    nonisolated static func < (lhs: BoonRarity, rhs: BoonRarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .common: "Common"
        case .rare: "Rare"
        case .epic: "Epic"
        }
    }

    var tint: Color {
        switch self {
        case .common: Theme.clay
        case .rare: Theme.lapis
        case .epic: Theme.goldLeaf
        }
    }

    /// Which third of the night this is, for the offer odds.
    enum Phase {
        case early
        case middle
        case late

        /// `progress` runs 0 (river mouth) to 1 (Apep).
        static func of(progress: Double) -> Phase {
            if progress < 0.34 { return .early }
            return progress < 0.67 ? .middle : .late
        }
    }

    /// The guide's rarity table for a new scalable boon offer.
    static func weights(phase: Phase) -> [Double] {
        switch phase {
        case .early: [0.75, 0.23, 0.02]
        case .middle: [0.45, 0.40, 0.15]
        case .late: [0.20, 0.45, 0.35]
        }
    }

    static func roll(progress: Double) -> BoonRarity {
        let weights = weights(phase: Phase.of(progress: progress))
        let total = weights.reduce(0, +)
        guard total > 0 else { return .common }
        var roll = Double.random(in: 0..<total)
        for (index, weight) in weights.enumerated() {
            if roll < weight { return BoonRarity(rawValue: index) ?? .common }
            roll -= weight
        }
        return .epic
    }
}

/// Highest level a scalable boon may reach. A prototype parameter.
let boonMaxLevel = 3

/// What sort of card this is. Regulars are the everyday 60; duos need two
/// gods' powers equipped; legendaries replace a named regular in its slot.
enum BoonKind: Hashable {
    case regular
    case duo
    case legendary
}

/// When a power answers. Every "first/second/third" counter means completed
/// primary player actions in that round — never ingredient count or animation
/// hits.
enum BoonTrigger: Hashable {
    case everyAttack
    case firstAttack
    case secondAttack
    case thirdAttack
    case firstLargeCombo
    case firstTwoFaceCombo
    case firstFrozenAttack
    case firstAttackOnWounded
    case firstComboWithBlock
    case everyGuard
    case firstGuard
    case firstFrozenGuard
    case firstEvade
    case firstFrozenAction
    case onDodge
    case onShieldAbsorb
    case encounterStart
    case roundStart
    case roundEnd
    case atCommitment

    /// Human-readable lead-in used on cards that do not print their own.
    var label: String {
        switch self {
        case .everyAttack: "Every attack"
        case .firstAttack: "First attack"
        case .secondAttack: "Second attack"
        case .thirdAttack: "Third attack"
        case .firstLargeCombo: "First large combo"
        case .firstTwoFaceCombo: "First two-face combo"
        case .firstFrozenAttack: "First held attack"
        case .firstAttackOnWounded: "First attack on the wounded"
        case .firstComboWithBlock: "First attack combo with a Block"
        case .everyGuard: "Every guard"
        case .firstGuard: "First guard"
        case .firstFrozenGuard: "First held guard"
        case .firstEvade: "First evade"
        case .firstFrozenAction: "First held action"
        case .onDodge: "On your first dodge"
        case .onShieldAbsorb: "When your shield takes a hit"
        case .encounterStart: "At the start of the fight"
        case .roundStart: "At the start of the round"
        case .roundEnd: "At the end of the round"
        case .atCommitment: "When you commit"
        }
    }
}

/// An extra clause tested before the action changes anything.
enum BoonCondition: Hashable {
    case targetBurning
    case targetBleeding
    case targetJudged
    case hadEightShield
    case hasCritIngredient
    case openedRoundWithFive
    case usesFrozenFace
    case sameTargetAsLast
    case isTwoFaceCombo
    case lostNoHealth
    case healthAtHalf
    case endedWithEightShield
    case endedWithZeroStamina
}

/// Which number on a card the level and rarity move. Everything else on the
/// card is fixed and never grows quietly.
enum BoonScalingField: Hashable {
    case flatDamage
    case percentDamage
    case pierce
    case burn
    case bleed
    case poison
    case judgement
    case shield
    case heal
    case evadePoints
    /// Cards whose scaling number is the *conditional* percentage, like Sun's
    /// Edge, where the fixed clause is the per-ingredient Burn.
    case bonusPercent
}

/// What a power actually does when it answers.
struct BoonPayload: Hashable {
    var flatDamage = 0
    var percentDamage = 0
    /// Pierce in percentage points.
    var pierce = 0
    var burn = 0
    var bleed = 0
    var poison = 0
    var judgement = 0
    var shield = 0
    var heal = 0
    var evadePoints = 0
    /// How much the target's next attack is softened by, in percentage points.
    var weakenPercent = 0
    /// How much harder your next attack on the target lands, in percentage
    /// points. Additive on the hit, never multiplied over it.
    var markPercent = 0
    /// Clears your own Burn, Bleed and Poison.
    var cleansesSelf = false
    /// Stamina banked for the following round.
    var staminaNext = 0
    /// Beats of Haste handed to the qualifying action.
    var haste = 0
    /// Scales the headline number by each qualifying ingredient.
    var perIngredient = false
    /// Ceiling when `perIngredient` pools its result (Sheltering Blow).
    var perIngredientCap = 0
    /// A conditional extra, tested before the action resolves.
    var bonusCondition: BoonCondition?
    var bonusPercentDamage = 0
    var bonusFlatDamage = 0
    var bonusShield = 0
    var bonusEvadePoints = 0
    var bonusJudgement = 0
    var bonusHeal = 0
    /// Extra Burn added when the card's condition holds.
    var burnBonus = 0
}

/// One card in the catalogue. The text is the contract: `effect` is printed
/// with its live value substituted, so what a player reads is always what the
/// engine will do at that rarity and level.
struct GodBoonDef: Identifiable, Hashable {
    let id: String
    let god: Deity
    let slot: BoonSlot
    let name: String
    /// Complete effect text. `%V` is replaced by the live scaling value.
    let effect: String
    /// The card's stated job, for the codex.
    let function: String
    let kind: BoonKind
    let trigger: BoonTrigger
    var payload: BoonPayload = BoonPayload()
    /// Which number rarity and level move; nil marks a Fixed card.
    var scales: BoonScalingField?
    /// Common level 1 / 2 / 3 values, exactly as printed in the guide.
    var values: [Int] = []
    /// A clause that must hold for the whole card to answer.
    var requires: BoonCondition?
    /// Duo prerequisites — both source groups must stay equipped.
    var sources: [BoonSourceGroup] = []
    /// The regular boon a legendary replaces.
    var evolves: String?

    var isFixed: Bool { scales == nil }

    /// Which gods may bring this card. A regular or a legendary is its own
    /// god's to give; a duo belongs to both gods it was made from, so either
    /// of them may offer it — it is never found any other way.
    var offeringGods: [Deity] {
        guard kind == .duo else { return [god] }
        var found: [Deity] = []
        for source in sources where !found.contains(source.god) {
            found.append(source.god)
        }
        return found.isEmpty ? [god] : found
    }

    /// The live value for this rarity and level. Level adds the card's own
    /// step; rarity adds one more than that step, which is what makes a
    /// Common level 3 able to beat a fresh Rare while the Rare keeps the
    /// higher ceiling.
    func value(rarity: BoonRarity, level: Int) -> Int {
        guard !values.isEmpty else { return 0 }
        let clamped = min(max(level, 1), boonMaxLevel)
        let base = values[min(clamped - 1, values.count - 1)]
        let step = values.count > 1 ? values[1] - values[0] : 0
        return base + (step + 1) * rarity.rawValue
    }

    /// The card's text with its live number written in.
    func text(rarity: BoonRarity, level: Int) -> String {
        guard scales != nil else { return effect }
        return effect.replacingOccurrences(of: "%V", with: "\(value(rarity: rarity, level: level))")
    }

    /// The payload as it resolves at this rarity and level.
    func resolved(rarity: BoonRarity, level: Int) -> BoonPayload {
        guard let scales else { return payload }
        var result = payload
        let live = value(rarity: rarity, level: level)
        switch scales {
        case .flatDamage: result.flatDamage = live
        case .percentDamage: result.percentDamage = live
        case .pierce: result.pierce = live
        case .burn: result.burn = live
        case .bleed: result.bleed = live
        case .poison: result.poison = live
        case .judgement: result.judgement = live
        case .shield: result.shield = live
        case .heal: result.heal = live
        case .evadePoints: result.evadePoints = live
        case .bonusPercent: result.bonusPercentDamage = live
        }
        return result
    }
}

/// The groups a duo asks for. A legendary counts as the boon it evolved from;
/// native faces never substitute for a named god source.
enum BoonSourceGroup: String, Hashable {
    case raBurn
    case sobekBleed
    case sobekHealing
    case anubisJudgement
    case besShield
    case horusFrozen
    case horusPierce
    case bastetEvade

    var label: String {
        switch self {
        case .raBurn: "Ra Burn"
        case .sobekBleed: "Sobek Bleed"
        case .sobekHealing: "Sobek Healing"
        case .anubisJudgement: "Anubis Judgement"
        case .besShield: "Bes Shield"
        case .horusFrozen: "Horus Frozen"
        case .horusPierce: "Horus Pierce"
        case .bastetEvade: "Bastet Evade"
        }
    }

    /// The god this group of powers belongs to — which is what makes a duo
    /// offerable by either of the two gods who made it.
    var god: Deity {
        switch self {
        case .raBurn: .ra
        case .sobekBleed, .sobekHealing: .sobek
        case .anubisJudgement: .anubis
        case .besShield: .bes
        case .horusFrozen, .horusPierce: .horus
        case .bastetEvade: .bastet
        }
    }

    /// The regular boons that satisfy this group, per the guide's table.
    var members: Set<String> {
        switch self {
        case .raBurn:
            ["RA-A1", "RA-A2", "RA-A3", "RA-A4", "RA-A5", "RA-D1", "RA-D2", "RA-D3"]
        case .sobekBleed:
            ["SO-A1", "SO-A2", "SO-A3", "SO-A4", "SO-A5", "SO-D1"]
        case .sobekHealing:
            ["SO-A4", "SO-A5", "SO-D2", "SO-D3", "SO-U2"]
        case .anubisJudgement:
            ["AN-A1", "AN-A2", "AN-A3", "AN-A4", "AN-A5", "AN-D1", "AN-D2"]
        case .besShield:
            ["BE-A1", "BE-A2", "BE-A3", "BE-A4", "BE-A5", "BE-D1", "BE-D2", "BE-D3", "BE-U2"]
        case .horusFrozen:
            ["HO-A1", "HO-D1", "HO-D2", "HO-D3", "HO-U1", "HO-U2"]
        case .horusPierce:
            ["HO-A1", "HO-A2", "HO-A3", "HO-A4", "HO-A5"]
        case .bastetEvade:
            ["BA-A1", "BA-A3", "BA-A5", "BA-D1", "BA-D2"]
        }
    }
}

/// A power as the character actually carries it: which card, how good a copy,
/// and how far it has been levelled.
struct EquippedBoon: Identifiable, Hashable, Codable {
    let defID: String
    var rarity: BoonRarity
    var level: Int

    var id: String { defID }

    var def: GodBoonDef? { GodCatalog.boon(defID) }

    /// Can this copy still take a level?
    var canLevel: Bool {
        guard let def, !def.isFixed else { return false }
        return level < boonMaxLevel
    }

    var payload: BoonPayload {
        def?.resolved(rarity: rarity, level: level) ?? BoonPayload()
    }

    var text: String {
        def?.text(rarity: rarity, level: level) ?? ""
    }
}
