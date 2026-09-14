import SwiftUI

/// What an offer card hands over when taken.
enum OfferKind: Hashable {
    /// A whole new die for a permanent gear piece.
    case die(Die)
    /// Reforge one face of your choice into this kind.
    case reforge(FaceKind)
    /// Reroll every face on one die of your choice.
    case reforgeDie
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
    /// A carryable item (replaces the one you hold).
    case item(ItemDef)
    /// Immediate healing.
    case heal(Int)
    /// Permanent max health.
    case maxHP(Int)
    /// Pure gold, from events.
    case gold(Int)
    /// A named relic: fills the item slot with its three dice.
    case relic(RelicDef)
    /// A Breath of Ra: permanently raise the turn capacity by this much.
    case breath(Int)
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

    /// Blessings glow in their god's colour; everything else uses its rarity.
    var tint: Color { deity?.tint ?? rarity.tint }

    /// True when a patron card may take a die from another god.
    var isReplacingPatron: Bool {
        if case .patron(_, let replace) = kind { return replace }
        return false
    }
}
