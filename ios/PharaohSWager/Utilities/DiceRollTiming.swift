import Foundation

/// One bounded roll schedule, shared by the engine and the reel renderer.
/// Stops use absolute deadlines so a busy frame cannot lengthen every later gap.
enum DiceRollTiming {
    static let firstStop: TimeInterval = 0.58
    static let stopSpacing: TimeInterval = 0.075
    static let maximumStagger: TimeInterval = 0.60

    static func stopTime(index: Int, count: Int, reduceMotion: Bool = false) -> TimeInterval {
        let lastIndex = max(0, count - 1)
        let position = min(max(0, index), lastIndex)
        let spacing = min(reduceMotion ? 0.025 : stopSpacing,
                          (reduceMotion ? 0.18 : maximumStagger) / Double(max(1, lastIndex)))
        return (reduceMotion ? 0.12 : firstStop) + Double(position) * spacing
    }
}
