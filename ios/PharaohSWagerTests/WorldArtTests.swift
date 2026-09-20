import XCTest
import UIKit
@testable import PharaohSWager

@MainActor
final class WorldArtTests: XCTestCase {
    func testEveryEnemyHasAnEffectFamily() {
        for enemy in InkTechniqueArt.enemies {
            XCTAssertNotNil(InkWorldArt.enemyFamily(enemy), enemy)
            XCTAssertEqual(InkWorldArt.enemyFamily(enemy + "_armoured"), InkWorldArt.enemyFamily(enemy))
        }
        XCTAssertNil(InkWorldArt.enemyFamily("unknown"))
        XCTAssertEqual(InkWorldArt.projectileIndex(.fireOrb, enemy: "apep"), 10)
        XCTAssertEqual(InkWorldArt.projectileIndex(.frostShard, enemy: "marshShade"), 4)
        XCTAssertEqual(InkWorldArt.impactIndex(.blunt), 2)
        XCTAssertEqual(InkWorldArt.impactIndex(.lattice, enemy: "hourEater"), 12)
        XCTAssertEqual(InkWorldArt.impactIndex(.bleedTick, enemy: "apep"), 15)
    }

    func testAllHeroProjectileFormsHaveDistinctDrawings() {
        let forms: [ProjectileForm] = [.arrow, .crescent, .tumblingBlade, .fireOrb, .frostShard,
                                       .lifeMotes, .arcaneBolt, .lightning, .venomFlask]
        XCTAssertEqual(Set(forms.map { InkWorldArt.projectileIndex($0) }).count, 9)
    }

    func testWorldImagesResolveWhenInstalled() throws {
        for name in ["ink_title_battle", "ink_regions", "ink_foregrounds", "ink_projectiles", "ink_impacts"] {
            guard UIImage(named: name) != nil else { throw XCTSkip("Install the Complete-Duat-Art ZIP: missing \(name)") }
        }
        for name in ["ink_projectiles", "ink_impacts"] {
            for index in 0..<16 { XCTAssertNotNil(InkWorldArt.cell(name, index: index)) }
            XCTAssertNil(InkWorldArt.cell(name, index: -1))
            XCTAssertNil(InkWorldArt.cell(name, index: 16))
        }
        for index in 0..<3 {
            XCTAssertNotNil(InkWorldArt.cell("ink_foregrounds", index: index, columns: 1, rows: 3))
            XCTAssertNotNil(InkArt.image("ink.region.\(index)"))
        }
    }
}
