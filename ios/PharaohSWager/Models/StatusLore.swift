import SwiftUI

/// Every status a fighter can wear, defined once. The fight reads these for
/// its tap-a-badge bubbles and the codex reads them for its glossary, so a
/// status can never be explained two different ways.
enum StatusKind: String, CaseIterable, Identifiable {
    case burn
    case bleed
    case poison
    case judgement
    case weaken
    case mark
    case evade
    case regeneration
    case shield
    case armour
    case champion

    var id: String { rawValue }

    var name: String {
        switch self {
        case .burn: "Burn"
        case .bleed: "Bleed"
        case .poison: "Poison"
        case .judgement: "Judgement"
        case .weaken: "Weaken"
        case .mark: "Mark"
        case .evade: "Evade"
        case .regeneration: "Regeneration"
        case .shield: "Guard"
        case .armour: "Plate"
        case .champion: "Champion"
        }
    }

    /// The painted mark this status wears in the fight.
    var art: String {
        switch self {
        case .burn: PharaohSWagerArt.Status.burn
        case .bleed: PharaohSWagerArt.Status.bleed
        case .poison: PharaohSWagerArt.Status.poison
        case .judgement: PharaohSWagerArt.Status.judgement
        case .weaken: PharaohSWagerArt.Status.frost
        case .mark: PharaohSWagerArt.Status.marked
        case .evade: PharaohSWagerArt.Status.evade
        case .regeneration: PharaohSWagerArt.Status.regeneration
        case .shield: PharaohSWagerArt.Status.shield
        case .armour: PharaohSWagerArt.Status.armour
        case .champion: PharaohSWagerArt.Status.champion
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .burn: "flame.fill"
        case .bleed: "drop.fill"
        case .poison: "drop.triangle.fill"
        case .judgement: "scalemass.fill"
        case .weaken: "arrow.down.right.circle.fill"
        case .mark: "scope"
        case .evade: "wind"
        case .regeneration: "leaf.fill"
        case .shield: "shield.lefthalf.filled"
        case .armour: "shield.fill"
        case .champion: "crown.fill"
        }
    }

    var tint: Color {
        switch self {
        case .burn: Theme.ember
        case .bleed: Theme.blood
        case .poison: Theme.venom
        case .judgement: Deity.anubis.tint
        case .weaken: Theme.frost
        case .mark: Theme.venom
        case .evade: Theme.steel
        case .regeneration: Theme.forest
        case .shield: Theme.steel
        case .armour: Theme.bronze
        case .champion: Theme.gold
        }
    }

    /// The god this status belongs to, where one owns it.
    var patron: Deity? {
        switch self {
        case .burn: .ra
        case .bleed: .sobek
        case .judgement: .anubis
        case .evade: .bastet
        case .shield: .bes
        default: nil
        }
    }

    /// What it does, in one short line, from the point of view of whoever is
    /// wearing it. Every status keeps a distinct job so two never read alike.
    func summary(onSelf: Bool) -> String {
        let you = onSelf ? "you" : "it"
        switch self {
        case .burn:
            return "Fast fire. Bites at round end, then halves."
        case .bleed:
            return "Bites just before \(you) attack\(onSelf ? "" : "s"). Aggression costs blood."
        case .poison:
            return "Bites at round end, then grows by 1. Never fades."
        case .judgement:
            return "Stored damage. A 3+ die attack combo releases it, past guard."
        case .weaken:
            return "\(onSelf ? "Your" : "Its") next attack lands softer."
        case .mark:
            return "The next attack on \(you) hits harder, then it is spent."
        case .evade:
            return "One charge dodges one chosen incoming hit."
        case .regeneration:
            return "Restores health at round end."
        case .shield:
            return "Absorbs direct damage across hits. Player guard expires at round end; Warriors retain up to 8."
        case .armour:
            return "Plate over health. Direct blows chip it first."
        case .champion:
            return "Carries its god's own power all fight."
        }
    }

    /// Exactly when it fires.
    var timing: String {
        switch self {
        case .burn, .poison, .regeneration:
            "Round end."
        case .bleed:
            "Just before the wearer attacks."
        case .judgement:
            "When a 3+ die attack combo releases it."
        case .weaken:
            "Next attack, then gone."
        case .mark:
            "Next attack on the wearer, then gone."
        case .evade:
            "Per incoming blow."
        case .shield, .armour:
            "On every direct blow."
        case .champion:
            "All fight."
        }
    }

    /// Whether a second application stacks or replaces.
    var stacking: String {
        switch self {
        case .bleed:
            "Strongest wins — never adds."
        case .burn:
            "Stacks up."
        case .poison:
            "Stacks up, and grows on its own."
        case .judgement:
            "Stacks until something releases it."
        case .weaken:
            "Strongest wins."
        case .mark:
            "One at a time."
        case .evade:
            "Each charge cancels one hit. Expires at round end."
        case .regeneration:
            "Strongest wins."
        case .shield:
            "Adds together. Player guard expires at round end; Warriors retain up to 8."
        case .armour:
            "Set when the creature rises."
        case .champion:
            "One per Trial."
        }
    }

