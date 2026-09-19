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
        let deadline = clock.now.advanced(by: .seconds(45))
        while engine.turnNumber == 1 && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.turnNumber == 2)
        #expect(engine.phase == .player)
    }


    @Test func alternatingActionsAreFinite() {
        #expect(BattleRules.alternating(player: [1, 2, 3], enemy: [4]) == [1, 4, 2, 3])
        #expect(BattleRules.alternating(player: [Int](), enemy: [4, 5]) == [4, 5])
    }

    @Test func catalogueHasExactlySixTiersForEveryFace() {
        #expect(SameFaceCatalog.all.count == 114)
        #expect(Set(SameFaceCatalog.all.map(\.id)).count == 114)
        for classID in ["archer", "warrior", "rogue", "magician"] {
            for face in SameFaceCatalog.palette(for: classID) {
                for count in 1...6 {
                    let action = SameFaceCatalog.action(face, count: count)
                    #expect(action?.faceCount == count)
                    #expect(action?.match(from: Array(repeating: face, count: count)) != nil)
                }
            }
        }
    }

    @Test func criticalContributionIsDeterministicAndBounded() {
        #expect(GameData.comboOutputScale(faces: 6, critDice: 3, crit: false) == 1.25)
        #expect(GameData.comboOutputScale(faces: 6, critDice: 3, crit: true) == 1.25)
        #expect(GameData.comboOutputScale(faces: 1, critDice: 1, crit: false) == 1.5)
        #expect(GameData.comboOutputScale(faces: 6, critDice: 6, crit: false) == 1.5)
        #expect(DieFace.critCap == 0.4)
    }

    @Test func duplicateSidesNeverCountAsMultiplePhysicalDice() {
        let die = Die(name: "Repeated sides", slot: .weapon, faces: Array(repeating: .arrow1, count: 6))
        #expect(SameFaceCatalog.maximumGroup(.arrow1, dice: [die]) == 1)
    }

    @Test func delayDoesNotInventAnExtraExchange() {
        let foeID = UUID()
        let enemy = TimelineEntry(side: .foe(foeID), beat: 1, duration: 1, title: "Enemy", detail: "", sourceID: foeID)
        let player = TimelineEntry(side: .player, beat: 2, duration: 1, title: "Player", detail: "", sourceID: UUID())
        var queue = [enemy, player]
        let ids = Set(queue.map(\.id))
        #expect(BattleRules.postponeEnemy(foeID, queue: &queue))
        #expect(queue.map(\.title) == ["Player", "Enemy"])
        #expect(Set(queue.map(\.id)) == ids)
        queue = [enemy]
        #expect(!BattleRules.postponeEnemy(foeID, queue: &queue))
        #expect(queue.count == 1)
    }

    @Test func reservedDodgeOnlySpendsOnItsStrike() {
        var charges: [String?] = ["second", nil]
        #expect(BattleRules.consumeDodge(reservations: &charges, strikeID: "first"))
        #expect(charges == ["second"])
        #expect(!BattleRules.consumeDodge(reservations: &charges, strikeID: "other"))
        #expect(BattleRules.consumeDodge(reservations: &charges, strikeID: "second"))
    }

    @Test(arguments: ["archer", "warrior", "rogue", "magician"])
    func startingLoadoutsUseEightPhysicalDiceAndDrawSix(classID: String) {
        let hero = GameData.heroClass(id: classID)
        #expect(hero.startingLoadout.allDice.count == 8)
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: hero.startingLoadout.allDice, classID: classID, maxHP: hero.maxHP, startHP: hero.maxHP, critBonus: 0)
        #expect(Set(engine.slots.map { $0.die.id }).count == 6)
        #expect(engine.rerollsRemaining == 2)
    }

    @Test func rerollSubsetUsesOnePassAndPreparesEveryRetainedResult() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus])
        try await roll(engine)
        let before = engine.rolled
        let selected = Array(engine.slots.prefix(2))
        let rerolledDieIDs = Set(selected.map { $0.die.id })
        engine.selectingReroll = true
        for slot in selected { engine.reroll(slotID: slot.id, reduceMotion: true) }
        #expect(engine.rerollSelection.count == 2)
        #expect(engine.rerollsRemaining == 2)
        engine.confirmReroll(reduceMotion: true)
        try await settled(engine)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.rolled.count == 6)
        for face in before where !rerolledDieIDs.contains(face.dieID) {
            let kept = try #require(engine.rolled.first { $0.id == face.id })
            #expect(kept.wasKept && kept.face == face.face && kept.isCrit == face.isCrit)
        }
        #expect(engine.rolled.filter { rerolledDieIDs.contains($0.dieID) }.allSatisfy { !$0.wasKept })
    }

    @Test func mixedArrowsCannotCombineAndSupportTakesAnEvent() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus])
        try await roll(engine)
        for face in engine.rolled { engine.placeInPlayBar(faceID: face.id) }
        #expect(engine.weldCandidates.isEmpty)
        #expect(engine.timeline.filter(\.isPlayer).count == 6)
    }

    @Test func fourMatchingDiceWindUpAndCanBeSeparatedAgain() async throws {
        let engine = battle([.arrow1, .arrow1, .arrow1, .arrow1, .block, .focus])
        try await roll(engine)
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        for face in arrows { engine.placeInPlayBar(faceID: face.id) }
        let candidate = try #require(engine.weldCandidates.first { $0.combo.faceCount == 4 })
        #expect(engine.combine(candidate))
        #expect(engine.turnPlan.count == 1)
        #expect(engine.timeline.filter(\.isPlayer).count == 2)
        #expect(engine.separate(faceID: arrows[0].id))
        #expect(engine.turnPlan.count == 4)
    }

    @Test func ordinarySoloRoundSettlesAndResetsTheHand() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus])
        try await roll(engine)
        let arrow = try #require(engine.rolled.first { $0.face == .arrow1 })
        engine.placeInPlayBar(faceID: arrow.id)
        let expected = try #require(SameFaceCatalog.action(.arrow1, count: 1)).damage
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == 500 - expected)
        #expect(engine.rolled.isEmpty && engine.slots.count == 6)
        #expect(engine.rerollsRemaining == 2)
    }

    @Test func godCatalogueRetainsStableIDsAndEvolvesInTheSourceSlot() {
        #expect(GodCatalog.regulars.count == 60)
        #expect(GodCatalog.duos.count == 15)
        #expect(GodCatalog.legendaries.count == 6)
        for legendary in GodCatalog.legendaries {
            #expect(legendary.slot == GodCatalog.boon(legendary.evolves ?? "")?.slot)
        }
    }
    @Test func enemyShieldDoesNotRestoreItsArmourPool() {
        let def = EnemyContent.enemy(hour: 1, isHerald: false)
        var foe = EnemyState(def: def)
        foe.armour = 0
        foe.gainGuard(18)
        #expect(foe.armour == 0)
        #expect(foe.shield == 18)
        foe.gainGuard(200)
        #expect(foe.shield == 100)
    }

    @Test func bleedingPairPaysAtRoundEndAndKeepsItsSecondTick() async throws {
        let engine = battle([.swiftSlash, .swiftSlash, .poison, .block, .evade, .heal], classID: "rogue")
        try await roll(engine)
        for slash in engine.rolled.filter({ $0.face == .swiftSlash }) { engine.placeInPlayBar(faceID: slash.id) }
        let candidate = try #require(engine.weldCandidates.first)
        #expect(engine.combine(candidate))
        let native = try #require(SameFaceCatalog.action(.swiftSlash, count: 2))
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == 500 - native.damage - native.bleedAmount)
        #expect(engine.enemies[0].bleedAmount == native.bleedAmount)
        #expect(engine.enemies[0].bleedTurns == 1)
    }

    @Test func dieOffersRespectClassPaletteAndThreeSideLimit() {
        for classID in ["archer", "warrior", "rogue", "magician"] {
            for rarity in Rarity.allCases {
                for offer in GameData.diceOffers(classID, rarity) {
                    #expect(offer.die.faces.count == 6)
                    for face in offer.die.faces {
                        #expect(SameFaceCatalog.palette(for: classID).contains(face.kind))
                        #expect(offer.die.faces.filter { $0.kind == face.kind }.count <= 3)
                    }
                }
            }
        }
    }

    @Test func echoReservationBelongsToTheSelectedAction() async throws {
        let engine = battle([.runeFire, .runeFire, .runeLife, .runeLife, .runeFrost, .channel],
            classID: "magician", chisels: ["ch_echoingStaff"])
        try await roll(engine)
        let life = engine.rolled.filter { $0.face == .runeLife }
        for face in life { engine.placeInPlayBar(faceID: face.id) }
        let candidate = try #require(engine.weldCandidates.first)
        #expect(engine.combine(candidate))
        let action = try #require(engine.turnPlan.first)
        engine.beginArming("ch_echoingStaff")
        #expect(engine.armHeldChisel(onto: action))
        #expect(engine.reservedRerolls == 1 && engine.rerollsRemaining == 1)
        #expect(engine.separate(faceID: life[0].id))
        #expect(engine.reservedRerolls == 0 && engine.rerollsRemaining == 2)
    }

}
