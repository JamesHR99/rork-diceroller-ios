import SwiftUI

/// One slot in a combo recipe. Most slots demand an exact face, but some
/// accept a family — "any arrow", "any rune", "any swing", "any strike" — or
/// a god's favour: "any face carrying this god's gift", "a face carrying this
/// exact gift", or "any gifted face at all".
enum FacePattern: Hashable {
    case exact(FaceKind)
    case anyArrow
    case anyRune
    case anySwing
    case anyStrike
    /// Any face carrying that god's gift — as its own gift or as a rite partner.
    case deity(Deity)
    /// A face carrying one specific named gift.
    case gift(String)
    /// Any gifted face at all.
    case anyDivine

    func matches(_ face: FaceKind) -> Bool {
        matches(face, mark: nil)
    }

    /// Gifts let ordinary faces satisfy divine slots: a Ra-gifted arrow counts
    /// as "any Ra-gifted face", and any gifted face counts as "any gift".
    /// Exact and family slots still read the face's own kind — a gifted arrow
    /// stays an arrow.
    func matches(_ face: FaceKind, mark: FaceMark?) -> Bool {
        switch self {
        case .exact(let kind): face == kind
        case .anyArrow: face.isArrow
        case .anyRune: face.isRune
        case .anySwing: face.isSwing
        case .anyStrike: face.isAttack
        case .deity(let owner): mark?.deity == owner || mark?.rite == owner
        case .gift(let id): mark?.giftID == id
        case .anyDivine: mark != nil
        }
    }

    var isExact: Bool {
        if case .exact = self { return true }
        return false
    }

    /// Representative face used to draw this slot's icon in the codex.
    var iconFace: FaceKind {
        switch self {
        case .exact(let kind): kind
        case .anyArrow: .arrow2
        case .anyRune: .runeArcane
        case .anySwing: .overhead
        case .anyStrike: .swiftSlash
        case .deity, .gift, .anyDivine: .block
        }
    }

    /// Icon drawn in a recipe row — gods show their own sigil rather than a face.
    var symbol: String {
        switch self {
        case .deity(let owner): owner.symbol
        case .gift(let id): GiftContent.gift(id: id)?.symbol ?? ownerSymbolFallback
        case .anyDivine: "sparkles"
        default: iconFace.symbol
        }
    }

    private var ownerSymbolFallback: String {
        if case .gift(let id) = self,
           let gift = GiftContent.gift(id: id) {
            return gift.deity.symbol
        }
        return "sparkles"
    }

    var tint: Color {
        switch self {
        case .deity(let owner): owner.tint
        case .gift(let id): GiftContent.gift(id: id)?.deity.tint ?? Theme.gold
        case .anyDivine: Theme.gold
        default: iconFace.tint
        }
    }

    var label: String {
        switch self {
        case .exact(let kind): kind.label
        case .anyArrow: "Any Arrow"
        case .anyRune: "Any Rune"
        case .anySwing: "Any Swing"
        case .anyStrike: "Any Strike"
        case .deity(let owner): "Any \(owner.name) Gift"
        case .gift(let id): GiftContent.gift(id: id)?.name ?? "A Gift"
        case .anyDivine: "Any Gifted Face"
        }
    }

    /// Wildcard slots are drawn with a dashed border in the codex.
    var isWildcard: Bool { !isExact }

    /// Slots that demand a god's favour, drawn in that god's colour.
    var isDivineSlot: Bool {
        switch self {
        case .deity, .gift, .anyDivine: true
        default: false
        }
    }
}
