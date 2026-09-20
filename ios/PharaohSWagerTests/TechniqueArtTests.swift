import XCTest
import UIKit
@testable import PharaohSWager

@MainActor
final class TechniqueArtTests: XCTestCase {
    func testAttackAndGuardSelection() {
        XCTAssertEqual(InkTechniqueArt.heroRow("archer", key: .strike, action: .init(faces: [.bowSmack]), power: 1), 2)
        XCTAssertEqual(InkTechniqueArt.heroRow("warrior", key: .strike, action: .init(faces: [.sideSwing]), power: 1), 1)
        XCTAssertEqual(InkTechniqueArt.heroRow("rogue", key: .strike, action: .init(faces: [.daggerThrow]), power: 1), 1)
        XCTAssertEqual(InkTechniqueArt.heroRow("magician", key: .strike, action: .init(faces: [.runeFrost]), power: 1), 1)
        XCTAssertEqual(InkTechniqueArt.heroRow("archer", key: .guardUp, action: .init(), power: 1), 3)
        XCTAssertEqual(InkTechniqueArt.heroRow("archer", key: .guardUp, action: .init(), power: 3), 4)
        XCTAssertNil(InkTechniqueArt.heroRow("archer", key: .hurt, action: .init(), power: 3))
    }

    func testEnemyMoveSelectionAndPhaseSafety() {
        XCTAssertEqual(InkTechniqueArt.enemyAttackFamily("reedLurker_pack", action: .init(moveID: "thrash")), "alternate")
        XCTAssertEqual(InkTechniqueArt.enemyAttackFamily("reedLurker", action: .init(moveID: "bite")), "melee")
        for stage in ["apep_coils", "apep_maw"] {
            XCTAssertTrue(InkTechniqueArt.hasPhaseBody(stage))
            XCTAssertNil(InkTechniqueArt.foe("apep", stage: stage, key: .strike, action: .init(), power: 3))
            XCTAssertNil(InkTechniqueArt.personality(hero: nil, enemy: "apep", stage: stage, frame: 0))
        }
    }

    func testAll112NewDrawingsResolveWhenInstalled() throws {
        for sheet in InkTechniqueArt.sheets where UIImage(named: sheet.name) == nil {
            throw XCTSkip("Install the combined Techniques-and-Personality ZIP; missing \(sheet.name)")
        }
        var count = 0
        for sheet in InkTechniqueArt.sheets {
            for index in 0..<(sheet.columns * sheet.rows) {
                let image = try XCTUnwrap(InkAtlasSlicer.plate(at: index, atlas: sheet.name,
                    columns: sheet.columns, rows: sheet.rows, threshold: sheet.threshold, referenceHeight: sheet.height))
                XCTAssertEqual(image.size.height, 380, accuracy: 1)
                count += 1
            }
        }
        XCTAssertEqual(count, 112)
        XCTAssertNil(InkTechniqueArt.image("ink.techH.archer.5"))
        XCTAssertNil(InkTechniqueArt.image("ink.personF.apep.2"))
    }
}