    /// Does it get past a raised guard?
    var bypassesGuard: Bool {
        switch self {
        case .burn, .bleed, .poison, .judgement: true
        default: false
        }
    }

    /// Its ceiling, where it has one.
    var cap: String? {
        switch self {
        case .burn: "Max \(GameData.burnStackCap)."
        case .bleed: "Max \(GameData.bleedStackCap)."
        case .poison: "Max \(GameData.poisonStackCap)."
        case .judgement: "Max \(GameData.judgementCap) stored."
        case .weaken: "Max \(Int(GameData.weakenCeiling * 100))%."
        case .evade: "Up to 6 charges. Expires at round end."
        default: nil
        }
    }

    /// The one-line codex entry beneath the name.
    var codexLine: String {
        var parts: [String] = [timing]
        if bypassesGuard { parts.append("Ignores guard.") }
        if let cap { parts.append(cap) }
        return parts.joined(separator: " ")
    }
}

/// A status actually riding a fighter right now, with its live numbers — what
/// the tap-a-badge bubble reads out.
struct LiveStatus: Identifiable {
    let kind: StatusKind
    /// True when the wearer is the player, so the bubble can be written in the
    /// second person.
    let onSelf: Bool
    /// How much it takes (or gives) per tick, where that applies.
    let perTick: Int?
    /// Ticks left before it burns out.
    let ticksLeft: Int?
    /// A flat stored total, for Judgement and guard pools.
    let total: Int?
    /// A percentage reading, for Evade, Weaken and Mark.
    let percent: Int?
    /// Turns left before a stored effect fires — Judgement's fuse on the
    /// scales. Distinct from `ticksLeft`, which counts repeating bites.
    let turnsLeft: Int?

    var id: String { kind.rawValue + (onSelf ? ".self" : ".foe") }

    init(
        kind: StatusKind,
        onSelf: Bool,
        perTick: Int? = nil,
        ticksLeft: Int? = nil,
        total: Int? = nil,
        percent: Int? = nil,
        turnsLeft: Int? = nil
    ) {
        self.kind = kind
        self.onSelf = onSelf
        self.perTick = perTick
        self.ticksLeft = ticksLeft
        self.total = total
        self.percent = percent
        self.turnsLeft = turnsLeft
    }

    /// The badge's own short label: "6" for a stack, "40%" for a chance,
    /// "6×3" only where a status still counts rounds.
    var badgeText: String {
        if let perTick, let ticksLeft { return "\(perTick)×\(ticksLeft)" }
        if let perTick { return "\(perTick)" }
        if let percent { return "\(percent)%" }
        if let total, let turnsLeft { return "\(total)·\(turnsLeft)" }
        if let total { return "\(total)" }
        return kind.name.uppercased()
    }

    /// The live numbers, as lines the bubble prints under the description.
    var readout: [(label: String, value: String)] {
        var lines: [(String, String)] = []
        if let perTick, let ticksLeft {
            lines.append((kind == .regeneration ? "Restores" : "Takes", "\(perTick) per round"))
            lines.append(("Rounds left", "\(ticksLeft)"))
        } else if let perTick {
            switch kind {
            case .burn: lines.append(("Takes", "\(perTick), then halves"))
            case .poison: lines.append(("Takes", "\(perTick), then grows to \(min(GameData.poisonStackCap, perTick + 1))"))
            case .bleed: lines.append(("Takes", "\(perTick) on its next attack"))
            default: lines.append(("Takes", "\(perTick)"))
            }
        }
        if let total, perTick == nil {
            lines.append((kind == .judgement ? "Stored" : "Depth", "\(total)"))
        }
        // Judgement is the one status you can watch coming, so the bubble
        // spells out both the wait and what the pile is currently worth.
        if kind == .judgement, let total {
            let verdict = GameData.judgementVerdict(stored: total)
            let bonus = GameData.judgementBonus(stored: total)
            lines.append(("Releases for", bonus > 0 ? "\(verdict) (\(total) +\(bonus) heavy)" : "\(verdict)"))
            lines.append(("Released by", "Your 3+ die attack combo"))
        }
        if let percent {
            switch kind {
            case .evade: lines.append(("Legacy chance", "\(percent)%"))
            case .weaken: lines.append(("Next attack weaker by", "\(percent)%"))
            case .mark: lines.append(("Next attack harder by", "+\(percent)%"))
            default: lines.append(("Strength", "\(percent)%"))
            }
        }
        lines.append(("Next fires", kind.timing))
        lines.append(("Past guard", kind.bypassesGuard ? "Yes — guard does not stop it" : "No — guard eats it first"))
        if let cap = kind.cap { lines.append(("Ceiling", cap)) }
        return lines.map { (label: $0.0, value: $0.1) }
    }
}

