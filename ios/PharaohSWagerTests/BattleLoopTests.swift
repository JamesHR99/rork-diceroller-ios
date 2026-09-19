import Foundation
import Testing
@testable import PharaohSWager

@MainActor
struct BattleLoopTests {
    private func battle(_ faces: [FaceKind], classID: String = "archer", boons: [String] = [], chisels: Set<String> = [], patron: Deity? = nil) -> BattleEngine {
        let move = EnemyMove(id: "two-hits", name: "Two hits", faces: [.swiftSlash, .swiftSlash], weight: 1, damage: 24)
        let enemy = EnemyDef(id: "test-foe", name: "Practice foe", title: "Tests", maxHP: 500,
            symbol: "circle", goldReward: 0, moves: [move])
        let dice = faces.enumerated().map { index, face in
            Die(name: "Test \(index)", slot: face.isAttack ? .weapon : .armor, faces: Array(repeating: face, count: 6), patron: patron)
        }
        return BattleEngine(enemies: [enemy], dice: dice, classID: classID, maxHP: 100, startHP: 100,
            critBonus: -1, boons: boons.map { EquippedBoon(defID: $0, rarity: .common, level: 1) }, chisels: chisels)
    }

    private func roll(_ engine: BattleEngine) async throws {
        engine.rollAll(reduceMotion: true)
        try await settled(engine)
    }

