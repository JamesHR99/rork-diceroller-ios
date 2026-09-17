import UIKit

/// Centralized haptic feedback helpers used across battle interactions.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func failure() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// The rumble a landing chain throws: a pair taps, a five-face chain rolls
    /// out as a run of hits that grows heavier, with an extra slam on a crit.
    @discardableResult
    static func chain(length: Int, crit: Bool) -> Task<Void, Never> {
        let beats = max(1, min(length, 5)) + (crit ? 2 : 0)
        return Task { @MainActor in
            for beat in 0..<beats {
                let progress = Double(beat) / Double(max(beats - 1, 1))
                let style: UIImpactFeedbackGenerator.FeedbackStyle =
                    progress > 0.66 ? .heavy : (progress > 0.33 ? .medium : .light)
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred(intensity: 0.55 + 0.45 * progress)
                try? await Task.sleep(for: .milliseconds(beat < beats - 1 ? 52 : 0))
            }
            if crit {
                try? await Task.sleep(for: .milliseconds(70))
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
