import Foundation

/// A permanent piece of equipment. The weapon and armour are never replaced,
/// only upgraded.
struct GearPiece: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var symbol: String
    var slot: GearSlot
    var dice: [Die]

    init(name: String, symbol: String, slot: GearSlot, dice: [Die], id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.slot = slot
        self.dice = dice
    }
}

/// Everything the hero carries into a fight.
struct Loadout: Hashable, Codable {
    var weapon: GearPiece
    var armor: GearPiece

    /// The collection never grows: five weapon dice and three armour dice.
    /// Equipment improvements replace or modify a die rather than quietly
    /// adding a ninth, so the draw stays understandable.
    static let maxDice = GameData.ownedDiceTotal

    var allDice: [Die] {
        weapon.dice + armor.dice
    }

    var diceCount: Int { allDice.count }

    var isFull: Bool { diceCount >= Loadout.maxDice }

    var pieces: [GearPiece] { [weapon, armor] }

    /// Adds a die to its matching gear piece. Returns false when at the cap.
    mutating func add(_ die: Die) -> Bool {
        guard !isFull else { return false }
        switch die.slot {
        case .weapon: weapon.dice.append(die)
        case .armor: armor.dice.append(die)
        }
        return true
    }

    mutating func remove(dieID: UUID) {
        weapon.dice.removeAll { $0.id == dieID }
        armor.dice.removeAll { $0.id == dieID }
    }

    /// Applies a transform to a single die wherever it lives.
    mutating func mutate(dieID: UUID, _ transform: (inout Die) -> Void) {
        if let index = weapon.dice.firstIndex(where: { $0.id == dieID }) {
            transform(&weapon.dice[index])
        } else if let index = armor.dice.firstIndex(where: { $0.id == dieID }) {
            transform(&armor.dice[index])
        }
    }

    func die(id: UUID) -> Die? {
        allDice.first { $0.id == id }
    }
}
