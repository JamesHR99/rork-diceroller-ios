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
        let deadline = clock.now.advanced(by: .seconds(15))
        while engine.isRolling && clock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try #require(!engine.isRolling)
    }

    private func nextRound(_ engine: BattleEngine) async throws {
        let previousTurn = engine.turnNumber
        engine.commitTurn()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(45))
        while engine.turnNumber == previousTurn && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.turnNumber == previousTurn + 1)
        #expect(engine.phase == .player)
    }



    @Test func bothSidesKeepUnbrokenGuardAcrossRounds() async throws {
        let move = EnemyMove(id: "guard", name: "Guard", faces: [.block], weight: 1, block: 8)
        let foe = EnemyDef(id: "guard-test", name: "Guard", title: "Test", maxHP: 500,
            symbol: "circle", goldReward: 0, moves: [move])
        let dice = (0..<6).map { Die(name: "Block \($0)", slot: .armor, faces: Array(repeating: .block, count: 6)) }
        let engine = BattleEngine(enemies: [foe], dice: dice, classID: "archer",
            maxHP: 100, startHP: 100, critBonus: -1)
        try await roll(engine)
        let face = try #require(engine.rolled.first)
        engine.placeInPlayBar(faceID: face.id)
        try await nextRound(engine)
        #expect(engine.playerShield == 8)
        let enemyGuard = engine.enemies[0].shield
        #expect(enemyGuard > 0)
        try await roll(engine)
        try await nextRound(engine)
        #expect(engine.playerShield == 8)
        #expect(engine.enemies[0].shield > enemyGuard)
        let fresh = BattleEngine(enemies: [foe], dice: dice, classID: "archer",
            maxHP: 100, startHP: 100, critBonus: -1)
        #expect(fresh.playerShield == 0)
        #expect(fresh.enemies[0].shield == 0)
    }

    @Test func criticalAndFocusDamageAreExplainedInPlanOrder() async throws {
        let engine = battle([.focus, .arrow1, .arrow1, .block, .block, .block])
        try await roll(engine)
        let focus = try #require(engine.rolled.first { $0.face == .focus })
        engine.placeInPlayBar(faceID: focus.id)
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        for face in arrows { engine.placeInPlayBar(faceID: face.id) }
        let attack = try #require(engine.displayedPlan.first { $0.damage > 0 })
        let base = try #require(attack.combo?.damage)
        let total = engine.displayedDamage(for: attack)
        #expect(engine.damageBreakdown(for: attack) == "\(base) base + \(total - base) Focus = \(total) damage")
        engine.returnToTray(faceID: focus.id)
        let criticalFaces = arrows.map { face in
            var result = face
            result.isCrit = true
            return result
        }
        let critical = PlanStep(faces: criticalFaces, combo: attack.combo)
        let criticalTotal = engine.displayedDamage(for: critical)
        #expect(engine.damageBreakdown(for: critical) == "\(base) base + \(criticalTotal - base) crit = \(criticalTotal) damage")
    }

    @Test func halfChargesPersistRechargeAndResetPerEncounter() async throws {
        let engine = battle(Array(repeating: .block, count: 6))
        try await roll(engine)
        let first = try #require(engine.slots.first)
        engine.selectingReroll = true
        engine.reroll(slotID: first.id, reduceMotion: true)
        #expect(!engine.isRolling && engine.rerollsRemaining == 0)
        engine.selectingReroll = false

        // Five physical dice form one action; only the sixth earns a half.
        for face in engine.rolled.prefix(5) { engine.placeInPlayBar(faceID: face.id) }
        #expect(engine.pendingRerollHalfCharges == 1)
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == 1 && engine.rerollsRemaining == 0)

        try await roll(engine)
        for face in engine.rolled.prefix(5) { engine.placeInPlayBar(faceID: face.id) }
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == 2 && engine.rerollsRemaining == 1)

        try await roll(engine)
        engine.selectingReroll = true
        engine.reroll(slotID: engine.slots[0].id, reduceMotion: true)
        #expect(engine.rerollHalfCharges == 0)
        try await settled(engine)
        // An empty plan still resolves the enemy queue and caps the award.
        let healthBefore = engine.playerHP
        #expect(engine.pendingRerollHalfCharges == 4)
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == 4)
        #expect(engine.playerHP < healthBefore)
        let fresh = battle(Array(repeating: .block, count: 6))
        #expect(fresh.rerollHalfCharges == 0)
    }

    @Test func fullHandEarnsNothingAndCommitCannotPayTwice() async throws {
        let engine = battle(Array(repeating: .block, count: 6))
        try await roll(engine)
        engine.gainRerollHalfCharges(1)
        for face in engine.rolled { engine.placeInPlayBar(faceID: face.id) }
        #expect(engine.pendingRerollHalfCharges == 0)
        engine.commitTurn()
        #expect(engine.rerollHalfCharges == 1)
        engine.commitTurn()
        #expect(engine.rerollHalfCharges == 1)
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == 1)
    }

    @Test func rewardsShareTheCapAndKeepHalfCharges() {
        let engine = battle(Array(repeating: .block, count: 6))
        engine.gainRerollHalfCharges(1)
        engine.gainRerollHalfCharges(2)
        #expect(engine.rerollHalfCharges == 3)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.rerollChargeText == "1.5")
        engine.gainRerollHalfCharges(20)
        #expect(engine.rerollHalfCharges == 4)
        #expect(engine.rerollsRemaining == 2)
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
        #expect(engine.rerollsRemaining == 0)
        #expect(engine.rerollHalfCharges == 0)
    }

    @Test func tappingARerollDieStartsImmediatelyAndSpendsExactlyOnce() async throws {
        let engine = battle([.arrow1, .arrow2, .arrow3, .block, .evade, .focus])
        try await roll(engine)
        engine.gainRerollHalfCharges(4)
        let before = engine.rolled
        let selected = try #require(engine.slots.first)
        engine.selectingReroll = true
        engine.reroll(slotID: selected.id, reduceMotion: true)
        #expect(engine.isRolling)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.rerollSelection.isEmpty)
        engine.reroll(slotID: selected.id, reduceMotion: true)
        #expect(engine.rerollsRemaining == 1)
        try await settled(engine)
        #expect(engine.rolled.count == 6)
        for face in before where face.dieID != selected.die.id {
            let kept = try #require(engine.rolled.first { $0.id == face.id })
            #expect(kept.wasKept && kept.face == face.face && kept.isCrit == face.isCrit)
        }
        #expect(engine.rolled.first { $0.dieID == selected.die.id }?.wasKept == false)
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
        #expect(engine.turnPlan.first?.faces.count == 4)
        #expect(engine.turnPlan.count == 1)
        #expect(engine.timeline.filter(\.isPlayer).count == 2)
        #expect(engine.separate(faceID: arrows[0].id))
        #expect(engine.turnPlan.count == 1)
        #expect(engine.turnPlan.first?.faces.count == 3)
        #expect(engine.timeline.filter(\.isPlayer).count == 1)
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
        #expect(engine.turnPlan.first?.isCombo == true)
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
        engine.gainRerollHalfCharges(4)
        let life = engine.rolled.filter { $0.face == .runeLife }
        for face in life { engine.placeInPlayBar(faceID: face.id) }
        #expect(engine.turnPlan.first?.isCombo == true)
        let action = try #require(engine.turnPlan.first)
        engine.beginArming("ch_echoingStaff")
        #expect(engine.armHeldChisel(onto: action))
        #expect(engine.reservedRerolls == 1 && engine.rerollsRemaining == 1)
        #expect(engine.separate(faceID: life[0].id))
        #expect(engine.reservedRerolls == 0 && engine.rerollsRemaining == 2)
    }

    @Test func adjacentRunsMatchTheRequestedExamplesAndRegroupOnRemoval() async throws {
        let engine = battle([.arrow1, .arrow1, .arrow2, .arrow1, .arrow1, .block])
        try await roll(engine)
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        let separator = try #require(engine.rolled.first { $0.face == .arrow2 })
        engine.placeInPlayBar(faceID: arrows[0].id)
        engine.placeInPlayBar(faceID: arrows[1].id)
        engine.placeInPlayBar(faceID: arrows[2].id)
        #expect(engine.turnPlan.map { $0.faces.count } == [3])
        engine.placeInPlayBar(faceID: separator.id, before: arrows[2].id)
        #expect(engine.turnPlan.map { $0.faces.count } == [2, 1, 1])
        engine.placeInPlayBar(faceID: arrows[3].id)
        #expect(engine.turnPlan.map { $0.faces.count } == [2, 1, 2])
        #expect(engine.turnPlan.map { $0.faces[0].matchFace } == [.arrow1, .arrow2, .arrow1])
        engine.returnToTray(faceID: separator.id)
        #expect(engine.turnPlan.map { $0.faces.count } == [4])
        #expect(Set(engine.turnPlan.flatMap(\.faces).map(\.dieID)).count == 4)
    }

    @Test func movingAMatchingDieAcrossABarrierDoesNotMergeAcrossIt() async throws {
        let engine = battle([.arrow1, .arrow1, .arrow2, .arrow1, .block, .focus])
        try await roll(engine)
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        let separator = try #require(engine.rolled.first { $0.face == .arrow2 })
        for face in arrows { engine.placeInPlayBar(faceID: face.id) }
        engine.placeInPlayBar(faceID: separator.id)
        engine.placeInPlayBar(faceID: arrows[0].id)
        #expect(engine.turnPlan.map { $0.faces.count } == [2, 1, 1])
    }

    @Test func destinationRerollIsSharedByBothDiceAndPersists() throws {
        let first = VoyageNode(id: UUID(), kind: .ferryman, stage: 0, hour: 1, isRevealed: true)
        let second = VoyageNode(id: UUID(), kind: .battle, stage: 0, hour: 1, isRevealed: false)
        let boss = VoyageNode(id: UUID(), kind: .boss, stage: 7, hour: 4, isRevealed: true)
        var voyage = Voyage(nodes: [first, second, boss])
        let firstReroll = voyage.rerollDestination(first.id)
        #expect(firstReroll)
        #expect(voyage.node(second.id) == second)
        #expect(voyage.node(first.id)?.stage == 0)
        #expect(voyage.node(first.id)?.kind.isForced == false)
        let secondReroll = voyage.rerollDestination(second.id)
        #expect(!secondReroll)
        let bossReroll = voyage.rerollDestination(boss.id)
        #expect(!bossReroll)
        let restored = try JSONDecoder().decode(Voyage.self, from: JSONEncoder().encode(voyage))
        #expect(!restored.canReroll(second))
        #expect(restored.nodes == voyage.nodes)
    }

    @Test func oldVoyageSavesDecodeWithoutRerollState() throws {
        let voyage = Voyage.generate()
        let data = try JSONEncoder().encode(voyage)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "rerolledStages")
        let oldData = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(Voyage.self, from: oldData)
        let first = try #require(restored.nodes.first)
        #expect(restored.canReroll(first))
    }

}

