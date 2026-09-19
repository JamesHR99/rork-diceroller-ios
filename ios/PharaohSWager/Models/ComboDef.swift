import SwiftUI

/// Which gear piece a combo belongs to — used to group the codex.
enum ComboSource: String, Hashable {
    case weapon
    case armor

    var label: String {
        switch self {
        case .weapon: "Weapon Combos"
        case .armor: "Armour Combos"
        }
    }
}

/// One ingredient line of a combo recipe: a face pattern and how many of it
/// the chain asks for. Order within the run of neighbouring dice never
/// matters — three Swift Slashes side by side make the same chain whichever
/// tap they arrived from.
struct ComboIngredient: Hashable {
    let pattern: FacePattern
    let count: Int

    init(_ pattern: FacePattern, _ count: Int = 1) {
        self.pattern = pattern
        self.count = count
    }

    var label: String {
        count == 1 ? pattern.label : "\(count)× \(pattern.label)"
    }
}

/// A combo recipe. It only forms out of dice standing next to each other in
/// the plan; within that run of neighbours the order of the ingredients does
/// not matter. Recipes are never listed for the player — a chain names itself
/// the first time it lands and is kept in the codex from then on.
struct ComboDef: Identifiable, Hashable {
    let id: String
    let name: String
    /// Class that owns this combo; nil means every class can use it.
    let owner: String?
    let source: ComboSource
    let required: [ComboIngredient]
    /// All matched faces must be different kinds (Arcane Storm).
    let distinct: Bool

    let damage: Int
    let heal: Int
    let shield: Int
    /// Guaranteed single-hit dodges granted when this action starts.
    let dodgeCharges: Int

    let bleedAmount: Int
    let bleedTurns: Int
    let poisonAmount: Int
    let poisonTurns: Int
    let burnAmount: Int
    let burnTurns: Int
    let regenAmount: Int
    let regenTurns: Int

    /// Fraction of the enemy's defences this attack ignores (0–1).
    let pierce: Double
    /// Fraction the enemy's next attack is weakened by (0–1).
    let weaken: Double
    /// How much harder the next attack on the target lands, in percentage
    /// points. Additive on the hit, never multiplied over it.
    let markPercent: Int
    /// Fraction of damage your shield absorbs thrown back at the attacker.
    let reflect: Double
    /// A recipe whose defence lands immediately and whose strike waits until
    /// later in the round, so the guard is up before the enemy's blow.
    let staged: Bool

    let lifesteal: Bool
    /// Damage grows with the enemy's bleed stacks (Hemorrhage).
    let scalesWithBleed: Bool
    /// Damage grows with how wounded the enemy already is (Executioner).
    let scalesWithWounds: Bool
    /// Damage grows with the burn already on the enemy.
    let scalesWithBurn: Bool
    /// Damage carried into next turn's first swing (momentum recipes).
    let momentumNext: Int
    /// This combo always crits, no matter which dice fed it.
    let guaranteedCrit: Bool

    let flavor: String

    init(
        id: String,
        name: String,
        owner: String?,
        source: ComboSource,
        required: [ComboIngredient],
        distinct: Bool = false,
        damage: Int = 0,
        heal: Int = 0,
        shield: Int = 0,
        dodgeCharges: Int = 0,
        bleedAmount: Int = 0,
        bleedTurns: Int = 0,
        poisonAmount: Int = 0,
        poisonTurns: Int = 0,
        burnAmount: Int = 0,
        burnTurns: Int = 0,
        regenAmount: Int = 0,
        regenTurns: Int = 0,
        pierce: Double = 0,
        weaken: Double = 0,
        markPercent: Int = 0,
        reflect: Double = 0,
        staged: Bool = false,
        lifesteal: Bool = false,
        scalesWithBleed: Bool = false,
        scalesWithWounds: Bool = false,
        scalesWithBurn: Bool = false,
        momentumNext: Int = 0,
        guaranteedCrit: Bool = false,
        flavor: String
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.source = source
        self.required = required
        self.distinct = distinct
        self.damage = damage
        self.heal = heal
        self.shield = shield
        self.dodgeCharges = dodgeCharges
        self.bleedAmount = bleedAmount
        self.bleedTurns = bleedTurns
        self.poisonAmount = poisonAmount
        self.poisonTurns = poisonTurns
        self.burnAmount = burnAmount
        self.burnTurns = burnTurns
        self.regenAmount = regenAmount
        self.regenTurns = regenTurns
        self.pierce = pierce
        self.weaken = weaken
        self.markPercent = markPercent
        self.reflect = reflect
        self.staged = staged
        self.lifesteal = lifesteal
        self.scalesWithBleed = scalesWithBleed
        self.scalesWithWounds = scalesWithWounds
        self.scalesWithBurn = scalesWithBurn
        self.momentumNext = momentumNext
        self.guaranteedCrit = guaranteedCrit
        self.flavor = flavor
    }

