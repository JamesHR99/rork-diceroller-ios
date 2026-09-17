import SwiftUI

/// What a move is *for*, which is what the situational AI weighs. A move can
/// be more than one of these at once — a gorge that bites and heals is both an
/// attack and a recovery.
struct MoveIntentKind: OptionSet, Hashable {
    let rawValue: Int

    static let attack = MoveIntentKind(rawValue: 1 << 0)
    static let guard_ = MoveIntentKind(rawValue: 1 << 1)
    static let recover = MoveIntentKind(rawValue: 1 << 2)
    /// A wind-up: it does nothing this round and makes the next blow worse.
    static let charge = MoveIntentKind(rawValue: 1 << 3)

    nonisolated static let none: MoveIntentKind = []
}

/// One weighted action the enemy AI can telegraph and perform.
struct EnemyMove: Identifiable, Hashable {
    let id: String
    let name: String
    let faces: [FaceKind]
    let weight: Int
    let comboName: String?
    let damage: Int
    let block: Int
    let heal: Int
    let bleedAmount: Int
    let bleedTurns: Int
    /// What the next attack this creature throws is multiplied by, when this
    /// move is a wind-up. 0 for everything that is not a charge.
    let charge: Double
    /// What this move costs out of the creature's round stamina. Authored
    /// moves leave it nil and pay by their own weight of faces.
    private let authoredCost: Int?

    init(
        id: String,
        name: String,
        faces: [FaceKind],
        weight: Int,
        comboName: String? = nil,
        damage: Int = 0,
        block: Int = 0,
        heal: Int = 0,
        bleedAmount: Int = 0,
        bleedTurns: Int = 0,
        charge: Double = 0,
        cost: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.faces = faces
        self.weight = weight
        self.comboName = comboName
        self.damage = damage
        self.block = block
        self.heal = heal
        self.bleedAmount = bleedAmount
        self.bleedTurns = bleedTurns
        self.charge = charge
        self.authoredCost = cost
    }

    /// Stamina this move takes out of the round: a jab is cheap, a three-face
    /// recipe is the creature's whole turn.
    var cost: Int {
        if let authoredCost { return max(1, authoredCost) }
        return max(1, min(3, faces.count))
    }

    var kind: MoveIntentKind {
        var kind: MoveIntentKind = .none
        if damage > 0 { kind.insert(.attack) }
        if block > 0 { kind.insert(.guard_) }
        if heal > 0 { kind.insert(.recover) }
        if charge > 0 { kind.insert(.charge) }
        return kind
    }

    /// A scaled copy, used for heralds, for chained turns and for Nehebkau's
    /// rising heat. Everything a move produces scales together, so a creature
    /// that spends its round on three actions does not also get full guard.
    func scaled(damage multiplier: Double, block blockMultiplier: Double = 1,
                heal healMultiplier: Double = 1) -> EnemyMove {
        EnemyMove(
            id: id, name: name, faces: faces, weight: weight, comboName: comboName,
            damage: Int(Double(damage) * multiplier),
            block: Int(Double(block) * blockMultiplier),
            heal: Int(Double(heal) * healMultiplier),
            bleedAmount: bleedAmount, bleedTurns: bleedTurns,
            charge: charge, cost: authoredCost
        )
    }

    /// This move as it lands when the creature is taking `actions` swings in
    /// one round: more actions, less behind each one.
    func inChain(of actions: Int) -> EnemyMove {
        guard actions > 1 else { return self }
        let scale = GameData.enemyChainScale(actions: actions)
        return scaled(damage: scale, block: scale, heal: scale)
    }
}

/// A phase of a multi-stage boss. The serpent coils back up with a new
/// repertoire each time its health drops past a threshold.
struct EnemyStage: Identifiable, Hashable {
    let id: String
    /// What the boss is called while this stage runs.
    let name: String
    /// Stage begins once health falls to or below this fraction of maximum.
    let beginsBelow: Double
    /// Spoken when the stage arrives.
    let arrival: String
    let moves: [EnemyMove]
}

