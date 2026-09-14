import Foundation

/// How deep one god's gift runs on a single face. The first two depths scale
/// the same gift up; the third is a named final form with a flourish on top.
enum MarkDepth: Int, CaseIterable, Hashable {
    case touched = 1
    case deepened = 2
    case finalForm = 3

    var label: String {
        switch self {
        case .touched: "Touched"
        case .deepened: "Deepened"
        case .finalForm: "Final Form"
        }
    }

    var next: MarkDepth? {
        MarkDepth(rawValue: rawValue + 1)
    }
}

/// What kind of face a gift landed on. A god reads the face it is given and
/// answers in kind — the same god is a different gift on a sword, a shield,
/// or a healing draught.
enum MarkRole: String, Hashable, CaseIterable {
    case attack
    case defend
    case support

    static func role(for kind: FaceKind) -> MarkRole {
        switch kind.soloKind {
        case .damage: .attack
        case .block, .evade: .defend
        case .heal, .poison, .stamina, .focus: .support
        }
    }

    var label: String {
        switch self {
        case .attack: "Attacks"
        case .defend: "Guards"
        case .support: "Mends & support"
        }
    }
}

/// A god's claim on one die face. The face keeps its kind, its numbers and
/// every chain it fed before; the gift adds the god's answer on top and
/// deepens each time the same gift is chosen again. Only a dual-god rite ever
/// adds a second god — and a bound face fires that pair's duo every play.
struct FaceMark: Hashable {
    var deity: Deity
    /// Which of the god's twelve gifts is laid on this face.
    var giftID: String
    var depth: MarkDepth = .touched
    /// Second god bound into the same face by a dual-god rite.
    var rite: Deity?

    init(deity: Deity, giftID: String, depth: MarkDepth = .touched, rite: Deity? = nil) {
        self.deity = deity
        self.giftID = giftID
        self.depth = depth
        self.rite = rite
    }

    /// Convenience: a fresh mark carrying a specific gift.
    init(gift: GiftDef, depth: MarkDepth = .touched) {
        self.deity = gift.deity
        self.giftID = gift.id
        self.depth = depth
        self.rite = nil
    }

    var gift: GiftDef? { GiftContent.gift(id: giftID) }

    var isFinalForm: Bool { depth == .finalForm }

    /// Every god this face speaks for — the gift's god, plus a rite partner.
    var gods: [Deity] {
        if let rite { [deity, rite] }
        else { [deity] }
    }

    /// The earned title a face shows once its gift reaches the final form.
    func title(for kind: FaceKind) -> String? {
        guard isFinalForm else { return nil }
        return gift?.finalFormName
    }

    /// Devotion weight this mark gives a god: the gift's god counts the full
    /// depth, a rite partner counts as a single touch.
    func devotionValue(for god: Deity) -> Int {
        if god == deity { return depth.rawValue }
        if god == rite { return 1 }
        return 0
    }
}
