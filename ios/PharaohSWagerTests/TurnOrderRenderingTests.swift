import XCTest
import SwiftUI
@testable import PharaohSWager

@MainActor
final class TurnOrderRenderingTests: XCTestCase {
    private var captureWindows: [UIWindow] = []

    private func capture<V: View>(_ view: V, name: String, size: CGSize) async throws {
        let host = UIHostingController(rootView: view.frame(width: size.width, height: size.height).background(Color.black))
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

    func testTurnOrderAndDestinationLayouts() async throws {
        let kinds: [FaceKind] = [.arrow1, .arrow1, .arrow2, .arrow1, .arrow1, .block]
        let dice = kinds.map { Die(name: "Layout", slot: .weapon, faces: Array(repeating: $0, count: 6)) }
        let engine = BattleEngine(enemies: [EnemyContent.enemy(hour: 1, isHerald: false)],
            dice: dice, classID: "archer", maxHP: 100, startHP: 100, critBonus: -1)
        engine.rollAll(reduceMotion: true)
        while engine.isRolling { try await Task.sleep(for: .milliseconds(20)) }
        let arrows = engine.rolled.filter { $0.face == .arrow1 }
        let separator = try XCTUnwrap(engine.rolled.first { $0.face == .arrow2 })
        for face in arrows.prefix(2) { engine.placeInPlayBar(faceID: face.id) }
        try await capture(PlayBarView(engine: engine, bodyHeight: 118), name: "Turn-order-single-pair", size: CGSize(width: 960, height: 160))
        engine.placeInPlayBar(faceID: separator.id)
        for face in arrows.suffix(2) { engine.placeInPlayBar(faceID: face.id) }
        try await capture(PlayBarView(engine: engine, bodyHeight: 102), name: "Turn-order-two-pairs-and-separator", size: CGSize(width: 760, height: 146))
        try await capture(NightChartView().environment(GameManager()), name: "Destination-dice", size: CGSize(width: 960, height: 414))
        try await capture(VStack(spacing: 30) { VerdictBanner(title: "THE WAY IS CLEAR", won: true); VerdictBanner(title: "DAWN", won: true) }, name: "Victory-contrast", size: CGSize(width: 960, height: 414))
    }
}
