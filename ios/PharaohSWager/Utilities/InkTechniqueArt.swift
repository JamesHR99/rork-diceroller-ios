import UIKit

/// Attack-specific drawings and interruptible idle acting. Missing optional
/// atlases return nil so the existing pose library remains a safe fallback.
enum InkTechniqueArt {
    static let enemies = InkArt.enemies + ["trainingDummy"]
    static let sheets: [(name: String, columns: Int, rows: Int, threshold: UInt8, height: CGFloat)] = [
        ("ink_hero_techniques", 4, 5, 240, 300),
        ("ink_hero_personality", 4, 3, 32, 420),
        ("ink_enemy_melee", 4, 4, 32, 380),
        ("ink_enemy_alternate", 4, 4, 32, 300),
        ("ink_enemy_evade", 4, 4, 32, 300),
        ("ink_enemy_personality_a", 4, 4, 32, 300),
        ("ink_enemy_personality_b", 4, 4, 32, 300),
    ]

    static func baseID(_ id: String) -> String {
        var result = id
        for suffix in ["_herald", "_armoured", "_pack"] where result.hasSuffix(suffix) {
            result = String(result.dropLast(suffix.count))
        }
        return result
    }

    /// Preserve the separate coils/maw bodies throughout their phases.
    static func hasPhaseBody(_ stage: String?) -> Bool {
        stage == "apep_coils" || stage == "apep_maw"
    }

    static func heroRow(_ id: String, key: FrameKey, action: CombatChoreography, power: Int) -> Int? {
        if key == .guardUp { return power >= 3 ? 4 : 3 }
        guard key == .strike || key == .follow else { return nil }
        let face = action.faces.first(where: { $0.isAttack || $0 == .poison }) ?? action.face
        switch id {
        case "archer": return face == .bowSmack ? 2 : (face == .arrow3 ? 1 : 0)
        case "warrior": return action.grantsGuard ? 2 : (face == .sideSwing ? 1 : 0)
        case "rogue": return face == .poison ? 2 : (face == .daggerThrow ? 1 : 0)
        case "magician": return face == .runeFrost ? 1 : (face == .runeFire ? 0 : 2)
        default: return nil
        }
    }

    static func hero(_ id: String, key: FrameKey, action: CombatChoreography, power: Int) -> String? {
        guard let row = heroRow(id, key: key, action: action, power: power) else { return nil }
        return available("ink.techH.\(id).\(row)")
    }

    /// Authored move identifiers take precedence over generic face categories.
    /// This changes only the pose, never the move's rules or projectile type.
    static func enemyAttackFamily(_ id: String, action: CombatChoreography) -> String {
        let alternates: [String: Set<String>] = [
            "reedLurker": ["thrash"], "marshShade": ["grasp", "feed"],
            "sandCrawler": ["sting"], "emberWraith": ["scorch", "conflagrate", "draw"],
            "flamekeeper": ["brand", "furnace"], "ashJackal": ["howl"],
            "nehebkau": ["molten", "sear"], "devourerSpawn": ["gorge"],
            "uncreatedShadow": ["unmake", "wail", "drink"],
            "hourEater": ["rewind"], "apep": ["venom"],
            "siltColossus": ["sweep"], "bronzeEffigy": ["stamp", "burst"],
            "boneplateDevourer": ["maul", "gorge"],
        ]
        return alternates[baseID(id)]?.contains(action.moveID ?? "") == true ? "alternate" : "melee"
    }

    static func foe(_ id: String, stage: String?, key: FrameKey, action: CombatChoreography, power: Int) -> String? {
        guard !hasPhaseBody(stage) else { return nil }
        let base = baseID(id)
        let family: String
        if key == .dodge || (key == .guardUp && (action.faces.contains(.evade) || power >= 3 || base == "trainingDummy")) {
            family = "evade"
        } else if key == .strike || key == .follow || key == .finisher {
            family = enemyAttackFamily(base, action: action)
        } else { return nil }
        return available("ink.techF.\(base).\(family)")
    }

    static func personality(hero: String?, enemy: String?, stage: String?, frame: Int) -> String? {
        if let hero { return available("ink.personH.\(hero).\(frame)") }
        guard let enemy, !hasPhaseBody(stage) else { return nil }
        return available("ink.personF.\(baseID(enemy)).\(frame)")
    }

    private static func available(_ name: String) -> String? { image(name) != nil ? name : nil }

    static func image(_ name: String) -> UIImage? {
        let parts = name.split(separator: ".").map(String.init)
        guard parts.count == 4, parts[0] == "ink" else { return nil }
        let sheetIndex: Int
        let index: Int
        switch parts[1] {
        case "techH", "personH":
            guard let column = InkArt.heroes.firstIndex(of: parts[2]), let row = Int(parts[3]),
                  row >= 0, row < (parts[1] == "techH" ? 5 : 3) else { return nil }
            sheetIndex = parts[1] == "techH" ? 0 : 1
            index = row * 4 + column
        case "techF":
            guard let slot = enemies.firstIndex(of: parts[2]),
                  let sheet = ["melee": 2, "alternate": 3, "evade": 4][parts[3]] else { return nil }
            sheetIndex = sheet
            index = slot
        case "personF":
            guard let slot = enemies.firstIndex(of: parts[2]), let row = Int(parts[3]), (0...1).contains(row) else { return nil }
            sheetIndex = 5 + row
            index = slot
        default: return nil
        }
        let spec = sheets[sheetIndex]
        return InkAtlasSlicer.plate(at: index, atlas: spec.name, columns: spec.columns, rows: spec.rows,
                                   threshold: spec.threshold, referenceHeight: spec.height)
    }
}