    private func settled(_ engine: BattleEngine) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(3))
        while engine.isRolling && clock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!engine.isRolling)
    }

    private func nextRound(_ engine: BattleEngine) async throws {
        engine.commitTurn()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(15))
        while engine.turnNumber == 1 && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.turnNumber == 2)
        #expect(engine.phase == .player)
    }

    @Test func alternatingActionsAreFinite() {
        #expect(BattleRules.alternating(player: ["P1", "P2", "P3"], enemy: ["E1"]) == ["P1", "E1", "P2", "P3"])
        #expect(BattleRules.alternating(player: ["P1"], enemy: ["E1", "E2"]) == ["P1", "E1", "E2"])
        #expect(BattleRules.alternating(player: [Int](), enemy: [1, 2]) == [1, 2])
    }

    @Test func delayChangesOrderWithoutDeletingOrRepeatingEnemyActions() {
        let foeID = UUID()
        let otherID = UUID()
        let player = TimelineEntry(side: .player, beat: 2, duration: 1, title: "Player", detail: "", sourceID: UUID())
        let enemy = TimelineEntry(side: .foe(foeID), beat: 1, duration: 1, title: "Enemy", detail: "", sourceID: foeID)
        let other = TimelineEntry(side: .foe(otherID), beat: 3, duration: 1, title: "Other", detail: "", sourceID: otherID)
        var queue = [enemy, player, other]
        let ids = Set(queue.map(\.id))
        #expect(BattleRules.postponeEnemy(foeID, queue: &queue))
        #expect(queue.map(\.title) == ["Player", "Enemy", "Other"])
        #expect(Set(queue.map(\.id)) == ids)
        queue = [enemy, other]
        #expect(BattleRules.postponeEnemy(foeID, queue: &queue))
        #expect(queue.count == 2)
        #expect(queue.last?.sourceID == foeID)
    }

    @Test func reservedDodgeWaitsForItsHitAndNeverCancelsAWholeMove() {
        var charges: [String?] = ["second", nil]
        #expect(BattleRules.consumeDodge(reservations: &charges, strikeID: "first"))
        #expect(charges == ["second"])
        #expect(!BattleRules.consumeDodge(reservations: &charges, strikeID: "other"))
        #expect(BattleRules.consumeDodge(reservations: &charges, strikeID: "second"))
        #expect(!BattleRules.consumeDodge(reservations: &charges, strikeID: "third"))
    }

    @Test(arguments: ["archer", "warrior", "rogue", "magician"])
    func allClassesDrawSixWithOneReroll(classID: String) {
        let hero = GameData.heroClass(id: classID)
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: hero.startingLoadout.allDice, classID: classID, maxHP: hero.maxHP, startHP: hero.maxHP, critBonus: 0)
        #expect(engine.slots.count == 6)
        #expect(Set(engine.slots.map { $0.die.id }).count == 6)
        #expect(engine.rerollsRemaining == 1)
    }

    @Test func selectiveRerollPreservesKeptResultsAndCannotRerollPlannedDice() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus])
        try await roll(engine)
        let before = engine.rolled
        let played = try #require(before.first { $0.face == .block })
        engine.placeInPlayBar(faceID: played.id)
        let plannedSlot = try #require(engine.slots.first { $0.die.id == played.dieID })
        engine.toggleReroll(slotID: plannedSlot.id)
        #expect(engine.rerollSelection.isEmpty)
        let selected = try #require(engine.slots.first { $0.die.id != played.dieID })
        let selectedFace = try #require(before.first { $0.dieID == selected.die.id })
        engine.toggleReroll(slotID: selected.id)
        engine.rerollSelected(reduceMotion: true)
        #expect(!engine.canCommit)
        #expect(!engine.canReroll)
        try await settled(engine)
        #expect(engine.rolled.count == 6)
        #expect(engine.rerollsRemaining == 0)
        #expect(!engine.rolled.contains { $0.id == selectedFace.id })
        for face in before where face.id != selectedFace.id {
            let kept = try #require(engine.rolled.first { $0.id == face.id })
            #expect(kept.face == face.face && kept.isCrit == face.isCrit && kept.wasKept)
        }
    }

    @Test func twinShotKeepsBlockSeparateAndFocusAttachesToTheCombinedAction() async throws {
        let engine = battle([.focus, .arrow1, .arrow1, .block, .evade, .heal])
        try await roll(engine)
        let focus = try #require(engine.rolled.first { $0.face == .focus })
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        let block = try #require(engine.rolled.first { $0.face == .block })
        for face in [focus] + arrows + [block] { engine.placeInPlayBar(faceID: face.id) }
        let enemyCount = engine.timeline.filter { !$0.isPlayer }.count
        #expect(engine.timeline.filter(\.isPlayer).count == 2)
        let candidate = try #require(engine.weldCandidates.first { $0.combo.id == "arc_twinShot" })
        #expect(engine.combine(candidate))
        let combo = try #require(engine.turnPlan.first { $0.isCombo })
        #expect(combo.faces.count == 2)
        #expect(combo.focusFaceID == focus.id)
        #expect(combo.focusBonus == 11)
        #expect(combo.damage == 33)
        #expect(engine.timeline.filter(\.isPlayer).count == 1)
        #expect(engine.timeline.filter { !$0.isPlayer }.count == enemyCount)
        #expect(engine.turnPlan.contains { $0.id == block.id && $0.isPreparedSupport })
        #expect(engine.separate(faceID: arrows[0].id))
        #expect(engine.timeline.filter(\.isPlayer).count == 2)
    }

    @Test func blockAndChosenEvadeProtectDifferentHitsAndRoundDrawIsFresh() async throws {
        let engine = battle([.block, .evade, .focus, .arrow1, .arrow2, .heal], boons: ["RA-D1"])
        try await roll(engine)
        let block = try #require(engine.rolled.first { $0.face == .block })
        let evade = try #require(engine.rolled.first { $0.face == .evade })
        engine.placeInPlayBar(faceID: block.id)
        engine.placeInPlayBar(faceID: evade.id)
        let hits = engine.incomingStrikes
        #expect(hits.count == 2)
        engine.assignEvade(faceID: evade.id, strikeID: hits[1].id)
        let expectedHP = 100 - max(0, hits[0].damage - BattleRules.blockValue - 4)
        let enemyHP = engine.enemies[0].hp
        try await nextRound(engine)
        #expect(engine.playerHP == expectedHP)
        #expect(engine.enemies[0].hp == enemyHP - 4)
        #expect(engine.enemies[0].burnAmount == 2)
        #expect(engine.playerShield == 0 && engine.dodgeCharges == 0)
        #expect(engine.slots.count == 6 && engine.rolled.isEmpty && !engine.hasRolled)
        #expect(engine.rerollsRemaining == 1)
    }

    @Test func extraRerollAndSiegeDrawShareTheSameBudget() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus],
            boons: ["AN-U2"], chisels: ["ch_siegeDraw"])
        #expect(engine.rerollsRemaining == 2)
        try await roll(engine)
        let arrow = try #require(engine.rolled.first { $0.face == .arrow1 })
        engine.placeInPlayBar(faceID: arrow.id)
        engine.beginArming("ch_siegeDraw")
        #expect(engine.armHeldChisel(ontoFace: arrow.id))
        #expect(engine.reservedRerolls == 1 && engine.rerollsRemaining == 1)
        engine.returnToTray(faceID: arrow.id)
        #expect(engine.reservedRerolls == 0 && engine.rerollsRemaining == 2)
    }

    @Test func focusedGodPowerCanTriggerAfterAnUnfocusedAttack() async throws {
        let engine = battle([.arrow1, .focus, .arrow2, .block, .evade, .heal], boons: ["RA-A4"])
        try await roll(engine)
        for kind in [FaceKind.arrow1, .focus, .arrow2] {
            let face = try #require(engine.rolled.first { $0.face == kind })
            engine.placeInPlayBar(faceID: face.id)
        }
        let damage = engine.turnPlan.reduce(0) { $0 + $1.damage }
        let before = engine.enemies[0].hp
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == before - damage - 4)
        #expect(engine.enemies[0].burnAmount == 2)
    }

    @Test func patronEvadeRetaliatesAgainstTheActualAttacker() async throws {
        let engine = battle([.arrow1, .focus, .arrow2, .block, .evade, .heal], patron: .ra)
        try await roll(engine)
        let evade = try #require(engine.rolled.first { $0.face == .evade })
        engine.placeInPlayBar(faceID: evade.id)
        let before = engine.enemies[0].hp
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == before - 2)
        #expect(engine.enemies[0].burnAmount == 1)
    }

    @Test func siegeBonusOnASingleArrowMatchesItsPreview() async throws {
        let engine = battle([.arrow1, .focus, .arrow2, .block, .evade, .heal], chisels: ["ch_siegeDraw"])
        try await roll(engine)
        let arrow = try #require(engine.rolled.first { $0.face == .arrow1 })
        engine.placeInPlayBar(faceID: arrow.id)
        engine.beginArming("ch_siegeDraw")
        #expect(engine.armHeldChisel(ontoFace: arrow.id))
        let step = try #require(engine.turnPlan.first)
        let expected = engine.displayedDamage(for: step)
        let before = engine.enemies[0].hp
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == before - expected)
        #expect(engine.siegeArmedFaceIDs.isEmpty && engine.rerollsRemaining == 1)
    }

    @Test func guardExpiresExceptForWarriorCarry() {
        #expect(BattleRules.guardAfterRound(30, warrior: false) == 0)
        #expect(BattleRules.guardAfterRound(30, warrior: true) == 8)
        #expect(BattleRules.guardAfterRound(3, warrior: true) == 3)
    }

    @Test func catalogueKeepsStableIDsAndWholeDodgeCharges() {
        #expect(GodCatalog.all.count == 81)
        #expect(Set(GodCatalog.all.map(\.id)).count == 81)
        for boon in GodCatalog.all {
            #expect(!boon.effect.lowercased().contains("stamina"))
            #expect(!boon.effect.lowercased().contains("evade chance"))
            #expect(boon.trigger != .atCommitment)
            for rarity in BoonRarity.allCases {
                for level in 1...3 {
                    let payload = boon.resolved(rarity: rarity, level: level)
                    #expect((0...2).contains(payload.dodgeCharges))
                }
            }
        }
        for hero in GameData.classes {
            for combo in GameData.classCombos(hero.id) + SharedContent.combos {
                #expect((2...5).contains(combo.faceCount))
                #expect((0...2).contains(combo.dodgeCharges))
            }
        }
    }
}
