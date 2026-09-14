import SwiftUI

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
        bleedTurns: Int = 0
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
    }

    /// A scaled copy, used for heralds and for Nehebkau's rising heat.
    func scaled(damage multiplier: Double, block blockMultiplier: Double = 1) -> EnemyMove {
        EnemyMove(
            id: id, name: name, faces: faces, weight: weight, comboName: comboName,
            damage: Int(Double(damage) * multiplier),
            block: Int(Double(block) * blockMultiplier),
            heal: heal,
            bleedAmount: bleedAmount, bleedTurns: bleedTurns
        )
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
        armour: Int = 0
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

    /// Weighted random move selection from whichever stage is running.
    func pickMove(hpFraction: Double = 1) -> EnemyMove {
        let pool = stage(hpFraction: hpFraction)?.moves ?? moves
        let usable = pool.isEmpty ? moves : pool
        let total = usable.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<max(total, 1))
        for move in usable {
            if roll < move.weight { return move }
            roll -= move.weight
        }
        return usable[0]
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
            heatPerTurn: heatPerTurn
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
            armour: max(16, Int(Double(maxHP) * 0.2))
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
            armour: armour
        )
    }
}
