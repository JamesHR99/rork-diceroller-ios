import Foundation

/// One of the six faces on a die. Faces carry their own crit chance, which
/// imbues raise permanently.
struct DieFace: Identifiable, Hashable {
    let id: UUID
    var kind: FaceKind
    /// How many imbues have been etched into this face (gold notches).
    var imbueTiers: Int
    /// Extra crit chance from imbues, on top of the face kind's base.
    var bonusCrit: Double
    /// A god's claim laid on top of this face. The face keeps its kind and
    /// every combo it feeds; the mark adds the god's answer on top.
    var mark: FaceMark?

    /// Hard ceiling so a single face can never become a guaranteed crit.
    static let critCap = 0.75

    init(_ kind: FaceKind, imbueTiers: Int = 0, bonusCrit: Double = 0, mark: FaceMark? = nil, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.imbueTiers = imbueTiers
        self.bonusCrit = bonusCrit
        self.mark = mark
    }

    var critChance: Double {
        min(DieFace.critCap, kind.baseCrit + bonusCrit)
    }

    var isImbued: Bool { imbueTiers > 0 }

    var isMarked: Bool { mark != nil }

    /// A copy of this face reforged into a different kind, keeping imbues.
    /// Reforging washes any god's mark away — a new face is a new claim.
    func reforged(to newKind: FaceKind) -> DieFace {
        DieFace(newKind, imbueTiers: imbueTiers, bonusCrit: bonusCrit, mark: nil, id: id)
    }

    /// A copy of this face with one more imbue tier etched in.
    func imbued(by amount: Double) -> DieFace {
        DieFace(kind, imbueTiers: imbueTiers + 1, bonusCrit: min(DieFace.critCap, bonusCrit + amount), mark: mark, id: id)
    }

    /// The god lays their first touch on this face, carrying a specific gift.
    func marked(by gift: GiftDef) -> DieFace {
        DieFace(kind, imbueTiers: imbueTiers, bonusCrit: bonusCrit, mark: FaceMark(gift: gift), id: id)
    }

    /// An existing mark runs one depth deeper (capped at the final form).
    func deepenedMark() -> DieFace {
        guard var existing = mark else { return self }
        existing.depth = existing.depth.next ?? .finalForm
        return DieFace(kind, imbueTiers: imbueTiers, bonusCrit: bonusCrit, mark: existing, id: id)
    }

    /// A dual-god rite binds a second god into this face.
    func bound(to rite: Deity) -> DieFace {
        guard var existing = mark else { return self }
        existing.rite = rite
        return DieFace(kind, imbueTiers: imbueTiers, bonusCrit: bonusCrit, mark: existing, id: id)
    }

    /// The name shown for this face in tray and lists — the earned final-form
    /// title when the mark has run its full course.
    var displayName: String { mark?.title(for: kind) ?? kind.label }
}
