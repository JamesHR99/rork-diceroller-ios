import SwiftUI

/// Every status a fighter can wear, defined once. The fight reads these for
/// its tap-a-badge bubbles and the codex reads them for its glossary, so a
/// status can never be explained two different ways.
enum StatusKind: String, CaseIterable, Identifiable {
    case burn
    case bleed
    case poison
    case judgement
    case stagger
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
        case .stagger: "Stagger"
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
        case .stagger: PharaohSWagerArt.Status.frost
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
        case .stagger: "snowflake"
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
        case .stagger: Theme.frost
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

    /// What it does, in one plain sentence, written from the point of view of
    /// whoever is wearing it.
    func summary(onSelf: Bool) -> String {
        let you = onSelf ? "you" : "it"
        let your = onSelf ? "your" : "its"
        switch self {
        case .burn:
            return "Fire eating away at \(you). It bites once at the end of every round and ignores guard entirely."
        case .bleed:
            return "An open wound. It bites once at the end of every round and ignores guard entirely."
        case .poison:
            return "Venom in the blood. It bites once at the end of every round and ignores guard entirely."
        case .judgement:
            return "Stored damage waiting on the scales. It falls against \(your) health all at once at the end of \(your) turn, and guard does not stop it."
        case .stagger:
            return "A blow that landed badly. \(onSelf ? "Your" : "Its") very next attack lands weaker, and then the effect is spent."
        case .mark:
            return "A marked target. The next hit that lands on \(you) is multiplied, then the mark is gone."
        case .evade:
            return "Footwork. Every single blow aimed at \(you) is rolled against this chance separately — a success means the blow misses completely."
        case .regeneration:
            return "Mending. It restores health once at the end of every round."
        case .shield:
            return "A raised guard. Direct blows eat through this before they touch health, and it is not spent by burn, bleed or poison."
        case .armour:
            return "Bronze plate worn over health. Direct blows chip through the plate first; once it is gone the health underneath is bare."
        case .champion:
            return "A god's chosen. This creature carries that god's own power for the whole fight — the encounter is otherwise ordinary."
        }
    }

    /// Exactly when it fires.
    var timing: String {
        switch self {
        case .burn, .bleed, .poison, .regeneration:
            "End of every round, one tick at a time."
        case .judgement:
            "All at once, at the end of the wearer's turn."
        case .stagger:
            "On the very next attack, then gone."
        case .mark:
            "On the next hit that lands, then gone."
        case .evade:
            "Rolled separately for every incoming blow."
        case .shield, .armour:
            "Whenever a direct blow arrives."
        case .champion:
            "For the whole fight."
        }
    }

    /// Whether a second application stacks or replaces.
    var stacking: String {
        switch self {
        case .bleed:
            "Refreshes rather than stacks — a new wound takes the stronger value and the longer count, it does not add to the old one."
        case .burn, .poison:
            "A fresh application takes whichever value and duration is stronger."
        case .judgement:
            "Stacks up, and keeps stacking until it falls."
        case .stagger:
            "Only the strongest stagger on the target counts."
        case .mark:
            "Only one mark at a time."
        case .evade:
            "Several sources add together, up to the ceiling."
        case .regeneration:
            "A fresh mend takes the stronger value."
        case .shield:
            "Adds up freely — every guard face deepens the same pool."
        case .armour:
            "Set when the creature rises; nothing deepens it mid-fight."
        case .champion:
            "One champion per Trial."
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
        case .burn: "Never more than \(GameData.burnTickCap) a tick."
        case .judgement: "Never more than \(GameData.judgementCap) stored."
        case .evade: "Never higher than \(Int(GameData.evadeCeiling * 100))% — nothing makes you untouchable."
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
    /// A percentage reading, for Evade, Stagger and Mark.
    let percent: Int?

    var id: String { kind.rawValue + (onSelf ? ".self" : ".foe") }

    init(
        kind: StatusKind,
        onSelf: Bool,
        perTick: Int? = nil,
        ticksLeft: Int? = nil,
        total: Int? = nil,
        percent: Int? = nil
    ) {
        self.kind = kind
        self.onSelf = onSelf
        self.perTick = perTick
        self.ticksLeft = ticksLeft
        self.total = total
        self.percent = percent
    }

    /// The badge's own short label, e.g. "6×3" or "40%".
    var badgeText: String {
        if let perTick, let ticksLeft { return "\(perTick)×\(ticksLeft)" }
        if let percent { return "\(percent)%" }
        if let total { return "\(total)" }
        return kind.name.uppercased()
    }

    /// The live numbers, as lines the bubble prints under the description.
    var readout: [(label: String, value: String)] {
        var lines: [(String, String)] = []
        if let perTick, let ticksLeft {
            lines.append((kind == .regeneration ? "Restores" : "Takes", "\(perTick) per round"))
            lines.append(("Rounds left", "\(ticksLeft)"))
            let owed = perTick * ticksLeft
            lines.append((kind == .regeneration ? "Left to restore" : "Total still owed", "\(owed)"))
        }
        if let total, perTick == nil {
            lines.append((kind == .judgement ? "Stored" : "Depth", "\(total)"))
        }
        if let percent {
            switch kind {
            case .evade: lines.append(("Chance per blow", "\(percent)%"))
            case .stagger: lines.append(("Next attack weakened by", "\(percent)%"))
            case .mark: lines.append(("Next hit multiplied by", "\(percent)%"))
            default: lines.append(("Strength", "\(percent)%"))
            }
        }
        lines.append(("Next fires", kind.timing))
        lines.append(("Past guard", kind.bypassesGuard ? "Yes — guard does not stop it" : "No — guard eats it first"))
        if let cap = kind.cap { lines.append(("Ceiling", cap)) }
        return lines.map { (label: $0.0, value: $0.1) }
    }
}
