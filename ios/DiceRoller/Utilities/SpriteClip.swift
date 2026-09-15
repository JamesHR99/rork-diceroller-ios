import Foundation

/// A drawn animation: the ordered plates that make up one action and how long
/// each plate is held. Unlike a `FrameSet` — which holds one drawing per pose
/// and leans on code-driven motion to sell it — a clip is real frame-by-frame
/// animation sliced out of a sprite sheet, so the art does the acting.
struct SpriteClip {
    /// Plate names in playback order. A frame may repeat to hold a beat.
    let frames: [String]
    /// Seconds each plate stays on screen.
    let frameDuration: Double
    /// Whether playback wraps instead of settling on the rest frame.
    let loops: Bool
    /// The frame the figure settles on once a one-shot clip finishes.
    let restIndex: Int

    init(frames: [String], frameDuration: Double, loops: Bool = false, restIndex: Int? = nil) {
        self.frames = frames
        self.frameDuration = frameDuration
        self.loops = loops
        self.restIndex = restIndex ?? max(frames.count - 1, 0)
    }

    var isEmpty: Bool { frames.isEmpty }

    /// How long one pass through the clip takes.
    var duration: Double { Double(frames.count) * frameDuration }

    /// The plate at an index, clamped so a short sheet can never overrun.
    func frame(_ index: Int) -> String {
        guard !frames.isEmpty else { return "" }
        return frames[min(max(index, 0), frames.count - 1)]
    }

    var restFrame: String { frame(restIndex) }
}

/// Every hand-drawn animation the game owns, resolved against the asset
/// catalogue once. A character with no sheet for an action returns `nil`, and
/// the fighter falls back to its single-drawing pose set — so a half-finished
/// character animates with whatever really landed instead of leaving a hole.
enum SpriteClipLibrary {
    /// The clip to play for one character's pose, or `nil` when that action was
    /// never drawn as a sheet.
    static func clip(for characterID: String?, pose: FighterPose) -> SpriteClip? {
        guard let characterID, !characterID.isEmpty else { return nil }
        let key = "\(characterID).\(poseKey(pose))"
        if let cached = cache[key] { return cached }
        let built = build(characterID, pose: pose)
        cache[key] = built
        return built
    }

    private static var cache: [String: SpriteClip?] = [:]

    private static func poseKey(_ pose: FighterPose) -> String {
        switch pose {
        case .idle: "idle"
        case .telegraph: "telegraph"
        case .attack: "attack"
        case .hurt: "hurt"
        case .block: "block"
        case .dodge: "dodge"
        case .heal: "heal"
        case .victory: "victory"
        case .defeat: "defeat"
        }
    }

    /// The archer's four sheets — idle, attack, block and take-damage — sliced
    /// into eight plates each. Actions without their own sheet borrow the
    /// closest drawn one: the aim frames stand in for a telegraph, the guard's
    /// slip becomes the dodge, and the recoil's doubled-over frame holds as the
    /// collapse.
    private static func build(_ characterID: String, pose: FighterPose) -> SpriteClip? {
        guard characterID == "archer" else { return nil }
        switch pose {
        case .idle:
            // Played out and back so the loop never snaps between the last
            // drawing and the first: a slow shift of weight on the deck.
            return clip("archer", "idle", [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1],
                        hold: 0.15, loops: true)
        case .attack:
            // Draw, aim, loose, recover — the whole sheet, timed to land its
            // release on the beat the arrow leaves the bow.
            return clip("archer", "attack", Array(0...7), hold: 0.055)
        case .block:
            return clip("archer", "block", Array(0...7), hold: 0.055)
        case .hurt:
            return clip("archer", "hurt", Array(0...7), hold: 0.05)
        case .dodge:
            // The guard's low slip, without the shield flaring.
            return clip("archer", "block", [1, 2, 2, 1], hold: 0.08)
        case .telegraph:
            return clip("archer", "attack", [1, 2, 3], hold: 0.1)
        case .heal:
            return clip("archer", "idle", [0, 1, 2, 3], hold: 0.16)
        case .victory:
            // The falcon shield burning: the closest thing to a flourish the
            // sheets drew.
            return clip("archer", "block", [3, 4, 5, 6, 7], hold: 0.09)
        case .defeat:
            return clip("archer", "hurt", [1, 2, 3], hold: 0.1)
        }
    }

    /// Builds a clip from a sheet's frame indices, dropping any plate that did
    /// not make it into the catalogue.
    private static func clip(_ hero: String,
                             _ sheet: String,
                             _ order: [Int],
                             hold: Double,
                             loops: Bool = false) -> SpriteClip? {
        let names: [String] = order
            .map { "duat_hero_\(hero)_\(sheet)_f\($0)" }
            .filter { DuatArt.exists($0) }
        guard names.count > 1 else { return nil }
        return SpriteClip(frames: names, frameDuration: hold, loops: loops)
    }
}
