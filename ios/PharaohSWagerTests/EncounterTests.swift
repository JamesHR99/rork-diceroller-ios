import XCTest
import SwiftUI
@testable import PharaohSWager

@MainActor
final class EncounterTests: XCTestCase {
    private var previousSave: RunSave?
    override func setUp() async throws {
        try await super.setUp()
        previousSave = RunSaveStore.load()
    }
    override func tearDown() async throws {
        if let previousSave { RunSaveStore.save(previousSave) } else { RunSaveStore.clear() }
        try await super.tearDown()
    }

    private func prepared(_ kind: StageKind = .omen, rerolls: Int = 1,
                          spun: Bool = true, hp: Int = 50, gold: Int = 500) -> GameManager {
        let hero = GameData.heroClass(id: "archer")
        let previous = VoyageNode(id: UUID(), kind: .battle, stage: 0, hour: 1, isRevealed: true)
        let next = VoyageNode(id: UUID(), kind: kind, stage: 1, hour: 1, isRevealed: true)
        let voyage = Voyage(nodes: [previous, next], pathRerolls: rerolls,
            wheelResults: spun ? [1: Voyage.wheelKinds.firstIndex(of: kind)!] : [:])
        RunSaveStore.save(RunSave(classID: hero.id, loadout: hero.startingLoadout,
            maxHP: hero.maxHP, currentHP: hp, gold: gold, critBonus: 0,
            equippedBoons: [], legendariesTaken: 0, acquiredUpgrades: [], capstoneID: nil,
            pairingID: nil, ownedChisels: [], trialUsed: false, voyage: voyage,
            clearedNodeIDs: [previous.id], lastClearedNodeID: previous.id, currentNodeID: nil,
            deepestHour: 1, usedEventIDs: [], totalDamage: 0, totalCombos: 0, totalCrits: 0,
            savedAt: Date()))
        let game = GameManager()
        game.continueRun()
        return game
    }

    func testOneInitialChargeConsumedAcrossStopsAndRestoredOnlyByRewards() throws {
        var voyage = Voyage.generate()
        XCTAssertEqual(voyage.rerollsRemaining, 1)
        XCTAssertNotNil(voyage.spin(stage: 1))
        XCTAssertEqual(voyage.rerollsRemaining, 1)
        XCTAssertNil(voyage.spin(stage: 1)) // No repeat free spins.
        XCTAssertNotNil(voyage.spin(stage: 1, usingReroll: true))
        XCTAssertEqual(voyage.rerollsRemaining, 0)
        XCTAssertNotNil(voyage.spin(stage: 2)) // Next stop does not refill.
        XCTAssertNil(voyage.spin(stage: 2, usingReroll: true))
        XCTAssertEqual(voyage.grantPathRerolls(9), 3)
        XCTAssertEqual(voyage.grantPathRerolls(1), 0)
        XCTAssertEqual(voyage.grantPathRerolls(-2), 0)
        for _ in 0..<3 { XCTAssertNotNil(voyage.spin(stage: 2, usingReroll: true)) }
        XCTAssertEqual(voyage.rerollsRemaining, 0)
        let restored = try JSONDecoder().decode(Voyage.self, from: JSONEncoder().encode(voyage))
        XCTAssertEqual(restored, voyage)
    }

    func testForcedMilestonesAndOpeningCannotSpinAndAllWedgesAlign() {
        var voyage = Voyage.generate()
        XCTAssertNil(voyage.spin(stage: 0))
        for stage in [3, 7, 11, 15, 19, 23] {
            XCTAssertNil(voyage.spin(stage: stage))
            XCTAssertNil(voyage.spin(stage: stage, usingReroll: true))
        }
        for index in Voyage.wheelKinds.indices {
            XCTAssertEqual(Double(index) * Voyage.wedgeDegrees + Voyage.rotation(for: index), 0)
        }
        XCTAssertEqual(voyage.rerollsRemaining, 1)
        XCTAssertEqual(voyage.nodes.count, 24)
    }

