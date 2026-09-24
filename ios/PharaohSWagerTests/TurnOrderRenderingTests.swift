import XCTest
import SwiftUI
@testable import PharaohSWager

@MainActor
final class TurnOrderRenderingTests: XCTestCase {
    private var captureWindows: [UIWindow] = []

    private func capture<V: View>(_ view: V, name: String, size: CGSize) async throws {
        let host = UIHostingController(rootView: view.frame(width: size.width, height: size.height).background(Color.black).ignoresSafeArea())
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        captureWindows.append(window)
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(1100))
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testInkArtAssetsAndBattleStage() async throws {
        for hero in InkArt.heroes {
            for key in [FrameKey.idle, .windup, .strike] {
                let name = try XCTUnwrap(InkArt.hero(hero, key))
                let plate = try XCTUnwrap(InkArt.image(name))
                XCTAssertEqual(plate.size.height, 380, "Poses must share a baseline")
                XCTAssertGreaterThan(plate.size.width, 200)
            }
        }
        for enemy in InkArt.enemies {
            XCTAssertNotNil(InkArt.image("ink.foeAttack.\(enemy)"))
        }
        for enemy in InkArt.enemies + ["trainingDummy"] {
            let name = try XCTUnwrap(InkArt.foe(enemy))
            XCTAssertNotNil(InkArt.image(name))
        }
        for gate in Gate.allCases { XCTAssertNotNil(InkArt.image("ink.region.\(gate.rawValue)")) }
        XCTAssertNotNil(InkArt.image("ink.barque"))
        XCTAssertNil(InkArt.image("ink.hero.unknown.0"))
        XCTAssertEqual(InkArt.foe("reedLurker_pack"), InkArt.foe("reedLurker"))

        try await capture(VStack(spacing: 10) {
            ForEach([FrameKey.idle, .windup, .strike], id: \.rawValue) { pose in
                HStack(alignment: .bottom, spacing: 20) {
                    ForEach(InkArt.heroes, id: \.self) { hero in
                        PortraitView(art: InkArt.hero(hero, pose), fallbackSymbol: "person", tint: .white, height: 160)
                            .frame(width: 205)
                    }
                }
            }
        }.background(Color(red: 0.05, green: 0.06, blue: 0.12)), name: "Ink-demigod-poses", size: CGSize(width: 960, height: 540))

        try await capture(VStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(Array(InkArt.enemies[(row * 5)..<(row * 5 + 5)]), id: \.self) { enemy in
                        PortraitView(art: InkArt.foe(enemy), fallbackSymbol: "person", tint: .white, height: 150)
                            .frame(width: 170)
                    }
                }
            }
        }.background(Color(red: 0.05, green: 0.06, blue: 0.12)), name: "Ink-enemy-roster", size: CGSize(width: 960, height: 500))

        try await capture(VStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(Array(InkArt.enemies[(row * 5)..<(row * 5 + 5)]), id: \.self) { enemy in
                        PortraitView(art: "ink.foeAttack.\(enemy)", fallbackSymbol: "person", tint: .white, height: 150)
                            .frame(width: 170)
                    }
                }
            }
        }.background(Color(red: 0.05, green: 0.06, blue: 0.12)), name: "Ink-enemy-attacks", size: CGSize(width: 960, height: 500))

        for gate in Gate.allCases {
            let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: gate.firstHour + 1, isHerald: false)],
                dice: [], classID: "archer", maxHP: 100, startHP: 100, critBonus: 0)
            try await capture(ZStack(alignment: .bottom) {
                PharaohSWagerSceneView(gate: gate, speed: 0, showsBarque: false)
                BattleBarqueView(gate: gate, width: 880)
                    .offset(y: 45)
                HStack(alignment: .bottom) {
                    FighterView(engine: engine, side: .player, heroSymbol: "arrow.up", heroName: "ARKHR",
                        accent: Theme.ember, heroClassID: "archer", stageHeight: 190, cardWidth: 260)
                    Spacer()
                    FighterView(engine: engine, side: .enemy, heroSymbol: "", heroName: "",
                        accent: gate.accent, foe: engine.enemies[0], stageHeight: 190, cardWidth: 260)
                }.padding(.horizontal, 100).padding(.bottom, 94)
            }, name: "Ink-battle-\(gate.rawValue)", size: CGSize(width: 960, height: 414))
        }
    }

    func testExpandedCombatArtVisuals() async throws {
        guard InkArt.image("ink.heroAction.archer.0") != nil,
              InkArt.image("ink.heroSpecial.archer.0") != nil,
              InkArt.image("ink.foeGuard.reedLurker") != nil,
              InkArt.image("ink.foeHurt.reedLurker") != nil else {
            throw XCTSkip("Install the combat-art expansion ZIP before capturing its visuals.")
        }
        for keys in [[FrameKey.guardUp, .hurt, .dodge], [.finisher, .victory, .defeat]] {
            try await capture(VStack(spacing: 8) {
                ForEach(keys, id: \.rawValue) { pose in
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(InkArt.heroes, id: \.self) { hero in
                            PortraitView(art: InkArt.hero(hero, pose), fallbackSymbol: "person", tint: .white, height: 160)
                                .frame(width: 205)
                        }
                    }
                }
            }.background(Color(red: 0.05, green: 0.06, blue: 0.12)),
              name: "Expanded-heroes-\(keys[0].rawValue)", size: CGSize(width: 960, height: 540))
        }
        for key in [FrameKey.guardUp, .hurt] {
            try await capture(VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(Array(InkArt.enemies[(row * 5)..<(row * 5 + 5)]), id: \.self) { enemy in
                            PortraitView(art: InkArt.foe(enemy, key: key), fallbackSymbol: "person", tint: .white, height: 150)
                                .frame(width: 170)
                        }
                    }
                }
            }.background(Color(red: 0.05, green: 0.06, blue: 0.12)),
              name: "Expanded-enemies-\(key.rawValue)", size: CGSize(width: 960, height: 500))
        }
    }

    func testSquareReelsAndFiveVisibleActions() async throws {
        // Exactly five dice keeps the hand deterministic and exercises the new
        // in-place selection treatment rather than the retired planning row.
        let kinds: [FaceKind] = [.arrow1, .arrow1, .block, .evade, .focus]
        let dice = kinds.map { Die(name: "Layout", slot: .weapon, faces: Array(repeating: $0, count: 6)) }
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: dice, classID: "archer", maxHP: 100, startHP: 100, critBonus: -1)
        engine.rollAll(reduceMotion: true)
        while engine.isRolling { try await Task.sleep(for: .milliseconds(20)) }

        for width in [660.0, 850.0] {
            try await capture(DiceTrayView(engine: engine, maxReelHeight: 100, maxRowWidth: width - 44, compact: false),
                name: "Square-reels-\(width)", size: CGSize(width: width, height: 160))
        }

        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        XCTAssertEqual(arrows.count, 2)
        for face in arrows { engine.toggleActionSelection(faceID: face.id) }
        XCTAssertEqual(engine.displayedPlan.count, 1)
        XCTAssertEqual(engine.displayedPlan.first?.faces.count, 2)

        for width in [660.0, 850.0] {
            try await capture(
                HStack(spacing: 8) {
                    ResolveMedallionView(engine: engine)
                    DiceTrayView(engine: engine, maxReelHeight: 86, maxRowWidth: width - 290, compact: true)
                    PlayBarView(engine: engine, bodyHeight: 94)
                },
                name: "Selected-bottom-hand-\(width)",
                size: CGSize(width: width, height: 122)
            )
        }
    }

    func testTurnOrderAndDestinationLayouts() async throws {
        // Five physical dice means the visual check never depends on which die
        // was randomly left in the draw bag.
        let kinds: [FaceKind] = [.arrow1, .arrow1, .arrow1, .arrow2, .block]
        let dice = kinds.map { Die(name: "Layout", slot: .weapon, faces: Array(repeating: $0, count: 6)) }
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: dice, classID: "archer", maxHP: 100, startHP: 100, critBonus: -1)
        engine.rollAll(reduceMotion: true)
        while engine.isRolling { try await Task.sleep(for: .milliseconds(20)) }

        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        for face in arrows.prefix(2) { engine.toggleActionSelection(faceID: face.id) }
        try await capture(
            HStack(spacing: 12) {
                ResolveMedallionView(engine: engine)
                PlayBarView(engine: engine, bodyHeight: 118)
            },
            name: "Battle-controls-play-selected",
            size: CGSize(width: 360, height: 150)
        )

        for face in arrows.prefix(2) { engine.toggleActionSelection(faceID: face.id) }
        try await capture(
            HStack(spacing: 12) {
                ResolveMedallionView(engine: engine)
                PlayBarView(engine: engine, bodyHeight: 102)
            },
            name: "Battle-controls-end-turn",
            size: CGSize(width: 340, height: 140)
        )

        try await capture(NightChartView().environment(GameManager()), name: "Destination-dice", size: CGSize(width: 960, height: 414))
        try await capture(VStack(spacing: 30) { VerdictBanner(title: "THE WAY IS CLEAR", won: true); VerdictBanner(title: "DAWN", won: true) }, name: "Victory-contrast", size: CGSize(width: 960, height: 414))
    }
}

