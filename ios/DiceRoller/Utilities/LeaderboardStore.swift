import Foundation

/// Local, device-only leaderboard of your ten deepest voyages.
enum LeaderboardStore {
    static let maxEntries = 10
    private static let storageKey = "diceroller.leaderboard.v2"

    static func load() -> [RunRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return ranked(try JSONDecoder().decode([RunRecord].self, from: data))
        } catch {
            return []
        }
    }

    /// Files a finished voyage and returns the new top ten.
    static func insert(_ record: RunRecord) -> [RunRecord] {
        let table = Array(ranked(load() + [record]).prefix(maxEntries))
        save(table)
        return table
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Deepest hour first; ties broken by seeing the dawn, then damage, then recency.
    static func ranked(_ records: [RunRecord]) -> [RunRecord] {
        records.sorted { lhs, rhs in
            if lhs.hourReached != rhs.hourReached { return lhs.hourReached > rhs.hourReached }
            if lhs.sawDawn != rhs.sawDawn { return lhs.sawDawn }
            if lhs.hoursCleared != rhs.hoursCleared { return lhs.hoursCleared > rhs.hoursCleared }
            if lhs.damageDealt != rhs.damageDealt { return lhs.damageDealt > rhs.damageDealt }
            return lhs.date > rhs.date
        }
    }

    private static func save(_ records: [RunRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("Leaderboard save failed: \(error.localizedDescription)")
            #endif
        }
    }
}
