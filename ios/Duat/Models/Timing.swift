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

/// The agility clock. Stamina says how much you can do in a round; agility says
/// *when* each action lands.
///
/// One rule, everywhere: an action's agility is its size in dice — one die
/// counts 1, a two-die chain 2, a three-die chain 3 — added to the actor's base
/// agility. Lower totals act first, and on a tie the player goes before any
/// creature. Nothing else is tuned per recipe: a bigger action is a slower one,
/// and that is the whole of it.
enum Timing {
    /// The most Haste a single action may claim.
    static let maxHastePerAction = 2

    /// The most a player may push one enemy's pending action back, per round.
    static let maxDelayPerEnemy = 2

    /// What an action of this many dice costs the actor on the clock. Never
    /// less than one beat — Haste pulls an action earlier, it never makes an
    /// action free.
    static func cost(size: Int, agility: Int, haste: Int = 0) -> Int {
        let hasted = min(max(haste, 0), maxHastePerAction)
        return max(1, max(agility, 0) + max(size, 1) - hasted)
    }

    /// Recipes that hand the next action a beat of Haste when they resolve.
    static let hasteGranting: Set<String> = ["rog_shadowstep"]

    /// Recipes that push one pending enemy action a beat later, once a round.
    static let delayGranting: Set<String> = ["mag_iceBlast", "mag_glacier", "war_earthshaker"]

    // MARK: - Enemy timing

    /// Base agility per creature, read the same way as the player's: lower is
    /// quicker. A jackal is off the mark before anything else in the river; a
    /// colossus takes its time whatever it is doing.
    private static let enemyAgility: [String: Int] = [
        "trainingDummy": 5,
        "reedLurker": 2, "marshShade": 2, "sandCrawler": 2, "siltColossus": 4,
        "emberWraith": 2, "flamekeeper": 3, "ashJackal": 1, "bronzeEffigy": 4,
        "devourerSpawn": 3, "uncreatedShadow": 1, "hourEater": 3, "boneplateDevourer": 4,
        "sekhen": 3, "nehebkau": 3, "apep": 2,
    ]

    static func agility(enemy id: String) -> Int {
        enemyAgility[id] ?? 3
    }

    /// A creature's move counts its faces the same way your chains do, and a
    /// wind-up counts as the heavy thing it is — so a charged blow is visible
    /// on the strip well before it arrives.
    static func size(move: EnemyMove) -> Int {
        max(move.charge > 0 ? 2 : 1, move.faces.count)
    }

    /// Agility a creature borrows for the first round when it catches you
    /// stepping off the barque — the guide's opening surprise. Taken *off* its
    /// total, because lower acts first.
    static let surpriseAgilityBonus = 2
    static let surpriseChance = 0.18
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
    /// This action's own agility — its size in dice plus the actor's base,
    /// after any Haste.
    let duration: Int
    let title: String
    /// What it will do, in the same words the plan card uses.
    let detail: String
    /// Which foe it is pointed at (player actions), for the fallback order.
    let targetID: UUID?
    let roles: ActionRole
    /// The plan step or enemy this entry was built from.
    let sourceID: UUID
    /// Set when Haste pulled this action earlier than its printed agility.
    let hastened: Int
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
        hastened: Int = 0,
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
        self.hastened = hastened
        self.chainIndex = chainIndex
    }

    var isPlayer: Bool { side.isPlayer }
}

/// Builds and orders the shared clock. Everything on it is deterministic once
/// the roll and the plan are known, which is what makes the preview honest.
enum TimelineBuilder {
    /// Orders a round's entries: earliest beat first, and on a tie the player
    /// resolves before any enemy. Enemy ties keep the order they rose in, so
    /// the strip always reads the way the fight will actually play.
    static func ordered(_ entries: [TimelineEntry], foeOrder: [UUID]) -> [TimelineEntry] {
        entries.enumerated().sorted { lhs, rhs in
            if lhs.element.beat != rhs.element.beat { return lhs.element.beat < rhs.element.beat }
            if lhs.element.isPlayer != rhs.element.isPlayer { return lhs.element.isPlayer }
            let lhsRank = rank(of: lhs.element, in: foeOrder)
            let rhsRank = rank(of: rhs.element, in: foeOrder)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private static func rank(of entry: TimelineEntry, in foeOrder: [UUID]) -> Int {
        guard case .foe(let id) = entry.side else { return -1 }
        return foeOrder.firstIndex(of: id) ?? foeOrder.count
    }
}
