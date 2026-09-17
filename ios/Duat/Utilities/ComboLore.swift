import Foundation

/// What the player has actually discovered about their own gear.
///
/// Chains are no longer handed to you as lettered suggestions under the tray —
/// you find them by arranging dice and watching what fires. This store is the
/// memory of that: a chain stays sealed in the codex until the first time it
/// lands, and then it is yours for good, across runs and across deaths.
///
/// Device-only and deliberately permanent: discovery is knowledge the *player*
/// has earned, not run state, so it survives a wipe of the voyage table.
enum ComboLore {
    private static let storageKey = "diceroller.combolore.v1"

    /// Every chain id the player has ever landed.
    static func known() -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        return Set(stored)
    }

    static func isKnown(_ comboID: String) -> Bool {
        known().contains(comboID)
    }

    /// Records a chain as discovered. Returns true only the first time, so the
    /// battle can announce it as a find rather than repeating itself.
    @discardableResult
    static func discover(_ comboID: String) -> Bool {
        var lore = known()
        guard lore.insert(comboID).inserted else { return false }
        UserDefaults.standard.set(Array(lore).sorted(), forKey: storageKey)
        return true
    }

    /// How many of these chains have been found — for the codex heading.
    static func knownCount(among combos: [ComboDef]) -> Int {
        let lore = known()
        return combos.filter { lore.contains($0.id) }.count
    }

    static func forgetEverything() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
