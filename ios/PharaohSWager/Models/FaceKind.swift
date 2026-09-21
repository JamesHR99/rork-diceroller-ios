import SwiftUI

/// Which gear family a face naturally belongs to — used to filter offers and
/// to colour faces by their owning class.
enum FaceFamily: String, Hashable {
    case archer
    case warrior
    case rogue
    case magician
    case shared
    case divine
}

/// How a face behaves when it is played on its own (no combo).
enum SoloKind: Hashable {
    case damage
    case block
    case evade
    case heal
    case poison
    case focus
}

/// Every die face in the game. The old defensive families have collapsed into
/// single meanings: every guard face is Block, every escape face is Evade,
/// every restorative is Heal. A face means the same thing wherever it appears
/// — weapon or armour.
enum FaceKind: String, CaseIterable, Hashable, Codable {
    // Archer
    case arrow1
    case arrow2
    case arrow3
    case bowSmack

    // Warrior
    case overhead
    case sideSwing

    // Rogue
    case swiftSlash
    case daggerThrow
    /// Venom on the blades: the Rogue's own armour-die face, and the mark
    /// three of the river's creatures attack with.
    case poison

    // Magician
    case runeFire
    case runeFrost
    case runeLife
    case runeArcane
    case wandZap
    case channel

    // Shared armour / utility
    case block
    case evade
    case heal
    case focus
    case energize

    // MARK: - Presentation

    var label: String {
        switch self {
        case .arrow1: return "Arrow I"
        case .arrow2: return "Arrow II"
        case .arrow3: return "Arrow III"
        case .bowSmack: return "Bow Smack"
        case .overhead: return "Overhead"
        case .sideSwing: return "Side Swing"
        case .swiftSlash: return "Swift Slash"
        case .daggerThrow: return "Dagger Throw"
        case .runeFire: return "Fire Rune"
        case .runeFrost: return "Frost Rune"
        case .runeLife: return "Life Rune"
        case .runeArcane: return "Arcane Rune"
        case .wandZap: return "Wand Zap"
        case .channel: return "Channel"
        case .block: return "Block"
        case .evade: return "Evade"
        case .heal: return "Heal"
        case .focus: return "Focus"
        case .energize: return "Energize"
        case .poison: return "Poison"
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
        case .swiftSlash: return "bolt.fill"
        case .daggerThrow: return "paperplane.fill"
        case .runeFire: return "flame.fill"
        case .runeFrost: return "snowflake"
        case .runeLife: return "leaf.fill"
        case .runeArcane: return "hexagon.fill"
        case .wandZap: return "wand.and.stars"
        case .channel: return "sparkles"
        case .block: return "shield.fill"
        case .evade: return "wind"
        case .heal: return "heart.fill"
        case .focus: return "eye.fill"
        case .energize: return "bolt.circle.fill"
        case .poison: return "drop.triangle.fill"
        }
    }

    var family: FaceFamily {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack: return .archer
        case .overhead, .sideSwing: return .warrior
        case .swiftSlash, .daggerThrow, .poison: return .rogue
        case .runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .channel: return .magician
        default: return .shared
        }
    }

    // MARK: - Numbers

    /// Damage for attacks, shield for guards, healing for restoratives.
    var baseValue: Int {
        switch self {
        case .arrow1: return 7
        case .arrow2: return 12
        case .arrow3: return 19
        case .bowSmack: return 6
        case .overhead: return 12
        case .sideSwing: return 9
        case .swiftSlash: return 7
        case .daggerThrow: return 11
        case .runeFire: return 4
        case .runeFrost: return 3
        case .runeLife: return 6
        case .runeArcane: return 4
        case .wandZap: return 8
        case .channel: return 0
        case .block: return BattleRules.blockValue
        case .evade: return 0
        case .heal: return 10
        case .focus: return 0
        case .energize: return 0
        case .poison: return 3
        }
    }

    /// What this face is worth played on its own, after the solo cut. A lone
    /// face is workable now — the chain is still the fight.
    var soloValue: Int {
        guard let action = SameFaceCatalog.action(self, count: 1) else { return 0 }
        return [action.damage, action.heal, action.shield, action.poisonAmount].max() ?? 0
    }

    /// Chance this face lands a critical the moment the die settles, before
    /// any imbues are added.
    var baseCrit: Double { 0.10 }

    var isAttack: Bool {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack,
             .overhead, .sideSwing,
             .swiftSlash, .daggerThrow,
             .runeFire, .runeFrost, .runeArcane, .wandZap:
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
        case .block: return .block
        case .evade: return .evade
        case .heal, .runeLife: return .heal
        case .poison: return .poison
        case .energize, .channel: return .focus
        case .focus: return .focus
        default: return .block
        }
    }

    /// What playing this face on its own does — shown in the codex and tray.
    var soloEffect: String { SameFaceCatalog.action(self, count: 1)?.effectSummary ?? "" }

    /// Short "what will this do" tag for the dice tray.
    var soloTag: String {
        switch soloKind {
        case .damage: return "\(soloValue) dmg"
        case .block: return "+\(soloValue) shield"
        case .heal: return "+\(soloValue) hp"
        case .evade: return "Evade 50%"
        case .poison: return "\(soloValue) psn"

        case .focus: return "+50% next hit"
        }
    }

    var tint: Color {
        switch self {
        case .arrow1, .arrow2, .arrow3, .bowSmack: return Theme.ember
        case .overhead, .sideSwing: return Theme.steelBlue
        case .swiftSlash, .daggerThrow: return Theme.venom
        case .runeFire: return Theme.ember
        case .runeFrost: return Theme.frost
        case .runeLife: return Theme.forest
        case .runeArcane, .channel, .wandZap: return Theme.arcane
        case .block: return Theme.steel
        case .evade: return Theme.steel
        case .heal: return Theme.forest
        case .focus: return Theme.gold
        case .energize: return Theme.gold
        case .poison: return Theme.venom
        }
    }
}


