import Foundation
import Testing
@testable import PharaohSWager

@MainActor
struct BattleLoopTests {
    private func battle(_ faces: [FaceKind], classID: String = "archer", startHP: Int = 100, boons: [String] = [], chisels: Set<String> = [], patron: Deity? = nil) -> BattleEngine {
        let move = EnemyMove(id: "two-hits", name: "Two hits", faces: [.swiftSlash, .swiftSlash], weight: 1, damage: 24)
        let enemy = EnemyDef(id: "test-foe", name: "Practice foe", title: "Tests", maxHP: 500,
            symbol: "circle", goldReward: 0, moves: [move])
        let dice = faces.enumerated().map { index, face in
            Die(name: "Test \(index)", slot: face.isAttack ? .weapon : .armor, faces: Array(repeating: face, count: 6), patron: patron)
        }
        return BattleEngine(enemies: [enemy], dice: dice, classID: classID, maxHP: 100, startHP: startHP,
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
        if engine.phase == .player, engine.canCommit {
            engine.commitTurn()
            let actionDeadline = ContinuousClock().now.advanced(by: .seconds(30))
            while engine.phase != .player && engine.phase != .won && engine.phase != .lost
                    && ContinuousClock().now < actionDeadline {
                try await Task.sleep(for: .milliseconds(20))
            }
        }
        if engine.phase == .player { engine.endPlayerTurn() }
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(45))
        while engine.turnNumber == previousTurn && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.turnNumber == previousTurn + 1 || engine.phase == .won || engine.phase == .lost)
        if engine.phase != .won && engine.phase != .lost { #expect(engine.phase == .player) }
    }



