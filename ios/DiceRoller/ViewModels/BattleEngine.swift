import SwiftUI
import Observation

/// The result of one die settling during your turn. The crit is decided the
/// instant the die lands, from that face's own crit chance.
struct RolledFace: Identifiable, Hashable {
    let id: UUID
    let dieID: UUID
    let dieName: String
    let face: FaceKind
    /// A god's mark on this face, if the die carries one — resolved on top of
    /// whatever the face itself does.
    let mark: FaceMark?
    let isCrit: Bool
    let critChance: Double
    let imbueTiers: Int
    /// True when this face was carried over from last turn's freeze — such a
    /// face feeds +10% crit odds into any combo it joins.
    var wasHeld = false

    /// The name shown in tray and plan — the earned final-form title when the
    /// mark has run its full course.
    var displayName: String { mark?.title(for: face) ?? face.label }
}

/// Visual + logical state of one reel in the tray. A slot has its own identity
/// because a frozen face rides into the next turn as an extra reel *beside*
/// the die it came from — the die itself rolls again.
struct DieSlot: Identifiable {
    let id: UUID
    let die: Die
    var state: SlotState
    /// True for the extra reel holding a face carried over from a freeze.
    /// Carried reels never tumble; they hand you their face and retire.
    let isCarried: Bool

    init(die: Die, state: SlotState, isCarried: Bool = false) {
        self.id = isCarried ? UUID() : die.id
        self.die = die
        self.state = state
        self.isCarried = isCarried
    }

    enum SlotState: Equatable {
        case idle
        case rolling
        case rolled(RolledFace)
        case spent
    }
}

/// One action in the turn plan, in the exact order it will resolve.
/// A step is either a combo (several stacked faces) or a single face.
struct PlanStep: Identifiable {
    let id: UUID
    let faces: [RolledFace]
    let combo: ComboDef?
    /// Warrior only: bonus damage from swings already thrown this turn.
    let momentumBonus: Int
    /// Bonus damage banked by a Focus face earlier in the plan.
    let focusBonus: Int
    /// Chance the whole combo crits, from how many crit dice fed it.
    let comboCritChance: Double
    /// True when any member was carried over from a freeze — frozen fuel
    /// sharpens the chain's crit roll.
    let frozenFuel: Bool

    init(faces: [RolledFace], combo: ComboDef?, momentumBonus: Int = 0, focusBonus: Int = 0) {
        self.id = faces.first?.id ?? UUID()
        self.faces = faces
        self.combo = combo
        self.momentumBonus = momentumBonus
        self.focusBonus = focusBonus
        self.frozenFuel = faces.contains { $0.wasHeld }
        if let combo {
            if combo.guaranteedCrit {
                self.comboCritChance = 1.0
            } else {
                let base = GameData.comboCritChance(
                    critDice: faces.filter(\.isCrit).count,
                    totalDice: faces.count
                )
                self.comboCritChance = frozenFuel
                    ? min(1.0, base + GameData.frozenFuelCritBonus)
                    : base
            }
        } else {
            self.comboCritChance = 0
        }
    }

    var isCombo: Bool { combo != nil }
    var critDice: Int { faces.filter(\.isCrit).count }
    var hasCritFace: Bool { critDice > 0 }
    var isGuaranteedCrit: Bool { combo?.guaranteedCrit == true }
    var title: String { combo?.name ?? faces.first?.displayName ?? "" }
    /// Fused combos cost less than their faces played apart.
    var staminaCost: Int { GameData.comboStaminaCost(faces: faces.count) }

    /// How much every part of this chain is multiplied by before it lands:
    /// the length of the chain plus the weight of each critical face feeding
    /// it. Solo steps have no chain scale.
    var comboScale: Double {
        guard combo != nil else { return 1 }
        return GameData.comboOutputScale(faces: faces.count, critDice: critDice, crit: false)
    }

    /// The same scale with the chain's own critical roll landed.
    var comboCritScale: Double {
        guard combo != nil else { return 1 }
        return GameData.comboOutputScale(faces: faces.count, critDice: critDice, crit: true)
    }

    /// Damage this step deals before enemy block, at its normal (non-crit) roll.
    var damage: Int {
        if let combo {
            guard combo.damage > 0 else { return 0 }
            return GameData.scaleUp(combo.damage, by: comboScale) + momentumBonus + focusBonus
        }
        guard let face = faces.first, face.face.isAttack else { return 0 }
        let base = face.isCrit
            ? GameData.scaleUp(face.face.soloValue, by: GameData.faceCritMultiplier)
            : face.face.soloValue
        return base + momentumBonus + focusBonus
    }

    /// Damage if the combo lands critical (single faces already show their crit).
    var critDamage: Int {
        guard let combo, combo.damage > 0 else { return damage }
        return GameData.scaleUp(combo.damage, by: comboCritScale) + momentumBonus + focusBonus
    }

    /// Short non-damage effects, e.g. "+24 HP", "Poison 12×3".
    var effects: [String] {
        if let combo {
            // Everything the chain does rides the same length-and-crit curve
            // as its damage, so a long defensive chain is worth building too.
            let scale = comboScale
            func scaled(_ value: Int) -> Int { GameData.scaleUp(value, by: scale) }
            var parts: [String] = []
            if combo.blocksAll { parts.append("Blocks all") }
            if combo.bleedAmount > 0 { parts.append("Bleed \(scaled(combo.bleedAmount))×\(combo.bleedTurns)") }
            if combo.poisonAmount > 0 { parts.append("Poison \(scaled(combo.poisonAmount))×\(combo.poisonTurns)") }
            if combo.burnAmount > 0 { parts.append("Burn \(scaled(combo.burnAmount))×\(combo.burnTurns)") }
            if combo.heal > 0 { parts.append("+\(scaled(combo.heal)) HP") }
            if combo.regenAmount > 0 { parts.append("Regen \(scaled(combo.regenAmount))×\(combo.regenTurns)") }
            if combo.lifesteal { parts.append("Lifesteal") }
            if combo.block > 0 { parts.append("+\(scaled(combo.block)) Block") }
            if combo.dodge > 0 { parts.append("+\(combo.dodge) Evade") }
            if combo.pierce > 0 { parts.append("Pierce \(Int(combo.pierce * 100))%") }
            if combo.stagger > 0 { parts.append("Stagger \(Int(combo.stagger * 100))%") }
            if combo.reflect > 0 { parts.append("Reflect") }
            // Only the length of the chain pays stamina back now, and only
            // from three faces up — recipes have no printed refund.
            let bank = GameData.comboStaminaBank(faces: faces.count)
            if bank > 0 { parts.append("+\(bank) Stam") }
            return parts
        }
        guard let face = faces.first else { return [] }
        let multiplier = face.isCrit ? GameData.faceCritMultiplier : 1.0
        let value = GameData.scaleUp(face.face.soloValue, by: multiplier)
        var list: [String] = []
        switch face.face.soloKind {
        case .heal: list = ["+\(value) HP"]
        case .block: list = face.face == .brace ? ["+\(value) Block", "Carries"] : ["+\(value) Block"]
        case .evade: list = face.face == .roll ? ["Evade", "+\(value) Block"] : ["Evade next hit"]
        case .poison: list = ["Poison \(value)×2"]
        case .stamina: list = ["+\(face.isCrit ? 2 : 1) Stam"]
        case .focus: list = ["+1 Stam", "Next hit +5"]
        case .damage:
            if face.face == .runeFrost { list = ["Slow"] }
            else if face.face == .bomb { list = ["Burn 4×2"] }
        }
        // A gifted face announces its god's answer in the plan too.
        if let mark = face.mark, let gift = mark.gift {
            list.append(contentsOf: gift.effect(mark.depth).parts)
        }
        return list
    }

    /// One-line readout of what this step does.
    var valueLine: String {
        var parts: [String] = []
        if damage > 0 { parts.append("\(damage) DMG") }
        parts.append(contentsOf: effects)
        return parts.isEmpty ? "No effect" : parts.joined(separator: " · ")
    }

    var tint: Color {
        if let combo { return combo.tint }
        if hasCritFace { return Theme.gold }
        return faces.first?.face.tint ?? Theme.parchment
    }
}

/// A combo your current roll can actually make. `slots` lines up with the
/// recipe: the rolled face that would fill each slot, in order. Nothing about
/// it is ever named to you mid-fight — it only feeds the count on each die.
struct ComboCandidate: Identifiable {
    let combo: ComboDef
    let slots: [RolledFace]
    /// How many of its faces are already sitting in the turn plan.
    let placedCount: Int

    var id: String { combo.id }
    var chain: Int { combo.required.count }
    var faces: [RolledFace] { slots }
    var isInPlan: Bool { placedCount == chain }
    var critDice: Int { faces.filter(\.isCrit).count }

    /// Damage the finished chain would deal at full length — used to rank one
    /// chain against another.
    var projectedDamage: Int {
        guard combo.damage > 0 else { return 0 }
        let scale = GameData.comboOutputScale(faces: chain, critDice: critDice, crit: false)
        return GameData.scaleUp(combo.damage, by: scale)
    }
}

/// The banner, shockwave and sparks thrown by a chain as it resolves.
struct ComboFlash: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let chain: Int
    let summary: String
    let tint: Color
    let crit: Bool
}

/// Animation pose for a fighter sprite in the arena.
enum FighterPose: Equatable {
    case idle
    /// A foe winding up: the tell it shows before its blow actually lands.
    case telegraph
    case attack
    case hurt
    case block
    case dodge
    case heal
    case victory
    case defeat
}

