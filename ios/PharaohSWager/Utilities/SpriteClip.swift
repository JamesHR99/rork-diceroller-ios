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

    /// The clip for a creature out of the river, keyed by the sheet its
    /// current stage uses. Returns `nil` for anything with no sheet, so the
    /// fighter falls back to its single-drawing pose set.
    static func foeClip(sheetID: String?, pose: FighterPose) -> SpriteClip? {
        guard let sheetID, !sheetID.isEmpty else { return nil }
        let key = "foe.\(sheetID).\(poseKey(pose))"
        if let cached = cache[key] { return cached }
        let built = buildFoe(sheetID, pose: pose)
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

    // MARK: - Timing

    /// How long each hero holds a plate, by action. Every hero was drawn as
    /// four eight-frame sheets, but they do not move alike: an axe hangs at the
    /// top of its arc, twin blades flurry, a staff builds and detonates.
    /// Idles are deliberately slow — a standing fighter should read as
    /// breathing, not fidgeting.
    private struct Tempo {
        var idle: Double
        var attack: Double
        var block: Double
        var hurt: Double
    }

    private static let tempos: [String: Tempo] = [
        // The draw is long and the loose is the only quick thing he does.
        "archer": Tempo(idle: 0.34, attack: 0.105, block: 0.10, hurt: 0.095),
        // The heaviest fighter on the deck: slowest breath, slowest swing.
        "warrior": Tempo(idle: 0.38, attack: 0.115, block: 0.11, hurt: 0.10),
        // Light on his feet — a shallower breath and the fastest blades.
        "rogue": Tempo(idle: 0.30, attack: 0.09, block: 0.09, hurt: 0.085),
        // The robes carry their own drift, so she breathes slowest of all.
        "magician": Tempo(idle: 0.40, attack: 0.11, block: 0.105, hurt: 0.095),
    ]

    /// The eight plates played out and back, so a loop never snaps between the
    /// last drawing and the first — the shift of weight simply reverses.
    private static let breath = [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]

    // MARK: - Building

    /// Four sheets per hero — idle, attack, block and take-damage — sliced into
    /// eight plates each. Actions without their own sheet borrow the closest
    /// drawn one: the wind-up frames stand in for a telegraph, the guard's slip
    /// becomes the dodge, the guard's flourish becomes a victory, and the
    /// recoil's doubled-over frames hold as the collapse.
    private static func build(_ hero: String, pose: FighterPose) -> SpriteClip? {
        guard let tempo = tempos[hero] else { return nil }
        switch pose {
        case .idle:
            return clip(hero, "idle", breath, hold: tempo.idle, loops: true)
        case .attack:
            return clip(hero, "attack", Array(0...7), hold: tempo.attack)
        case .block:
            return clip(hero, "block", Array(0...7), hold: tempo.block)
        case .hurt:
            return clip(hero, "hurt", Array(0...7), hold: tempo.hurt)
        case .dodge:
            // The guard's low slip, held rather than flaring into the block.
            return clip(hero, "block", [1, 2, 2, 1], hold: tempo.block * 1.6)
        case .telegraph:
            // The first beats of the swing, slowed to a tell.
            return clip(hero, "attack", [1, 2, 3], hold: tempo.attack * 1.9)
        case .heal:
            // A breath drawn in and let out over the mending.
            return clip(hero, "idle", [0, 1, 2, 3, 2, 1], hold: tempo.idle * 0.9)
        case .victory:
            // The back half of the guard sheet: the closest thing to a flourish
            // the sheets drew.
            return clip(hero, "block", [3, 4, 5, 6, 7], hold: tempo.block * 1.7)
        case .defeat:
            return clip(hero, "hurt", [1, 2, 3], hold: tempo.hurt * 2.2)
        }
    }

    // MARK: - Creatures

    /// How long a creature holds one plate, per row. The sheets were drawn as
    /// four keyframes rather than eight, so every plate carries more of the
    /// action and is held roughly twice as long as a hero's.
    private struct FoeTempo {
        static let idle = 0.40
        static let attack = 0.17
        static let flinch = 0.14
        static let guardUp = 0.20
    }

    /// Four plates played out and back, so a creature's standing loop never
    /// snaps between its last drawing and its first.
    private static let foeBreath = [0, 1, 2, 3, 2, 1]

    /// Rows top to bottom: standing, striking, flinching from a hit, and a
    /// guard raised and held. The game's `block` pose is the guard, and its
    /// `hurt` pose is the flinch — the sheets name them the other way round.
    private static func buildFoe(_ id: String, pose: FighterPose) -> SpriteClip? {
        switch pose {
        case .idle:
            return foe(id, "idle", foeBreath, hold: FoeTempo.idle, loops: true)
        case .attack:
            return foe(id, "attack", [0, 1, 2, 3], hold: FoeTempo.attack)
        case .hurt:
            return foe(id, "block", [0, 1, 2, 3], hold: FoeTempo.flinch)
        case .block:
            // The guard enters and then holds, rather than relaxing straight
            // back out of it — the sheet's last drawing drifts toward idle.
            return foe(id, "defend", [0, 1, 2, 2], hold: FoeTempo.guardUp, restIndex: 2)
        case .telegraph:
            // The wind-up alone, stretched into a readable tell.
            return foe(id, "attack", [0, 0, 1], hold: FoeTempo.attack * 1.5)
        case .dodge:
            // The guard's first slip, taken quickly and held low.
            return foe(id, "defend", [0, 1, 1], hold: FoeTempo.guardUp * 0.8)
        case .heal:
            return foe(id, "idle", [0, 1, 2, 3, 2, 1], hold: FoeTempo.idle * 0.9, loops: true)
        case .victory:
            return foe(id, "attack", [2, 3], hold: FoeTempo.attack * 2.2)
        case .defeat:
            // Doubled over on the flinch, held as the collapse.
            return foe(id, "block", [1, 2, 3], hold: FoeTempo.flinch * 2.6)
        }
    }

    private static func foe(_ id: String,
                            _ row: String,
                            _ order: [Int],
                            hold: Double,
                            loops: Bool = false,
                            restIndex: Int? = nil) -> SpriteClip? {
        let names: [String] = order
            .map { EnemySheet.plate(id, row, $0) }
            .filter { PharaohSWagerArt.exists($0) }
        guard names.count > 1 else { return nil }
        return SpriteClip(frames: names, frameDuration: hold, loops: loops, restIndex: restIndex)
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
            .filter { PharaohSWagerArt.exists($0) }
        guard names.count > 1 else { return nil }
        return SpriteClip(frames: names, frameDuration: hold, loops: loops)
    }
}
