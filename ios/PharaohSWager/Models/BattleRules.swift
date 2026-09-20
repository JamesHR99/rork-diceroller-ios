import Foundation

/// Shared, deterministic rules used by planning, resolution and tests.
enum BattleRules {
    static let handSize = 6
    static let baseRerolls = 0
    static let maximumRerolls = 2
    static let focusPercent = 50
    static let blockValue = 8
    static let maximumDodges = 6
    static let warriorGuardCarry = 8

    static func focusedBonus(damage: Int) -> Int {
        max(0, damage * focusPercent / 100)
    }

    /// Neither side gets extra actions when the other side plays more cards.
    static func alternating<T>(player: [T], enemy: [T]) -> [T] {
        var result: [T] = []
        for index in 0..<max(player.count, enemy.count) {
            if player.indices.contains(index) { result.append(player[index]) }
            if enemy.indices.contains(index) { result.append(enemy[index]) }
        }
        return result
    }

    static func consumeDodge(reservations: inout [String?], strikeID: String) -> Bool {
        guard let index = reservations.firstIndex(where: { $0 == strikeID })
            ?? reservations.firstIndex(where: { $0 == nil }) else { return false }
        reservations.remove(at: index)
        return true
    }

    /// Move one announced foe action after the next player action. No entry
    /// is added or removed, even if the player has no actions left.
    static func postponeEnemy(_ foeID: UUID, queue: inout [TimelineEntry]) -> Bool {
        guard let index = queue.firstIndex(where: { $0.sourceID == foeID && !$0.isPlayer }),
              let nextPlayer = queue.indices.first(where: { $0 > index && queue[$0].isPlayer }) else { return false }
        let delayed = queue.remove(at: index)
        queue.insert(delayed, at: nextPlayer)
        return true
    }

    static func guardAfterRound(_ guardValue: Int, warrior: Bool) -> Int {
        warrior ? min(warriorGuardCarry, max(0, guardValue)) : 0
    }
}

/// One specific hit, rather than an entire multi-hit move. IDs survive planning
/// and resolution because they name the foe, its announced move and hit index.
struct EnemyStrike: Identifiable, Hashable {
    let foeID: UUID
    let moveIndex: Int
    let hitIndex: Int
    let title: String
    let damage: Int

    var id: String { "\(foeID.uuidString):\(moveIndex):\(hitIndex)" }
}