/// An enemy encountered on the voyage.
struct EnemyDef: Identifiable, Hashable {
    let id: String
    let name: String
    /// Where in the Duat this thing is met, shown above the arena.
    let title: String
    /// A line of flavour used on the arrival card.
    let blurb: String
    let maxHP: Int
    let symbol: String
    let goldReward: Int
    let isBoss: Bool
    let moves: [EnemyMove]
    /// Multi-stage bosses. Ordered from the opening stage downward.
    let stages: [EnemyStage]
    /// Extra damage added to every attack for each turn the fight has run.
    let heatPerTurn: Int
    /// Metal worn over the health. Direct damage chips armour away before it
    /// can touch health; poison, burn and bleed seep under it. 0 = unarmoured.
    let armour: Int
    /// What this creature can spend in one round. A jab costs 1 and a
    /// three-face recipe 3, so this is what decides whether it throws one
    /// heavy blow or strings a guard and two quick cuts together.
    let stamina: Int

    init(
        id: String,
        name: String,
        title: String,
        blurb: String = "",
        maxHP: Int,
        symbol: String,
        goldReward: Int,
        isBoss: Bool = false,
        moves: [EnemyMove],
        stages: [EnemyStage] = [],
        heatPerTurn: Int = 0,
        armour: Int = 0,
        stamina: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.blurb = blurb
        // Solo attacks hit harder and recipes no longer multiply by length,
        // so every foe carries a touch more health to keep the night honest.
        self.maxHP = max(1, Int((Double(maxHP) * GameData.enemyHealthTune).rounded()))
        self.symbol = symbol
        self.goldReward = goldReward
        self.isBoss = isBoss
        self.moves = moves
        self.stages = stages
        self.heatPerTurn = heatPerTurn
        self.armour = armour
        self.stamina = stamina ?? (isBoss ? GameData.bossRoundStamina : GameData.enemyRoundStamina)
    }

    // MARK: - Stages

    /// Which stage is running at this health fraction (0 when not staged).
    func stageIndex(hpFraction: Double) -> Int {
        guard !stages.isEmpty else { return 0 }
        var index = 0
        for (offset, stage) in stages.enumerated() where hpFraction <= stage.beginsBelow {
            index = offset
        }
        return index
    }

    func stage(hpFraction: Double) -> EnemyStage? {
        guard !stages.isEmpty else { return nil }
        return stages[min(stageIndex(hpFraction: hpFraction), stages.count - 1)]
    }

    /// The name shown in the arena, which changes as a boss re-coils.
    func displayName(hpFraction: Double) -> String {
        stage(hpFraction: hpFraction)?.name ?? name
    }

    // MARK: - Moves

    /// Every move available at this health, which is what the planner draws
    /// its round from.
    func movePool(hpFraction: Double = 1) -> [EnemyMove] {
        let pool = stage(hpFraction: hpFraction)?.moves ?? moves
        return pool.isEmpty ? moves : pool
    }

    /// A tougher variant used for Heralds of Apep on optional stops.
    func herald() -> EnemyDef {
        EnemyDef(
            id: id + "_herald",
            name: "Herald " + name,
            title: title,
            blurb: "It wears Apep's mark and it knows your name.",
            maxHP: Int(Double(maxHP) * 1.45),
            symbol: symbol,
            goldReward: Int(Double(goldReward) * 1.8),
            moves: moves.map { $0.scaled(damage: 1.3, block: 1.3) },
            stages: stages,
            heatPerTurn: heatPerTurn,
            stamina: stamina + 1
        )
    }

    /// An armoured elite: same moves, but a bronze plate sits over the health
    /// and every point of it has to be earned. Occasionally spawns on battles.
    func armoured() -> EnemyDef {
        EnemyDef(
            id: id + "_armoured",
            name: "Armoured " + name,
            title: title,
            blurb: "Bronze over old wounds. You will have to earn its health.",
            maxHP: Int(Double(maxHP) * 1.3),
            symbol: symbol,
            goldReward: Int(Double(goldReward) * 1.6),
            isBoss: isBoss,
            moves: moves,
            stages: stages,
            heatPerTurn: heatPerTurn,
            armour: max(16, Int(Double(maxHP) * 0.2)),
            stamina: stamina
        )
    }

    /// One member of a pack: two-thirds health and a little less gold, so a
    /// fight against three foes is not triple the fight against one.
    func packMember() -> EnemyDef {
        EnemyDef(
            id: id + "_pack",
            name: name,
            title: title,
            blurb: blurb,
            maxHP: max(1, Int(Double(maxHP) * GameData.packHealthScale)),
            symbol: symbol,
            goldReward: Int(Double(goldReward) * 0.7),
            isBoss: isBoss,
            moves: moves,
            stages: stages,
            heatPerTurn: heatPerTurn,
            armour: armour,
            // One of three cannot also take three actions a round, or a pack
            // turn becomes nine blows.
            stamina: max(2, stamina - 2)
        )
    }
}
