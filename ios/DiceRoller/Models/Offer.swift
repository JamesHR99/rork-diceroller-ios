import SwiftUI

/// What an offer card hands over when taken.
enum OfferKind: Hashable {
    /// A whole new die for a permanent gear piece.
    case die(Die)
    /// Reforge one face of your choice into this kind.
    case reforge(FaceKind)
    /// Reroll every face the gods have not claimed on one die of your choice.
    case reforgeDie
    /// A god's named gift: lay it on one of your existing faces — starting
    /// fresh, deepening the same gift, or (rarely, `replace: true`) burning
    /// off whatever the face already carries and laying this gift instead.
    case gift(GiftDef, replace: Bool)
    /// A dual-god rite: bind the second god onto a face already carrying the
    /// first. The only way two gods ever share a face — and the only way a
    /// bound face fires its duo at full strength every play.
    case rite(Deity, Deity)
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

    /// The gift this card lays down, if it is one.
    var giftDef: GiftDef? {
        if case .gift(let gift, _) = kind { return gift }
        return nil
    }

    /// True when this gift card may burn an existing gift off a face.
    var isReplacingGift: Bool {
        if case .gift(_, let replace) = kind { return replace }
        return false
    }

    /// The partner god of a dual-god rite card, if it is one.
    var ritePartner: Deity? {
        if case .rite(_, let partner) = kind { return partner }
        return nil
    }

    var isRite: Bool {
        if case .rite = kind { return true }
        return false
    }
}
