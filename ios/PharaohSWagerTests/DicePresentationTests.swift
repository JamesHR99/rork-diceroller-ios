import Foundation
import Testing
@testable import PharaohSWager

@MainActor
struct DicePresentationTests {
    @Test(arguments: [1, 2, 4, 5, 6, 8, 12])
    func rollStopsStayOrderedAndBounded(count: Int) {
        let stops = (0..<count).map { DiceRollTiming.stopTime(index: $0, count: count) }
        #expect(stops.first == 0.58)
        #expect((stops.last ?? 0) <= 1.18 + 0.000001)
        for (previous, next) in zip(stops, stops.dropFirst()) {
            #expect(next > previous)
            #expect(next - previous <= 0.075 + 0.000001)
        }
        if count <= 6 { #expect((stops.last ?? 0) < 1) }
    }

    @Test(arguments: [1, 4, 6, 12])
    func reducedMotionDoesNotKeepThePlayerWaiting(count: Int) {
        let stop = DiceRollTiming.stopTime(index: count - 1, count: count, reduceMotion: true)
        #expect(stop <= 0.30 + 0.000001)
        #expect(stop < DiceRollTiming.stopTime(index: count - 1, count: count))
    }

    @Test func repeatedTapDoesNotRerollOrChangeTheLanding() async throws {
        let hero = GameData.classes[0]
        let engine = BattleEngine(
            enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: hero.startingLoadout.allDice,
            classID: hero.id, maxHP: hero.maxHP, startHP: hero.maxHP,
            critBonus: 0
        )
        let slotIDs = Set(engine.slots.map(\.id))
        engine.rollAll(reduceMotion: true)
        let rollID = engine.rollID
        let landings = Dictionary(uniqueKeysWithValues: engine.slots.compactMap { slot in
            engine.landingFace(slotID: slot.id).map { (slot.id, $0) }
        })
        #expect(!engine.canCommit)
        #expect(landings.count == slotIDs.count)
        engine.rollAll(reduceMotion: true)
        #expect(engine.rollID == rollID)

        // A generous ceiling lets a loaded simulator schedule the task. The
        // exact presentation budget is covered independently above.
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while engine.isRolling && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(!engine.isRolling)
        #expect(engine.canCommit)
        #expect(Set(engine.slots.map(\.id)) == slotIDs)
        #expect(engine.rolled.count == slotIDs.count)
        #expect(Set(engine.rolled.map(\.id)).count == slotIDs.count)
        for slot in engine.slots {
            guard case .rolled(let face) = slot.state else {
                Issue.record("A reel did not settle")
                continue
            }
            #expect(face.face == landings[slot.id])
            #expect(engine.landingFace(slotID: slot.id) == nil)
        }
    }

    @Test(arguments: [320.0, 354.0, 375.0, 393.0, 768.0])
    func deckNeverClaimsSpaceOutsideTheSafeArea(height: Double) {
        for header in [120.0, 152.0, height + 20] {
            let metrics = BattleDeckMetrics(screenHeight: CGFloat(height), headerHeight: CGFloat(header))
            #expect(metrics.height >= 0)
            #expect(metrics.height <= CGFloat(max(0, height - header)))
            #expect(metrics.planHeight >= 72)
            #expect(metrics.reelHeight >= 60)
        }
    }
}
