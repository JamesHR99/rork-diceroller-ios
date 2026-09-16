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

/// The preparation clock. Stamina says how much you can do in a round; agility
/// and preparation say *when* each action lands. They are deliberately separate
/// systems — a cheap action can be slow and an expensive one can be quick.
enum Timing {
    /// Preparation before agility, for actions with no authored override.
    /// Read from the rework guide's default table.
    static let soloGuardPrep = 3
    static let quickAttackPrep = 4
    static let ordinaryPrep = 5
    static let pairPrep = 6
    static let triplePrep = 9
    static let quadPrep = 12

    /// The most Haste a single action may claim beyond its class agility.
    static let maxHastePerAction = 2

    /// The most a player may push one enemy's pending action back, per round.
    static let maxDelayPerEnemy = 2

    /// How long an action takes once the actor's agility and any earned Haste
    /// are taken off. Never faster than a single beat — agility shortens the
    /// wind-up, it never removes it.
    static func duration(preparation: Int, agility: Int, haste: Int = 0) -> Int {
        let hasted = min(max(haste, 0), maxHastePerAction)
        return max(1, preparation - max(agility, 0) - hasted)
    }

    /// Default preparation for a single face played alone, by what it does.
    static func soloPreparation(for kind: FaceKind) -> Int {
        switch kind {
        case .block, .evade:
            return soloGuardPrep
        case .swiftSlash, .bowSmack, .arrow1, .sideSwing:
            return quickAttackPrep
        default:
            return ordinaryPrep
        }
    }

    /// Default preparation for a fused combo of this many faces.
    static func comboPreparation(faces: Int) -> Int {
        switch faces {
        case ...2: return pairPrep
        case 3: return triplePrep
        default: return quadPrep
        }
    }

    /// Authored preparation per recipe, from the guide's timing table. This is
    /// the one place recipe timing is tuned — a stronger attack is not fast
    /// merely because it uses fewer ingredients.
    private static let recipePrep: [String: Int] = [
        // Archer
        "arc_twinShot": 6, "arc_piercingBolt": 6, "arc_pointBlank": 5,
        "arc_quickGuard": 4, "arc_fieldDressing": 6, "arc_steadyAim": 6,
        "arc_perfectShot": 9, "arc_stormOfShafts": 12,
        // Warrior
        "war_crushingBlow": 6, "war_wideSweep": 6, "war_earthshaker": 9,
        "war_riposte": 4, "war_secondWind": 5, "war_executioner": 9,
        "war_warlordsAnswer": 12, "war_bloodTide": 12,
        // Rogue
        "rog_flurry": 6, "rog_openingCut": 6, "rog_twinFang": 6,
        "rog_shadowstep": 5, "rog_patchUp": 6, "rog_hemorrhage": 9,
        "rog_vanishingStrike": 9, "rog_thousandCuts": 9,
        // Magician
        "mag_fireball": 6, "mag_iceBlast": 6, "mag_chillWard": 4,
        "mag_lifeSiphon": 6, "mag_kindle": 5, "mag_blink": 4,
        "mag_meteor": 9, "mag_arcaneStorm": 9,
        // Shared
        "shr_detonate": 6, "shr_venomCoat": 6, "shr_steadiedStrike": 6,
        "shr_breachStrike": 6, "shr_envenomedEdge": 6, "shr_blindingBlast": 5,
    ]

    /// Preparation for a named recipe, falling back to the face-count default.
    static func preparation(recipe id: String, faces: Int) -> Int {
        recipePrep[id] ?? comboPreparation(faces: faces)
    }

    /// Recipes that hand the next action a beat of Haste when they resolve.
    static let hasteGranting: Set<String> = ["rog_shadowstep"]

    /// Recipes that push one pending enemy action a beat later, once a round.
    static let delayGranting: Set<String> = ["mag_iceBlast", "war_earthshaker"]

    // MARK: - Enemy timing

    /// Base agility per creature, from the guide's table. High agility never
    /// grants extra actions — it only shortens the wind-up.
    private static let enemyAgility: [String: Int] = [
        "trainingDummy": 0,
        "reedLurker": 2, "marshShade": 2, "sandCrawler": 2, "siltColossus": 0,
        "emberWraith": 2, "flamekeeper": 1, "ashJackal": 3, "bronzeEffigy": 0,
        "devourerSpawn": 1, "uncreatedShadow": 3, "hourEater": 1, "boneplateDevourer": 0,
        "sekhen": 1, "nehebkau": 1, "apep": 2,
    ]

    static func agility(enemy id: String) -> Int {
        enemyAgility[id] ?? 1
    }

    /// How long an enemy move takes to come round. Pure defence and recovery
    /// land quickly; damaging moves take their weight in preparation, so a
    /// heavy hit is visible on the strip well before it arrives.
    static func preparation(move: EnemyMove) -> Int {
        if move.damage <= 0 { return soloGuardPrep }
        if move.faces.count >= 3 { return triplePrep }
        if move.faces.count == 2 { return pairPrep }
        return move.damage >= 14 ? ordinaryPrep : quickAttackPrep
    }

    /// Agility a creature borrows for the first round when it catches you
    /// stepping off the barque — the guide's opening surprise.
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
    /// How long its wind-up ran, after agility and Haste.
    let duration: Int
    let title: String
    /// What it will do, in the same words the plan card uses.
    let detail: String
    /// Which foe it is pointed at (player actions), for the fallback order.
    let targetID: UUID?
    let roles: ActionRole
    /// The plan step or enemy this entry was built from.
    let sourceID: UUID
    /// Set when Haste pulled this action earlier than its printed preparation.
    let hastened: Int

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
        hastened: Int = 0
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