/// Floating combat text event rendered above a fighter. `foeID` names the foe
/// it floats over in a pack fight; nil means over the player.
struct FloatText: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let color: Color
    let onEnemy: Bool
    var foeID: UUID? = nil
    let xJitter: CGFloat = .random(in: -26...26)
    let big: Bool
}

/// One foe on the deck: its own health, armour, block, statuses, telegraphed
/// intent and pose. A battle holds one for every enemy in the fight.
struct EnemyState: Identifiable {
    let id = UUID()
    let def: EnemyDef
    var hp: Int
    /// Metal worn over the health; direct damage chips it before health.
    let armourMax: Int
    var armour: Int
    var block = 0
    var bleedAmount = 0
    var bleedTurns = 0
    var poisonAmount = 0
    var poisonTurns = 0
    var burnAmount = 0
    var burnTurns = 0
    var stagger = 0.0
    var mark = 1.0
    var pose: FighterPose = .idle
    var intent: EnemyMove
    /// Which stage a multi-stage serpent-lord is currently in.
    var stageIndex = 0

    init(def: EnemyDef) {
        self.def = def
        self.hp = def.maxHP
        self.armourMax = def.armour
        self.armour = def.armour
        self.intent = def.pickMove(hpFraction: 1)
    }

    var isAlive: Bool { hp > 0 }
    var hpFraction: Double { def.maxHP > 0 ? Double(hp) / Double(def.maxHP) : 0 }
    /// Bosses re-coil a little sooner under the tighter economy.
    var stagedHPFraction: Double {
        def.isBoss ? min(1, hpFraction + GameData.bossStageShift) : hpFraction
    }
    var displayName: String { def.displayName(hpFraction: stagedHPFraction) }
}

/// Turn-based combat: one all-dice roll per turn, a stamina budget for placing
/// faces, per-face crits, ordered class combos with their own crit rolls,
/// statuses, and weighted enemy AI.
@Observable
final class BattleEngine {
    enum Phase: Equatable {
        case player
        case resolving
        case enemyActing
        case won
        case lost
    }

    // MARK: Config
    /// The foes in this fight, in the order they rose. Solo fights are a pack of one.
    private(set) var enemies: [EnemyState]
    let classID: String
    let critBonus: Double
    let maxStamina: Int
    /// How deep into the Duat this fight sits — scales enemy pressure.
    let hour: Int
    let playerMaxHP: Int
    /// How many faces of each god you carry — drives the divine passives.
    let devotion: [Deity: Int]
    private let comboPool: [ComboDef]
    private let burnBoost: (amount: Int, turns: Int)
    private let poisonBoost: (amount: Int, turns: Int)
    private let bloodTithe: Int

    // MARK: Player state
    private(set) var playerHP: Int
    private(set) var playerBlock = 0
    private(set) var dodgeStacks = 0
    private(set) var fullBlockActive = false
    private(set) var reflectFraction = 0.0
    private(set) var carryBlockActive = false
    private(set) var playerBleedAmount = 0
    private(set) var playerBleedTurns = 0
    private(set) var regenAmount = 0
    private(set) var regenTurns = 0
    /// Stamina left to spend this turn *before* the current plan is paid for.
    /// Committing a turn draws this down permanently; laying dice out in the
    /// plan does not touch it.
    private(set) var turnStamina: Int
    private(set) var nextTurnStamina = 0
    /// Damage banked onto next turn's first swing (Cleaving Follow-Through).
    private(set) var momentumCarry = 0
    /// Crit chance granted by blessings played this fight.
    private(set) var blessedCrit = 0.0

    // MARK: Enemy state
    /// Which foe your attacks are aimed at. It sticks until you tap another,
    /// and slides to the nearest living foe when your target falls mid-turn.
    private(set) var aimedID: UUID?
    /// Set for a beat when a boss re-coils, so the arena can announce it.
    private(set) var stageAnnouncement: String?

    // MARK: Board state
    /// Your actual loadout — six of these are drawn to the table every turn.
    /// Carried reels are added alongside them, never in place of them.
    private let loadoutDice: [Die]
    private(set) var slots: [DieSlot]
    /// The dice the current draw put on the table — the loadout's other dice
    /// wait in the bag this turn. The codex marks them.
    private(set) var drawnDieIDs: Set<UUID> = []
    private(set) var rolled: [RolledFace] = []
    private(set) var hasRolled = false
    /// Reels you froze this turn — their face carries into the next turn.
    private(set) var frozenSlotIDs: Set<UUID> = []
    /// Carried reels waiting to be laid out at the start of the next turn.
    private var pendingCarry: [DieSlot] = []
    /// Freezes spent this turn. Freezing is free; the allowance is the cost.
    private(set) var freezesUsed = 0
    /// Freeze mode: armed by the button above the commit button, then you tap
    /// dice in the tray to ice them.
    var freezeArmed = false
    private(set) var playOrder: [UUID] = []
    private(set) var phase: Phase = .player
    private(set) var turnNumber = 1
    private(set) var committedPlan: [PlanStep] = []
    private(set) var activeStepIndex: Int?
    private(set) var lastAction = "Roll your dice."

    // MARK: Fighter animation
    private(set) var playerPose: FighterPose = .idle
    /// The gods whose gifts ride the blow currently being thrown. The arena
    /// tints the strike and stamps their sigils over the impact; empty means a
    /// plain, unblessed swing.
    private(set) var strikeGods: [Deity] = []
    /// True when the face driving this blow carries a god's final form, so the
    /// flare blooms rather than just tinting.
    private(set) var strikeIsFinalForm = false

    /// Every chain this roll could make, longest first — rebuilt whenever the
    /// board changes rather than on every redraw. Never shown by name.
    private(set) var comboCandidates: [ComboCandidate] = []
    /// How many of those chains each rolled die could feed.
    private(set) var comboUseCounts: [UUID: Int] = [:]

    // MARK: Effects & stats
    /// Set for a beat as a chain lands, so the arena can slam its banner.
    private(set) var comboFlash: ComboFlash?
    private(set) var floaters: [FloatText] = []
    private(set) var shakeTrigger: CGFloat = 0
    /// Bumped every time a reel slams home, so the tray can flare with it.
    private(set) var slamPulse: Int = 0
    /// True on the beat the last reel of a roll locks.
    private(set) var lastReelLocked = false
    private(set) var damageDealt = 0
    private(set) var combosLanded = 0
    private(set) var critsLanded = 0

    init(
        enemies: [EnemyDef],
        dice: [Die],
        classID: String,
        maxHP: Int,
        startHP: Int,
        maxStamina: Int,
        hour: Int = 1,
        critBonus: Double,
        devotion: [Deity: Int] = [:]
    ) {
        let foes = enemies.map { EnemyState(def: $0) }
        self.enemies = foes
        self.aimedID = foes.first?.id
        self.classID = classID
        self.critBonus = critBonus + GameData.devotionCrit(devotion)
        self.maxStamina = maxStamina
        self.hour = hour
        self.playerMaxHP = maxHP
        self.playerHP = startHP
        self.turnStamina = maxStamina
        self.loadoutDice = dice
        let opening = Self.draw(count: GameData.diceDrawCount, from: dice, excluding: [])
        self.slots = opening.map { DieSlot(die: $0, state: .idle) }
        self.drawnDieIDs = Set(opening.map(\.id))
        self.devotion = devotion
        let pool = GameData.combosByPriority(for: classID, devotion: devotion)
        self.comboPool = pool
        self.burnBoost = GameData.burnBonus(devotion)
        self.poisonBoost = GameData.poisonBonus(devotion)
        self.bloodTithe = GameData.bloodTithe(devotion)

        // Bes stands in the doorway; Bastet lands you on your feet.
        self.playerBlock = GameData.openingBlock(devotion)
        self.dodgeStacks = GameData.openingEvades(devotion)
        if playerBlock > 0 || dodgeStacks > 0 {
            self.lastAction = "The gods are with you. Roll your dice."
        }
    }

    // MARK: - Derived

    /// The first foe's definition — used by records and reward screens.
    var enemy: EnemyDef { enemies[0].def }

    var enemyDefs: [EnemyDef] { enemies.map(\.def) }

    /// True when more than one foe rose from the river.
    var isPack: Bool { enemies.count > 1 }

    var livingFoes: [EnemyState] { enemies.filter(\.isAlive) }

    var hasLivingFoes: Bool { enemies.contains(where: \.isAlive) }

    // MARK: - Reading the blow before it lands

    /// Extra damage this foe has banked from how long the fight has run.
    func heatDamage(for foe: EnemyState) -> Int {
        foe.def.heatPerTurn * max(0, turnNumber - 1)
    }

    /// The hour's depth folded into a printed damage value. The single place
    /// the scaling lives, so the telegraph and the blow can never disagree.
    private func scaledDamage(_ printed: Int, heat: Int) -> Int {
        Int(Double(printed + heat + GameData.enemyDamageBonus(hour: hour))
            * GameData.enemyDamageScale(hour: hour))
    }

    /// What this foe's telegraphed move will actually do if it resolves right
    /// now — hour depth, heat and any pending stagger already applied. Drives
    /// the intent capsule so the number you read while planning is the number
    /// that hits you.
    func projectedStrike(for foe: EnemyState) -> (damage: Int, heal: Int, block: Int) {
        var damage = 0
        if foe.intent.damage > 0 {
            damage = scaledDamage(foe.intent.damage, heat: heatDamage(for: foe))
            if foe.stagger > 0 {
                damage = Int(Double(damage) * (1 - foe.stagger))
            }
            damage = max(0, damage)
        }
        return (damage, foe.intent.heal, foe.intent.block)
    }