    func testOldTwoChannelSaveCollapsesWithoutLosingNodeIdentity() throws {
        let game = prepared(spun: false)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(try XCTUnwrap(game.savedRun))) as? [String: Any])
        var voyage = try XCTUnwrap(object["voyage"] as? [String: Any])
        voyage.removeValue(forKey: "pathRerolls")
        voyage.removeValue(forKey: "wheelResults")
        object.removeValue(forKey: "encounter")
        voyage["rerolledStages"] = [0]
        object["voyage"] = voyage
        let oldSave = try JSONDecoder().decode(RunSave.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(oldSave.voyage.rerollsRemaining, 1)
        var restored = oldSave.voyage
        let original = try XCTUnwrap(restored.nodes(inStage: 1).first)
        restored.nodes.append(VoyageNode(id: UUID(), kind: .battle, stage: 1, hour: 1, isRevealed: false))
        XCTAssertNotNil(restored.spin(stage: 1))
        XCTAssertEqual(restored.nodes(inStage: 1).count, 1)
        XCTAssertEqual(restored.nodes(inStage: 1).first?.id, original.id)
    }

    func testSpinAndSpendAreSavedBeforeAnimationAndCannotBeUndoneByResume() throws {
        let game = prepared(spun: false)
        game.enter(try XCTUnwrap(game.availableNodes.first))
        XCTAssertEqual(game.screen, .chart)
        let result = try XCTUnwrap(game.spinEncounterWheel())
        XCTAssertEqual(game.wheelResult, result)
        XCTAssertNotNil(game.spinEncounterWheel(usingReroll: true))
        let locked = game.wheelResult
        game.saveAndExit()
        let resumed = GameManager(); resumed.continueRun()
        XCTAssertEqual(resumed.wheelResult, locked)
        XCTAssertEqual(resumed.pathRerolls, 0)
        XCTAssertNil(resumed.spinEncounterWheel())
        XCTAssertNil(resumed.spinEncounterWheel(usingReroll: true))
    }

    func testOmenHasThreeFreeHiddenChoicesAndGrantsOnlyOnceAcrossResume() throws {
        let game = prepared()
        game.enter(try XCTUnwrap(game.availableNodes.first))
        let event = try XCTUnwrap(game.currentEvent)
        XCTAssertEqual(event.choices.count, 3)
        XCTAssertEqual(Set(event.choices.map(\.id)).count, 3)
        XCTAssertTrue(event.choices.allSatisfy { $0.goldCost == 0 && $0.hpCost == 0 && $0.maxHPChange == 0 })
        let reroll = try XCTUnwrap(event.choices.first { $0.reward == .pathRerolls(1) })
        game.choose(reroll)
        XCTAssertEqual(game.pathRerolls, 2)
        XCTAssertNotNil(game.eventOutcome)
        game.choose(reroll)
        XCTAssertEqual(game.pathRerolls, 2)
        game.saveAndExit()
        let resumed = GameManager(); resumed.continueRun()
        XCTAssertEqual(resumed.screen, .event)
        XCTAssertEqual(resumed.currentEvent, event)
        resumed.choose(reroll)
        XCTAssertEqual(resumed.pathRerolls, 2)
        XCTAssertNotNil(resumed.eventOutcome)
        resumed.leaveEncounter()
        XCTAssertEqual(resumed.pathRerolls, 2)
    }

    func testFullOmenRerollsConvertToGold() throws {
        let game = prepared(rerolls: 3)
        game.enter(try XCTUnwrap(game.availableNodes.first))
        let choice = try XCTUnwrap(game.currentEvent?.choices.first { $0.reward == .pathRerolls(1) })
        let before = game.gold
        game.choose(choice)
        XCTAssertEqual(game.pathRerolls, 3)
        XCTAssertEqual(game.gold, before + 25)
    }

    func testShopStockPurchasesCapsAndPersistence() throws {
        let game = prepared(.ferryman, rerolls: 2)
        game.enter(try XCTUnwrap(game.availableNodes.first))
        let original = game.shopStock
        XCTAssertTrue(original.allSatisfy { $0.price > 0 })
        XCTAssertEqual(original.filter { if case .reforge = $0.kind { true } else { false } }.count, 2)
        let reroll = try XCTUnwrap(original.first { if case .pathRerolls = $0.kind { true } else { false } })
        let before = game.gold
        game.purchase(reroll)
        XCTAssertEqual(game.pathRerolls, 3)
        XCTAssertEqual(game.gold, before - reroll.price)
        game.purchase(reroll)
        XCTAssertEqual(game.gold, before - reroll.price)
        let stock = game.shopStock
        game.saveAndExit()
        let resumed = GameManager(); resumed.continueRun()
        XCTAssertEqual(resumed.screen, .shop)
        XCTAssertEqual(resumed.shopStock, stock)
        XCTAssertEqual(resumed.pathRerolls, 3)
        XCTAssertFalse(resumed.shopStock.contains(reroll))
    }

    func testFullRerollsOrHealthAndInsufficientGoldDoNotCharge() throws {
        let game = prepared(.ferryman, rerolls: 3, hp: GameData.heroClass(id: "archer").maxHP)
        game.enter(try XCTUnwrap(game.availableNodes.first))
        let blocked = game.shopStock.filter { offer in
            switch offer.kind { case .heal, .pathRerolls: true; default: false }
        }
        let before = game.gold
        for offer in blocked { XCTAssertFalse(game.canPurchase(offer)); game.purchase(offer) }
        XCTAssertEqual(game.gold, before)
        let poor = prepared(.ferryman, gold: 0)
        poor.enter(try XCTUnwrap(poor.availableNodes.first))
        for offer in poor.shopStock { poor.purchase(offer) }
        XCTAssertEqual(poor.gold, 0)
        XCTAssertEqual(poor.pathRerolls, 1)
    }

    func testFacePurchaseResumesTargetingAndCancellationRefundsOnce() throws {
        let game = prepared(.ferryman)
        game.enter(try XCTUnwrap(game.availableNodes.first))
        let offer = try XCTUnwrap(game.shopStock.first { if case .reforge = $0.kind { true } else { false } })
        let before = game.gold
        game.purchase(offer)
        XCTAssertNotNil(game.pendingSelection)
        game.saveAndExit()
        let resumed = GameManager(); resumed.continueRun()
        XCTAssertNotNil(resumed.pendingSelection)
        XCTAssertEqual(resumed.gold, before - offer.price)
        resumed.cancelSelection()
        XCTAssertEqual(resumed.gold, before)
        XCTAssertTrue(resumed.shopStock.contains(offer))
        resumed.cancelSelection()
        XCTAssertEqual(resumed.gold, before)
    }

    func testMarketBoonRoundTripsAndKeepsPaidPrice() throws {
        let def = try XCTUnwrap(GodCatalog.regulars(of: .ra).first)
        let offer = Offer(name: def.name, detail: "Gift", symbol: def.god.symbol,
            rarity: .rare, comboHint: "Test", price: 90, kind: .boon(def, .common), deity: .ra)
        let snapshot = try XCTUnwrap(MarketOfferSave(offer))
        let decoded = try JSONDecoder().decode(MarketOfferSave.self, from: JSONEncoder().encode(snapshot))
        XCTAssertEqual(decoded.offer, offer)
    }

    func testEncounterScreensAtSmallIPhoneLandscapeSize() async throws {
        let game = prepared(.omen, spun: false)
        try await capture(NightChartView().environment(game), name: "Encounter-wheel-ready")
        _ = game.spinEncounterWheel()
        try await capture(NightChartView().environment(game), name: "Encounter-wheel-locked")
        let omen = prepared(.omen)
        omen.enter(try XCTUnwrap(omen.availableNodes.first))
        try await capture(EventView().environment(omen), name: "Three-sealed-omens")
        let choice = try XCTUnwrap(omen.currentEvent?.choices.first { $0.reward == .pathRerolls(1) })
        omen.choose(choice)
        try await capture(EventView().environment(omen), name: "Omen-revealed")
        let shop = prepared(.ferryman)
        shop.enter(try XCTUnwrap(shop.availableNodes.first))
        try await capture(ShopView().environment(shop), name: "Ferryman-market")
    }

    private func capture<V: View>(_ view: V, name: String) async throws {
        let size = CGSize(width: 660, height: 320)
        let host = UIHostingController(rootView: view.frame(width: size.width, height: size.height)
            .background(Theme.bg).ignoresSafeArea())
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(500))
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
