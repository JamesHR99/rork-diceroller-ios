import Foundation

/// Everything a blessed face does when it is played on its own. Ordinary faces
/// are described by `SoloKind`; god faces carry one of these instead so a single
/// blessing can burn, pierce and heal in the same breath.
struct DivineFaceEffect: Hashable {
    var damage: Int = 0
    var heal: Int = 0
    var block: Int = 0
    var dodgeGain: Int = 0
    var rerollsNext: Int = 0
    var burnAmount: Int = 0
    var burnTurns: Int = 0
    var poisonAmount: Int = 0
    var poisonTurns: Int = 0
    var bleedAmount: Int = 0
    var bleedTurns: Int = 0
    var regenAmount: Int = 0
    var regenTurns: Int = 0
    var pierce: Double = 0
    var weaken: Double = 0
    /// Fraction of damage taken this turn thrown back at the attacker (guards).
    var reflect: Double = 0
    var mark: Double = 1
    /// Crit chance added to every face for the rest of the fight.
    var critBoost: Double = 0
    var lifesteal: Bool = false
    var carryBlock: Bool = false
    /// Clears bleed on you.
    var cleanse: Bool = false
    var blocksAll: Bool = false
    /// This face always lands critical, whatever its printed chance.
    var alwaysCrit: Bool = false
    var scalesWithWounds: Bool = false
    var scalesWithBurn: Bool = false
    var scalesWithWeaken: Bool = false

    /// The number shown as the face's headline value.
    var headlineValue: Int {
        if damage > 0 { return damage }
        if heal > 0 { return heal }
        if block > 0 { return block }
        if poisonAmount > 0 { return poisonAmount }
        if bleedAmount > 0 { return bleedAmount }
        return 0
    }

    var isAttack: Bool { damage > 0 }

    /// Full sentence for the codex and offer cards.
    var summary: String {
        parts.joined(separator: ", ")
    }

    /// Compact readout for the dice tray.
    var tag: String {
        if damage > 0 { return "\(damage) dmg" }
        if heal > 0 { return "+\(heal) hp" }
        if block > 0 { return "+\(block) blk" }
        if poisonAmount > 0 { return "\(poisonAmount) psn" }
        if dodgeGain > 0 { return "evade" }
        if mark > 1 { return "mark" }
        return "blessing"
    }

    var parts: [String] {
        var list: [String] = []
        if blocksAll { list.append("blocks the whole turn") }
        if damage > 0 { list.append("\(damage) damage") }
        if scalesWithWounds { list.append("+damage the more wounded they are") }
        if scalesWithBurn { list.append("+3 damage per burn stack") }
        if scalesWithWeaken { list.append("+12 dmg vs weakened") }
        if alwaysCrit { list.append("always crits") }
        if pierce > 0 { list.append("ignores \(Int(pierce * 100))% block") }
        if lifesteal { list.append("heals for the damage dealt") }
        if burnAmount > 0 { list.append("burn \(burnAmount) for \(burnTurns)") }
        if poisonAmount > 0 { list.append("poison \(poisonAmount) for \(poisonTurns)") }
        if bleedAmount > 0 { list.append("bleed \(bleedAmount) for \(bleedTurns)") }
        if heal > 0 { list.append("heal \(heal)") }
        if regenAmount > 0 { list.append("regen \(regenAmount) for \(regenTurns)") }
        if block > 0 { list.append("\(block) block") }
        if carryBlock { list.append("block carries over") }
        if cleanse { list.append("clears bleed") }
        if dodgeGain > 0 { list.append("\(dodgeGain) evade") }
        if weaken > 0 { list.append("weaken \(Int(weaken * 100))%") }
        if reflect > 0 { list.append("scorches back \(Int(reflect * 100))%") }
        if mark > 1 { list.append("marks +\(Int((mark - 1) * 100))%") }
        if critBoost > 0 { list.append("+\(Int(critBoost * 100))% crit for the fight") }
        if rerollsNext > 0 { list.append("+\(rerollsNext) reroll next round") }
        return list
    }
}