    /// The foe your attacks are currently aimed at — or the nearest living one
    /// once your target has fallen. Solo fights resolve to the single foe.
    var aimedFoe: EnemyState? {
        if let id = aimedID, let foe = enemies.first(where: { $0.id == id && $0.isAlive }) {
            return foe
        }
        return enemies.first(where: \.isAlive)
    }

    /// Aim at a living foe while planning. Solo fights ignore it — there is
    /// nobody else to aim at.
    func aim(at id: UUID) {
        guard phase == .player,
              enemies.contains(where: { $0.id == id && $0.isAlive }),
              aimedID != id else { return }
        aimedID = id
        Haptics.light()
    }

    /// Index of the foe your attacks are aimed at, re-aiming to the nearest
    /// living foe when the target has fallen.
    private func aimedIndex() -> Int? {
        if let id = aimedID,
           let index = enemies.firstIndex(where: { $0.id == id && $0.isAlive }) {
            return index
        }
        guard let index = enemies.firstIndex(where: \.isAlive) else { return nil }
        aimedID = enemies[index].id
        return index
    }

    /// How much of the aimed enemy is left, 0 through 1.
    var enemyHPFraction: Double { aimedFoe?.hpFraction ?? 0 }

    /// Bosses re-coil a little sooner under the tighter economy.
    var stagedHPFraction: Double { aimedFoe?.stagedHPFraction ?? 0 }

    /// The name shown in the arena — bosses rename themselves as they re-coil.
    var enemyDisplayName: String {
        aimedFoe?.displayName ?? enemies.last?.displayName ?? ""
    }

    /// Extra damage the aimed foe has accumulated simply by the fight running long.
    var enemyHeat: Int {
        guard let foe = aimedFoe else { return 0 }
        return foe.def.heatPerTurn * max(0, turnNumber - 1)
    }

    var playedFaces: [RolledFace] {
        playOrder.compactMap { faceID in rolled.first { $0.id == faceID } }
    }

    var turnPlan: [PlanStep] { buildPlan(from: playedFaces) }

    var displayedPlan: [PlanStep] {
        phase == .player ? turnPlan : committedPlan
    }

    var projectedDamage: Int {
        turnPlan.reduce(0) { $0 + $1.damage }
    }

    /// Total stamina the current plan will spend — fused combos cost less
    /// than their faces played apart.
    var planStaminaCost: Int {
        turnPlan.reduce(0) { $0 + $1.staminaCost }
    }

    /// What the bar reads: the turn's budget minus whatever the plan as it
    /// stands will cost. Because both placing and taking back a die only
    /// reshape the plan, the two are exact mirrors of each other — laying a
    /// die out and pulling it straight back always lands on the same number.
    var stamina: Int { max(0, turnStamina - planStaminaCost) }

    /// Stamina you would open the next turn with if you committed the plan as
    /// it stands: leftover + recovery (capped at the base maximum), plus the
    /// overcharge you earned — Focus, Energize, the gods, and a single point
    /// from any chain of three faces or more.
    var projectedNextTurnStamina: Int {
        let carried = min(maxStamina, stamina + GameData.staminaRecoveryPerTurn)
        let comboBank = turnPlan.reduce(0) { total, step in
            guard step.combo != nil else { return total }
            return total + GameData.comboStaminaBank(faces: step.faces.count)
        }
        return carried + nextTurnStamina + comboBank
    }

    /// Stamina cost of a hypothetical play order, discounts included.
    private func planCost(for order: [UUID]) -> Int {
        let faces = order.compactMap { faceID in rolled.first { $0.id == faceID } }
        return buildPlan(from: faces).reduce(0) { $0 + $1.staminaCost }
    }

    var hasCombo: Bool { turnPlan.contains { $0.isCombo } }

    // MARK: - Chains in hand

    /// Recounts the chains hiding in this roll. The recipes themselves are
    /// never named to you mid-fight — the search only feeds the number each die
    /// carries in the tray, so which chain it is stays yours to discover.
    /// Far too heavy to run from a view body, so it is recomputed only when the
    /// board actually changes: a reel lands, a die moves, a turn begins.
    private func refreshCandidates() {
        guard phase == .player, hasRolled, !isRolling else { return clearChainCounts() }
        let pool = candidatePool
        guard !pool.isEmpty else { return clearChainCounts() }
        let planned = Set(playOrder)
        var found: [ComboCandidate] = []
        for combo in comboPool {
            guard let slots = assign(combo: combo, pool: pool) else { continue }
            let placed = slots.filter { planned.contains($0.id) }.count
            found.append(ComboCandidate(combo: combo, slots: slots, placedCount: placed))
        }
        comboCandidates = found.sorted { lhs, rhs in
            if lhs.chain != rhs.chain { return lhs.chain > rhs.chain }
            if lhs.projectedDamage != rhs.projectedDamage { return lhs.projectedDamage > rhs.projectedDamage }
            return lhs.combo.name < rhs.combo.name
        }
        comboUseCounts = countUses(comboCandidates, pool: pool)
    }

    private func clearChainCounts() {
        if !comboCandidates.isEmpty { comboCandidates = [] }
        if !comboUseCounts.isEmpty { comboUseCounts = [:] }
    }

    /// How many different chains each rolled die could feed. Dice that are
    /// interchangeable with a chosen one — same face, same god, same edge —
    /// share the credit, so two identical dice never read differently.
    private func countUses(_ candidates: [ComboCandidate], pool: [RolledFace]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for candidate in candidates {
            let signatures = Set(candidate.faces.map(signature))
            for face in pool where signatures.contains(signature(face)) {
                counts[face.id, default: 0] += 1
            }
        }
        return counts
    }

    /// Two dice with the same signature are worth exactly the same to a recipe.
    private func signature(_ face: RolledFace) -> String {
        "\(face.face.rawValue)|\(face.mark?.deity.rawValue ?? "-")|\(face.mark?.giftID ?? "-")|\(face.isCrit)"
    }

    /// How many chains are still reachable from where the turn stands, named
    /// to nobody. Falls as you spend dice on a line.
    var chainsInHand: Int { comboCandidates.count }

    /// The busiest die in the tray — used to scale how loudly the counts read.
    var maxChainCount: Int { comboUseCounts.values.max() ?? 0 }

    /// How many chains this particular die could feed.
    func chainCount(for faceID: UUID) -> Int { comboUseCounts[faceID] ?? 0 }

    /// Faces a chain could still be built out of *right now*: everything left
    /// in the tray, plus the tail of the plan that has not yet fused into a
    /// chain — those are the only laid-out dice a new face can still join.
    /// Dice already welded into a finished chain drop out, so the tallies on
    /// the tray fall live as you commit to a line. Criticals sort first so
    /// chains are fed the sharpest dice.
    private var candidatePool: [RolledFace] {
        danglingTail + availableFaces.sorted { lhs, rhs in
            lhs.isCrit && !rhs.isCrit
        }
    }

    /// The run of unfused faces sitting at the end of the plan. A chain forms
    /// from adjacent chips, so only this tail is still open to new dice.
    private var danglingTail: [RolledFace] {
        var tail: [RolledFace] = []
        for step in buildPlan(from: playedFaces).reversed() {
            guard step.combo == nil else { break }
            tail.insert(contentsOf: step.faces, at: 0)
        }
        return tail
    }

    /// Tries to fill a recipe out of the pool. Returns the first working
    /// assignment, or nil when this roll simply cannot make it.
    private func assign(combo: ComboDef, pool: [RolledFace]) -> [RolledFace]? {
        var chosen = [RolledFace?](repeating: nil, count: combo.required.count)
        var used: Set<UUID> = []
        // Permissive slots ("any strike") can match a lot of dice; the budget
        // keeps the search bounded no matter how wide the recipe opens up.
        var budget = 2500

        func search(slot: Int) -> Bool {
            guard budget > 0 else { return false }
            budget -= 1
            if slot == combo.required.count { return groupRulesHold(combo, chosen) }
            let pattern = combo.required[slot]
            // Dice that are interchangeable for this slot are only tried once.
            var tried: Set<String> = []
            for face in pool where !used.contains(face.id) && pattern.matches(face.face, mark: face.mark) {
                guard tried.insert(signature(face)).inserted else { continue }
                chosen[slot] = face
                used.insert(face.id)
                if groupRulesHold(combo, chosen), search(slot: slot + 1) { return true }
                used.remove(face.id)
                chosen[slot] = nil
            }
            return false
        }

        return search(slot: 0) ? chosen.compactMap { $0 } : nil
    }

    /// Same-kind / all-distinct / distinct-gods rules, checked against the
    /// slots filled so far so dead branches are cut early.
    private func groupRulesHold(_ combo: ComboDef, _ chosen: [RolledFace?]) -> Bool {
        let faces = chosen.compactMap { $0 }
        guard !faces.isEmpty else { return true }
        let kinds = faces.map(\.face)
        if combo.sameKind, Set(kinds).count != 1 { return false }
        if combo.distinct, Set(kinds).count != kinds.count { return false }
        if combo.distinctDeities {
            let gods = faces.compactMap { $0.mark?.deity }
            if gods.count != faces.count { return false }
            if Set(gods).count != faces.count { return false }
        }
        return true
    }

    var isRolling: Bool { slots.contains { $0.state == .rolling } }

    /// How many reels of the current roll have already slammed home.
    var lockedReelCount: Int {
        slots.filter { if case .rolled = $0.state { return true } else { return false } }.count
    }

