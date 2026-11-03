import Foundation
import Testing
@testable import PharaohSWager

@MainActor
struct EnemyBleedTests {
    @Test func enemyCatalogueTelegraphsTheSharedBleedRule() {
        let enemies = [EnemyContent.trainingDummy] + EnemyContent.serpentLords
            + EnemyContent.gateRoster(.reeds) + EnemyContent.gateRoster(.fire)
            + EnemyContent.gateRoster(.coils)
        let moves = enemies.flatMap { $0.moves + $0.stages.flatMap(\.moves) }
        let bleeds = moves.filter { $0.bleedAmount > 0 }
        #expect(!bleeds.isEmpty)
        for move in bleeds {
            #expect(move.bleedTurns == 2, "\(move.name) must forecast two ticks")
            #expect(move.bleedAmount <= GameData.bleedStackCap, "\(move.name) must forecast capped potency")
        }
    }

    @Test func announcedBleedTicksTwiceAndBlockedReapplicationDoesNotRefreshIt() async throws {
        let move = EnemyMove(id: "bleed", name: "Wound", faces: [.swiftSlash], weight: 1,
                             damage: 1, bleedAmount: 4, bleedTurns: 2)
        let foe = EnemyDef(id: "bleeder", name: "Bleeder", title: "Test", maxHP: 500,
                           symbol: "circle", goldReward: 0, moves: [move])
        let dice = (0..<6).map { Die(name: "Guard \($0)", slot: .armor,
                                      faces: Array(repeating: .block, count: 6)) }
        let engine = BattleEngine(enemies: [foe], dice: dice, classID: "archer",
                                  maxHP: 100, startHP: 100, critBonus: -1)
        let projectedDamage = engine.projectedStrike(for: engine.enemies[0]).damage
        #expect(engine.enemyActionOrder.first?.detail.contains("bleed 4×2") == true)

        engine.rollAll(reduceMotion: true)
        try await waitForRoll(engine)
        engine.endPlayerTurn()
        try await waitForRound(engine, after: 1)
        #expect(engine.playerHP == 100 - projectedDamage - 4)
        #expect(engine.playerBleedAmount == 4)
        #expect(engine.playerBleedTurns == 1)

        engine.rollAll(reduceMotion: true)
        try await waitForRoll(engine)
        let guardFace = try #require(engine.rolled.first)
        engine.toggleActionSelection(faceID: guardFace.id)
        engine.endPlayerTurn()
        try await waitForRound(engine, after: 2)
        #expect(engine.playerHP == 100 - projectedDamage - 8)
        #expect(engine.playerBleedAmount == 0)
        #expect(engine.playerBleedTurns == 0)
    }

    private func waitForRoll(_ engine: BattleEngine) async throws {
        let deadline = ContinuousClock().now.advanced(by: .seconds(15))
        while engine.isRolling && ContinuousClock().now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(!engine.isRolling)
    }

    private func waitForRound(_ engine: BattleEngine, after previous: Int) async throws {
        let deadline = ContinuousClock().now.advanced(by: .seconds(45))
        while engine.turnNumber == previous && engine.phase != .lost && ContinuousClock().now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(engine.turnNumber == previous + 1)
    }
}
