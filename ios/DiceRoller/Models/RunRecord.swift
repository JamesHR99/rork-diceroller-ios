import Foundation

/// One finished voyage, kept in the personal leaderboard.
nonisolated struct RunRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let classID: String
    let className: String
    let classSymbol: String
    /// The hour of the night the run reached, 1 through 12.
    let hourReached: Int
    /// Hours whose guardian was beaten.
    let hoursCleared: Int
    /// True when Apep fell and the sun came up.
    let sawDawn: Bool
    let damageDealt: Int
    let combos: Int
    let crits: Int
    let date: Date

    /// Which gate the run died in, or the last one crossed.
    var gate: Gate { Gate.forHour(hourReached) }

    /// "Saw the dawn" or "Fell in the Ninth Hour".
    var verdict: String {
        sawDawn ? "Saw the dawn" : "Fell in the \(Voyage.ordinal(hourReached)) Hour"
    }

    /// Short readout for the leaderboard row.
    var hourLabel: String { Voyage.romanNumeral(hourReached) }

    var gateLabel: String {
        sawDawn ? "Dawn" : gate.name
    }

    var dateLabel: String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}
