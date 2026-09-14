import SwiftUI

/// Which gear family a face naturally belongs to — used to filter offers and
/// to colour faces by their owning class.
enum FaceFamily: String, Hashable {
    case archer
    case warrior
    case rogue
    case magician
    case shared
    case item
    case divine
}

/// How a face behaves when it is played on its own (no combo).
enum SoloKind: Hashable {
    case damage
    case block
    case heal
    case evade
    case poison
    case stamina
    case focus
}

/// Every die face in the game. Class faces feed that class's combo list;
/// shared faces show up on armour and items across the roster. God content
/// never overwrites a face any more — it travels as `FaceMark`s (gifts) laid
/// on top of any face you own.
enum FaceKind: String, CaseIterable, Hashable {
    // Archer
    case arrow1
    case arrow2
    case arrow3
    case bowSmack

    // Warrior
    case overhead
    case sideSwing
    case parry
    case brace
    case taunt

    // Rogue
    case swiftSlash
    case daggerThrow

    // Magician
    case runeFire
    case runeFrost
    case runeLife
    case runeArcane
    case wandZap
    case ward
    case channel

    // Shared armour / utility
    case block
    case dodge
    case heal
    case roll
    case focus
    case energize

    // Item faces
    case bomb
    case smoke
    case poison
    case elixir

    // MARK: - Presentation

    var label: String {
        switch self {
        case .arrow1: return "Arrow I"
        case .arrow2: return "Arrow II"
        case .arrow3: return "Arrow III"
        case .bowSmack: return "Bow Smack"
        case .overhead: return "Overhead"
        case .sideSwing: return "Side Swing"
        case .parry: return "Parry"
        case .brace: return "Brace"
        case .taunt: return "Taunt"
        case .swiftSlash: return "Swift Slash"
        case .daggerThrow: return "Dagger Throw"
        case .runeFire: return "Fire Rune"
        case .runeFrost: return "Frost Rune"
        case .runeLife: return "Life Rune"
        case .runeArcane: return "Arcane Rune"
        case .wandZap: return "Wand Zap"
        case .ward: return "Ward"
        case .channel: return "Channel"
        case .block: return "Block"
        case .dodge: return "Dodge"
        case .heal: return "Heal"
        case .roll: return "Roll"
        case .focus: return "Focus"
        case .energize: return "Energize"
        case .bomb: return "Bomb"
        case .smoke: return "Smoke"
        case .poison: return "Poison"
        case .elixir: return "Elixir"
        default: return rawValue
        }
    }

    /// Compact label for tight chips in the tray and play bar.
    var shortLabel: String {
        switch self {
        case .arrow1: return "ARW I"
        case .arrow2: return "ARW II"
        case .arrow3: return "ARW III"
        case .bowSmack: return "SMACK"
        case .overhead: return "OVER"
        case .sideSwing: return "SIDE"
        case .swiftSlash: return "SLASH"
        case .daggerThrow: return "THROW"
        case .runeFire: return "FIRE"
        case .runeFrost: return "FROST"
        case .runeLife: return "LIFE"
        case .runeArcane: return "ARCANE"
        case .wandZap: return "ZAP"
        default: return label.uppercased()
        }
    }

    var symbol: String {
        switch self {
        case .arrow1: return "arrowtriangle.up"
        case .arrow2: return "arrowtriangle.up.fill"
        case .arrow3: return "arrowshape.up.circle.fill"
        case .bowSmack: return "figure.archery"
        case .overhead: return "arrow.down.circle.fill"
        case .sideSwing: return "arrow.left.and.right.circle.fill"
        case .parry: return "shield.lefthalf.filled"
        case .brace: return "shield.righthalf.filled"
        case .taunt: return "megaphone.fill"
        case .swiftSlash: return "bolt.fill"
        case .daggerThrow: return "paperplane.fill"
        case .runeFire: return "flame.fill"
        case .runeFrost: return "snowflake"
        case .runeLife: return "leaf.fill"
        case .runeArcane: return "hexagon.fill"
        case .wandZap: return "wand.and.stars"
        case .ward: return "circle.hexagongrid.fill"
        case .channel: return "sparkles"
        case .block: return "shield.fill"
        case .dodge: return "wind"
        case .heal: return "heart.fill"
        case .roll: return "figure.run"
        case .focus: return "eye.fill"
        case .energize: return "bolt.circle.fill"
        case .bomb: return "burst.fill"
        case .smoke: return "cloud.fog.fill"
        case .poison: return "drop.triangle.fill"
        case .elixir: return "cross.vial.fill"
        default: return "sparkle"
        }
    }