    /// Total faces the recipe consumes.
    var faceCount: Int { required.reduce(0) { $0 + $1.count } }

    /// Dice consumed by this recipe; each recipe resolves as one action.
    var diceCount: Int { faceCount }

    /// The two beats a staged recipe resolves on, named for the card and the
    /// timeline. A single-impact recipe has none.
    var stagedBeats: (guardFirst: String, strikeLater: String)? {
        guard staged else { return nil }
        return ("Defence ready", "Then strike")
    }

    /// What this action *is*, which decides which god powers answer it.
    var roles: ActionRole {
        var roles: ActionRole = .none
        if damage > 0 || scalesWithBleed || scalesWithWounds || scalesWithBurn {
            roles.insert(.attack)
        }
        if shield > 0 { roles.insert(.guardian) }
        if dodgeCharges > 0 { roles.insert(.evade) }
        if heal > 0 || regenAmount > 0 || lifesteal || momentumNext > 0 { roles.insert(.support) }
        return roles
    }

    /// How specific this recipe is — exact slots beat wildcards when two
    /// recipes of the same shape could both match.
    var specificity: Int { required.reduce(0) { $0 + ($1.pattern.isExact ? 1 : 0) } }

    /// Can this recipe be satisfied out of these faces, with quantities and
    /// wildcards but no order? Each face is used at most once. Returns the
    /// indices of the faces it would consume, or nil.
    ///
    /// The recipe only needs *enough* faces, not exactly its own length: any
    /// face it does not consume is left for another recipe or to resolve on
    /// its own. Demanding an exact count meant a spare die in the plan broke
    /// the combo apart entirely.
    func match(from faces: [FaceKind]) -> [Int]? {
        guard faces.count >= faceCount else { return nil }
        var used = Array(repeating: false, count: faces.count)
        var assignment: [Int] = []

        func search(line: Int) -> Bool {
            guard line < required.count else { return true }
            let pattern = required[line].pattern
            let need = required[line].count
            var chosen: [Int] = []
            func pick(_ start: Int, taken: Int) -> Bool {
                if taken == need {
                    let snapshot = assignment
                    assignment.append(contentsOf: chosen)
                    if search(line: line + 1) { return true }
                    assignment = snapshot
                    return false
                }
                for index in start..<faces.count where !used[index] && pattern.matches(faces[index]) {
                    used[index] = true
                    chosen.append(index)
                    if pick(index + 1, taken: taken + 1) { return true }
                    chosen.removeLast()
                    used[index] = false
                }
                return false
            }
            return pick(0, taken: 0)
        }

        guard search(line: 0) else { return nil }
        if distinct, Set(assignment.map { faces[$0] }).count != faceCount { return nil }
        return assignment
    }

    /// Does this set of faces satisfy the recipe? (Codex path.)
    func matches(_ faces: [FaceKind]) -> Bool {
        guard faces.count == faceCount else { return false }
        return match(from: faces) != nil
    }

    /// Human-readable ingredient list.
    var ingredientSummary: String {
        required.map(\.label).joined(separator: " + ")
    }

    /// One-line effect readout for the codex and play bar.
    var effectSummary: String {
        var parts: [String] = []
        if damage > 0 { parts.append("\(damage) dmg") }
        if scalesWithBleed { parts.append("+2 dmg per bleed stack") }
        if scalesWithWounds { parts.append("+dmg vs wounded") }
        if scalesWithBurn { parts.append("+3 dmg per burn stack") }
        if pierce > 0 { parts.append("ignores \(Int(pierce * 100))% defences") }
        if weaken > 0 { parts.append("weaken \(Int(weaken * 100))%") }
        if markPercent > 0 { parts.append("mark +\(markPercent)%") }
        if reflect > 0 { parts.append("reflects \(Int(reflect * 100))% of blocked hits") }
        if bleedAmount > 0 { parts.append("bleed \(bleedAmount)×\(bleedTurns)") }
        if poisonAmount > 0 { parts.append("poison \(poisonAmount)×\(poisonTurns)") }
        if burnAmount > 0 { parts.append("burn \(burnAmount)×\(burnTurns)") }
        if heal > 0 { parts.append("heal \(heal)") }
        if regenAmount > 0 { parts.append("regen \(regenAmount)×\(regenTurns)") }
        if lifesteal { parts.append("heals for damage dealt") }
        if shield > 0 { parts.append("\(shield) shield") }
        if dodgeCharges > 0 { parts.append("+\(dodgeCharges)% evade") }
        if momentumNext > 0 { parts.append("+\(momentumNext) next swing") }
        if guaranteedCrit { parts.append("always crits") }
        return parts.joined(separator: ", ")
    }

    var tint: Color {
        if guaranteedCrit { return Theme.gold }
        switch owner {
        case "archer": return Theme.ember
        case "warrior": return Theme.steelBlue
        case "rogue": return Theme.venom
        case "magician": return Theme.arcane
        default: return Theme.gold
        }
    }
}

