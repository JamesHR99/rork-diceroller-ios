import SwiftUI
import UIKit

/// Which drawing of a fighter's animation set is being shown. Every character
/// is drawn once per key; the sequencer walks these in order to play an action.
enum FrameKey: String, CaseIterable {
    case idle
    case windup
    case strike
    case follow
    case guardUp
    case hurt
    case dodge
    case defeat
    case victory
}

/// Every drawing that exists for one fighter, resolved against the asset
/// catalogue once and then reused. A frame that was never drawn falls back to
/// the idle plate, so a half-finished set still animates cleanly instead of
/// leaving a hole on the deck.
struct FrameSet {
    private let frames: [FrameKey: String]

    init(frames: [FrameKey: String]) {
        self.frames = frames
    }

    /// The plate to draw for this key, falling back to the idle drawing.
    func art(_ key: FrameKey) -> String? {
        frames[key] ?? frames[.idle]
    }

    /// True when this character really was drawn in that pose. The motion code
    /// leans harder on code-driven squash and smear when it wasn't, so an
    /// undrawn frame still reads as movement rather than a frozen plate.
    func has(_ key: FrameKey) -> Bool { frames[key] != nil }

    /// How many distinct drawings this fighter actually owns.
    var drawnCount: Int { frames.count }
}

/// Painted plates for everyone who appears on the river: the four demigods,
/// the six gods, and every servant of Apep. Each fighter resolves to a full
/// animation set; anything undrawn falls back to its portrait, then its glyph,
/// so a missing plate never leaves a hole on screen.
enum CharacterArt {
    private static let demigods: [String: String] = [
        "archer": "egyptian_archer_demigod",
        "warrior": "egyptian_warrior_khopesh",
        "rogue": "egyptian_rogue_assassin",
        "magician": "egyptian_priest_wand",
    ]

    private static let gods: [Deity: String] = [
        .ra: "ra_falcon_deity",
        .sobek: "sobek_crocodile_deity",
        .anubis: "anubis_scales_ankh",
        .bes: "bes_deity_sword_tambourine",
        .horus: "horus_falcon_deity",
        .bastet: "bastet_goddess_sistrum",
    ]

    private static let foes: [String: String] = [
        "reedLurker": "reed_lurker_crocodile",
        "marshShade": "marsh_shade_ghost",
        "sandCrawler": "sand_crawler_beetle",
        "sekhen": "reed_serpent_boss",
        "emberWraith": "ember_wraith_egyptian",
        "flamekeeper": "flamekeeper_guardian",
        "ashJackal": "ash_jackal_ember",
        "nehebkau": "nehebkau_serpent_boss",
        "devourerSpawn": "devourer_spawn_creature",
        "uncreatedShadow": "void_humanoid_silhouette",
        "hourEater": "hour_eater_egyptian",
        "apep": "apep_serpent_boss",
        "siltColossus": "sand_crawler_beetle",
        "bronzeEffigy": "flamekeeper_guardian",
        "boneplateDevourer": "devourer_spawn_creature",
    ]