    var family: FaceFamily {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack: return .archer
        case .overhead, .sideSwing, .parry, .brace, .taunt: return .warrior
        case .swiftSlash, .daggerThrow: return .rogue
        case .runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .ward, .channel: return .magician
        case .bomb, .smoke, .poison, .elixir: return .item
        default: return .shared
        }
    }

    // MARK: - Numbers

    /// Damage for attacks, block for guards, healing for restoratives.
    var baseValue: Int {
        switch self {
        case .arrow1: return 7
        case .arrow2: return 12
        case .arrow3: return 19
        case .bowSmack: return 6
        case .overhead: return 12
        case .sideSwing: return 9
        case .parry: return 8
        case .brace: return 10
        case .taunt: return 6
        case .swiftSlash: return 7
        case .daggerThrow: return 11
        case .runeFire: return 4
        case .runeFrost: return 3
        case .runeLife: return 5
        case .runeArcane: return 4
        case .wandZap: return 8
        case .ward: return 9
        case .channel: return 0
        case .block: return 7
        case .dodge: return 0
        case .heal: return 8
        case .roll: return 4
        case .focus: return 0
        case .energize: return 0
        case .bomb: return 15
        case .smoke: return 0
        case .poison: return 3
        case .elixir: return 12
        default: return 0
        }
    }

    /// What this face is worth played on its own, after the chip-damage cut.
    /// A lone face is a last resort now — the chain is the fight.
    var soloValue: Int {
        guard baseValue > 0 else { return 0 }
        let scale = isAttack ? GameData.soloAttackScale : GameData.soloGuardScale
        return max(1, Int((Double(baseValue) * scale).rounded()))
    }

    /// Chance this face lands a critical the moment the die settles, before
    /// any imbues or charms are added.
    var baseCrit: Double {
        switch self {
        case .arrow3, .overhead, .daggerThrow: return 0.08
        case .arrow2, .swiftSlash, .runeArcane, .bomb: return 0.06
        default: return 0.05
        }
    }

    var isAttack: Bool {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack,
             .overhead, .sideSwing,
             .swiftSlash, .daggerThrow,
             .runeFire, .runeFrost, .runeArcane, .wandZap,
             .bomb:
            return true
        default:
            return false
        }
    }

    var isArrow: Bool {
        self == .arrow1 || self == .arrow2 || self == .arrow3
    }

    var isRune: Bool {
        self == .runeFire || self == .runeFrost || self == .runeLife || self == .runeArcane
    }

    var isSwing: Bool {
        self == .overhead || self == .sideSwing
    }

    var soloKind: SoloKind {
        if isAttack { return .damage }
        switch self {
        case .parry, .brace, .taunt, .ward, .block: return .block
        case .heal, .elixir, .runeLife: return .heal
        case .dodge, .smoke, .roll: return .evade
        case .poison: return .poison
        case .energize, .channel: return .stamina
        case .focus: return .focus
        default: return .block
        }
    }

    /// What playing this face on its own does — shown in the codex and tray.
    var soloEffect: String {
        switch self {
        case .runeFrost: return "Deal \(soloValue) damage and slow the next attack"
        case .bomb: return "Deal \(soloValue) damage and burn 4 for 2 turns"
        case .roll: return "Evade the next hit and gain \(soloValue) block"
        case .focus: return "+1 stamina next turn, next attack this turn +5"
        case .poison: return "Poison \(soloValue) for 2 turns"
        case .brace: return "Gain \(soloValue) block that carries into next turn"
        case .taunt: return "Gain \(soloValue) block and bait the enemy"
        default:
            switch soloKind {
            case .damage: return "Deal \(soloValue) damage"
            case .block: return "Gain \(soloValue) block"
            case .heal: return "Restore \(soloValue) health"
            case .evade: return "Evade the next hit"
            case .stamina: return "+1 stamina next turn"
            case .poison: return "Poison \(soloValue) for 2 turns"
            case .focus: return "+1 stamina next turn"
            }
        }
    }

    /// Short "what will this do" tag for the dice tray.
    var soloTag: String {
        switch soloKind {
        case .damage: return "\(soloValue) dmg"
        case .block: return "+\(soloValue) blk"
        case .heal: return "+\(soloValue) hp"
        case .evade: return "evade"
        case .poison: return "\(soloValue) psn"
        case .stamina: return "+1 stam"
        case .focus: return "focus"
        }
    }

    var tint: Color {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack: return Theme.ember
        case .overhead, .sideSwing, .parry, .brace: return Theme.steelBlue
        case .taunt: return Theme.gold
        case .swiftSlash, .daggerThrow: return Theme.venom
        case .runeFire: return Theme.ember
        case .runeFrost: return Theme.frost
        case .runeLife: return Theme.forest
        case .runeArcane, .ward, .channel, .wandZap: return Theme.arcane
        case .block: return Theme.steel
        case .dodge, .roll, .smoke: return Theme.steel
        case .heal, .elixir: return Theme.forest
        case .focus: return Theme.gold
        case .energize: return Theme.gold
        case .bomb: return Theme.blood
        case .poison: return Theme.venom
        default: return Theme.parchment
        }
    }
}
