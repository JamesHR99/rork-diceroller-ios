//
//  PharaohSWagerTests.swift
//  PharaohSWagerTests
//
//  Created by Rork on July 22, 2026.
//

import Foundation
import Testing
@testable import PharaohSWager

@MainActor
@Suite(.serialized)
struct PharaohSWagerTests {

    @Test func omenWagersExplainTheirActualProgressScaledPayout() throws {
        for id in ["shrine_dive", "gate_spar"] {
            let choice = try #require(EventContent.all.flatMap(\.choices).first { $0.id == id })
            for progress in [0.0, 0.5, 1.0] {
                let detail = choice.displayedDetail(progress: progress)
                #expect(detail.contains("\(EventReward.gambleGold(progress: progress)) gold"))
                if case .gamble(let chance, let damage) = choice.reward {
                    #expect(detail.contains("\(Int((chance * 100).rounded()))%"))
                    #expect(detail.contains("\(damage) damage"))
                } else { Issue.record("Expected a wager") }
            }
        }
        let idol = try #require(EventContent.all.flatMap(\.choices).first { $0.id == "idol_palm" })
        #expect(idol.displayedDetail(progress: 0).contains("god power"))
    }

    private func shrineVisit() throws -> GameManager {
        let game = GameManager()
        game.startRun(with: try #require(GameData.classes.first))
        if game.screen == .tutorial { game.finishBriefing() }
        game.saveAndExit()
        let original = try #require(game.savedRun)
        let first = try #require(original.voyage.nodes.first { $0.stage == 0 })
        var voyage = original.voyage
        voyage.nodes = [VoyageNode(id: first.id, kind: .shrine, stage: 0,
                                   hour: 1, isRevealed: true)] + voyage.nodes.filter { $0.stage != 0 }
        let save = RunSave(classID: original.classID, loadout: original.loadout,
            maxHP: original.maxHP, currentHP: original.currentHP, gold: original.gold,
            critBonus: original.critBonus, equippedBoons: original.equippedBoons,
            legendariesTaken: original.legendariesTaken, acquiredUpgrades: original.acquiredUpgrades,
            capstoneID: original.capstoneID, pairingID: original.pairingID,
            ownedChisels: original.ownedChisels, trialUsed: original.trialUsed,
            voyage: voyage, clearedNodeIDs: [], lastClearedNodeID: nil, currentNodeID: nil,
            deepestHour: 1, usedEventIDs: [], totalDamage: 0, totalCombos: 0, totalCrits: 0,
            savedAt: Date())
        RunSaveStore.save(save)
        let resumed = GameManager()
        resumed.continueRun()
        resumed.enter(try #require(resumed.availableNodes.first))
        return resumed
    }

    @Test func shrineGodOffersSurviveBackAndSave() throws {
        let game = try shrineVisit()
        #expect(game.isShrine)
        #expect(game.visitingDeity == nil)
        game.chooseShrineDeity(.ra)
        let ra = game.rewardOffers
        #expect(!ra.isEmpty)
        game.backToShrineDeities()
        game.chooseShrineDeity(.bes)
        let bes = game.rewardOffers
        game.backToShrineDeities()
        game.chooseShrineDeity(.ra)
        #expect(game.rewardOffers == ra)
        game.saveAndExit()

        let restored = GameManager()
        restored.continueRun()
        #expect(restored.isShrine)
        #expect(restored.visitingDeity == .ra)
        #expect(restored.rewardOffers == ra)
        restored.backToShrineDeities()
        restored.chooseShrineDeity(.bes)
        #expect(restored.rewardOffers == bes)
    }

    @Test func olderSaveWithoutShrineVisitStillDecodes() throws {
        let game = GameManager()
        game.startRun(with: try #require(GameData.classes.first))
        if game.screen == .tutorial { game.finishBriefing() }
        game.saveAndExit()
        let save = try #require(game.savedRun)
        let data = try JSONEncoder().encode(save)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "shrineVisit")
        let older = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(RunSave.self, from: older)
        #expect(decoded.shrineVisit == nil)
        #expect(decoded.classID == save.classID)
    }

    private func combatReward() throws -> (GameManager, Offer) {
        let game = GameManager()
        let hero = try #require(GameData.classes.first)
        game.startRun(with: hero)
        if game.screen == .tutorial { game.finishBriefing() }
        let battle = try #require(game.battle)
        #expect(battle.enemies.first?.def.id == EnemyContent.trainingDummy.id)
        // Exercise the reward transition without relying on random dice rolls.
        game.concludeBattle()
        return (game, try #require(game.rewardOffers.first))
    }

    @Test func draftReplacementCanBeCancelledThenConfirmed() throws {
        let (game, offer) = try combatReward()
        let original = try #require(game.loadout)
        let old = try #require(original.allDice.first)
        game.replaceDraftDie(with: offer)
        #expect(game.replacingDraftDie)
        game.cancelSelection()
        #expect(game.screen == .reward)
        #expect(game.loadout == original)
        #expect(game.rewardOffers.contains { $0.id == offer.id })

        game.replaceDraftDie(with: offer)
        guard case .swapDie(let incoming) = game.pendingSelection else {
            Issue.record("Expected a die replacement")
            return
        }
        game.applySwap(replacing: UUID(), with: incoming)
        #expect(game.loadout == original)
        game.applySwap(replacing: old.id, with: incoming)
        #expect(game.loadout?.diceCount == original.diceCount)
        #expect(game.loadout?.die(id: old.id) == nil)
        #expect(game.loadout?.die(id: incoming.id) != nil)
        #expect(!game.replacingDraftDie)
        #expect(game.screen == .chart)
    }

    @Test func draftCanStillGrowTheBag() throws {
        let (game, offer) = try combatReward()
        let count = try #require(game.loadout?.diceCount)
        game.claimReward(offer)
        #expect(game.loadout?.diceCount == count + 1)
        #expect(game.screen == .chart)
    }

    @Test func openingBriefingStaysShortAccurateAndDecisionFocused() {
        for hero in GameData.classes {
            let pages = BriefingPage.pages(for: hero)
            let copy = pages.map { "\($0.title) \($0.body)" }.joined(separator: " ")
            #expect(pages.count == 4)
            #expect(pages.first?.id == "order")
            #expect(pages.last?.id == "progression")
            #expect(!copy.localizedCaseInsensitiveContains("drag dice"))
            #expect(!copy.localizedCaseInsensitiveContains("use minus"))
            #expect(copy.contains("\(BattleRules.handSize)"))
            #expect(copy.localizedCaseInsensitiveContains("skip"))
        }
    }

}
