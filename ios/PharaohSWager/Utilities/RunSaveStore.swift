import Foundation

/// A night written down: everything permanent about a run, saved between
/// fights so the voyage can be put away and picked back up later.
///
/// Deliberately never saved mid-fight. A rolled hand is not in here, so a
/// saved night can never be reloaded and re-rolled for a better result — and
/// the save itself stays small and honest.
nonisolated struct RunSave: Codable {
    /// Bumped whenever the shape changes, so an old save is discarded rather
    /// than decoded into nonsense.
    ///
    /// 5: combat became a ten-die draw bag with five-die hands, Resolve and a
    /// discard/reshuffle loop. Older runs keep an eight-die loadout and cannot
    /// be resumed honestly under these rules.
    ///
    /// 2: the river became a run of two-channel forks. Stops no longer carry
    /// connections, they carry a revealed flag instead, an hour is two stops
    /// rather than four, and Mooring is gone as a kind — nothing about an old
    /// chart can be read into the new one.
    static let currentVersion = 5

    var version: Int = RunSave.currentVersion

    // Who you are
    let classID: String
    let loadout: Loadout
    let maxHP: Int
    let currentHP: Int
    let gold: Int
    let critBonus: Double

    // What the gods have given you
    let equippedBoons: [EquippedBoon]
    let legendariesTaken: Int
    let acquiredUpgrades: [String]
    let capstoneID: String?
    let pairingID: String?
    let ownedChisels: [String]
    let trialUsed: Bool

    // Where you are on the river
    let voyage: Voyage
    let clearedNodeIDs: [UUID]
    let lastClearedNodeID: UUID?
    /// The stage the barque was sitting at. A fight in progress resumes from
    /// the *start* of this node, with the health and gear you walked in with.
    let currentNodeID: UUID?
    let deepestHour: Int
    let usedEventIDs: [String]

    // The tallies the leaderboard will want
    let totalDamage: Int
    let totalCombos: Int
    let totalCrits: Int

    let savedAt: Date

    /// The hour this save sits in, for the Continue card on the title screen.
    var hour: Int {
        if let currentNodeID, let node = voyage.node(currentNodeID) { return node.hour }
        if let lastClearedNodeID, let node = voyage.node(lastClearedNodeID) {
            return min(Voyage.totalHours, node.isHourEnd ? node.hour + 1 : node.hour)
        }
        return deepestHour
    }

    var hero: HeroClass { GameData.heroClass(id: classID) }

    /// "The Fifth Hour · Gate of Fire"
    var placeLabel: String { Voyage.fullName(hour) }
}

/// Where the saved night lives. One save at a time — this is a roguelike, not
/// a game with save files.
enum RunSaveStore {
    private static let storageKey = "diceroller.runsave.v1"

    /// The saved night, or nil when there is none to pick up.
    static func load() -> RunSave? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        do {
            let save = try JSONDecoder().decode(RunSave.self, from: data)
            // A save from an older shape of the game is not worth guessing at.
            guard (2...RunSave.currentVersion).contains(save.version) else {
                clear()
                return nil
            }
            return save
        } catch {
            // A save we cannot read is worse than none at all.
            print("[RunSave] could not read saved night: \(error.localizedDescription)")
            clear()
            return nil
        }
    }

    static var hasSave: Bool {
        UserDefaults.standard.data(forKey: storageKey) != nil
    }

    static func save(_ run: RunSave) {
        do {
            let data = try JSONEncoder().encode(run)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[RunSave] could not write saved night: \(error.localizedDescription)")
        }
    }

    /// Clears the saved night — called when a run ends, is abandoned, or is
    /// deliberately overwritten by a fresh one.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}


