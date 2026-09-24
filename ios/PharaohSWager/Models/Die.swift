import Foundation

/// Legacy persistence bucket from the pre-dice-bag rules. Gameplay no longer
/// treats dice as weapon or armour dice; both cases are one unified pool.
enum GearSlot: String, Hashable, CaseIterable, Codable {
    case weapon
    case armor

    var label: String { "Dice" }

    var symbol: String { "dice.fill" }
}

/// A six-faced die in the run's unified dice bag. At most one god may claim
/// a die as its patron. The legacy slot is serialized only for save/content
/// compatibility and has no combat, draw, reward or UI meaning.
struct Die: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var slot: GearSlot // legacy storage only
    var rarity: Rarity
    var faces: [DieFace]
    /// The god who claimed this die, if any. A blessed die is the entry ticket
    /// to that god's upgrades and to their pairing with another god.
    var patron: Deity?

    init(name: String, slot: GearSlot, rarity: Rarity = .common, faces: [FaceKind], patron: Deity? = nil, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.slot = slot
        self.rarity = rarity
        self.faces = faces.map { DieFace($0) }
        self.patron = patron
    }

    init(name: String, slot: GearSlot, rarity: Rarity, dieFaces: [DieFace], patron: Deity? = nil, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.slot = slot
        self.rarity = rarity
        self.faces = dieFaces
        self.patron = patron
    }

    /// Fresh copy with a brand-new identity, used whenever a die is granted.
    func instantiated() -> Die {
        Die(
            name: name, slot: slot, rarity: rarity,
            dieFaces: faces.map { DieFace($0.kind, imbueTiers: $0.imbueTiers, bonusCrit: $0.bonusCrit) },
            patron: patron
        )
    }

    /// Average crit chance across the six faces — the headline number on cards.
    var averageCrit: Double {
        guard !faces.isEmpty else { return 0 }
        return faces.reduce(0) { $0 + $1.critChance } / Double(faces.count)
    }

    var hasImbue: Bool { faces.contains(where: \.isImbued) }

    var isBlessed: Bool { patron != nil }

    /// Rolls a face at random and decides on the spot whether it crits.
    func roll(critBonus: Double) -> (face: DieFace, isCrit: Bool, chance: Double) {
        let face = faces.randomElement() ?? DieFace(.block)
        let chance = min(DieFace.critCap, face.critChance + critBonus)
        return (face, Double.random(in: 0..<1) < chance, chance)
    }
}
