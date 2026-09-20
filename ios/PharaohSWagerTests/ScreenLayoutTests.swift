import XCTest
import SwiftUI
@testable import PharaohSWager

@MainActor
final class ScreenLayoutTests: XCTestCase {
    // SwiftUI/CA can finish an animation transaction after an async capture
    // returns. Keep hidden hosts alive across XCTest case-instance teardown;
    // releasing a hosting window at that boundary crashed the simulator.
    // This bounded collection exists only in the test process.
    private static var captureWindows: [UIWindow] = []

    private func capture<V: View>(_ view: V, name: String, size: CGSize) async throws {
        let host = UIHostingController(rootView: view.frame(width: size.width, height: size.height).background(Theme.bg))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        Self.captureWindows.append(window)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(500))
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            XCTAssertTrue(host.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLandscapeMenuAndSelection() async throws {
        let game = GameManager()
        try await capture(TitleView().environment(game), name: "Pharaohs-Wager-menu", size: CGSize(width: 800, height: 350))
        try await capture(HeroSelectionView().environment(game), name: "New-run-cast-off", size: CGSize(width: 800, height: 350))
    }

    func testThreeFixedBoonCards() async throws {
        let game = GameManager()
        for deity in Deity.allCases {
            let offers = game.makeGodFavourOffers(deity: deity, count: 3, progress: 0.5)
            try await capture(HStack(spacing: 8) {
                ForEach(offers) { offer in
                    OfferCardView(offer: offer, isSelected: false, affordable: true, width: nil, fixedPresentation: true) {}
                }
            }.padding(4), name: "Fixed-boons-\(deity.rawValue)", size: CGSize(width: 760, height: 224))
        }
    }
}
