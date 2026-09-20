import XCTest
@testable import PharaohSWager

@MainActor
final class CombatArtTests: XCTestCase {
    private func requireExpandedSprites() throws {
        for name in ["ink.heroAction.archer.0", "ink.heroSpecial.archer.0", "ink.foeGuard.reedLurker", "ink.foeHurt.reedLurker", "ink.apep.0.0"] {
            guard InkArt.image(name) != nil else {
                throw XCTSkip("Install DiceRoller-Combat-Art-Expansion.zip as described in docs/combat-art-install.md, then rerun the asset tests.")
            }
        }
    }

    func testEveryHeroHasDedicatedReactionsAndFinisher() throws {
        try requireExpandedSprites()
        for hero in InkArt.heroes {
            var names: Set<String> = []
            for key in [FrameKey.idle, .windup, .strike, .guardUp, .hurt, .dodge, .finisher, .victory, .defeat] {
                let name = try XCTUnwrap(InkArt.hero(hero, key))
                let image = try XCTUnwrap(InkArt.image(name), "Missing \(hero) \(key)")
                XCTAssertGreaterThan(image.size.width, 100)
                XCTAssertEqual(image.size.height, 380, accuracy: 1)
                names.insert(name)
            }
            XCTAssertEqual(names.count, 9, "Reactions must not silently alias idle")
        }
    }

    func testEnemyReactionsAndApepStagesResolve() throws {
        try requireExpandedSprites()
        for enemy in InkArt.enemies {
            var names: Set<String> = []
            for key in [FrameKey.idle, .strike, .guardUp, .hurt] {
                let name = try XCTUnwrap(InkArt.foe(enemy, key: key))
                XCTAssertNotNil(InkArt.image(name))
                names.insert(name)
            }
            XCTAssertEqual(names.count, 4)
        }
        let stages = ["apep_head", "apep_coils", "apep_maw"]
        let names = try stages.map { try XCTUnwrap(InkArt.foe("apep", stageID: $0)) }
        XCTAssertEqual(Set(names).count, 3)
        for name in names { XCTAssertNotNil(InkArt.image(name)) }
        XCTAssertNil(InkArt.image("ink.apep.3.0"))
        XCTAssertNil(InkArt.image("ink.heroAction.archer.6"))
    }

    func testSixDiceAndMixedContactsUseOneSchedule() {
        let faces: [FaceKind] = [.overhead, .arrow1, .block, .runeFire, .daggerThrow, .arrow3]
        let contacts = BattleAnimationTiming.contacts(faces: faces)
        XCTAssertEqual(contacts.map(\.face), [.overhead, .arrow1, .runeFire, .daggerThrow, .arrow3])
        XCTAssertEqual(contacts.last!.delay, 0.6, accuracy: 0.0001)
        XCTAssertEqual(BattleAnimationTiming.contactDelay(faces: faces), 0.8, accuracy: 0.0001)
        XCTAssertEqual(BattleAnimationTiming.contacts(faces: Array(repeating: .arrow1, count: 6)).count, 6)
        XCTAssertEqual(BattleAnimationTiming.contacts(faces: Array(repeating: .arrow1, count: 20)).count, 6)
    }

    func testAttackRecipesHaveDifferentMotionAndDefensiveLeadIns() {
        let overhead = CombatChoreography(faces: [.overhead]).score(pose: .attack, weapon: .axe, power: 3)
        let sweep = CombatChoreography(faces: [.sideSwing]).score(pose: .attack, weapon: .axe, power: 3)
        XCTAssertNotEqual(overhead, sweep)
        let recipe = CombatChoreography(faces: [.swiftSlash], grantsGuard: true, grantsEvade: true)
        let score = recipe.score(pose: .attack, weapon: .blades, power: 5)
        XCTAssertEqual(Array(score.prefix(2)).map(\.key), [.dodge, .guardUp])
        XCTAssertTrue(score.contains { $0.key == .finisher })
        XCTAssertFalse(recipe.score(pose: .attack, weapon: .blades, power: 2).contains { $0.key == .finisher })
        XCTAssertTrue(score.allSatisfy { $0.hold > 0 && $0.hold.isFinite })
    }
}
