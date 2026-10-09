import Foundation

/// Save only the live market payloads; boon definitions remain in the catalog.
struct MarketOfferSave: Codable {
    enum Payload: Codable {
        case heal(Int)
        case pathRerolls(Int)
        case reforge(FaceKind)
        case boon(String, BoonRarity)
    }
    let id: UUID
    let name: String
    let detail: String
    let symbol: String
    let rarity: Rarity
    let comboHint: String
    let price: Int
    let payload: Payload

    init?(_ offer: Offer) {
        switch offer.kind {
        case .heal(let amount): payload = .heal(amount)
        case .pathRerolls(let amount): payload = .pathRerolls(amount)
        case .reforge(let face): payload = .reforge(face)
        case .boon(let def, let rarity): payload = .boon(def.id, rarity)
        default: return nil
        }
        id = offer.id
        name = offer.name
        detail = offer.detail
        symbol = offer.symbol
        rarity = offer.rarity
        comboHint = offer.comboHint
        price = offer.price
    }

    var offer: Offer? {
        let kind: OfferKind
        var deity: Deity?
        switch payload {
        case .heal(let amount): kind = .heal(amount)
        case .pathRerolls(let amount): kind = .pathRerolls(amount)
        case .reforge(let face): kind = .reforge(face)
        case .boon(let id, let rarity):
            guard let def = GodCatalog.boon(id) else { return nil }
            kind = .boon(def, rarity)
            deity = def.god
        }
        return Offer(name: name, detail: detail, symbol: symbol, rarity: rarity,
            comboHint: comboHint, price: price, kind: kind, deity: deity, id: id)
    }
}

/// Targeting steps supported by the market and sealed omens.
enum EncounterSelectionSave: Codable {
    case reforge(FaceKind, String)
    case imbue(Double, String)
    case replaceBoon(String, BoonRarity)

    init?(_ selection: PendingSelection) {
        switch selection {
        case .reforge(let face, let title): self = .reforge(face, title)
        case .imbue(let amount, let title): self = .imbue(amount, title)
        case .replaceBoon(let def, let rarity): self = .replaceBoon(def.id, rarity)
        default: return nil
        }
    }

    var selection: PendingSelection? {
        switch self {
        case .reforge(let face, let title): return .reforge(face, title: title)
        case .imbue(let amount, let title): return .imbue(amount, title: title)
        case .replaceBoon(let id, let rarity):
            guard let def = GodCatalog.boon(id) else { return nil }
            return .replaceBoon(def, rarity: rarity)
        }
    }
}

struct EncounterSave: Codable {
    let nodeID: UUID
    let shopStock: [MarketOfferSave]
    let pendingPurchase: MarketOfferSave?
    let event: RunEvent?
    let outcome: String?
    let selection: EncounterSelectionSave?
}