    /// Beat before the first reel locks — a short, hard pull.
    private static let firstLockDelay: Double = 0.85

    /// Face-change interval every drum runs at. The whole row whirls flat out
    /// and stays there; only the reel about to land ever slows down.
    static let drumStepBase: Double = 0.032

    /// Gaps between reels locking. Each one hangs a little longer than the
    /// last, so the row still winds up — but the drums never lose their speed.
    private func lockGaps(count: Int) -> [Double] {
        let scale: Double = count > 7 ? 0.72 : (count > 5 ? 0.84 : 1)
        return (0..<count).map { min(0.46 + 0.1 * Double($0), 1.0) * scale }
    }

    /// Where this reel sits in the stopping order, left to right.
    private func reelIndex(slotID: UUID) -> Int {
        rollableDice.firstIndex(of: slotID) ?? 0
    }

    /// Every drum turns at exactly the same pace, whatever its place in the
    /// row. A reel waiting its turn never drags — it whirls flat out until the
    /// moment its own stop comes up.
    func drumStep(slotID: UUID) -> Double { Self.drumStepBase }

    /// How far out from its own stop this reel starts braking. The window is
    /// short and identical for every reel, so the row holds full speed and only
    /// the next die in line winds down as it lands.
    func brakeWindows(slotID: UUID) -> (crawl: Double, haul: Double, ring: Double) {
        (crawl: 0.16, haul: 0.38, ring: 0.3)
    }

    /// Seconds from the pull until this die slams home — the reel uses it to
    /// wind its drum down just before the stop.
    func lockTime(slotID: UUID) -> Double {
        let order = rollableDice
        guard let index = order.firstIndex(of: slotID) else { return Self.firstLockDelay }
        return Self.firstLockDelay + lockGaps(count: order.count).prefix(index).reduce(0, +)
    }

    var canRoll: Bool { phase == .player && !hasRolled && rollableDice.isEmpty == false }

    /// Reels that will actually tumble: the six dice this turn's draw put on
    /// the table. A frozen face rides along as its own carried reel instead
    /// of benching the die it came from.
    private var rollableDice: [UUID] {
        slots.filter { !$0.isCarried }.map(\.id)
    }

    func isFrozen(slotID: UUID) -> Bool { frozenSlotIDs.contains(slotID) }

    var frozenCount: Int { frozenSlotIDs.count }

    /// How many carried faces the last freeze handed you this turn.
    var carriedCount: Int { slots.filter(\.isCarried).count }

    /// Which reel is currently showing this rolled face.
    private func slotID(showing faceID: UUID) -> UUID? {
        slots.first { slot in
            if case .rolled(let face) = slot.state { return face.id == faceID }
            return false
        }?.id
    }

    /// Freezes still available this turn.
    var freezesRemaining: Int { max(0, freezesPerTurn - freezesUsed) }

    var freezesPerTurn: Int { GameData.freezesPerTurn(hour: hour) }

    /// How many dice the loadout holds beyond the ones on the table — the
    /// bag this hand was drawn from.
    var undrawnCount: Int { max(0, loadoutDice.count - drawnDieIDs.count) }

    /// Draws the turn's hand at random from the whole loadout. Dice whose
    /// faces are currently held are left in the bag, so a held face never
    /// arrives alongside a fresh roll of its own die — the hold is the only
    /// way to guarantee a face comes back.
    static func draw(count: Int, from dice: [Die], excluding heldIDs: Set<UUID>) -> [Die] {
        let bag = dice.filter { !heldIDs.contains($0.id) }
        guard bag.count > count else { return bag }
        return Array(bag.shuffled().prefix(count))
    }

    /// Is there a settled, unplayed die left that could still be frozen?
    var canFreezeAny: Bool {
        guard phase == .player else { return false }
        return slots.contains { slot in
            guard case .rolled(let face) = slot.state else { return false }
            return !playOrder.contains(face.id)
        }
    }

    var canCommit: Bool { phase == .player && hasRolled && !isRolling }

    /// Faces still sitting in the tray waiting to be played.
    var availableFaces: [RolledFace] {
        rolled.filter { !playOrder.contains($0.id) }
    }

    // MARK: - Player actions

    /// Rolls the whole loadout at once, settling reel by reel. The row is
    /// shuffled fresh every roll, so the order the faces arrive in is never
    /// the same twice — carried faces keep their place at the front.
    func rollAll() {
        guard canRoll else { return }
        hasRolled = true
        clearChainCounts()
        shuffleRow()
        let tumbling = rollableDice
        for index in slots.indices where !slots[index].isCarried {
            slots[index].state = .rolling
        }
        lastAction = "The drums spin..."
        lastReelLocked = false
        Haptics.medium()
        let gaps = lockGaps(count: tumbling.count)
        Task {
            try? await Task.sleep(for: .seconds(Self.firstLockDelay))
            for (offset, slotID) in tumbling.enumerated() {
                guard phase == .player else { return }
                settle(slotID: slotID, isLast: offset == tumbling.count - 1)
                guard offset < tumbling.count - 1 else { break }
                try? await Task.sleep(for: .seconds(gaps[offset]))
            }
            guard phase == .player else { return }
            let crits = rolled.filter(\.isCrit).count
            lastAction = crits > 0
                ? "\(crits) CRITICAL\(crits > 1 ? "S" : "")! Feed them into a chain."
                : "Chain faces together — alone they barely scratch, fused they hit hard."
        }
    }

    /// Shuffles the tumbling reels into a fresh order for this roll. Carried
    /// reels stay pinned at the front so a face you paid a freeze for is
    /// always exactly where you left it.
    private func shuffleRow() {
        let carried = slots.filter(\.isCarried)
        let rolling = slots.filter { !$0.isCarried }.shuffled()
        slots = carried + rolling
    }

