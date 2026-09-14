import Foundation

/// Which piece of gear a die is bolted to.
enum GearSlot: String, Hashable, CaseIterable {
    case weapon
    case armor
    case item

    var label: String {
        switch self {
        case .weapon: "Weapon"
        case .armor: "Armour"
        case .item: "Item"
        }
    }

    var symbol: String {
        switch self {
        case .weapon: "burst.fill"
        case .armor: "shield.lefthalf.filled"
        case .item: "bag.fill"
        }
    }
}

/// A six-faced die belonging to a weapon, armour or item.
struct Die: Identifiable, Hashable {
    let id: UUID
    var name: String
    var slot: GearSlot
    var rarity: Rarity
    var faces: [DieFace]

    init(name: String, slot: GearSlot, rarity: Rarity = .common, faces: [FaceKind], id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.slot = slot
        self.rarity = rarity
        self.faces = faces.map { DieFace($0) }
    }

    init(name: String, slot: GearSlot, rarity: Rarity, dieFaces: [DieFace], id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.slot = slot
        self.rarity = rarity
        self.faces = dieFaces
    }

    /// Fresh copy with a brand-new identity, used whenever a die is granted.
    func instantiated() -> Die {
        Die(name: name, slot: slot, rarity: rarity, dieFaces: faces.map { DieFace($0.kind, imbueTiers: $0.imbueTiers, bonusCrit: $0.bonusCrit) })
    }

    /// Average crit chance across the six faces — the headline number on cards.
    var averageCrit: Double {
        guard !faces.isEmpty else { return 0 }
        return faces.reduce(0) { $0 + $1.critChance } / Double(faces.count)
    }

    var hasImbue: Bool { faces.contains(where: \.isImbued) }

    /// Every god bound to this die through its faces' gifts.
    var blessings: [Deity] {
        faces.flatMap { face -> [Deity] in
            face.mark?.gods ?? []
        }
    }

    var isBlessed: Bool { !blessings.isEmpty }

    /// Rolls a face at random and decides on the spot whether it crits.
    func roll(critBonus: Double) -> (face: DieFace, isCrit: Bool, chance: Double) {
        let face = faces.randomElement() ?? DieFace(.block)
        let chance = min(DieFace.critCap, face.critChance + critBonus)
        return (face, Double.random(in: 0..<1) < chance, chance)
    }
}
