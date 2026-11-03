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
struct PharaohSWagerTests {

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
