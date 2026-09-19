import Foundation

/// One of the six faces on a die. Faces carry their own crit chance, which
/// imbues raise permanently. A patron god may claim the die these faces sit
/// on — the faces never change, the god simply answers what you play.
struct DieFace: Identifiable, Hashable, Codable {
    let id: UUID
    var kind: FaceKind
    /// How many imbues have been etched into this face (gold notches).
    var imbueTiers: Int
    /// Extra crit chance from imbues, on top of the face kind's base.
    var bonusCrit: Double

    /// Hard ceiling so a single face can never become a guaranteed crit.
    static let critCap = 0.40

    init(_ kind: FaceKind, imbueTiers: Int = 0, bonusCrit: Double = 0, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.imbueTiers = imbueTiers
        self.bonusCrit = bonusCrit
    }

    var critChance: Double {
        min(DieFace.critCap, kind.baseCrit + bonusCrit)
    }

    var isImbued: Bool { imbueTiers > 0 }

    /// A copy of this face reforged into a different kind, keeping imbues.
    func reforged(to newKind: FaceKind) -> DieFace {
        DieFace(newKind, imbueTiers: imbueTiers, bonusCrit: bonusCrit, id: id)
    }

    /// A copy of this face with one more imbue tier etched in.
    func imbued(by amount: Double) -> DieFace {
        DieFace(kind, imbueTiers: imbueTiers + 1, bonusCrit: min(DieFace.critCap, bonusCrit + amount), id: id)
    }
}

