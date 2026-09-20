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
            atlas = "ink_heroes"
            // Measured bounds, rather than assuming the illustrator used an exact grid.
            let boxes: [[CGRect]] = [
                [CGRect(x: 0, y: 0, width: 360, height: 376), CGRect(x: 380, y: 0, width: 365, height: 378),
                 CGRect(x: 765, y: 0, width: 375, height: 380), CGRect(x: 1150, y: 0, width: 386, height: 377)],
                [CGRect(x: 0, y: 375, width: 365, height: 352), CGRect(x: 375, y: 379, width: 370, height: 348),
                 CGRect(x: 765, y: 390, width: 370, height: 340), CGRect(x: 1150, y: 380, width: 386, height: 347)],
                [CGRect(x: 0, y: 728, width: 350, height: 296), CGRect(x: 355, y: 735, width: 390, height: 289),
                 CGRect(x: 775, y: 740, width: 405, height: 284), CGRect(x: 1145, y: 725, width: 391, height: 299)]
            ]
            rect = boxes[row][column]
        } else if parts.count == 3, parts[1] == "foe", let index = enemies.firstIndex(of: parts[2]) {
            atlas = "ink_enemies"
            rect = CGRect(x: CGFloat(index % 5) * 307.2, y: CGFloat(index / 5) * 341.333,
                          width: 307.2, height: 341.333)
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
        let result: UIImage
        if name.hasPrefix("ink.hero.") {
            // Shared 380px baseline prevents a crouching attack from being enlarged
            // to the standing pose's height. Original alpha is retained.
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            let size = CGSize(width: cut.width, height: 380)
            result = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                UIImage(cgImage: cut).draw(in: CGRect(x: 0, y: 380 - cut.height, width: cut.width, height: cut.height))
            }
        } else { result = UIImage(cgImage: cut) }
        cache[name] = result
        return result
    }
}