    private func settle(slotID: UUID, isLast: Bool = false) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }),
              slots[index].state == .rolling else { return }
        let die = slots[index].die
        let outcome = die.roll(critBonus: critBonus + blessedCrit)
        let result = RolledFace(
            id: UUID(),
            dieID: die.id,
            dieName: die.name,
            face: outcome.face.kind,
            mark: outcome.face.mark,
            isCrit: outcome.isCrit,
            critChance: outcome.chance,
            imbueTiers: outcome.face.imbueTiers
        )
        slots[index].state = .rolled(result)
        rolled.append(result)
        slamPulse += 1
        lastReelLocked = isLast
        refreshCandidates()

        // Every reel lands like a hammer on stone; crits and the closing reel
        // hit hardest of all.
        let kick: CGFloat = outcome.isCrit ? 0.85 : (isLast ? 0.62 : 0.36)
        withAnimation(.linear(duration: 0.16)) { shakeTrigger += kick }
        if outcome.isCrit {
            critsLanded += 1
            Haptics.heavy()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(55))
                Haptics.heavy()
            }
        } else if isLast {
            Haptics.heavy()
        } else {
            Haptics.medium()
        }
    }

    /// Place a rolled face into the play bar. A face costs 1 stamina on its
    /// own, less once it fuses into a combo — the discount lands the moment
    /// the fusion forms. Passing `before` inserts ahead of that step.
    func placeInPlayBar(faceID: UUID, before targetID: UUID? = nil) {
        guard phase == .player, let face = rolled.first(where: { $0.id == faceID }) else { return }
        guard faceID != targetID else { return }

        var prospective = playOrder
        prospective.removeAll { $0 == faceID }
        if let targetID, let targetIndex = prospective.firstIndex(of: targetID) {
            prospective.insert(faceID, at: targetIndex)
        } else {
            prospective.append(faceID)
        }

        // The plan prices itself: if the whole prospective order fits the
        // turn's budget it is affordable. Nothing is charged here, so taking
        // the die straight back restores the bar exactly.
        guard planCost(for: prospective) <= turnStamina else {
            lastAction = "Out of stamina — take a die back or end your turn."
            Haptics.warning()
            return
        }

        // Playing a frozen reel thaws it and hands the freeze back.
        if let slotID = slotID(showing: face.id), frozenSlotIDs.contains(slotID) {
            frozenSlotIDs.remove(slotID)
            freezesUsed = max(0, freezesUsed - 1)
        }
        playOrder = prospective
        refreshCandidates()
        Haptics.light()
    }

    /// Send a chip from the play bar back to the tray. The bar reprices the
    /// remaining plan, so the die's stamina comes back in full — and pulling a
    /// die out of a fusion takes back the discount that fusion was granted.
    func returnToTray(faceID: UUID) {
        guard phase == .player, playOrder.contains(faceID) else { return }
        playOrder.removeAll { $0 == faceID }
        refreshCandidates()
        Haptics.light()
    }

    /// Freeze (or thaw) a settled reel. Freezing is free but you only get
    /// \(freezesPerTurn) a turn. A frozen face keeps exactly as it landed,
    /// crit and all — and the die it came from still rolls again next turn,
    /// so a freeze hands you an extra face rather than benching a die.
    func toggleFreeze(slotID: UUID) {
        guard phase == .player,
              let index = slots.firstIndex(where: { $0.id == slotID }),
              case .rolled(let face) = slots[index].state else { return }

        if frozenSlotIDs.contains(slotID) {
            frozenSlotIDs.remove(slotID)
            freezesUsed = max(0, freezesUsed - 1)
            lastAction = "\(face.displayName) thaws — it will not carry over."
            Haptics.light()
            return
        }

        guard !playOrder.contains(face.id) else {
            lastAction = "Take that die out of your plan before freezing it."
            Haptics.warning()
            return
        }
        guard freezesRemaining > 0 else {
            lastAction = "No freezes left this turn — \(freezesPerTurn) is the limit."
            Haptics.warning()
            return
        }
        freezesUsed += 1
        frozenSlotIDs.insert(slotID)
        let left = freezesRemaining
        lastAction = slots[index].isCarried
            ? "\(face.displayName) held again — it carries another turn."
            : "\(face.displayName) held — it carries over and the die still rolls next turn."
        if left == 0 { freezeArmed = false }
        Haptics.medium()
    }

    func commitTurn() {
        guard canCommit else { return }
        phase = .resolving
        Task { await resolveTurn() }
    }

    // MARK: - Turn resolution

    private func resolveTurn() async {
        let steps = buildPlan(from: playedFaces)
        committedPlan = steps

        // Frozen, unplayed faces survive the turn; everything else is spent.
        // The dice they came from are *not* benched — each carried face rides
        // into next turn as its own extra reel while its die rolls again.
        let carriedSlots = slots.filter { slot in
            guard frozenSlotIDs.contains(slot.id), case .rolled(let face) = slot.state else { return false }
            return !playOrder.contains(face.id)
        }
        for index in slots.indices {
            if case .rolled = slots[index].state { slots[index].state = .spent }
        }
        frozenSlotIDs = []
        freezesUsed = 0
        freezeArmed = false
        // Faces that survive the freeze remember it — frozen fuel for any
        // chain they join next turn.
        pendingCarry = carriedSlots.compactMap { slot in
            guard case .rolled(let face) = slot.state else { return nil }
            var held = face
            held.wasHeld = true
            return DieSlot(die: slot.die, state: .rolled(held), isCarried: true)
        }
        rolled = pendingCarry.compactMap { slot in
            if case .rolled(let face) = slot.state { return face }
            return nil
        }
        // Committing is the only thing that truly spends stamina. Draw the
        // plan's cost out of the budget as the plan is cleared, so the bar
        // never reads the cost twice.
        turnStamina = max(0, turnStamina - steps.reduce(0) { $0 + $1.staminaCost })
        playOrder = []
        clearChainCounts()

        for (index, step) in steps.enumerated() {
            activeStepIndex = index
            try? await Task.sleep(for: .milliseconds(260))
            if let combo = step.combo {
                let didCrit = Double.random(in: 0..<1) < step.comboCritChance
                playerPose = combo.damage > 0 ? .attack : (combo.blocksAll || combo.block > 0 ? .block : .heal)
                noteStrikeGods(in: step.faces)
                applyCombo(combo, step: step, crit: didCrit)
                // After the chain's own effect lands, every gifted face in it
                // speaks in turn — gently scaled, with duos and the pantheon
                // flourish stacked on top.
                resolveGiftRiders(in: step, crit: didCrit)
                // The deck holds its breath: long chains and criticals hang
                // on screen before the next step fires.
                let hang = 480 + min(step.faces.count, 5) * 90 + (didCrit ? 420 : 0)
                try? await Task.sleep(for: .milliseconds(hang))
            } else if let face = step.faces.first {
                playerPose = pose(for: face.face)
                noteStrikeGods(in: [face])
                applyFace(face, bonus: step.momentumBonus + step.focusBonus)
                try? await Task.sleep(for: .milliseconds(380))
            }
            resetPoses()
            if !hasLivingFoes {
                activeStepIndex = nil
                finishVictory()
                return
            }
        }

        activeStepIndex = nil
        try? await Task.sleep(for: .milliseconds(380))
        await enemyTurn()
    }

    private func pose(for face: FaceKind) -> FighterPose {
        if face.isAttack || face == .poison { return .attack }
        switch face.soloKind {
        case .heal: return .heal
        case .block: return .block
        case .evade: return .dodge
        default: return .idle
        }
    }

    private func resetPoses() {
        if phase != .won && phase != .lost {
            playerPose = .idle
            strikeGods = []
            strikeIsFinalForm = false
            for index in enemies.indices { enemies[index].pose = .idle }
        }
    }

    /// Reads which gods are behind the blow about to land, in play order, so
    /// the arena can burn it in their colours. A rite face contributes both of
    /// its gods; the flare shows at most two.
    private func noteStrikeGods(in faces: [RolledFace]) {
        var ordered: [Deity] = []
        var finalForm = false
        for face in faces {
            guard let mark = face.mark else { continue }
            if mark.isFinalForm { finalForm = true }
            for god in mark.gods where !ordered.contains(god) {
                ordered.append(god)
            }
        }
        strikeGods = Array(ordered.prefix(2))
        strikeIsFinalForm = finalForm
    }

    // MARK: - Applying combos

    private func applyCombo(_ combo: ComboDef, step: PlanStep, crit: Bool) {
        combosLanded += 1
        // A chain pays no refund of its own any more: three faces or more hand
        // you a single point next turn, and nothing else. The bar is meant to
        // hold you to your base — Focus and the gods are how you push past it.
        nextTurnStamina += GameData.comboStaminaBank(faces: step.faces.count)
        // The chain announces itself: banner, shockwave and a rumble that
        // grows with how long the chain was.
        announce(combo: combo, step: step, crit: crit)
        // Everything this chain does rides its length and the crit dice that
        // fed it — a critical face is never wasted inside a combo. A god's own
        // chain grows with the devotion standing behind it when it fires.
        var multiplier = GameData.comboOutputScale(
            faces: step.faces.count,
            critDice: step.critDice,
            crit: crit
        )
        if combo.devotionRequired > 0, let god = combo.deity {
            let scale = GameData.devotionChainScale(devotion: devotion[god] ?? 0, required: combo.devotionRequired)
            if scale > 1 {
                multiplier *= scale
                addFloat("DEVOTION \(devotion[god] ?? 0)", color: god.tint, onEnemy: false)
            }
        }

        if crit {
            addFloat("CRITICAL", color: Theme.gold, onEnemy: false, big: true)
            withAnimation(.linear(duration: 0.45)) { shakeTrigger += 1 }
        }
        if step.critDice > 0 {
            addFloat("\(step.critDice)× CRIT FUEL", color: Theme.gold, onEnemy: false)
        }
        if step.faces.count >= 3 {
            addFloat("\(step.faces.count)-CHAIN", color: combo.tint, onEnemy: false)
        }
        addFloat(combo.name.uppercased(), color: crit ? Theme.gold : combo.tint,
                 onEnemy: combo.damage > 0 || combo.poisonAmount > 0, big: true)
        lastAction = crit ? "\(combo.name) CRITS! \(combo.flavor)" : "\(combo.name)! \(combo.flavor)"

        if combo.blocksAll {
            fullBlockActive = true
            reflectFraction = max(reflectFraction, combo.reflect)
            addFloat("FULL GUARD", color: Theme.steel, onEnemy: false, big: true)
        }
        if combo.carryBlock { carryBlockActive = true }
        if combo.cleanseBleed, playerBleedTurns > 0 {
            playerBleedTurns = 0
            playerBleedAmount = 0
            addFloat("Bleed cleared", color: Theme.forest, onEnemy: false)
        }
        if combo.momentumNext > 0 {
            momentumCarry += GameData.scaleUp(combo.momentumNext, by: multiplier)
        }

        if combo.damage > 0 {
            var raw = GameData.scaleUp(combo.damage, by: multiplier) + step.momentumBonus + step.focusBonus
            if let foe = aimedFoe {
                if combo.scalesWithBleed { raw += foe.bleedAmount * 2 }
                if combo.scalesWithWounds { raw += (foe.def.maxHP - foe.hp) / 5 }
                if combo.scalesWithBurn { raw += foe.burnAmount * 3 }
            }
            let dealt = damageEnemy(raw, pierce: combo.pierce)
            if combo.lifesteal, dealt > 0 {
                playerHP = min(playerMaxHP, playerHP + dealt)
                addFloat("+\(dealt)", color: Theme.forest, onEnemy: false)
            }
        }
        if combo.bleedAmount > 0 {
            applyBleed(GameData.scaleUp(combo.bleedAmount, by: multiplier),
                       turns: crit ? combo.bleedTurns + 1 : combo.bleedTurns)
        }
        if combo.poisonAmount > 0 {
            applyPoison(GameData.scaleUp(combo.poisonAmount, by: multiplier),
                        turns: crit ? combo.poisonTurns + 1 : combo.poisonTurns)
        }
        if combo.burnAmount > 0 {
            applyBurn(GameData.scaleUp(combo.burnAmount, by: multiplier),
                      turns: crit ? combo.burnTurns + 1 : combo.burnTurns)
        }
        if combo.heal > 0 {
            var amount = GameData.scaleUp(combo.heal, by: multiplier)
            if combo.scalesWithBlock { amount += playerBlock }
            playerHP = min(playerMaxHP, playerHP + amount)
            addFloat("+\(amount)", color: Theme.forest, onEnemy: false)
        }
        if combo.regenAmount > 0 {
            regenAmount = max(regenAmount, GameData.scaleUp(combo.regenAmount, by: multiplier))
            regenTurns = max(regenTurns, combo.regenTurns)
            addFloat("Regen", color: Theme.forest, onEnemy: false)
        }
        if combo.block > 0 {
            let amount = GameData.scaleUp(combo.block, by: multiplier)
            playerBlock += amount
            addFloat("+\(amount) Block", color: Theme.steel, onEnemy: false)
        }
        if combo.dodge > 0 {
            dodgeStacks += combo.dodge
            addFloat("+\(combo.dodge) Evade", color: Theme.steel, onEnemy: false)
        }
        if combo.stagger > 0 {
            if let index = aimedIndex() {
                enemies[index].stagger = max(enemies[index].stagger, min(0.85, combo.stagger * (crit ? 1.3 : 1.0)))
            }
            addFloat("Staggered", color: Theme.frost, onEnemy: true)
        }
        if combo.mark > 1 {
            if let index = aimedIndex() {
                enemies[index].mark = max(enemies[index].mark, combo.mark)
            }
            addFloat("Marked", color: Theme.venom, onEnemy: true)
        }
        // Only a real chain — three faces or more — pays anything forward.
        let bank = GameData.comboStaminaBank(faces: step.faces.count)
        if bank > 0 {
            addFloat("+\(bank) Stamina", color: Theme.gold, onEnemy: false)
        }
    }

    // MARK: - Applying single faces

    private func applyFace(_ face: RolledFace, bonus: Int) {
        let multiplier = face.isCrit ? GameData.faceCritMultiplier : 1.0
        let value = GameData.scaleUp(face.face.soloValue, by: multiplier)
        if face.isCrit {
            // Name the face that crit — never just "CRIT" on its own.
            addFloat("\(face.displayName.uppercased()) CRIT", color: Theme.gold, onEnemy: face.face.isAttack)
            withAnimation(.linear(duration: 0.3)) { shakeTrigger += 0.6 }
            Haptics.heavy()
        }

        if face.face.isAttack {
            damageEnemy(value + bonus, pierce: 0)
            lastAction = face.isCrit
                ? "\(face.displayName) crits for \(value + bonus)!"
                : "\(face.displayName) hits for \(value + bonus)."
            if face.face == .runeFrost {
                if let index = aimedIndex() {
                    enemies[index].stagger = max(enemies[index].stagger, 0.2)
                }
                addFloat("Slowed", color: Theme.frost, onEnemy: true)
            }
            if face.face == .bomb {
                applyBurn(face.isCrit ? 6 : 4, turns: 2)
            }
            applyGiftRider(of: face, multiplier: multiplier)
            return
        }

        switch face.face.soloKind {
        case .heal:
            playerHP = min(playerMaxHP, playerHP + value)
            addFloat("+\(value)", color: Theme.forest, onEnemy: false)
            lastAction = "You recover \(value) health."
        case .block:
            playerBlock += value
            if face.face == .brace { carryBlockActive = true }
            addFloat("+\(value) Block", color: Theme.steel, onEnemy: false)
            lastAction = "You brace behind \(value) block."
        case .evade:
            dodgeStacks += 1
            if face.face == .roll {
                playerBlock += value
                addFloat("+\(value) Block", color: Theme.steel, onEnemy: false)
            }
            addFloat("+1 Evade", color: Theme.steel, onEnemy: false)
            lastAction = "You ready an evasion."
        case .poison:
            applyPoison(value, turns: 2)
            lastAction = "A drop of venom finds its mark."
        case .stamina:
            let gain = face.isCrit ? 2 : 1
            nextTurnStamina += gain
            addFloat("+\(gain) Stamina Next", color: Theme.gold, onEnemy: false)
            lastAction = "You steady your breath — +\(gain) stamina next turn."
        case .focus:
            nextTurnStamina += 1
            addFloat("Focused", color: Theme.gold, onEnemy: false)
            lastAction = "You narrow your aim."
        case .damage:
            break
        }

        applyGiftRider(of: face, multiplier: multiplier)
    }

    // MARK: - Shared god-effect dispatcher

    /// Everything a `DivineFaceEffect` does, in one place — gift riders, duos
    /// and flourish payoffs all funnel through here. The banner and the
    /// last-action line are the caller's; this only lands the fields.
    private func applyEffectFields(_ effect: DivineFaceEffect, multiplier: Double) {
        if effect.blocksAll {
            fullBlockActive = true
            reflectFraction = max(reflectFraction, effect.reflect)
            addFloat("FULL GUARD", color: Theme.steel, onEnemy: false, big: true)
        }
        if effect.cleanse, playerBleedTurns > 0 {
            playerBleedTurns = 0
            playerBleedAmount = 0
            addFloat("Bleed cleared", color: Theme.forest, onEnemy: false)
        }
        if effect.critBoost > 0 {
            blessedCrit = min(0.4, blessedCrit + effect.critBoost)
            addFloat("+\(Int(effect.critBoost * 100))% Crit", color: Theme.gold, onEnemy: false)
        }
        if effect.damage > 0 {
            var raw = GameData.scaleUp(effect.damage, by: multiplier)
            if let foe = aimedFoe {
                if effect.scalesWithWounds { raw += (foe.def.maxHP - foe.hp) / 5 }
                if effect.scalesWithBurn { raw += foe.burnAmount * 3 }
                if effect.scalesWithStagger, foe.stagger > 0 { raw += 12 }
            }
            let dealt = damageEnemy(raw, pierce: effect.pierce)
            if effect.lifesteal, dealt > 0 {
                playerHP = min(playerMaxHP, playerHP + dealt)
                addFloat("+\(dealt)", color: Theme.forest, onEnemy: false)
            }
        }
        if effect.burnAmount > 0 {
            applyBurn(GameData.scaleUp(effect.burnAmount, by: multiplier), turns: effect.burnTurns)
        }
        if effect.poisonAmount > 0 {
            applyPoison(GameData.scaleUp(effect.poisonAmount, by: multiplier), turns: effect.poisonTurns)
        }
        if effect.bleedAmount > 0 {
            applyBleed(GameData.scaleUp(effect.bleedAmount, by: multiplier), turns: effect.bleedTurns)
        }
        if effect.heal > 0 {
            let amount = GameData.scaleUp(effect.heal, by: multiplier)
            playerHP = min(playerMaxHP, playerHP + amount)
            addFloat("+\(amount)", color: Theme.forest, onEnemy: false)
        }
        if effect.regenAmount > 0 {
            regenAmount = max(regenAmount, GameData.scaleUp(effect.regenAmount, by: multiplier))
            regenTurns = max(regenTurns, effect.regenTurns)
            addFloat("Regen", color: Theme.forest, onEnemy: false)
        }
        if effect.block > 0 {
            let amount = GameData.scaleUp(effect.block, by: multiplier)
            playerBlock += amount
            addFloat("+\(amount) Block", color: Theme.steel, onEnemy: false)
        }
        if effect.carryBlock { carryBlockActive = true }
        if effect.dodgeGain > 0 {
            dodgeStacks += effect.dodgeGain
            addFloat("+\(effect.dodgeGain) Evade", color: Theme.steel, onEnemy: false)
        }
        if effect.stagger > 0 {
            if let index = aimedIndex() {
                enemies[index].stagger = max(enemies[index].stagger, min(0.85, effect.stagger))
            }
            addFloat("Staggered", color: Theme.frost, onEnemy: true)
        }
        if effect.mark > 1 {
            if let index = aimedIndex() {
                enemies[index].mark = max(enemies[index].mark, effect.mark)
            }
            addFloat("Marked", color: Theme.venom, onEnemy: true)
        }
        if effect.staminaNext > 0 {
            nextTurnStamina += effect.staminaNext
            addFloat("+\(effect.staminaNext) Stamina", color: Theme.gold, onEnemy: false)
        }
        if effect.reflect > 0 && !effect.blocksAll {
            reflectFraction = max(reflectFraction, effect.reflect)
            addFloat("Scorching \(Int(effect.reflect * 100))%", color: Theme.sunGold, onEnemy: false)
        }
    }

    // MARK: - Gift riders

    /// After a chain's own effect lands, every gifted face in the chain speaks
    /// in turn, in play order, gently scaled. Two different gods in one chain
    /// fire their named duo on top; three or more trigger the pantheon
    /// flourish, boosting every rider in the chain.
    private func resolveGiftRiders(in step: PlanStep, crit: Bool) {
        let gifted = step.faces.filter { $0.mark != nil }
        guard !gifted.isEmpty else { return }

        var weights: [Deity: Int] = [:]
        for member in gifted {
            for god in member.mark?.gods ?? [] { weights[god, default: 0] += 1 }
        }
        let gods = Set(weights.keys)
        let flourish = gods.count >= 3
        var riderScale = GameData.comboRiderScale(faces: step.faces.count, critDice: step.critDice, crit: crit)
        if flourish {
            riderScale *= GameData.pantheonFlourish
            addFloat("PANTHEON FLOURISH", color: Theme.gold, onEnemy: false, big: true)
            withAnimation(.linear(duration: 0.4)) { shakeTrigger += 0.8 }
            Haptics.heavy()
        }

        for member in gifted {
            applyGiftRider(of: member, multiplier: riderScale)
        }

        // Two different gods in one chain: their duo answers as a bonus rider.
        if gods.count >= 2, let duo = DuoContent.bestDuo(among: gods, weightedBy: weights) {
            applyDuo(duo, bound: false, multiplier: riderScale)
        }
    }

    /// One gifted face's rider, played solo or inside a chain — the gift speaks
    /// on top of whatever the face itself does. A bound face (a dual-god rite)
    /// fires its duo at full strength every single play.
    private func applyGiftRider(of face: RolledFace, multiplier: Double) {
        guard let mark = face.mark, let gift = mark.gift else { return }
        let effect = gift.effect(mark.depth)
        let label = mark.isFinalForm ? gift.finalFormName : gift.name
        addFloat(label.uppercased(), color: mark.deity.tint,
                 onEnemy: effect.damage > 0 || effect.poisonAmount > 0 || effect.bleedAmount > 0 || effect.burnAmount > 0,
                 big: mark.isFinalForm)
        lastAction = mark.isFinalForm
            ? "\(gift.finalFormName) — \(mark.deity.name)'s final gift answers."
            : "\(gift.name) rides on top — \(mark.deity.name)'s gift answers."
        applyEffectFields(effect, multiplier: multiplier)

        if let rite = mark.rite, let duo = DuoContent.duo(mark.deity, rite) {
            applyDuo(duo, bound: true, multiplier: multiplier)
        }
    }

    /// A named duo: chained pairs get the taste, bound faces the real thing.
    private func applyDuo(_ duo: DuoDef, bound: Bool, multiplier: Double) {
        let effect = bound ? duo.bound : duo.chained
        addFloat(duo.name.uppercased(), color: duo.first.tint,
                 onEnemy: effect.damage > 0 || effect.poisonAmount > 0 || effect.bleedAmount > 0, big: true)
        lastAction = bound
            ? "\(duo.name) — bound together, \(duo.first.name) and \(duo.second.name) answer at full strength."
            : "\(duo.name) — \(duo.first.name) and \(duo.second.name) answer together."
        applyEffectFields(effect, multiplier: multiplier)
    }

    /// Statuses seep under armour — they land on health directly.
    private func applyBurn(_ amount: Int, turns: Int) {
        guard amount > 0, let index = aimedIndex() else { return }
        enemies[index].burnAmount = max(enemies[index].burnAmount, amount + burnBoost.amount)
        enemies[index].burnTurns = max(enemies[index].burnTurns, turns + burnBoost.turns)
        addFloat(burnBoost.turns > 0 ? "Burning! (Ra)" : "Burning!", color: Theme.ember, onEnemy: true)
    }

    private func applyPoison(_ amount: Int, turns: Int) {
        guard amount > 0, let index = aimedIndex() else { return }
        enemies[index].poisonAmount = max(enemies[index].poisonAmount, amount + poisonBoost.amount)
        enemies[index].poisonTurns = max(enemies[index].poisonTurns, turns + poisonBoost.turns)
        addFloat(poisonBoost.amount > 0 ? "Poisoned! (Anubis)" : "Poisoned!", color: Theme.venom, onEnemy: true)
    }

    private func applyBleed(_ amount: Int, turns: Int) {
        guard amount > 0, let index = aimedIndex() else { return }
        enemies[index].bleedAmount = max(enemies[index].bleedAmount, amount)
        enemies[index].bleedTurns = max(enemies[index].bleedTurns, turns)
        addFloat("Bleeding!", color: Theme.blood, onEnemy: true)
    }

    @discardableResult
    private func damageEnemy(_ raw: Int, pierce: Double) -> Int {
        guard let index = aimedIndex() else { return 0 }
        var foe = enemies[index]
        defer { enemies[index] = foe }

        var damage = Int(Double(raw) * foe.mark)
        if foe.mark > 1 { foe.mark = 1.0 }
        // Block first — the guard chews the hit before the plate.
        if foe.block > 0 {
            let ignored = Int(Double(foe.block) * pierce)
            let effectiveBlock = max(0, foe.block - ignored)
            let absorbed = min(effectiveBlock, damage)
            foe.block -= absorbed
            damage -= absorbed
            if absorbed > 0 { addFloat("Blocked \(absorbed)", color: Theme.steel, onEnemy: true, foe: foe.id) }
            if ignored > 0 { addFloat("Pierced!", color: Theme.gold, onEnemy: true, foe: foe.id) }
        }
        // Then the armour plate soaks what is left. Pierce punches through it
        // exactly as it does block; statuses never touch it at all.
        if foe.armour > 0 {
            let ignored = Int(Double(foe.armourMax) * pierce)
            let effectiveArmour = max(0, foe.armour - ignored)
            let absorbed = min(effectiveArmour, damage)
            foe.armour -= absorbed
            damage -= absorbed
            if absorbed > 0 {
                addFloat("Armour \(absorbed)", color: Theme.bronze, onEnemy: true, foe: foe.id)
                if foe.armour == 0 {
                    addFloat("ARMOUR BROKEN", color: Theme.boneWhite, onEnemy: true,
                             big: true, foe: foe.id)
                    withAnimation(.linear(duration: 0.4)) { shakeTrigger += 0.8 }
                    Haptics.heavy()
                }
            }
            if ignored > 0 { addFloat("Pierced!", color: Theme.gold, onEnemy: true, foe: foe.id) }
        }
        guard damage > 0 else {
            foe.pose = .block
            return 0
        }
        foe.pose = .hurt
        foe.hp = max(0, foe.hp - damage)
        damageDealt += damage
        addFloat("-\(damage)", color: Theme.ember, onEnemy: true, big: damage >= 40, foe: foe.id)
        // Sobek takes his cut of every wound.
        if bloodTithe > 0, playerHP < playerMaxHP {
            playerHP = min(playerMaxHP, playerHP + bloodTithe)
            addFloat("+\(bloodTithe) Sobek", color: Theme.nileGreen, onEnemy: false)
        }
        if damage >= 45 {
            withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
            Haptics.heavy()
        }
        return damage
    }

    // MARK: - Enemy turn

    private func enemyTurn() async {
        phase = .enemyActing
        for index in enemies.indices where enemies[index].isAlive {
            enemies[index].block = 0
        }

        // Statuses seep under armour: every living foe takes its ticks up front.
        for index in enemies.indices where enemies[index].isAlive {
            for tick in statusTicks(index: index) {
                try? await Task.sleep(for: .milliseconds(360))
                enemies[index].pose = .hurt
                enemies[index].hp = max(0, enemies[index].hp - tick.amount)
                damageDealt += tick.amount
                addFloat("-\(tick.amount) \(tick.label)", color: tick.color, onEnemy: true,
                         foe: enemies[index].id)
                lastAction = "\(enemies[index].displayName) takes \(tick.amount) \(tick.label.lowercased()) damage."
                try? await Task.sleep(for: .milliseconds(300))
                resetPoses()
                if !hasLivingFoes { finishVictory(); return }
            }
        }

        // Then each living foe acts, one after another.
        for index in enemies.indices where enemies[index].isAlive {
            try? await Task.sleep(for: .milliseconds(260))
            if await foeActs(index: index) { return }
            if !hasLivingFoes { finishVictory(); return }
        }

        fullBlockActive = false
        reflectFraction = 0

        try? await Task.sleep(for: .milliseconds(380))
        startPlayerTurn()
    }

    /// One foe takes its telegraphed turn. Returns true when the player died.
    private func foeActs(index: Int) async -> Bool {
        var foe = enemies[index]
        defer { enemies[index] = foe }

        let move = foe.intent
        lastAction = "\(foe.displayName) uses \(move.comboName ?? move.name)!"

        if move.block > 0 {
            foe.pose = .block
            foe.block += move.block
            addFloat("+\(move.block) Block", color: Theme.steel, onEnemy: true, foe: foe.id)
            try? await Task.sleep(for: .milliseconds(360))
            resetPoses()
        }
        if move.heal > 0 {
            foe.pose = .heal
            foe.hp = min(foe.def.maxHP, foe.hp + move.heal)
            addFloat("+\(move.heal)", color: Theme.forest, onEnemy: true, foe: foe.id)
            try? await Task.sleep(for: .milliseconds(360))
            resetPoses()
        }

        // Nehebkau's scales — and Apep's fury — build the longer you take.
        // The hour's depth presses harder still.
        let heat = heatDamage(for: foe)
        let attackFaces = max(1, move.faces.filter(\.isAttack).count)
        var landedAnyHit = false
        if move.damage > 0 {
            var total = scaledDamage(move.damage, heat: heat)
            if heat > 0 {
                addFloat("+\(heat) Heat", color: Theme.ember, onEnemy: true, foe: foe.id)
            }
            if foe.stagger > 0 {
                total = Int(Double(total) * (1 - foe.stagger))
                addFloat("Staggered!", color: Theme.frost, onEnemy: true, foe: foe.id)
                foe.stagger = 0
            }
            let perHit = total / attackFaces
            var remainder = total - perHit * attackFaces
            for _ in 0..<attackFaces {
                // The tell: the foe coils before it strikes, so the blow is
                // read on the deck a beat before it arrives.
                foe.pose = .telegraph
                try? await Task.sleep(for: .milliseconds(300))
                foe.pose = .attack
                var hit = perHit + remainder
                remainder = 0
                if fullBlockActive {
                    playerPose = .block
                    addFloat("BLOCKED", color: Theme.steel, onEnemy: false)
                    if reflectFraction > 0 {
                        let back = Int(Double(hit) * reflectFraction)
                        if back > 0 {
                            foe.hp = max(0, foe.hp - back)
                            damageDealt += back
                            addFloat("-\(back) Riposte", color: Theme.gold, onEnemy: true, foe: foe.id)
                        }
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    resetPoses()
                    continue
                }
                if dodgeStacks > 0 {
                    dodgeStacks -= 1
                    playerPose = .dodge
                    addFloat("Evaded!", color: Theme.steel, onEnemy: false)
                    Haptics.light()
                    try? await Task.sleep(for: .milliseconds(300))
                    resetPoses()
                    continue
                }
                if playerBlock > 0 {
                    let absorbed = min(playerBlock, hit)
                    playerBlock -= absorbed
                    hit -= absorbed
                    if absorbed > 0 {
                        playerPose = .block
                        addFloat("Blocked \(absorbed)", color: Theme.steel, onEnemy: false)
                    }
                }
                guard hit > 0 else {
                    try? await Task.sleep(for: .milliseconds(300))
                    resetPoses()
                    continue
                }
                landedAnyHit = true
                playerPose = .hurt
                playerHP = max(0, playerHP - hit)
                addFloat("-\(hit)", color: Theme.blood, onEnemy: false, big: hit >= 20)
                withAnimation(.linear(duration: 0.3)) { shakeTrigger += 1 }
                Haptics.heavy()
                try? await Task.sleep(for: .milliseconds(300))
                resetPoses()
            }
        }

        if move.bleedAmount > 0 && landedAnyHit {
            playerBleedAmount = move.bleedAmount
            playerBleedTurns = move.bleedTurns
            addFloat("Bleeding!", color: Theme.blood, onEnemy: false)
        }

        if playerHP <= 0 {
            finishDefeat("\(foe.displayName) puts out the disc...")
            return true
        }
        return false
    }

    private struct StatusTick {
        let amount: Int
        let label: String
        let color: Color
    }

    private func statusTicks(index: Int) -> [StatusTick] {
        var ticks: [StatusTick] = []
        if enemies[index].bleedTurns > 0 {
            ticks.append(StatusTick(amount: enemies[index].bleedAmount, label: "Bleed", color: Theme.blood))
            enemies[index].bleedTurns -= 1
        }
        if enemies[index].poisonTurns > 0 {
            ticks.append(StatusTick(amount: enemies[index].poisonAmount, label: "Poison", color: Theme.venom))
            enemies[index].poisonTurns -= 1
        }
        if enemies[index].burnTurns > 0 {
            ticks.append(StatusTick(amount: enemies[index].burnAmount, label: "Burn", color: Theme.ember))
            enemies[index].burnTurns -= 1
        }
        return ticks
    }

    private func startPlayerTurn() {
        if carryBlockActive {
            carryBlockActive = false
        } else {
            playerBlock = 0
        }

        if regenTurns > 0 {
            playerHP = min(playerMaxHP, playerHP + regenAmount)
            regenTurns -= 1
            addFloat("+\(regenAmount) Regen", color: Theme.forest, onEnemy: false)
        }

        if playerBleedTurns > 0 {
            playerHP = max(0, playerHP - playerBleedAmount)
            playerBleedTurns -= 1
            addFloat("-\(playerBleedAmount) Bleed", color: Theme.blood, onEnemy: false)
            if playerHP <= 0 {
                finishDefeat("You bleed out...")
                return
            }
        }

        // The bar never refills: unspent stamina carries and each turn
        // recovers a single point, capped at the base maximum. Chains, not the
        // clock, are how you refuel — earned stamina (Focus, combo banks,
        // blessings) lands above the cap and expires if left unspent.
        let recovered = min(maxStamina, min(turnStamina, maxStamina) + GameData.staminaRecoveryPerTurn)
        turnStamina = recovered + nextTurnStamina
        freezesUsed = 0
        freezeArmed = false
        if nextTurnStamina > 0 {
            addFloat("+\(nextTurnStamina) Stamina", color: Theme.gold, onEnemy: false)
        }
        nextTurnStamina = 0
        playOrder = []
        clearChainCounts()
        committedPlan = []
        activeStepIndex = nil
        // Lay the board out fresh: a fresh draw from the loadout — everything
        // except the dice whose faces you held — plus one extra reel for each
        // carried face.
        let carriedSlots = pendingCarry
        pendingCarry = []
        let heldDieIDs = Set(carriedSlots.map { $0.die.id })
        let drawn = Self.draw(count: GameData.diceDrawCount, from: loadoutDice, excluding: heldDieIDs)
        slots = carriedSlots + drawn.map { DieSlot(die: $0, state: .idle) }
        drawnDieIDs = Set(drawn.map(\.id))
        rolled = carriedSlots.compactMap { slot in
            if case .rolled(let face) = slot.state { return face }
            return nil
        }
        hasRolled = false
        // Telegraph the next round: every living foe picks its move, and a
        // serpent-lord re-coils into its next stage as its health falls.
        var reCoiled = false
        for index in enemies.indices where enemies[index].isAlive {
            let fraction = enemies[index].stagedHPFraction
            let newStage = enemies[index].def.stageIndex(hpFraction: fraction)
            if newStage != enemies[index].stageIndex,
               let stage = enemies[index].def.stage(hpFraction: fraction) {
                reCoiled = true
                stageAnnouncement = stage.arrival
                lastAction = stage.arrival
                addFloat(stage.name, color: Theme.blood, onEnemy: true, big: true, foe: enemies[index].id)
            }
            enemies[index].stageIndex = newStage
            enemies[index].intent = enemies[index].def.pickMove(hpFraction: fraction)
        }
        turnNumber += 1
        let held = carriedSlots.count
        if reCoiled {
            withAnimation(.linear(duration: 0.5)) { shakeTrigger += 1 }
            Haptics.heavy()
        } else {
            stageAnnouncement = nil
            if held > 0 {
                lastAction = "\(held) face\(held > 1 ? "s" : "") held — roll the rest and chain them together."
            } else if stamina <= GameData.staminaRecoveryPerTurn {
                lastAction = "Turn \(turnNumber) — you open on \(stamina); only chains pay stamina back."
            } else {
                lastAction = "Turn \(turnNumber) — roll your dice."
            }
        }
        phase = .player
        resetPoses()
        refreshCandidates()
    }

    private func finishVictory() {
        phase = .won
        playerPose = .victory
        for index in enemies.indices { enemies[index].pose = .defeat }
        Haptics.success()
        lastAction = isPack
            ? "The last of the pack sinks beneath the water!"
            : "\(enemyDisplayName) is defeated!"
    }

    private func finishDefeat(_ message: String) {
        phase = .lost
        playerPose = .defeat
        for index in enemies.indices where enemies[index].isAlive {
            enemies[index].pose = .victory
        }
        Haptics.failure()
        lastAction = message
    }

    // MARK: - Ordered combo detection

    /// Scans the play bar left to right: adjacent chips matching one of your
    /// class's recipes fuse into a single step; everything else resolves alone.
    func buildPlan(from faces: [RolledFace]) -> [PlanStep] {
        var steps: [PlanStep] = []
        var index = 0
        var attacksSoFar = 0
        var pendingFocus = 0
        var pendingMomentum = momentumCarry

        while index < faces.count {
            var matched = false
            for combo in comboPool {
                let length = combo.required.count
                guard index + length <= faces.count else { continue }
                let window = Array(faces[index..<index + length])
                guard combo.matches(window.map(\.face), marks: window.map(\.mark)) else { continue }

                let momentum = combo.damage > 0 ? momentumBonus(for: attacksSoFar) + pendingMomentum : 0
                let focus = combo.damage > 0 ? pendingFocus : 0
                steps.append(PlanStep(faces: window, combo: combo, momentumBonus: momentum, focusBonus: focus))
                if combo.damage > 0 {
                    pendingFocus = 0
                    pendingMomentum = 0
                }
                attacksSoFar += window.filter { $0.face.isAttack }.count
                index += length
                matched = true
                break
            }
            if !matched {
                let face = faces[index]
                let isAttack = face.face.isAttack
                let momentum = isAttack ? momentumBonus(for: attacksSoFar) + pendingMomentum : 0
                let focus = isAttack ? pendingFocus : 0
                steps.append(PlanStep(faces: [face], combo: nil, momentumBonus: momentum, focusBonus: focus))
                if isAttack {
                    pendingFocus = 0
                    pendingMomentum = 0
                    attacksSoFar += 1
                }
                if face.face == .focus { pendingFocus += 5 }
                index += 1
            }
        }
        return steps
    }

    /// Warrior passive: each swing already thrown this turn adds damage.
    private func momentumBonus(for attacksSoFar: Int) -> Int {
        guard classID == "warrior", attacksSoFar > 0 else { return 0 }
        return attacksSoFar * 5
    }

    // MARK: - Chain spectacle

    /// Throws the banner, the shockwave and the rumble a landing chain earns.
    /// Everything scales with the length of the chain: a pair taps, a five-face
    /// chain shakes the deck.
    private func announce(combo: ComboDef, step: PlanStep, crit: Bool) {
        let length = step.faces.count
        let flash = ComboFlash(
            name: combo.name,
            chain: length,
            summary: step.valueLine,
            tint: crit ? Theme.gold : combo.tint,
            crit: crit
        )
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            comboFlash = flash
        }
        let kick = CGFloat(min(Double(length), 5.0)) * (crit ? 0.26 : 0.16)
        withAnimation(.linear(duration: 0.3)) { shakeTrigger += kick }
        Haptics.chain(length: length, crit: crit)
        Task {
            try? await Task.sleep(for: .milliseconds(crit ? 1250 : 1000))
            guard comboFlash?.id == flash.id else { return }
            withAnimation(.easeOut(duration: 0.25)) { comboFlash = nil }
        }
    }

    // MARK: - Floating text

    private func addFloat(_ text: String, color: Color, onEnemy: Bool, big: Bool = false, foe: UUID? = nil) {
        // Enemy-directed text floats over the foe it hit — the aimed one unless
        // the caller names another (the acting foe on the enemy turn).
        let target = onEnemy ? (foe ?? aimedFoe?.id) : nil
        let event = FloatText(text: text, color: color, onEnemy: onEnemy, foeID: target, big: big)
        floaters.append(event)
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            floaters.removeAll { $0.id == event.id }
        }
    }
}
