import Foundation

/// What an action *does*, which decides which boons answer it. Roles overlap:
/// Warlord's Answer is an Attack and a Guard at once, and a Chill Ward is a
/// Guard that heals. Every role test in the catalogue reads this set.
struct ActionRole: OptionSet, Hashable {
    let rawValue: Int

    static let attack = ActionRole(rawValue: 1 << 0)
    static let guardian = ActionRole(rawValue: 1 << 1)
    static let evade = ActionRole(rawValue: 1 << 2)
    static let support = ActionRole(rawValue: 1 << 3)

    nonisolated static let none: ActionRole = []
}

/// Effects that postpone a pending foe action behind one player action.
enum Timing {
    static let maxDelayPerEnemy = 2
    static let delayGranting: Set<String> = ["mag_iceBlast", "mag_glacier", "war_earthshaker"]
}

/// Who owns a beat on the shared clock.
enum TimelineSide: Hashable {
    case player
    case foe(UUID)

    var isPlayer: Bool { self == .player }
}

/// One scheduled action on the shared clock — a planned step of yours or an
/// enemy's telegraphed intent. The timeline is planning information: it is
/// built while you arrange the turn and resolved in exactly this order.
struct TimelineEntry: Identifiable, Hashable {
    let id: UUID
    let side: TimelineSide
    /// The beat this action lands on, counting from the start of the round.
    let beat: Int
    /// One exchange for every action, independent of ingredient count.
    let duration: Int
    let title: String
    /// What it will do, in the same words the plan card uses.
    let detail: String
    /// Which foe it is pointed at (player actions), for the fallback order.
    let targetID: UUID?
    let roles: ActionRole
    /// The plan step or enemy this entry was built from.
    let sourceID: UUID

    /// Which of the creature's telegraphed moves this entry is — a foe that
    /// spends its round on three actions puts three entries on the clock.
    let chainIndex: Int

    init(
        id: UUID = UUID(),
        side: TimelineSide,
        beat: Int,
        duration: Int,
        title: String,
        detail: String,
        targetID: UUID? = nil,
        roles: ActionRole = .none,
        sourceID: UUID,
        chainIndex: Int = 0
    ) {
        self.id = id
        self.side = side
        self.beat = beat
        self.duration = duration
        self.title = title
        self.detail = detail
        self.targetID = targetID
        self.roles = roles
        self.sourceID = sourceID
        self.chainIndex = chainIndex
    }

    var isPlayer: Bool { side.isPlayer }
}

