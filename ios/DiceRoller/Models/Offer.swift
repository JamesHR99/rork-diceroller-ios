import SwiftUI

/// What an offer card hands over when taken.
enum OfferKind: Hashable {
    /// A whole new die for a permanent gear piece.
    case die(Die)
    /// Reforge one face of your choice into this kind.
    case reforge(FaceKind)
    /// Reroll every face on one die of your choice.
    case reforgeDie
    /// A god's power, offered at a rolled rarity and shown before you pick it.
    /// Taking it equips the card into its own slot.
    case boon(GodBoonDef, BoonRarity)
    /// A level on a power you already carry: same slot, same rarity, one step
    /// stronger. Never a second copy.
    case boonLevel(EquippedBoon)
    /// A legendary, found the same way as any other boon and kept in its own
    /// Legendary slot. Carries the rarity it was offered at, unless the power
    /// it evolved from is equipped and hands its own across.
    case legendary(GodBoonDef, BoonRarity)
    /// A god claims one of your dice as its patron — an unblessed die, or
    /// (rarely, `replace: true`) explicitly taking a die from another god.
    case patron(Deity, replace: Bool)
    /// A god's upgrade: earned once, needs a blessed die of that god.
    case upgrade(GodUpgrade)
    /// A god's capstone: one per run, needs two upgrades of that god.
    case capstone(GodCapstone)
    /// A pairing: two gods standing together, one per run.
    case pairing(PairingDef)
    /// Permanently raise one chosen face's crit chance.
    case imbue(Double)
    /// Immediate healing.
    case heal(Int)
    /// Permanent max health.
    case maxHP(Int)
    /// Pure gold, from events.
    case gold(Int)
    /// One of Ptah's Chisels, offered directly the way a god offers a boon:
    /// three laid out, one taken.
    case chiselPick(ChiselDef)
}

/// One card on a shop shelf, loot screen, or event outcome.
struct Offer: Identifiable, Hashable {
    let id: UUID
    let name: String
    let detail: String
    let symbol: String
    let rarity: Rarity
    /// Which combo this offer feeds, shown on the card.
    let comboHint: String
    let price: Int
    let kind: OfferKind
    /// Set when the card is a god's favour, so it can be gilded in their colour.
    let deity: Deity?

    init(
        name: String,
        detail: String,
        symbol: String,
        rarity: Rarity,
        comboHint: String,
        price: Int,
        kind: OfferKind,
        deity: Deity? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.symbol = symbol
        self.rarity = rarity
        self.comboHint = comboHint
        self.price = price
        self.kind = kind
        self.deity = deity
    }

    var isFree: Bool { price <= 0 }

    /// The boon rarity this card carries, shown on the card before choosing.
    var boonRarity: BoonRarity? {
        switch kind {
        case .boon(_, let rarity): rarity
        case .boonLevel(let owned): owned.rarity
        case .legendary(_, let rarity): rarity
        default: nil
        }
    }

    /// Level before and after, for a card that is explicitly an upgrade.
    var levelStep: (from: Int, to: Int)? {
        guard case .boonLevel(let owned) = kind else { return nil }
        return (owned.level, min(owned.level + 1, boonMaxLevel))
    }

    /// Blessings glow in their god's colour, Ptah's Chisel in his hammered
    /// copper; everything else uses its rarity.
    var tint: Color {
        if case .chiselPick = kind { return Theme.copper }
        return deity?.tint ?? rarity.tint
    }

    /// True when a patron card may take a die from another god.
    var isReplacingPatron: Bool {
        if case .patron(_, let replace) = kind { return replace }
        return false
    }
}