    /// Candidate plate names per frame, most specific first. The Duat pack's
    /// painted poses lead every list; the older pipeline names follow, so a
    /// frame the pack did not draw still finds whatever else exists.
    private static let heroPlates: [String: [FrameKey: [String]]] = [
        "archer": [
            .idle: ["egyptian_archer_idle", "egyptian_archer_bow_down", "egyptian_archer_demigod"],
            .windup: ["hero_archer_windup", "archer_bow_drawn_attack"],
            .strike: ["hero_archer_strike", "egyptian_archer_strike"],
            .follow: ["hero_archer_followthrough", "egyptian_archer_bow_down"],
            .guardUp: ["duat_hero_archer_guardUp", "hero_archer_guard"],
            .hurt: ["hero_archer_hurt", "egyptian_archer_hurt"],
            .dodge: ["hero_archer_dodge", "egyptian_archer_dodge"],
            .defeat: ["hero_archer_defeat", "egyptian_archer_defeat_pose"],
            .victory: ["hero_archer_victory", "egyptian_archer_victory"],
        ],
        "warrior": [
            .idle: ["egyptian_warrior_idle", "egyptian_warrior_khopesh"],
            .windup: ["hero_warrior_windup", "the_same_character_2"],
            .strike: ["hero_warrior_strike", "the_same_character", "egyptian_warrior_attack"],
            .follow: ["hero_warrior_followthrough", "egyptian_warrior_attack"],
            .guardUp: ["hero_warrior_guard", "egyptian_warrior_guard"],
            .hurt: ["hero_warrior_hurt", "egyptian_warrior_hurt"],
            .dodge: ["hero_warrior_dodge", "egyptian_warrior_dodge"],
            .defeat: ["hero_warrior_defeat", "egyptian_warrior_defeated"],
            .victory: ["hero_warrior_victory", "egyptian_warrior_victory"],
        ],
        "rogue": [
            .idle: ["egyptian_rogue_idle", "egyptian_rogue_assassin"],
            .windup: ["rogue_frame_windup", "egyptian_rogue_crouch_knives"],
            .strike: ["rogue_frame_strike", "egyptian_rogue_strike_pose"],
            .follow: ["hero_rogue_followthrough", "egyptian_rogue_strike_pose"],
            .guardUp: ["rogue_frame_guard", "egyptian_rogue_guard_pose_2"],
            .hurt: ["duat_hero_rogue_hurt", "hero_rogue_hurt"],
            .dodge: ["rogue_frame_dodge", "egyptian_rogue_dodge_4"],
            .defeat: ["duat_hero_rogue_defeat", "hero_rogue_defeat"],
            .victory: ["hero_rogue_victory", "egyptian_rogue_victory_2"],
        ],
        "magician": [
            .idle: ["egyptian_priest_magician", "egyptian_priest_wand"],
            .windup: ["hero_magician_windup", "priest_magician_staff_attack_3"],
            .strike: ["hero_magician_strike", "egyptian_priest_staff_attack_11"],
            .follow: ["duat_hero_magician_follow", "hero_magician_followthrough"],
            .guardUp: ["hero_magician_guard", "egyptian_priest_guard_staff_3"],
            .hurt: ["hero_magician_hurt", "egyptian_priest_hurt_2"],
            .dodge: ["duat_hero_magician_dodge", "hero_magician_dodge"],
            .defeat: ["duat_hero_magician_defeat", "hero_magician_defeat"],
            .victory: ["duat_hero_magician_victory", "hero_magician_victory"],
        ],
    ]

    /// The painted pose each hero falls back to when nothing else was drawn —
    /// their strongest plate from the Duat pack, standing in for the resting
    /// pose so a painted figure is always on the deck. The warrior has no
    /// painted pose yet and keeps his inked figure until his art lands.
    private static let heroRestingPlates: [String: String] = [
        "archer": "duat_hero_archer_guardUp",
        "rogue": "duat_hero_rogue_hurt",
        "magician": "duat_hero_magician_follow",
    ]

    /// Resolved sets are cached — `UIImage(named:)` hits the catalogue, and a
    /// fighter's set is asked for on every frame of every battle.
    private static var cache: [String: FrameSet] = [:]

    /// The portrait plate for one of the four demigods, falling back to their
    /// painted Duat pose when the older portrait was never filed.
    static func demigod(_ classID: String) -> String? {
        DuatArt.resolve(demigods[classID]) ?? DuatArt.resolve(heroRestingPlates[classID])
    }

    /// A god's portrait, falling back to their painted Duat sigil.
    static func god(_ deity: Deity) -> String? {
        DuatArt.resolve(gods[deity]) ?? deity.artName
    }

    /// A herald wears the face of the guardian it was promoted from; pack and
    /// elite variants wear theirs too. A creature with its own painted sheet
    /// shows its resting drawing; anything still undrawn stands in the Straw
    /// Effigy's pose.
    static func foe(_ enemyID: String, stageID: String? = nil) -> String? {
        if let sheet = foeSheetID(enemyID, stageID: stageID) {
            return DuatArt.resolve(EnemySheet.portrait(sheet))
        }
        return DuatArt.resolve(foes[baseID(enemyID)]) ?? DuatArt.resolve(DuatArt.strawEffigy)
    }

    /// Which painted sheet this creature animates from, or `nil` when it was
    /// never drawn. A serpent-lord re-coils into a new body partway through
    /// its fight, and each stage owns its own sheet.
    static func foeSheetID(_ enemyID: String, stageID: String? = nil) -> String? {
        if let stageID, let staged = EnemySheet.stageSheets[stageID],
           EnemySheet.contentBoxes[staged] != nil {
            return staged
        }
        let id = baseID(enemyID)
        return EnemySheet.contentBoxes[id] != nil ? id : nil
    }