    @Test(arguments: [false, true])
    func ordinaryGuardExpiresOnBothSidesExceptBesRetention(bes: Bool) async throws {
        let move = EnemyMove(id: "guard", name: "Guard", faces: [.block], weight: 1, block: 8)
        let foe = EnemyDef(id: "guard-test", name: "Guard", title: "Test", maxHP: 500,
            symbol: "circle", goldReward: 0, moves: [move])
        let dice = (0..<6).map { Die(name: "Block \($0)", slot: .armor, faces: Array(repeating: .block, count: 6)) }
        let engine = BattleEngine(enemies: [foe], dice: dice, classID: "archer",
            maxHP: 100, startHP: 100, critBonus: -1,
            boons: bes ? [EquippedBoon(defID: "BE-U1", rarity: .common, level: 1)] : [])
        try await roll(engine)
        let face = try #require(engine.rolled.first)
        engine.placeInPlayBar(faceID: face.id)
        try await nextRound(engine)
        #expect(engine.playerShield == (bes ? 8 : 0))
        let enemyGuard = engine.enemies[0].shield
        #expect(enemyGuard == 0)
        try await roll(engine)
        try await nextRound(engine)
        #expect(engine.playerShield == (bes ? 8 : 0))
        #expect(engine.enemies[0].shield == 0)
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

    @Test func playingAnActionSpendsOnlyItsDice() async throws {
        let engine = battle(Array(repeating: .block, count: 10))
        try await roll(engine)
        let before = engine.rolled.count
        let face = try #require(engine.rolled.first)
        engine.placeInPlayBar(faceID: face.id)
        engine.commitTurn()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(20))
        while engine.phase != .player && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.rolled.count == before - 1)
        #expect(engine.resolveRemaining == 2)
        #expect(engine.canEndTurn)
    }

    @Test func selectiveRerollResetsEachTurnInsteadOfChargingFromUnusedDice() async throws {
        let engine = battle(Array(repeating: .block, count: 10))
        try await roll(engine)
        #expect(engine.rerollsRemaining == 1)
        let first = try #require(engine.slots.first)
        engine.selectingReroll = true
        engine.reroll(slotID: first.id, reduceMotion: true)
        try await settled(engine)
        #expect(engine.rerollsRemaining == 0)
        #expect(engine.pendingRerollHalfCharges == 0)
        try await nextRound(engine)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.rerollHalfCharges == 2)
    }

    @Test func resolveIsSpentByImmediateActionsAndResetsNextTurn() async throws {
        let engine = battle(Array(repeating: .block, count: 10))
        try await roll(engine)
        let face = try #require(engine.rolled.first)
        engine.placeInPlayBar(faceID: face.id)
        #expect(engine.plannedResolveCost == 1)
        engine.commitTurn()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(20))
        while engine.phase != .player && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.resolveRemaining == 2)
        engine.endPlayerTurn()
        while engine.turnNumber == 1 && clock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(engine.resolveRemaining == 3)
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
    func startingLoadoutsUseTenPhysicalDiceAndDrawFive(classID: String) {
        let hero = GameData.heroClass(id: classID)
        #expect(hero.startingLoadout.allDice.count == 10)
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: hero.startingLoadout.allDice, classID: classID, maxHP: hero.maxHP, startHP: hero.maxHP, critBonus: 0)
        #expect(Set(engine.slots.map { $0.die.id }).count == 5)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.rerollHalfCharges == 2)
        #expect(engine.resolveRemaining == 3)
        #expect(engine.drawBag.count == 5)
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
        #expect(engine.rolled.count == 5)
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
        #expect(engine.timeline.filter(\.isPlayer).count == 5)
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
        #expect(engine.rolled.isEmpty && engine.slots.count == 5)
        #expect(engine.rerollsRemaining == 1)
        #expect(engine.resolveRemaining == 3)
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

    @Test func partialEvadeMultipliesWithOtherReductionsAndNeverBecomesImmunity() {
        #expect(BattleRules.splitHits(25, count: 2) == [13, 12])
        #expect(BattleRules.splitHits(26, count: 3) == [10, 8, 8])
        #expect(BattleRules.reducedHit(20, evadePercent: 50) == 10)
        #expect(BattleRules.reducedHit(20, weaken: 0.2, evadePercent: 50) == 8)
        #expect(BattleRules.reducedHit(100, weaken: 0.2, ward: 0.2, evadePercent: 50) == 32)
        #expect(BattleRules.reducedHit(20, evadePercent: 100) == 5)
        #expect(BattleRules.reducedHit(1, evadePercent: 75) == 1)
        #expect(BattleRules.reducedHit(0, evadePercent: 75) == 0)
    }

    @Test func besRetentionPreservesButDoesNotGenerateGuard() {
        #expect(BattleRules.guardAfterRound(72) == 0)
        #expect(BattleRules.guardAfterRound(72, retention: 8) == 8)
        #expect(BattleRules.guardAfterRound(3, retention: 8) == 3)
        #expect(BattleRules.guardAfterRound(0, retention: 8) == 0)
        #expect(BattleRules.guardAfterRound(72, warrior: true) == 0)
    }

    @Test func bonusRerollsHaveOneSharedHalfChargeBudget() {
        #expect(BattleRules.bonusRerollAward(currentHalfCharges: 0, alreadyAwarded: 0) == 1)
        #expect(BattleRules.bonusRerollAward(currentHalfCharges: 0, alreadyAwarded: 1) == 0)
        #expect(BattleRules.bonusRerollAward(currentHalfCharges: 4, alreadyAwarded: 0) == 0)
        #expect(BattleRules.bonusRerollAward(currentHalfCharges: 3, alreadyAwarded: 0) == 1)
    }

    @Test func changedCatalogueKeepsStableIDsAndHonestScaling() throws {
        #expect(GodCatalog.regulars.count == 60)
        #expect(GodCatalog.duos.count == 15)
        #expect(GodCatalog.legendaries.count == 6)
        #expect(Set(GodCatalog.all.map(\.id)).count == GodCatalog.all.count)
        for id in ["HO-D2", "BA-D1", "LG-BA"] {
            let def = try #require(GodCatalog.boon(id))
            #expect(def.scales == .evadePercent)
            #expect(def.resolved(rarity: .common, level: 1).evadePercent == 10)
            #expect(def.resolved(rarity: .common, level: 3).evadePercent == 20)
            #expect(def.resolved(rarity: .epic, level: 3).evadePercent == 30)
            #expect(!def.text(rarity: .epic, level: 3).contains("%V"))
        }
        #expect(GodCatalog.boon("SO-D3")?.trigger == .onNativeHeal)
        #expect(GodCatalog.boon("SO-U2")?.trigger == .onEffectiveHeal)
        #expect(GodCatalog.boon("BE-A2")?.trigger == .onShieldAbsorb)
        #expect(GodCatalog.boon("BA-A4")?.trigger == .onDodge)
        #expect(GodCatalog.boon("AN-U1")?.requires == nil)
    }

    @Test func oneEvadeOnlyReducesItsAssignedHitAndExpires() async throws {
        let engine = battle([.evade, .block, .block, .block, .block, .block])
        try await roll(engine)
        let evade = try #require(engine.rolled.first { $0.face == .evade })
        engine.placeInPlayBar(faceID: evade.id)
        let damage = engine.projectedRoundTotals(for: engine.enemies[0]).damage
        let firstHit = damage - damage / 2
        try await nextRound(engine)
        #expect(engine.playerHP == 100 - damage + firstHit - BattleRules.reducedHit(firstHit, evadePercent: 50))
        #expect(engine.dodgeCharges == 0)
    }

    @Test func riverSlipHealsAfterPartialDamage() async throws {
        let engine = battle([.evade, .block, .block, .block, .block, .block], startHP: 50, boons: ["SO-D2"])
        try await roll(engine)
        let evade = try #require(engine.rolled.first { $0.face == .evade })
        engine.placeInPlayBar(faceID: evade.id)
        let damage = engine.projectedRoundTotals(for: engine.enemies[0]).damage
        let firstHit = damage - damage / 2
        try await nextRound(engine)
        #expect(engine.playerHP == 50 - damage + firstHit - BattleRules.reducedHit(firstHit, evadePercent: 50) + 3)
    }

    @Test(arguments: [false, true])
    func patientHunterRequiresActualHealing(wounded: Bool) async throws {
        let engine = battle([.heal, .arrow1, .block, .block, .block, .block],
            startHP: wounded ? 50 : 100, boons: ["SO-U2"])
        try await roll(engine)
        let heal = try #require(engine.rolled.first { $0.face == .heal })
        let attack = try #require(engine.rolled.first { $0.face == .arrow1 })
        engine.placeInPlayBar(faceID: heal.id)
        engine.placeInPlayBar(faceID: attack.id)
        let damage = try #require(engine.turnPlan.last).damage
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == 500 - damage - (wounded ? 6 : 0))
    }

    @Test(arguments: ["BE-A2", "BA-A4"])
    func defensiveReactionsEmpowerTheFollowingAttack(boon: String) async throws {
        let defence: FaceKind = boon == "BE-A2" ? .block : .evade
        let engine = battle([defence, .arrow1, .focus, .focus, .focus, .focus], boons: [boon])
        try await roll(engine)
        let guardFace = try #require(engine.rolled.first { $0.face == defence })
        let attack = try #require(engine.rolled.first { $0.face == .arrow1 })
        engine.placeInPlayBar(faceID: guardFace.id)
        engine.placeInPlayBar(faceID: attack.id)
        let damage = try #require(engine.turnPlan.last).damage
        try await nextRound(engine)
        #expect(engine.enemies[0].hp == 500 - damage - 6)
    }

    @Test func thermalAndLightFeetCannotDoubleTheBonusCharge() async throws {
        let engine = battle([.evade, .arrow1, .arrow2, .arrow3, .block, .focus], boons: ["HO-U1", "BA-U1"])
        try await roll(engine)
        engine.gainRerollHalfCharges(2)
        let focus = try #require(engine.slots.first { slot in
            if case .rolled(let face) = slot.state { return face.face == .focus }
            return false
        })
        engine.selectingReroll = true
        engine.reroll(slotID: focus.id, reduceMotion: true)
        try await settled(engine)
        let evade = try #require(engine.rolled.first { $0.face == .evade })
        engine.placeInPlayBar(faceID: evade.id)
        for face in engine.rolled where face.id != evade.id { engine.placeInPlayBar(faceID: face.id) }
        #expect(engine.pendingRerollHalfCharges == 0)
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == 1)
    }

    @Test(arguments: [5, 6])
    func bankedEmbersRequiresAnUnusedDie(played: Int) async throws {
        let engine = battle(Array(repeating: .arrow1, count: 6), boons: ["RA-U2"])
        try await roll(engine)
        for face in engine.rolled.prefix(played) { engine.placeInPlayBar(faceID: face.id) }
        try await nextRound(engine)
        #expect(engine.rerollHalfCharges == (played == 5 ? 2 : 0))
    }

    @Test func lastMeasureAddsJudgementWithoutRequiringAllSixDice() async throws {
        let engine = battle([.arrow1, .arrow2, .block, .block, .block, .block], boons: ["AN-A2", "AN-U1"])
        try await roll(engine)
        for kind in [FaceKind.arrow1, .arrow2] {
            let face = try #require(engine.rolled.first { $0.face == kind })
            engine.placeInPlayBar(faceID: face.id)
        }
        try await nextRound(engine)
        #expect(engine.enemies[0].judgementAmount == 6)
    }

    @Test func nativeHealingGetsOnlyOneSetOfSobekExtrasPerRound() async throws {
        let engine = battle([.heal, .focus, .heal, .block, .block, .block],
            startHP: 20, boons: ["SO-D3", "SO-U1"])
        try await roll(engine)
        let heals = engine.rolled.filter { $0.face == .heal }
        let focus = try #require(engine.rolled.first { $0.face == .focus })
        engine.placeInPlayBar(faceID: heals[0].id)
        engine.placeInPlayBar(faceID: focus.id)
        engine.placeInPlayBar(faceID: heals[1].id)
        let damage = engine.projectedRoundTotals(for: engine.enemies[0]).damage
        let hits = BattleRules.splitHits(damage, count: 2)
        let softened = hits.reduce(0) { $0 + BattleRules.reducedHit($1, weaken: 0.2) }
        try await nextRound(engine)
        #expect(engine.playerHP == 20 + 8 + 7 - softened + 8)
    }

}
