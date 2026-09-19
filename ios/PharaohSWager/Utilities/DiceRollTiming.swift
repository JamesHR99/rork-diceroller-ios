import Foundation

/// One bounded roll schedule, shared by the engine and the reel renderer.
/// Stops use absolute deadlines so a busy frame cannot lengthen every later gap.
enum DiceRollTiming {
    /// Give the drum time to establish its speed before the first reel lands.
    /// The following reels then lock with a clear left-to-right cadence.
    static let firstStop: TimeInterval = 0.82
    static let stopSpacing: TimeInterval = 0.16
    static let maximumStagger: TimeInterval = 0.96

    static func stopTime(index: Int, count: Int, reduceMotion: Bool = false) -> TimeInterval {
        let lastIndex = max(0, count - 1)
        let position = min(max(0, index), lastIndex)
        let spacing = min(reduceMotion ? 0.025 : stopSpacing,
                          (reduceMotion ? 0.18 : maximumStagger) / Double(max(1, lastIndex)))
        return (reduceMotion ? 0.12 : firstStop) + Double(position) * spacing
    }
}