    /// Strips the promotion suffixes a foe may carry so variants share art.
    private static func baseID(_ enemyID: String) -> String {
        for suffix in ["_herald", "_armoured", "_pack"] where enemyID.hasSuffix(suffix) {
            return String(enemyID.dropLast(suffix.count))
        }
        return enemyID
    }

    /// The full animation set for one of the four demigods.
    static func heroFrames(_ classID: String) -> FrameSet {
        resolve(cacheKey: "hero.\(classID)",
                plates: heroPlates[classID] ?? [:],
                base: demigods[classID],
                painted: heroRestingPlates[classID])
    }

    /// The full animation set for a foe, shared by its promoted variants.
    /// Nothing out of the river has been redrawn yet except the Straw Effigy,
    /// so every foe stands in its pose until their own plates land — a painted
    /// figure beats a glyph, and the code-driven motion does the acting.
    static func foeFrames(_ enemyID: String, stageID: String? = nil) -> FrameSet {
        let id = baseID(enemyID)
        // A creature with its own sheet never needs the single-drawing set,
        // but it still resolves one so the glyph fallback chain stays whole.
        let resting = foeSheetID(enemyID, stageID: stageID).map(EnemySheet.portrait)
        return resolve(cacheKey: "foe.\(resting ?? id)",
                       plates: foePlates(for: id),
                       base: resting ?? foes[id],
                       painted: DuatArt.strawEffigy)
    }

    /// Extra plate names a foe's frames landed under. The art pipeline names
    /// drawings after what it sees rather than the slot they fill, so anything
    /// off-convention is listed here and still finds its frame.
    private static let foeAliases: [String: [FrameKey: [String]]] = [
        "reedLurker": [
            .windup: ["crocodile_wound_up_lunge"],
            .strike: ["crocodile_lunging"],
            .follow: ["crocodile_lunging"],
            .hurt: ["crocodile_hurt_recoil"],
            .defeat: ["crocodile_defeat_collapsed"],
        ],
        "marshShade": [
            .windup: ["ghost_windup_pose"],
            .strike: ["ghost_shroud_strike_pose"],
            .follow: ["ghost_shroud_strike_pose"],
            .hurt: ["marsh_ghost_hurt_pose"],
        ],
        "sandCrawler": [
            .strike: ["sand_beetle_strike"],
            .follow: ["sand_beetle_strike"],
        ],
        "siltColossus": [
            .strike: ["sand_beetle_strike"],
            .follow: ["sand_beetle_strike"],
        ],
    ]

    /// Foes follow one naming convention, since their sets are drawn as a
    /// batch: `<stem>_<frame>`, e.g. `reed_lurker_crocodile_strike`. Anything
    /// the pipeline renamed is picked up from the alias table.
    private static func foePlates(for id: String) -> [FrameKey: [String]] {
        guard let stem = foes[id] else { return [:] }
        let aliases = foeAliases[id] ?? [:]
        var plates: [FrameKey: [String]] = [:]
        for key in FrameKey.allCases {
            plates[key] = ["\(stem)_\(key.rawValue)"] + (aliases[key] ?? [])
        }
        plates[.idle] = ["\(stem)_idle", stem]
        return plates
    }

    /// Keeps the first candidate that actually exists in the catalogue.
    /// `painted` is the Duat plate this fighter rests on when its own idle was
    /// never drawn — it is the last resort before the inked glyph.
    private static func resolve(cacheKey: String,
                                plates: [FrameKey: [String]],
                                base: String?,
                                painted: String? = nil) -> FrameSet {
        if let cached = cache[cacheKey] { return cached }

        var found: [FrameKey: String] = [:]
        for (key, candidates) in plates {
            for name in candidates where DuatArt.exists(name) {
                found[key] = name
                break
            }
        }
        // A character with no drawn idle still animates off its portrait, and
        // failing that, off whichever painted pose it does own.
        if found[.idle] == nil, let base, DuatArt.exists(base) {
            found[.idle] = base
        }
        if found[.idle] == nil, let painted, DuatArt.exists(painted) {
            found[.idle] = painted
        }

        let set = FrameSet(frames: found)
        cache[cacheKey] = set
        return set
    }
}
