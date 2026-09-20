import UIKit

/// Fixed-cell effect sheets deliberately retain their alpha and common pivot.
/// Unlike character atlases, tiny sparks are part of their cell, not separate bodies.
enum InkWorldArt {
    private static var cache: [String: UIImage] = [:]

    static func cell(_ atlas: String, index: Int, columns: Int = 4, rows: Int = 4) -> UIImage? {
        guard columns > 0, rows > 0, index >= 0, index < columns * rows else { return nil }
        let key = "\(atlas).\(columns).\(rows).\(index)"
        if let image = cache[key] { return image }
        guard let source = UIImage(named: atlas)?.cgImage else { return nil }
        let x0 = source.width * (index % columns) / columns
        let x1 = source.width * (index % columns + 1) / columns
        let y0 = source.height * (index / columns) / rows
        let y1 = source.height * (index / columns + 1) / rows
        guard let cut = source.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) else { return nil }
        let image = UIImage(cgImage: cut)
        cache[key] = image
        return image
    }

    static func enemyFamily(_ id: String?) -> Int? {
        guard let id else { return nil }
        switch InkTechniqueArt.baseID(id) {
        case "reedLurker", "sandCrawler", "sekhen", "nehebkau", "apep": return 11 // serpent venom
        case "marshShade": return 9 // spectral
        case "emberWraith", "flamekeeper", "ashJackal": return 10 // ember
        case "devourerSpawn", "boneplateDevourer": return 12 // bone
        case "uncreatedShadow": return 13 // void
        case "hourEater": return 15 // time
        case "siltColossus", "bronzeEffigy", "trainingDummy": return 14 // bronze/stone
        default: return nil
        }
    }

    static func projectileIndex(_ form: ProjectileForm, enemy: String? = nil) -> Int {
        // Keep explicit spell elements readable; non-elemental shots take the creature's identity.
        if let family = enemyFamily(enemy) {
            switch form {
            case .fireOrb: return 10
            case .venomFlask: return 11
            case .frostShard: return 4
            case .lifeMotes: return 5
            default: return family
            }
        }
        switch form {
        case .arrow: return 0
        case .crescent: return 1
        case .tumblingBlade: return 2
        case .fireOrb: return 3
        case .frostShard: return 4
        case .lifeMotes: return 5
        case .arcaneBolt: return 6
        case .lightning: return 7
        case .venomFlask: return 8
        }
    }

    static func impactIndex(_ form: ImpactForm, enemy: String? = nil) -> Int {
        switch form {
        case .bleedTick: return 15
        case .poisonTick, .venom: return 7
        case .burnTick, .scorch, .fireExplosion: return enemy == nil ? 3 : 9
        case .frostCrust: return 4
        case .bloom: return 6
        default: break
        }
        if let family = enemyFamily(enemy) {
            switch family {
            case 9: return 8
            case 10: return 9
            case 11: return 7
            case 12: return 10
            case 13: return 11
            case 15: return 12
            default: return 2
            }
        }
        switch form {
        case .gashes: return 1
        case .puncture: return 0
        case .blunt: return 2
        case .lattice: return 5
        default: return 2
        }
    }
}
