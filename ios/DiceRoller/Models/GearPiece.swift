import Foundation

/// A permanent piece of equipment. The weapon and armour are never replaced —
/// only upgraded — while the item slot starts empty and can be swapped.
struct GearPiece: Identifiable, Hashable {
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
struct Loadout: Hashable {
    var weapon: GearPiece
    var armor: GearPiece
    var item: GearPiece?

    /// The collection never grows: five weapon dice and three armour dice.
    /// Equipment improvements replace or modify a die rather than quietly
    /// adding a ninth, so the draw stays understandable.
    static let maxDice = GameData.ownedDiceTotal

    var allDice: [Die] {
        weapon.dice + armor.dice + (item?.dice ?? [])
    }

    var diceCount: Int { allDice.count }

    var isFull: Bool { diceCount >= Loadout.maxDice }

    var pieces: [GearPiece] {
        var list = [weapon, armor]
        if let item { list.append(item) }
        return list
    }

    /// Adds a die to its matching gear piece. Returns false when at the cap.
    mutating func add(_ die: Die) -> Bool {
        guard !isFull else { return false }
        switch die.slot {
        case .weapon: weapon.dice.append(die)
        case .armor: armor.dice.append(die)
        case .item:
            if item != nil { item?.dice.append(die) } else { return false }
        }
        return true
    }

    mutating func remove(dieID: UUID) {
        weapon.dice.removeAll { $0.id == dieID }
        armor.dice.removeAll { $0.id == dieID }
        item?.dice.removeAll { $0.id == dieID }
    }

    /// Applies a transform to a single die wherever it lives.
    mutating func mutate(dieID: UUID, _ transform: (inout Die) -> Void) {
        if let index = weapon.dice.firstIndex(where: { $0.id == dieID }) {
            transform(&weapon.dice[index])
        } else if let index = armor.dice.firstIndex(where: { $0.id == dieID }) {
            transform(&armor.dice[index])
        } else if var piece = item, let index = piece.dice.firstIndex(where: { $0.id == dieID }) {
            transform(&piece.dice[index])
            item = piece
        }
    }

    func die(id: UUID) -> Die? {
        allDice.first { $0.id == id }
    }
}
