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
        guard heroes.contains(id), UIImage(named: "ink_heroes") != nil else { return nil }
        let row: Int
        switch key {
        case .windup, .guardUp, .dodge: row = 1
        case .strike, .follow, .victory: row = 2
        default: row = 0
        }
        return "ink.hero.\(id).\(row)"
    }

    static func foe(_ id: String) -> String? {
        var base = id
        for suffix in ["_herald", "_armoured", "_pack"] where base.hasSuffix(suffix) {
            base = String(base.dropLast(suffix.count))
        }
        if base == "trainingDummy", UIImage(named: "ink_dummy") != nil { return "ink.dummy" }
        guard enemies.contains(base), UIImage(named: "ink_enemies") != nil else { return nil }
        return "ink.foe.\(base)"
    }

    static func image(_ name: String) -> UIImage? {
        guard name.hasPrefix("ink.") else { return nil }
        if let cached = cache[name] { return cached }
        var atlas: String
        var rect: CGRect
        let parts = name.split(separator: ".").map(String.init)
        if parts.count == 4, parts[1] == "hero",
           let column = heroes.firstIndex(of: parts[2]), let row = Int(parts[3]), (0...2).contains(row) {
            return InkAtlasSlicer.plate(at: row * 4 + column, atlas: "ink_heroes", columns: 4, rows: 3)
        } else if parts.count == 3, ["foe", "foeAttack"].contains(parts[1]), let index = enemies.firstIndex(of: parts[2]) {
            return InkAtlasSlicer.plate(at: index, atlas: parts[1] == "foeAttack" ? "ink_enemy_attacks" : "ink_enemies", columns: 5, rows: 3)
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
