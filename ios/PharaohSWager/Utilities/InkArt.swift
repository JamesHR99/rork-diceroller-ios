import UIKit

/// Virtual plates cut once from the original, alpha-preserving production atlases.
/// Keeping the generated masters also makes future art revisions reproducible.
enum InkArt {
    static let heroes = ["archer", "warrior", "rogue", "magician"]
    static let enemies = ["reedLurker", "marshShade", "sandCrawler", "sekhen", "emberWraith",
                          "flamekeeper", "ashJackal", "nehebkau", "devourerSpawn", "uncreatedShadow",
                          "hourEater", "apep", "siltColossus", "bronzeEffigy", "boneplateDevourer"]
    private static var cache: [String: UIImage] = [:]

    static func hero(_ id: String, _ key: FrameKey = .idle) -> String? {
        guard heroes.contains(id) else { return nil }
        let actionRow: Int
        switch key {
        case .idle: actionRow = 0
        case .windup: actionRow = 1
        case .strike, .follow: actionRow = 2
        case .guardUp: actionRow = 3
        case .hurt: actionRow = 4
        case .dodge: actionRow = 5
        case .finisher, .victory, .defeat:
            let row = key == .finisher ? 0 : (key == .victory ? 1 : 2)
            let name = "ink.heroSpecial.\(id).\(row)"
            if image(name) != nil { return name }
            actionRow = key == .defeat ? 4 : 2
        }
        let name = "ink.heroAction.\(id).\(actionRow)"
        if image(name) != nil { return name }
        // Keep the earlier ready/anticipation/release set as a real fallback.
        let old = "ink.hero.\(id).\(min(actionRow, 2))"
        return image(old) != nil ? old : nil
    }

    static func foe(_ id: String, stageID: String? = nil, key: FrameKey = .idle) -> String? {
        var base = id
        for suffix in ["_herald", "_armoured", "_pack"] where base.hasSuffix(suffix) {
            base = String(base.dropLast(suffix.count))
        }
        if base == "trainingDummy", image("ink.dummy") != nil { return "ink.dummy" }
        if base == "apep" || base == "apep_coils" || base == "apep_maw" {
            let stage = stageID ?? base
            let column = stage == "apep_coils" ? 1 : (stage == "apep_maw" ? 2 : 0)
            let row: Int
            switch key {
            case .strike, .follow, .finisher, .victory: row = 1
            case .guardUp, .dodge, .windup: row = 2
            case .hurt, .defeat: row = 3
            default: row = 0
            }
            let name = "ink.apep.\(column).\(row)"
            if image(name) != nil { return name }
            base = "apep"
        }
        guard enemies.contains(base) else { return nil }
        let family: String
        switch key {
        case .strike, .follow, .finisher, .victory: family = "foeAttack"
        case .guardUp, .dodge, .windup: family = "foeGuard"
        case .hurt, .defeat: family = "foeHurt"
        default: family = "foe"
        }
        let name = "ink.\(family).\(base)"
        if image(name) != nil { return name }
        let idle = "ink.foe.\(base)"
        return image(idle) != nil ? idle : nil
    }

    static func image(_ name: String) -> UIImage? {
        guard name.hasPrefix("ink.") else { return nil }
        if let technique = InkTechniqueArt.image(name) { return technique }
        if let cached = cache[name] { return cached }
        var atlas: String
        var rect: CGRect
        let parts = name.split(separator: ".").map(String.init)
        if parts.count == 4, parts[1] == "heroAction",
           let column = heroes.firstIndex(of: parts[2]), let row = Int(parts[3]), (0...5).contains(row) {
            return InkAtlasSlicer.plate(at: row * 4 + column, atlas: "ink_hero_actions", columns: 4, rows: 6,
                                       threshold: 240, referenceHeight: 320)
        } else if parts.count == 4, parts[1] == "heroSpecial",
                  let column = heroes.firstIndex(of: parts[2]), let row = Int(parts[3]), (0...2).contains(row) {
            return InkAtlasSlicer.plate(at: row * 4 + column, atlas: "ink_hero_specials", columns: 4, rows: 3,
                                       referenceHeight: 420)
        } else if parts.count == 4, parts[1] == "apep",
                  let column = Int(parts[2]), let row = Int(parts[3]), (0...2).contains(column), (0...3).contains(row) {
            return InkAtlasSlicer.plate(at: row * 3 + column, atlas: "ink_apep_phases", columns: 3, rows: 4)
        } else if parts.count == 4, parts[1] == "hero",
                  let column = heroes.firstIndex(of: parts[2]), let row = Int(parts[3]), (0...2).contains(row) {
            return InkAtlasSlicer.plate(at: row * 4 + column, atlas: "ink_heroes", columns: 4, rows: 3)
        } else if parts.count == 3, let index = enemies.firstIndex(of: parts[2]),
                  let sheet = ["foe": "ink_enemies", "foeAttack": "ink_enemy_attacks",
                               "foeGuard": "ink_enemy_guards", "foeHurt": "ink_enemy_hurt"][parts[1]] {
            return InkAtlasSlicer.plate(at: index, atlas: sheet, columns: 5, rows: 3,
                                       referenceHeight: parts[1] == "foeGuard" ? 310 : 380)
        } else if parts.count == 3, parts[1] == "region", let index = Int(parts[2]), (0...2).contains(index) {
            atlas = "ink_regions"
            rect = CGRect(x: 0, y: CGFloat(index) * 341.333, width: 1536, height: 341.333)
        } else if name == "ink.barque" {
            atlas = "ink_barque"
            rect = CGRect(x: 0, y: 225, width: 1536, height: 515)
        } else if name == "ink.dummy" {
            atlas = "ink_dummy"
            rect = CGRect(x: 165, y: 0, width: 755, height: 1536)
        } else { return nil }
        guard let source = UIImage(named: atlas)?.cgImage else { return nil }
        // All atlas coordinates use their export's pixel space, never UIKit points.
        guard let cut = source.cropping(to: rect.integral.intersection(CGRect(x: 0, y: 0, width: source.width, height: source.height))) else { return nil }
        let result = UIImage(cgImage: cut)
        cache[name] = result
        return result
    }
}
