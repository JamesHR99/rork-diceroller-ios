import Foundation

/// Everything the creature can see when it decides what to do with its round:
/// its own condition, the guard it is standing behind, and how close you are
/// to going over the side.
struct EnemyTurnContext {
    /// The creature's own health, as a fraction of its maximum.
    let hpFraction: Double
    /// True when it has no guard left at all.
    let isBare: Bool
    /// True when it is already standing behind a guard worth the name.
    let isWellGuarded: Bool
    /// Your health, as a fraction of your maximum.
    let playerHPFraction: Double
    /// True while you are holding a shield that would eat the next blow.
    let playerHasShield: Bool
    /// True when the creature is already holding a wind-up.
    let isCharging: Bool

    /// The opening context, used before a fight has state of its own.
    static let opening = EnemyTurnContext(
        hpFraction: 1, isBare: false, isWellGuarded: false,
        playerHPFraction: 1, playerHasShield: false, isCharging: false
    )
}

/// Decides how a creature spends its round.
///
/// A creature has an internal allowance for choosing announced moves. It may put everything into
/// one heavy blow, or string a guard and two quick cuts together — and the
/// more separate actions it takes, the less each one is worth. That is what
/// makes a round of block-attack-block worth planning: the read is no longer
/// "one blow is coming", it is "three things are coming and here is the order".
///
/// Which moves it reaches for is situational. A hurt creature looks for a
/// mend, a bare one raises guard, one standing over a nearly-dead enemy goes
/// for the throat, and a healthy one with time to spare winds up something
/// that will hurt a great deal more next round.
enum EnemyPlanner {

    /// The round's sequence of moves, already scaled for how many of them
    /// there are, so the telegraph and the blow can never disagree.
    static func plan(
        def: EnemyDef,
        hpFraction: Double,
        context: EnemyTurnContext
    ) -> [EnemyMove] {
        let usable = def.movePool(hpFraction: hpFraction)
        guard !usable.isEmpty else { return [] }

        let heaviest = usable.map(\.damage).max() ?? 0
        var remaining = def.stamina
        var chosen: [EnemyMove] = []
        var usedKinds: MoveIntentKind = .none
        var usedIDs: Set<String> = []

        while chosen.count < GameData.enemyMaxActionsPerRound, remaining > 0 {
            let candidates = usable.filter { move in
                guard move.cost <= remaining, !usedIDs.contains(move.id) else { return false }
                // One guard, one mend and one wind-up to a round — a creature
                // that blocks twice in a turn just reads as a stalled fight.
                if move.kind.contains(.guard_), usedKinds.contains(.guard_) { return false }
                if move.kind.contains(.recover), usedKinds.contains(.recover) { return false }
                if move.kind.contains(.charge), !chosen.isEmpty { return false }
                return true
            }
            guard !candidates.isEmpty else { break }

            let weights = candidates.map {
                weight($0, context: context, heaviest: heaviest)
            }
            guard let pick = weightedPick(candidates, weights: weights) else { break }

            chosen.append(pick)
            usedIDs.insert(pick.id)
            usedKinds.insert(pick.kind)
            remaining -= pick.cost

            // A wind-up is the whole round: it is standing there gathering
            // itself, which is exactly the window you are meant to use.
            if pick.kind.contains(.charge) { break }
        }

        if chosen.isEmpty, let fallback = usable.first { chosen = [fallback] }
        let actions = chosen.count
        return chosen.map { $0.inChain(of: actions) }
    }

    // MARK: - Weighting

    /// How much a creature in this condition wants to make this move.
    private static func weight(
        _ move: EnemyMove,
        context: EnemyTurnContext,
        heaviest: Int
    ) -> Double {
        var weight = Double(max(move.weight, 1))
        let kind = move.kind

        // Mending: urgent when hurt, close to a wasted round when healthy.
        if kind.contains(.recover) {
            if context.hpFraction <= GameData.enemyHurtThreshold {
                weight *= GameData.enemyHealUrgentBoost
            } else if context.hpFraction >= GameData.enemyHealthyThreshold {
                weight *= GameData.enemyHealHealthyDamp
            }
        }

        // Guard: raised when it is standing bare, skipped when it already has
        // a wall up.
        if kind.contains(.guard_) {
            if context.isBare { weight *= GameData.enemyGuardBareBoost }
            if context.isWellGuarded { weight *= GameData.enemyGuardStackedDamp }
        }

        // Attacks: it presses when you are nearly out, and it prefers its
        // heaviest blow when there is no shield in the way of it.
        if kind.contains(.attack) {
            if context.playerHPFraction <= GameData.enemyFinisherThreshold {
                weight *= GameData.enemyFinisherBoost
            }
            if !context.playerHasShield, heaviest > 0,
               Double(move.damage) >= Double(heaviest) * 0.8 {
                weight *= GameData.enemyUnguardedBoost
            }
            // A creature holding a wind-up wants to spend it.
            if context.isCharging { weight *= 2.5 }
        }

        // Wind-ups: only when it has the health and the time to afford one,
        // and never while it is already holding one.
        if kind.contains(.charge) {
            if context.isCharging { return 0 }
            let unhurried = context.hpFraction >= 0.5
                && context.playerHPFraction > GameData.enemyFinisherThreshold
            weight *= unhurried ? GameData.enemyChargeBoost : GameData.enemyChargeDamp
        }

        // A creature holding a wind-up does not wander off to tidy its guard.
        if context.isCharging, kind.contains(.guard_) || kind.contains(.recover) {
            weight *= 0.4
        }

        return max(weight, 0.01)
    }

    private static func weightedPick(_ moves: [EnemyMove], weights: [Double]) -> EnemyMove? {
        let total = weights.reduce(0, +)
        guard total > 0 else { return moves.first }
        var roll = Double.random(in: 0..<total)
        for (move, weight) in zip(moves, weights) {
            if roll < weight { return move }
            roll -= weight
        }
        return moves.last
    }
}

