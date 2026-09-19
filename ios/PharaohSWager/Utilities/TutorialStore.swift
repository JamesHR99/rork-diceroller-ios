import Foundation

/// Whether the player still wants the opening briefing.
///
/// The briefing shows at the start of every run by default — it is short, and
/// a roguelike run is a fresh start each time. "Don't show me again" on the
/// last page turns it off for good, and it stays reachable from the title.
enum TutorialStore {
    private static let suppressedKey = "diceroller.tutorial.suppressed.v2"

    /// True once the player has asked not to see the briefing again.
    static var isSuppressed: Bool {
        UserDefaults.standard.bool(forKey: suppressedKey)
    }

    static func suppress() {
        UserDefaults.standard.set(true, forKey: suppressedKey)
    }

    /// Turns the briefing back on — used by the title screen's own entry.
    static func restore() {
        UserDefaults.standard.removeObject(forKey: suppressedKey)
    }
}

