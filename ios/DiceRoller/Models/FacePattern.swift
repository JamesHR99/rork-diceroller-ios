import SwiftUI

/// One slot type in a combo recipe. Most slots demand an exact face, but some
/// accept a family — "any arrow", "any rune", "any swing", "any strike".
/// Recipes ask for ingredients and quantities, never a tap order.
enum FacePattern: Hashable {
    case exact(FaceKind)
    case anyArrow
    case anyRune
    case anySwing
    case anyStrike

    func matches(_ face: FaceKind) -> Bool {
        switch self {
        case .exact(let kind): face == kind
        case .anyArrow: face.isArrow
        case .anyRune: face.isRune
        case .anySwing: face.isSwing
        case .anyStrike: face.isAttack
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
        }
    }

    var symbol: String { iconFace.symbol }

    var tint: Color { iconFace.tint }

    var label: String {
        switch self {
        case .exact(let kind): kind.label
        case .anyArrow: "Any Arrow"
        case .anyRune: "Any Rune"
        case .anySwing: "Any Swing"
        case .anyStrike: "Any Strike"
        }
    }

    /// Wildcard slots are drawn with a dashed border in the codex.
    var isWildcard: Bool { !isExact }
}
