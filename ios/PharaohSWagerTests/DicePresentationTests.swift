import Foundation
import Testing
@testable import PharaohSWager

@MainActor
struct DicePresentationTests {
    @Test(arguments: [1, 2, 4, 5, 6, 8, 12])
    func rollStopsStayOrderedAndBounded(count: Int) {
        let stops = (0..<count).map { DiceRollTiming.stopTime(index: $0, count: count) }
        #expect(stops.first == 0.82)
        #expect((stops.last ?? 0) <= 1.78 + 0.000001)
        for (previous, next) in zip(stops, stops.dropFirst()) {
            #expect(next > previous)
            #expect(next - previous <= 0.16 + 0.000001)
        }
        if count <= 6 { #expect((stops.last ?? 0) <= 1.62 + 0.000001) }
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
        let deadline = clock.now.advanced(by: .seconds(15))
        while engine.isRolling && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(!engine.isRolling)
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

    @Test(arguments: ["archer", "warrior", "rogue", "magician"])
    func largerCombosOwnLongerClassPerformances(classID: String) {
        let durations = (1...5).map { BattleAnimationTiming.playerDuration(classID: classID, power: $0) }
        for (small, large) in zip(durations, durations.dropFirst()) {
            #expect(large > small)
        }
        #expect(durations.last! - durations.first! >= 0.65)
    }

    @Test func contactTimingIncludesProjectileFlightAndVolleyCadence() {
        let solo = BattleAnimationTiming.contactDelay(faces: [.runeFire])
        let volley = BattleAnimationTiming.contactDelay(faces: [.arrow1, .arrow2, .arrow3])
        #expect(solo >= FaceKind.runeFire.projectile!.flight)
        #expect(volley >= FaceKind.arrow3.projectile!.flight + 0.24)
        #expect(BattleAnimationTiming.contactDelay(faces: [.overhead]) == 0.22)
    }

    @Test func repeatedFoePoseStillRestartsAnimation() {
        var foe = EnemyState(def: EnemyContent.enemy(hour: 1, isHerald: false))
        foe.animate(.attack, power: 2)
        let first = foe.animationID
        foe.animate(.attack, power: 4)
        #expect(foe.animationID == first + 1)
        #expect(foe.actionPower == 4)
    }
}
