import SwiftUI
import Observation

/// The result of one die settling during your turn. The crit is decided the
/// instant the die lands, from that face's own crit chance.
struct RolledFace: Identifiable, Hashable {
    let id: UUID
    let dieID: UUID
    let dieName: String
    let face: FaceKind
    /// The god who claims the die this face came from, if any — their blessing
    /// answers whatever this face does.
    let patron: Deity?
    let isCrit: Bool
    let critChance: Double
    let imbueTiers: Int
    /// True when this face was carried over from last turn's freeze.
    var wasHeld = false
    /// Chisel substitutions: Adjustable Nock shifts a held arrow a tier,
    /// Prismatic Focus stands an Arcane rune in for another, Concealed Blade
    /// counts an Evade as a Swift Slash. The true face keeps its god and crit.
    var effectiveFace: FaceKind?
    /// Returning Knife: this appearance has already come back once.
    var hasReturned = false

    var displayName: String { face.label }

    init(
        id: UUID,
        dieID: UUID,
        dieName: String,
        face: FaceKind,
        patron: Deity?,
        isCrit: Bool,
        critChance: Double,
        imbueTiers: Int,
        wasHeld: Bool = false,
        effectiveFace: FaceKind? = nil,
        hasReturned: Bool = false
    ) {
        self.id = id
        self.dieID = dieID
        self.dieName = dieName
        self.face = face
        self.patron = patron
        self.isCrit = isCrit
        self.critChance = critChance
        self.imbueTiers = imbueTiers
        self.wasHeld = wasHeld
        self.effectiveFace = effectiveFace
        self.hasReturned = hasReturned
    }

    /// The face the engine matches recipes with and prints values from —
    /// the true face wherever no Chisel substitution stands.
    var matchFace: FaceKind { effectiveFace ?? face }
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
    /// Relentless Advance: stamina shaved off this step, never below 1.
    let staminaDiscount: Int

    init(
        faces: [RolledFace],
        combo: ComboDef?,
        momentumBonus: Int = 0,
        focusBonus: Int = 0,
        staminaDiscount: Int = 0
    ) {
        self.id = faces.first?.id ?? UUID()
        self.faces = faces
        self.combo = combo
        self.momentumBonus = momentumBonus
        self.focusBonus = focusBonus
        self.staminaDiscount = staminaDiscount
        if let combo {
            if combo.guaranteedCrit {
                self.comboCritChance = 1.0
            } else {
                let base = GameData.comboCritChance(
                    critDice: faces.filter(\.isCrit).count,
                    totalDice: faces.count
                )
                self.comboCritChance = base
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
    /// Fused combos cost less than their faces played apart. Relentless
    /// Advance shaves one more off the first weapon combo of a turn.
    var staminaCost: Int {
        max(1, GameData.comboStaminaCost(faces: faces.count) - staminaDiscount)
    }

    /// True when this step touches a foe — direct damage or an enemy status —
    /// so it is listed in the allocation overlay and needs a target.
    var targetsEnemy: Bool {
        if damage > 0 { return true }
        if let combo {
            return combo.bleedAmount > 0 || combo.poisonAmount > 0
                || combo.burnAmount > 0 || combo.stagger > 0
        }
        guard let face = faces.first else { return false }
        return face.face.soloKind == .poison || face.face == .runeFrost
    }

    /// Every part of the chain is lifted by its critical dice. Recipes print
    /// their own value now — length no longer multiplies anything.
    var comboScale: Double {
        guard combo != nil else { return 1 }
        return GameData.comboOutputScale(faces: faces.count, critDice: critDice, crit: false)
    }

    /// The same scale with the chain's own critical roll landed.
    var comboCritScale: Double {
        guard combo != nil else { return 1 }
        return GameData.comboOutputScale(faces: faces.count, critDice: critDice, crit: true)
    }

    /// Damage this step deals before enemy defences, at its normal roll.
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

    /// Short non-damage effects, e.g. "+24 HP", "Bleed 8×3".
    var effects: [String] {
        if let combo {
            let scale = comboScale
            func scaled(_ value: Int) -> Int { GameData.scaleUp(value, by: scale) }
            var parts: [String] = []
            if combo.bleedAmount > 0 { parts.append("Bleed \(scaled(combo.bleedAmount))×\(combo.bleedTurns)") }
            if combo.poisonAmount > 0 { parts.append("Poison \(scaled(combo.poisonAmount))×\(combo.poisonTurns)") }
            if combo.burnAmount > 0 { parts.append("Burn \(scaled(combo.burnAmount))×\(combo.burnTurns)") }
            if combo.heal > 0 { parts.append("+\(scaled(combo.heal)) HP") }
            if combo.regenAmount > 0 { parts.append("Regen \(scaled(combo.regenAmount))×\(combo.regenTurns)") }
            if combo.lifesteal { parts.append("Lifesteal") }
            if combo.shield > 0 { parts.append("+\(scaled(combo.shield)) Shield") }
            if combo.evadePercent > 0 { parts.append("+\(combo.evadePercent)% Evade") }
            if combo.pierce > 0 { parts.append("Pierce \(Int(combo.pierce * 100))%") }
            if combo.stagger > 0 { parts.append("Stagger \(Int(combo.stagger * 100))%") }
            if combo.reflect > 0 { parts.append("Reflect \(Int(combo.reflect * 100))%") }
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
        case .block: list = ["+\(value) Shield"]
        case .evade: list = ["+\(face.isCrit ? 20 : 15)% Evade"]
        case .poison: list = ["Poison \(value)×2"]
        case .stamina: list = ["+\(face.isCrit ? 2 : 1) Stam"]
        case .focus: list = ["+1 Stam", "Next hit +5"]
        case .damage:
            if face.face == .runeFrost { list = ["Slow"] }
            else if face.face == .bomb { list = ["Burn 4×2"] }
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

/// A combo your roll could make right now, listed in the combo panel with a
/// letter that matches the markers under the dice feeding it.
struct ComboCandidate: Identifiable {
    let combo: ComboDef
    let slots: [RolledFace]
    /// How many of its faces are already sitting in the turn plan.
    let placedCount: Int
    /// The letter this candidate wears in the panel, matching tray markers.
    let letter: String
    /// True when the player has locked this recipe in for the turn.
    let isForced: Bool

    var id: String { combo.id }
    var chain: Int { combo.faceCount }
    var faces: [RolledFace] { slots }
    var isInPlan: Bool { placedCount == chain }
    var critDice: Int { faces.filter(\.isCrit).count }

    /// Damage the finished chain would deal at full length.
    var projectedDamage: Int {
        guard combo.damage > 0 else { return 0 }
        let scale = GameData.comboOutputScale(faces: chain, critDice: critDice, crit: false)
        return GameData.scaleUp(combo.damage, by: scale)
    }
}

/// One letter carved under a die: the chain that letter names, in that
/// chain's own colour. The letters are the compact read of the roll — tapping
/// one fuses or dissolves its chain, so the full combo list underneath the
/// tray is optional rather than the only way to form a combo.
struct ComboMarker: Identifiable, Equatable {
    let comboID: String
    let name: String
    let letter: String
    let color: Color
    let staminaCost: Int
    /// True when the whole chain is already locked into the turn plan.
    let isPlanned: Bool

    var id: String { comboID }
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

/// The Echoing Staff's deferred half-cast, fired at the start of your next
/// turn — half damage, healing and shield, nothing else repeated.
struct PendingEcho {
    let damage: Int
    let heal: Int
    let shield: Int
    let foeID: UUID?
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
    /// Damage Anubis has stored against this foe. It detonates against health
    /// at the end of your next turn; further additions join the pile.
    var judgementAmount = 0
    var judgementPending = false

    init(def: EnemyDef) {
        self.def = def
        self.hp = def.maxHP
        self.armourMax = def.armour
        self.armour = def.armour
        self.intent = def.pickMove(hpFraction: 1)
    }

    var isAlive: Bool { hp > 0 }
    var hpFraction: Double { def.maxHP > 0 ? Double(hp) / Double(def.maxHP) : 0 }
    /// Divine Trials: this foe carries the attending god's lent power.
    var isTrialChampion = false
    /// Bastet's trial gift: a charge that slips one blow this turn.
    var evadeCharges = 0
    /// Bosses re-coil a little sooner under the tighter economy.
    var stagedHPFraction: Double {
        def.isBoss ? min(1, hpFraction + GameData.bossStageShift) : hpFraction
    }
    var displayName: String { def.displayName(hpFraction: stagedHPFraction) }
}

/// Turn-based combat: one all-dice roll per turn, a stamina budget for placing
/// faces, per-face crits, unordered class combos, persistent shield, rolling
/// evade chance, god blessings, and weighted enemy AI.
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
    /// Gods with a claim on dice you carry this battle.
    let patrons: Set<Deity>
    /// Upgrades earned this run, quiet for gods you no longer carry.
    let upgrades: Set<String>
    /// The capstone this run committed to, if any.
    let capstoneID: String?
    /// The pairing this run committed to, if its gods are equipped.
    let pairing: PairingDef?
    /// Chisels of Ptah carried this run. They reshape the weapon, not the dice.
    let chisels: Set<String>
    /// A god's Trial waiting on this fight, before it is accepted or declined.
    private(set) var trial: DivineTrial?
    private let comboPool: [ComboDef]

    // MARK: Player state
    private(set) var playerHP: Int
    /// The shield: block that soaks damage and stays until something breaks
    /// it. It never expires on its own — a quiet turn spent on defence is an
    /// investment, and burn and bleed still go straight to health.
    private(set) var playerShield = 0
    /// Chance an incoming hit is slipped entirely, rolled fresh per hit.
    /// Playing Evade faces stacks this up; it clears after the enemy turn.
    private(set) var evadeChance = 0.0
    private(set) var reflectFraction = 0.0
    private(set) var playerBleedAmount = 0
    private(set) var playerBleedTurns = 0
    private(set) var regenAmount = 0
    private(set) var regenTurns = 0
    /// Stamina left to spend this turn *before* the current plan is paid for.
    private(set) var turnStamina: Int
    private(set) var nextTurnStamina = 0
    /// Damage banked onto next turn's first swing (momentum recipes).
    private(set) var momentumCarry = 0

    // Primes: bonuses banked onto the next damaging action. They expire after
    // your next player turn if left unspent.
    private var primeDamageFlat = 0
    private var primePercentPoints = 0
    private var primeBurnExtra = 0
    private var primeHealAmount = 0
    private var primeExpiryTurn = 0

    // Per-turn flags for once-a-turn god and pairing answers.
    private var bastetEvadeUsed = false
    private var capstoneUsedThisTurn = false
    private var thermalUsedThisTurn = false
    private var pairingFiredThisTurn = false
    private var bloodDrawnThisTurn = false
    private var healGivenThisTurn = false
    private var firstEvadeFired = false
    private var silentDescentArmed = false
    private var shieldRebuiltThisBattle = false
    private var nineLivesUsed = false
    /// Shield damage soaked during the current enemy turn, for Unbroken House.
    private var shieldAbsorbedThisEnemyTurn = 0
    private var hardestHitFoeID: UUID?
    private var hardestHitAmount = 0
    private var tookHealthDamageThisEnemyTurn = false

    // Chisels of Ptah: optional Chisels arm per recipe, keyed by combo id, and
    // hold until fired or disarmed.
    private(set) var siegeArmed: Set<String> = []
    private(set) var counterweightArmed: Set<String> = []
    private(set) var assassinArmed: Set<String> = []
    private(set) var echoArmedComboID: String?
    /// Twin Bowstring's second arrow, Crescent Edge's splash and the echo's
    /// retargets: step ID → foe ID, defaulted to the weakest living foe.
    private(set) var secondaryAllocations: [UUID: UUID] = [:]
    /// Adjustable Nock: the one held arrow shifted a tier this turn.
    private(set) var nockShiftedFaceID: UUID?
    private var returningKnifeUsedThisTurn = false
    private var returningKnifeSlot: DieSlot?
    private var currentUsedThisTurn = false
    private var lastSpellWasMixed: Bool?
    private(set) var relentlessActive = false
    private var weaponComboLandedThisTurn = false
    private var pendingEcho: PendingEcho?

    // Divine Trials: the player-side state the trial's lent power touches.
    private(set) var trialAccepted = false
    private(set) var trialChampionID: UUID?
    private(set) var playerBurnAmount = 0
    private(set) var playerBurnTurns = 0
    private(set) var playerJudgementAmount = 0
    private(set) var playerJudgementPending = false
    private var trialFirstStrikeUsed = false
    private var enemyTurnCount = 0

    // MARK: Enemy state
    /// Which foe each plan step is sent at: step ID → foe ID. Built when the
    /// turn is committed (or defaulted for solo fights) and read during
    /// resolution. Every blow carries its own statuses and god triggers to
    /// whichever foe it lands on.
    private(set) var allocations: [UUID: UUID] = [:]
    /// True while the allocation overlay is up — attacks are being pointed at
    /// foes before the turn fires.
    private(set) var isAllocating = false
    /// The attack row highlighted in the allocation overlay.
    private(set) var selectedAllocationID: UUID?
    /// Which hit of the selected row is being pointed: 0 the blow itself,
    /// 1 its chisel-granted second hit (split arrow or splash).
    private(set) var selectedAllocationHit = 0
    /// The foe the blow currently being thrown was sent at.
    private(set) var activeTargetID: UUID?
    /// Set for a beat when a boss re-coils, so the arena can announce it.
    private(set) var stageAnnouncement: String?

    // MARK: Board state
    private let loadoutDice: [Die]
    private(set) var slots: [DieSlot]
    private(set) var drawnDieIDs: Set<UUID> = []
    private(set) var rolled: [RolledFace] = []
    private(set) var hasRolled = false
    private(set) var frozenSlotIDs: Set<UUID> = []
    private var pendingCarry: [DieSlot] = []
    private(set) var freezesUsed = 0
    var freezeArmed = false
    private(set) var playOrder: [UUID] = []
    private(set) var phase: Phase = .player
    private(set) var turnNumber = 1
    private(set) var committedPlan: [PlanStep] = []
    private(set) var activeStepIndex: Int?
    private(set) var lastAction = "Roll your dice."

    // Manual combo planning: recipes the player dissolved out of the auto
    // grouping, and recipes the player locked in by hand.
    private(set) var dissolvedCombos: Set<String> = []
    private(set) var forcedCombos: Set<String> = []

    // MARK: Fighter animation
    private(set) var playerPose: FighterPose = .idle
    /// The gods whose blessings ride the blow currently being thrown.
    private(set) var strikeGods: [Deity] = []

    /// Every chain this roll could make, longest first — rebuilt whenever the
    /// board changes rather than on every redraw.
    private(set) var comboCandidates: [ComboCandidate] = []
    private(set) var comboMarkers: [UUID: [ComboMarker]] = [:]

    // MARK: Effects & stats
    private(set) var comboFlash: ComboFlash?
    private(set) var floaters: [FloatText] = []
    private(set) var shakeTrigger: CGFloat = 0
    private(set) var slamPulse: Int = 0
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
        patrons: Set<Deity> = [],
        upgrades: Set<String> = [],
        capstoneID: String? = nil,
        pairing: PairingDef? = nil,
        chisels: Set<String> = [],
        trial: DivineTrial? = nil
    ) {
        let foes = enemies.map { EnemyState(def: $0) }
        self.enemies = foes
        self.classID = classID
        self.critBonus = critBonus
        self.maxStamina = maxStamina
        self.hour = hour
        self.playerMaxHP = maxHP
        self.playerHP = startHP
        self.turnStamina = maxStamina
        self.loadoutDice = dice
        let opening = Self.draw(count: GameData.diceDrawCount, from: dice, excluding: [])
        self.slots = opening.map { DieSlot(die: $0, state: .idle) }
        self.drawnDieIDs = Set(opening.map(\.id))
        self.patrons = patrons
        self.upgrades = upgrades
        self.capstoneID = capstoneID
        self.pairing = pairing
        self.chisels = chisels
        self.trial = trial
        self.comboPool = GameData.combosByPriority(for: classID)

        // Bes stands in the doorway from the first turn when his Loud House
        // equivalent lives in the upgrades; nothing else opens pre-built.
        if patrons.contains(.bes), upgrades.contains("be_stout") {
            // The Stout Door only strengthens grants; nothing opens for it.
        }
    }

    private func hasUpgrade(_ id: String) -> Bool { upgrades.contains(id) }

    private func hasChisel(_ id: String) -> Bool { chisels.contains(id) }

    // MARK: - Derived

    var enemy: EnemyDef { enemies[0].def }
    var enemyDefs: [EnemyDef] { enemies.map(\.def) }
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
    /// now — hour depth, heat and any pending stagger already applied.
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

    var enemyDisplayName: String {
        livingFoes.first?.displayName ?? enemies.last?.displayName ?? ""
    }

    // MARK: - Chisels of Ptah

    /// True when this combo step is an arrow combo — Twin Bowstring and
    /// Siege Draw key off it.
    private func isArrowCombo(_ step: PlanStep) -> Bool {
        guard let combo = step.combo else { return false }
        return combo.damage > 0 && combo.required.contains { $0.pattern.matches(.arrow1) }
    }

    private func twinBowstringApplies(_ step: PlanStep) -> Bool {
        guard step.isCombo else { return false }
        return hasChisel("ch_twinBowstring") && isArrowCombo(step)
    }

    private func crescentApplies(_ step: PlanStep) -> Bool {
        guard let combo = step.combo else { return false }
        return hasChisel("ch_crescentEdge") && combo.damage > 0 && combo.source == .weapon
    }

    /// True when this step sends a second, chisel-granted hit somewhere —
    /// Twin Bowstring's second arrow or Crescent Edge's splash.
    func hasSecondaryHit(_ step: PlanStep) -> Bool {
        twinBowstringApplies(step) || (crescentApplies(step) && livingFoes.count > 1)
    }

    /// Who the step's chisel-granted second hit is pointed at: an explicit
    /// allocation, or the weakest living foe other than the main target.
    func secondaryFoeID(for step: PlanStep) -> UUID? {
        guard hasSecondaryHit(step) else { return nil }
        let mainID = allocatedFoeID(for: step)
        if let id = secondaryAllocations[step.id],
           enemies.contains(where: { $0.id == id && $0.isAlive }) {
            return id
        }
        let others = livingFoes.filter { $0.id != mainID }
        return (others.min(by: { $0.hp < $1.hp }) ?? livingFoes.first)?.id
    }

    /// Damage the step's primary hit deals before enemy defences.
    func mainDamage(for step: PlanStep) -> Int {
        if twinBowstringApplies(step) {
            return GameData.scaleUp(displayedDamage(for: step), by: GameData.twinSplitFraction)
        }
        return displayedDamage(for: step)
    }

    /// Damage the step's chisel-granted second hit deals before defences —
    /// zero when this step carries none.
    func secondaryDamage(for step: PlanStep) -> Int {
        if twinBowstringApplies(step) {
            return GameData.scaleUp(displayedDamage(for: step), by: GameData.twinSplitFraction)
        }
        if crescentApplies(step) {
            return max(1, Int(Double(displayedDamage(for: step)) * GameData.crescentFraction))
        }
        return 0
    }

    /// Multiplier on a step's raw damage from its armed optional Chisels.
    private func armedDamageMultiplier(for step: PlanStep) -> Double {
        guard let combo = step.combo else { return 1.0 }
        var multiplier = 1.0
        if siegeArmed.contains(combo.id) { multiplier += GameData.siegeDamageBonus }
        if assassinArmed.contains(combo.id) { multiplier += GameData.assassinDamageBonus }
        return multiplier
    }

    /// Extra pierce this step's armed Chisels grant.
    private func armedPierce(for step: PlanStep) -> Double {
        guard let combo = step.combo else { return 0 }
        var pierce = 0.0
        if siegeArmed.contains(combo.id) { pierce += GameData.siegePierce }
        if assassinArmed.contains(combo.id) { pierce += GameData.assassinPierce }
        return pierce
    }

    /// A step's damage with its armed Chisels folded in — the number the
    /// plan and the forecast print.
    func displayedDamage(for step: PlanStep) -> Int {
        let multiplier = armedDamageMultiplier(for: step)
        guard multiplier != 1.0 else { return step.damage }
        return GameData.scaleUp(step.damage, by: multiplier)
    }

    /// One copper line naming what the armed Chisels and passives do to this
    /// step, printed under its effect line.
    func chiselLine(for step: PlanStep) -> String? {
        guard let combo = step.combo else { return nil }
        var parts: [String] = []
        if siegeArmed.contains(combo.id) { parts.append("SIEGE +40% · PIERCE 50%") }
        if assassinArmed.contains(combo.id) { parts.append("COMMITTED +40% · PIERCE 50%") }
        if counterweightArmed.contains(combo.id) {
            let spend = min(GameData.counterweightMaxSpend, playerShield)
            if spend > 0 { parts.append("COUNTERWEIGHT +\(spend * GameData.counterweightDamagePerPoint)") }
        }
        if echoArmedComboID == combo.id { parts.append("ECHO NEXT TURN") }
        if twinBowstringApplies(step) { parts.append("2 × 60% HITS") }
        if crescentApplies(step) { parts.append("SPLASH 35%") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The optional Chisel that could arm onto this recipe, for the copper
    /// badge on its chip — nil when none applies.
    func badgeChisel(for comboID: String) -> ChiselDef? {
        guard phase == .player,
              let combo = comboPool.first(where: { $0.id == comboID }) else { return nil }
        if hasChisel("ch_siegeDraw"), combo.damage > 0,
           combo.required.contains(where: { $0.pattern.matches(.arrow1) }) {
            return ChiselCatalog.def("ch_siegeDraw")
        }
        if hasChisel("ch_counterweight"), combo.damage > 0, playerShield > 0 {
            return ChiselCatalog.def("ch_counterweight")
        }
        if hasChisel("ch_assassin"), combo.damage > 0,
           evadeChance >= GameData.assassinEvadeCost {
            return ChiselCatalog.def("ch_assassin")
        }
        if hasChisel("ch_echoingStaff"), combo.source == .weapon {
            return ChiselCatalog.def("ch_echoingStaff")
        }
        return nil
    }

    func isArmed(_ chisel: ChiselDef, comboID: String) -> Bool {
        switch chisel.id {
        case "ch_siegeDraw": siegeArmed.contains(comboID)
        case "ch_counterweight": counterweightArmed.contains(comboID)
        case "ch_assassin": assassinArmed.contains(comboID)
        case "ch_echoingStaff": echoArmedComboID == comboID
        default: false
        }
    }

    func toggleArmed(_ chisel: ChiselDef, comboID: String) {
        guard phase == .player else { return }
        switch chisel.id {
        case "ch_siegeDraw":
            if siegeArmed.contains(comboID) { siegeArmed.remove(comboID) } else { siegeArmed.insert(comboID) }
        case "ch_counterweight":
            guard playerShield > 0 else { return }
            if counterweightArmed.contains(comboID) { counterweightArmed.remove(comboID) } else { counterweightArmed.insert(comboID) }
        case "ch_assassin":
            guard evadeChance >= GameData.assassinEvadeCost else { return }
            if assassinArmed.contains(comboID) { assassinArmed.remove(comboID) } else { assassinArmed.insert(comboID) }
        case "ch_echoingStaff":
            echoArmedComboID = echoArmedComboID == comboID ? nil : comboID
        default:
            return
        }
        Haptics.light()
    }

    /// Adjustable Nock: a held arrow may shift one tier, once a turn — and
    /// tapping the shifted arrow again sets it back true.
    func nockAvailable(for faceID: UUID) -> Bool {
        guard hasChisel("ch_adjustableNock"), phase == .player,
              let face = rolled.first(where: { $0.id == faceID }) else { return false }
        return face.wasHeld && face.matchFace.isArrow
            && (nockShiftedFaceID == nil || nockShiftedFaceID == faceID)
    }

    func nockShift(faceID: UUID, up: Bool) {
        guard nockAvailable(for: faceID),
              let index = rolled.firstIndex(where: { $0.id == faceID }) else { return }
        if nockShiftedFaceID == faceID, rolled[index].effectiveFace != nil {
            rolled[index].effectiveFace = nil
            nockShiftedFaceID = nil
            refreshCandidates()
            Haptics.light()
            return
        }
        let tiers: [FaceKind] = [.arrow1, .arrow2, .arrow3]
        guard let tier = tiers.firstIndex(of: rolled[index].matchFace) else { return }
        let shifted = tier + (up ? 1 : -1)
        guard tiers.indices.contains(shifted) else { return }
        rolled[index].effectiveFace = tiers[shifted]
        nockShiftedFaceID = faceID
        refreshCandidates()
        Haptics.light()
    }

    var hasEchoPending: Bool { pendingEcho != nil }

    /// True when any optional Chisel is armed onto this step's recipe — the
    /// copper hammer worn by the plan card.
    func isComboArmed(_ step: PlanStep) -> Bool {
        guard let combo = step.combo else { return false }
        return siegeArmed.contains(combo.id) || counterweightArmed.contains(combo.id)
            || assassinArmed.contains(combo.id) || echoArmedComboID == combo.id
    }

    // MARK: - Divine Trials

    /// The trial waits until the player answers it.
    var trialPromptVisible: Bool { trial != nil && !trialAccepted }

    func acceptTrial() {
        guard let trial, !trialAccepted else { return }
        trialAccepted = true
        guard let champion = enemies.filter(\.isAlive).randomElement() else { return }
        trialChampionID = champion.id
        if let index = enemies.firstIndex(where: { $0.id == champion.id }) {
            enemies[index].isTrialChampion = true
        }
        lastAction = "\(trial.deity.name)'s trial begins — the champion carries their power."
        Haptics.heavy()
    }

    func declineTrial() {
        guard !trialAccepted else { return }
        trial = nil
        lastAction = "The god withdraws. The fight is only a fight."
        Haptics.light()
    }

    private func isChampion(_ foe: EnemyState) -> Bool {
        trialAccepted && foe.id == trialChampionID
    }

    /// The one-line lent-power note under a champion's intent chip.
    func trialForecast(for foe: EnemyState) -> (icon: String, text: String, tint: Color)? {
        guard isChampion(foe), let trial else { return nil }
        switch trial.deity {
        case .ra: return ("flame.fill", "first hit: burn 2×2", Theme.ember)
        case .sobek: return ("drop.fill", "first hit: bleed 2×2 · feeds 4", Theme.blood)
        case .anubis: return ("scalemass.fill", "sentence \(GameData.trialSentence) every 2nd turn", Deity.anubis.tint)
        case .bes: return ("shield.checkered", "+8 gate after acting", Deity.bes.tint)
        case .horus: return ("bird.fill", "every 3rd: pierces half guard", Deity.horus.tint)
        case .bastet: return ("cat.fill", "evade on your 2nd turns", Deity.bastet.tint)
        }
    }

    // MARK: - Targeting

    /// True when at least one step in the plan can touch a foe — damage or an
    /// enemy status — so committing a pack fight opens the allocation overlay.
    var needsAllocation: Bool {
        livingFoes.count > 1 && turnPlan.contains(where: \.targetsEnemy)
    }

    /// The steps the allocation overlay lists, in play order.
    var allocatableSteps: [PlanStep] {
        turnPlan.filter(\.targetsEnemy)
    }

    /// The foe a step is currently pointed at, falling back to the first
    /// living foe whenever the assignment is missing or has fallen.
    func allocatedFoeID(for step: PlanStep) -> UUID? {
        if let id = allocations[step.id],
           enemies.contains(where: { $0.id == id && $0.isAlive }) {
            return id
        }
        return livingFoes.first?.id
    }

    /// Damage the current allocation points at one foe: primary hits, plus
    /// the chisel-granted second hits pointed here.
    func allocatedDamage(for foeID: UUID) -> Int {
        turnPlan.reduce(0) { total, step in
            guard step.targetsEnemy, step.damage > 0 else { return total }
            var sum = total
            if allocatedFoeID(for: step) == foeID { sum += mainDamage(for: step) }
            if secondaryFoeID(for: step) == foeID { sum += secondaryDamage(for: step) }
            return sum
        }
    }

    /// Who wears the gold ring: during allocation, the selected attack's
    /// target; during resolution, the foe the blow in flight was sent at.
    func isTargeted(foeID: UUID) -> Bool {
        if isAllocating {
            guard let selectedAllocationID,
                  let step = turnPlan.first(where: { $0.id == selectedAllocationID }) else {
                return false
            }
            if selectedAllocationHit == 1 {
                return secondaryFoeID(for: step) == foeID
            }
            return allocatedFoeID(for: step) == foeID
        }
        return activeTargetID == foeID
    }

    // MARK: - Allocation

    /// Commit entry point. Solo fights — and plans that cannot touch a foe —
    /// resolve straight away; packs open the allocation overlay first, with
    /// every attack pre-assigned to the first living foe.
    func beginCommit() {
        guard canCommit else { return }
        guard needsAllocation else {
            commitTurn()
            return
        }
        let steps = allocatableSteps
        guard let defaultFoe = livingFoes.first?.id else { return }
        allocations = Dictionary(uniqueKeysWithValues: steps.map { ($0.id, defaultFoe) })
        for step in steps where hasSecondaryHit(step) {
            secondaryAllocations[step.id] = secondaryFoeID(for: step) ?? defaultFoe
        }
        selectedAllocationID = steps.first?.id
        selectedAllocationHit = 0
        isAllocating = true
        Haptics.light()
    }

    /// Tap an attack row in the overlay to select it.
    func selectAllocation(_ stepID: UUID) {
        guard isAllocating, allocatableSteps.contains(where: { $0.id == stepID }) else { return }
        selectedAllocationID = stepID
        selectedAllocationHit = 0
        Haptics.light()
    }

    /// Point the row's second, chisel-granted hit instead of the blow itself.
    func selectSecondaryHit(_ stepID: UUID) {
        guard isAllocating, allocatableSteps.contains(where: { $0.id == stepID }) else { return }
        selectedAllocationID = stepID
        selectedAllocationHit = 1
        Haptics.light()
    }

    /// Send the selected hit at this foe, then advance to the next attack
    /// so a sweep down the list assigns quickly.
    func assignSelected(to foeID: UUID) {
        guard isAllocating, let stepID = selectedAllocationID,
              enemies.contains(where: { $0.id == foeID && $0.isAlive }),
              allocatableSteps.contains(where: { $0.id == stepID }) else { return }
        if selectedAllocationHit == 1 {
            secondaryAllocations[stepID] = foeID
        } else {
            allocations[stepID] = foeID
        }
        Haptics.light()
        let steps = allocatableSteps
        if let index = steps.firstIndex(where: { $0.id == stepID }), index + 1 < steps.count {
            selectedAllocationID = steps[index + 1].id
            selectedAllocationHit = 0
        }
    }

    /// Cycle the selected hit through the living foes.
    func cycleTarget(for stepID: UUID) {
        guard isAllocating,
              let step = allocatableSteps.first(where: { $0.id == stepID }),
              livingFoes.count > 1 else { return }
        let living = livingFoes
        let current: UUID
        if selectedAllocationHit == 1 {
            current = secondaryFoeID(for: step) ?? living[0].id
        } else {
            current = allocatedFoeID(for: step) ?? living[0].id
        }
        guard let index = living.firstIndex(where: { $0.id == current }) else { return }
        let next = living[(index + 1) % living.count].id
        if selectedAllocationHit == 1 {
            secondaryAllocations[step.id] = next
        } else {
            allocations[step.id] = next
        }
        selectedAllocationID = step.id
        Haptics.light()
    }

    /// Back to planning — the plan is untouched.
    func cancelAllocation() {
        guard isAllocating else { return }
        isAllocating = false
        selectedAllocationID = nil
        selectedAllocationHit = 0
        Haptics.light()
    }

    /// Fire the turn with the allocations as they stand.
    func confirmAllocation() {
        guard isAllocating else { return }
        isAllocating = false
        selectedAllocationID = nil
        selectedAllocationHit = 0
        Haptics.medium()
        commitTurn()
    }

    /// The living foe a step resolves against: its assigned target, or the
    /// first living foe once that one has fallen mid-turn. The assignment is
    /// repaired in place so later steps keep their intent.
    private func targetIndex(for step: PlanStep) -> Int? {
        if let id = allocations[step.id],
           let index = enemies.firstIndex(where: { $0.id == id && $0.isAlive }) {
            return index
        }
        guard let index = enemies.firstIndex(where: \.isAlive) else { return nil }
        allocations[step.id] = enemies[index].id
        return index
    }

    /// Slides a fallen target onto the nearest living foe — damage never
    /// fizzles because the assigned foe died earlier in the turn.
    private func resolveTarget(_ target: Int?) -> Int? {
        guard let target, enemies.indices.contains(target) else { return nil }
        if enemies[target].isAlive { return target }
        return enemies.firstIndex(where: \.isAlive)
    }

    var playedFaces: [RolledFace] {
        playOrder.compactMap { faceID in rolled.first { $0.id == faceID } }
    }

    var turnPlan: [PlanStep] { buildPlan(from: playedFaces) }

    var displayedPlan: [PlanStep] {
        phase == .player ? turnPlan : committedPlan
    }

    var projectedDamage: Int {
        turnPlan.reduce(0) { total, step in
            guard step.targetsEnemy, step.damage > 0 else { return total }
            return total + mainDamage(for: step) + secondaryDamage(for: step)
        }
    }

    var planStaminaCost: Int {
        let siege = turnPlan.filter { step in
            step.combo.map { siegeArmed.contains($0.id) } == true
        }.count
        let echo = echoArmedComboID.map { comboID in
            turnPlan.contains { $0.combo?.id == comboID } ? GameData.echoStaminaCost : 0
        } ?? 0
        return turnPlan.reduce(0) { $0 + $1.staminaCost }
            + siege * GameData.siegeStaminaCost + echo
    }

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

    private func planCost(for order: [UUID]) -> Int {
        let faces = order.compactMap { faceID in rolled.first { $0.id == faceID } }
        return buildPlan(from: faces).reduce(0) { $0 + $1.staminaCost }
    }

    var hasCombo: Bool { turnPlan.contains { $0.isCombo } }

    // MARK: - Chains in hand

    /// Recomputes the combo panel: every chain the unassigned faces could
    /// still make, plus the forced ones already locked in. Heavy, so it only
    /// runs when the board actually changes.
    private func refreshCandidates() {
        guard phase == .player, hasRolled, !isRolling else { return clearChainCounts() }
        guard !comboPool.isEmpty else { return clearChainCounts() }

        let planned = Set(playOrder)
        let assignedIDs = Set(buildPlan(from: playedFaces).filter(\.isCombo).flatMap { $0.faces.map(\.id) })
        let free = rolled.filter { !assignedIDs.contains($0.id) }
        var found: [ComboCandidate] = []
        var markers: [UUID: [ComboMarker]] = [:]

        var assisted = 0
        for combo in comboPool {
            let forced = forcedCombos.contains(combo.id)
            let dissolved = dissolvedCombos.contains(combo.id)
            guard forced || !dissolved else { continue }
            let kinds = free.map(\.matchFace)
            var indices = combo.match(from: kinds)
            var substituted: (index: Int, kind: FaceKind)? = nil
            if indices == nil, assisted < 1,
               let match = chiselAssistedMatch(combo, kinds: kinds) {
                indices = match.indices
                substituted = match.substitution
            }
            guard let indices else { continue }
            var slots = indices.map { free[$0] }
            if let substituted {
                assisted += 1
                if let local = indices.firstIndex(of: substituted.index) {
                    slots[local].effectiveFace = substituted.kind
                }
            }
            let placed = slots.filter { planned.contains($0.id) }.count
            let letter = Self.letter(at: found.count)
            found.append(ComboCandidate(combo: combo, slots: slots, placedCount: placed,
                                        letter: letter, isForced: forced))
            let marker = ComboMarker(
                comboID: combo.id,
                name: combo.name,
                letter: letter,
                color: combo.tint,
                staminaCost: combo.staminaCost,
                isPlanned: forced && placed == slots.count
            )
            for face in slots {
                markers[face.id, default: []].append(marker)
            }
        }
        comboCandidates = found.sorted { lhs, rhs in
            if lhs.isForced != rhs.isForced { return lhs.isForced }
            if lhs.chain != rhs.chain { return lhs.chain > rhs.chain }
            if lhs.projectedDamage != rhs.projectedDamage { return lhs.projectedDamage > rhs.projectedDamage }
            return lhs.combo.name < rhs.combo.name
        }
        comboMarkers = markers
    }

    private static func letter(at index: Int) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        guard index < alphabet.count else { return "?" }
        let offset = alphabet.index(alphabet.startIndex, offsetBy: index)
        return String(alphabet[offset])
    }

    private func clearChainCounts() {
        if !comboCandidates.isEmpty { comboCandidates = [] }
        if !comboMarkers.isEmpty { comboMarkers = [:] }
    }

    /// How many chains this particular die could feed — the tray's tally dots.
    func chainCount(for faceID: UUID) -> Int { comboMarkers[faceID]?.count ?? 0 }

    var chainsInHand: Int { comboCandidates.count }
    var maxChainCount: Int { comboMarkers.values.map(\.count).max() ?? 0 }

    /// Faces a chain could still be built out of *right now*.
    var availableFaces: [RolledFace] {
        rolled.filter { !playOrder.contains($0.id) }
    }

    var isRolling: Bool { slots.contains { $0.state == .rolling } }

    var lockedReelCount: Int {
        slots.filter { if case .rolled = $0.state { return true } else { return false } }.count
    }

    private static let firstLockDelay: Double = 0.85

    static let drumStepBase: Double = 0.032

    private func lockGaps(count: Int) -> [Double] {
        let scale: Double = count > 7 ? 0.72 : (count > 5 ? 0.84 : 1)
        return (0..<count).map { min(0.46 + 0.1 * Double($0), 1.0) * scale }
    }

    private func reelIndex(slotID: UUID) -> Int {
        rollableDice.firstIndex(of: slotID) ?? 0
    }

    func drumStep(slotID: UUID) -> Double { Self.drumStepBase }

    func brakeWindows(slotID: UUID) -> (crawl: Double, haul: Double, ring: Double) {
        (crawl: 0.16, haul: 0.38, ring: 0.3)
    }

    func lockTime(slotID: UUID) -> Double {
        let order = rollableDice
        guard let index = order.firstIndex(of: slotID) else { return Self.firstLockDelay }
        return Self.firstLockDelay + lockGaps(count: order.count).prefix(index).reduce(0, +)
    }

    var canRoll: Bool { phase == .player && !hasRolled && rollableDice.isEmpty == false }

    private var rollableDice: [UUID] {
        slots.filter { !$0.isCarried }.map(\.id)
    }

    func isFrozen(slotID: UUID) -> Bool { frozenSlotIDs.contains(slotID) }

    var frozenCount: Int { frozenSlotIDs.count }

    var carriedCount: Int { slots.filter(\.isCarried).count }

    private func slotID(showing faceID: UUID) -> UUID? {
        slots.first { slot in
            if case .rolled(let face) = slot.state { return face.id == faceID }
            return false
        }?.id
    }

    var freezesRemaining: Int { max(0, freezesPerTurn - freezesUsed) }

    var freezesPerTurn: Int { GameData.freezesPerTurn(hour: hour) }

    var undrawnCount: Int { max(0, loadoutDice.count - drawnDieIDs.count) }

    /// Draws the turn's hand at random from the whole loadout. Dice whose
    /// faces are currently held are left in the bag.
    static func draw(count: Int, from dice: [Die], excluding heldIDs: Set<UUID>) -> [Die] {
        let bag = dice.filter { !heldIDs.contains($0.id) }
        guard bag.count > count else { return bag }
        return Array(bag.shuffled().prefix(count))
    }

    var canFreezeAny: Bool {
        guard phase == .player else { return false }
        return slots.contains { slot in
            guard case .rolled(let face) = slot.state else { return false }
            return !playOrder.contains(face.id)
        }
    }

    var canCommit: Bool { phase == .player && hasRolled && !isRolling }

    // MARK: - Player actions

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

    private func shuffleRow() {
        let carried = slots.filter(\.isCarried)
        let rolling = slots.filter { !$0.isCarried }.shuffled()
        slots = carried + rolling
    }

    private func settle(slotID: UUID, isLast: Bool = false) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }),
              slots[index].state == .rolling else { return }
        let die = slots[index].die
        var extra = 0.0
        if die.patron == .horus, hasUpgrade("ho_windRead") { extra += 0.08 }
        let outcome = die.roll(critBonus: critBonus + extra)
        let result = RolledFace(
            id: UUID(),
            dieID: die.id,
            dieName: die.name,
            face: outcome.face.kind,
            patron: die.patron,
            isCrit: outcome.isCrit,
            critChance: outcome.chance,
            imbueTiers: outcome.face.imbueTiers
        )
        slots[index].state = .rolled(result)
        rolled.append(result)
        slamPulse += 1
        lastReelLocked = isLast
        refreshCandidates()

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
    /// the fusion forms.
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

        guard planCost(for: prospective) <= turnStamina else {
            lastAction = "Out of stamina — take a die back or end your turn."
            Haptics.warning()
            return
        }

        if let slotID = slotID(showing: face.id), frozenSlotIDs.contains(slotID) {
            frozenSlotIDs.remove(slotID)
            freezesUsed = max(0, freezesUsed - 1)
        }
        playOrder = prospective
        refreshCandidates()
        Haptics.light()
    }

    /// Send a chip from the play bar back to the tray. The bar reprices the
    /// remaining plan, so the die's stamina comes back in full.
    func returnToTray(faceID: UUID) {
        guard phase == .player, playOrder.contains(faceID) else { return }
        playOrder.removeAll { $0 == faceID }
        refreshCandidates()
        Haptics.light()
    }

    /// Freeze (or thaw) a settled reel. Freezing is free but you only get
    /// `freezesPerTurn` a turn. A frozen face keeps exactly as it landed.
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

    // MARK: - Combo panel actions

    /// Tap a combo in the panel. A planned combo dissolves — its faces stay
    /// in the plan and resolve alone. An available combo locks in: its faces
    /// join the plan and the recipe can no longer be beaten by the greedy
    /// grouping.
    func toggleCombo(_ comboID: String) {
        guard phase == .player, let candidate = comboCandidates.first(where: { $0.combo.id == comboID }) else { return }

        if candidate.isForced && candidate.isInPlan {
            forcedCombos.remove(comboID)
            dissolvedCombos.insert(comboID)
            lastAction = "\(candidate.combo.name) dissolved — its faces play alone."
            refreshCandidates()
            Haptics.light()
            return
        }

        // Lock it in and pull any of its faces that are not placed yet.
        var prospective = playOrder
        var missing: [RolledFace] = []
        for face in candidate.faces where !prospective.contains(face.id) {
            missing.append(face)
        }
        guard planCost(for: prospective) + missing.count <= turnStamina else {
            lastAction = "Out of stamina to form \(candidate.combo.name)."
            Haptics.warning()
            return
        }
        for face in missing { prospective.append(face.id) }
        for faceID in prospective {
            if let slotID = slotID(showing: faceID), frozenSlotIDs.contains(slotID) {
                frozenSlotIDs.remove(slotID)
                freezesUsed = max(0, freezesUsed - 1)
            }
        }
        playOrder = prospective
        dissolvedCombos.remove(comboID)
        forcedCombos.insert(comboID)
        lastAction = "\(candidate.combo.name) planned — \(candidate.combo.ingredientSummary)."
        refreshCandidates()
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
        weaponComboLandedThisTurn = false

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
        pendingCarry = carriedSlots.compactMap { slot in
            guard case .rolled(let face) = slot.state else { return nil }
            var held = face
            held.wasHeld = true
            // Adjustable Nock is a once-a-turn shift; the true arrow returns.
            held.effectiveFace = nil
            return DieSlot(die: slot.die, state: .rolled(held), isCarried: true)
        }
        rolled = pendingCarry.compactMap { slot in
            if case .rolled(let face) = slot.state { return face }
            return nil
        }
        let planIDs = Set(steps.compactMap { $0.combo?.id })
        let armedExtras = steps.filter { $0.combo.map { planIDs.contains($0.id) && siegeArmed.contains($0.id) } == true }.count * GameData.siegeStaminaCost
            + (echoArmedComboID.map { planIDs.contains($0) ? GameData.echoStaminaCost : 0 } ?? 0)
        turnStamina = max(0, turnStamina - steps.reduce(0) { $0 + $1.staminaCost } - armedExtras)
        playOrder = []
        clearChainCounts()

        for (index, step) in steps.enumerated() {
            activeStepIndex = index
            try? await Task.sleep(for: .milliseconds(260))
            let target = targetIndex(for: step)
            activeTargetID = target.map { enemies[$0].id }

            // Assassin's Commitment: the evade charge burns before the blow
            // lands, so the combo's own evasion can never pay for it.
            if let combo = step.combo, assassinArmed.contains(combo.id), evadeChance > 0 {
                evadeChance = max(0, evadeChance - GameData.assassinEvadeCost)
                addFloat("Commitment −15% Evade", color: Theme.ptahCopper, onEnemy: false)
            }

            // Bastet's trial gift: one charge slips the first damaging blow
            // aimed at the champion this turn.
            var skipStep = false
            if step.targetsEnemy, step.damage > 0, let target,
               enemies.indices.contains(target), enemies[target].isAlive,
               enemies[target].isTrialChampion, enemies[target].evadeCharges > 0 {
                enemies[target].evadeCharges -= 1
                addFloat("EVADED!", color: Deity.bastet.tint, onEnemy: true, big: true, foe: enemies[target].id)
                lastAction = "\(enemies[target].displayName) vanishes — the blow finds empty air."
                skipStep = true
            }

            if !skipStep {
                if let combo = step.combo {
                    let didCrit = Double.random(in: 0..<1) < step.comboCritChance
                    playerPose = combo.damage > 0 ? .attack : (combo.shield > 0 ? .block : .heal)
                    noteStrikeGods(in: step.faces)
                    applyCombo(combo, step: step, crit: didCrit, targetIndex: target)
                    // Concealed Blade: the substituted Evade still grants its
                    // evasion, and its god still answered it as a defensive face.
                    if hasChisel("ch_concealedBlade"),
                       step.faces.contains(where: { $0.face == .evade && $0.effectiveFace == .swiftSlash }) {
                        gainEvade(0.15)
                        addFloat("Concealed Blade", color: Theme.ptahCopper, onEnemy: false)
                    }
                    if combo.source == .weapon, combo.damage > 0 {
                        weaponComboLandedThisTurn = true
                    }
                    // Returning Knife: the first dagger thrown each turn comes
                    // back as a held face next turn.
                    if hasChisel("ch_returningKnife"), !returningKnifeUsedThisTurn,
                       let daggerFace = step.faces.first(where: { $0.matchFace == .daggerThrow && !$0.hasReturned }) {
                        returningKnifeUsedThisTurn = true
                        var returned = daggerFace
                        returned.wasHeld = true
                        returned.hasReturned = true
                        returned.effectiveFace = nil
                        if let die = loadoutDice.first(where: { $0.id == daggerFace.dieID }) {
                            returningKnifeSlot = DieSlot(die: die, state: .rolled(returned), isCarried: true)
                        }
                        addFloat("Returning Knife", color: Theme.ptahCopper, onEnemy: false)
                    }
                    resolveBlessings(in: step, targetIndex: target)
                    pairingAfterAction(step: step, dealtDamage: combo.damage > 0, targetIndex: target)
                    let hang = 480 + min(step.faces.count, 5) * 90 + (didCrit ? 420 : 0)
                    try? await Task.sleep(for: .milliseconds(hang))
                } else if let face = step.faces.first {
                    playerPose = pose(for: face.face)
                    noteStrikeGods(in: [face])
                    let dealt = applyFace(face, bonus: step.momentumBonus + step.focusBonus, targetIndex: target)
                    resolveBlessings(in: step, targetIndex: target)
                    pairingAfterAction(step: step, dealtDamage: dealt, targetIndex: target)
                    try? await Task.sleep(for: .milliseconds(380))
                }
            }
            resetPoses()
            if !hasLivingFoes {
                activeStepIndex = nil
                finishVictory()
                return
            }
        }

        // Relentless Advance: land a weapon combo this turn and the first one
        // next turn is cheaper. Skip a turn without one and the momentum is gone.
        relentlessActive = weaponComboLandedThisTurn
        if let knifeSlot = returningKnifeSlot {
            pendingCarry.append(knifeSlot)
            returningKnifeSlot = nil
        }
        returningKnifeUsedThisTurn = false

        activeStepIndex = nil
        try? await Task.sleep(for: .milliseconds(380))
        detonateJudgements()
        boilingNileTick()
        // Anubis's Sentence: stored by a trial champion, it falls against
        // health at the end of your next turn.
        if playerJudgementPending {
            playerJudgementPending = false
            let amount = playerJudgementAmount
            playerJudgementAmount = 0
            playerHP = max(0, playerHP - amount)
            addFloat("-\(amount) SENTENCE", color: Deity.anubis.tint, onEnemy: false, big: true)
            withAnimation(.linear(duration: 0.35)) { shakeTrigger += 0.6 }
            if playerHP <= 0 {
                finishDefeat("The Sentence falls, and the scale tips...")
                return
            }
        }
        if !hasLivingFoes {
            finishVictory()
            return
        }
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
            activeTargetID = nil
            for index in enemies.indices { enemies[index].pose = .idle }
        }
    }

    /// Reads which gods stand behind the blow about to land, in play order.
    private func noteStrikeGods(in faces: [RolledFace]) {
        var ordered: [Deity] = []
        for face in faces {
            guard let god = face.patron, !ordered.contains(god) else { continue }
            ordered.append(god)
        }
        strikeGods = Array(ordered.prefix(2))
    }

    // MARK: - Applying combos

    private func applyCombo(_ combo: ComboDef, step: PlanStep, crit: Bool, targetIndex target: Int?) {
        let foeID = target.flatMap { enemies.indices.contains($0) ? enemies[$0].id : nil }
        combosLanded += 1
        nextTurnStamina += GameData.comboStaminaBank(faces: step.faces.count)
        announce(combo: combo, step: step, crit: crit)
        var multiplier = GameData.comboOutputScale(
            faces: step.faces.count,
            critDice: step.critDice,
            crit: crit
        )

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
                 onEnemy: combo.damage > 0 || combo.poisonAmount > 0, big: true, foe: foeID)
        lastAction = crit ? "\(combo.name) CRITS! \(combo.flavor)" : "\(combo.name)! \(combo.flavor)"

        if combo.momentumNext > 0 {
            momentumCarry += GameData.scaleUp(combo.momentumNext, by: multiplier)
        }

        if combo.damage > 0 {
            var raw = GameData.scaleUp(combo.damage, by: multiplier) + step.momentumBonus + step.focusBonus
            raw = applyDamageBonuses(raw, step: step, scalesWithBleed: combo.scalesWithBleed,
                                     scalesWithWounds: combo.scalesWithWounds, scalesWithBurn: combo.scalesWithBurn,
                                     targetIndex: target)

            // Counterweight: spend held shield for damage before the blow lands.
            if counterweightArmed.contains(combo.id) {
                let spend = min(GameData.counterweightMaxSpend, playerShield)
                if spend > 0 {
                    playerShield -= spend
                    let bonus = spend * GameData.counterweightDamagePerPoint
                    raw += bonus
                    addFloat("Counterweight +\(bonus)", color: Theme.ptahCopper, onEnemy: false)
                }
            }

            // Capstone: Solar Flare — once a turn, a chain of three or more
            // holding a Ra attack face detonates the target's burn for 3 a
            // stack, then applies fresh burn.
            if capstoneID == "ra_solarFlare", !capstoneUsedThisTurn,
               step.faces.count >= 3,
               step.faces.contains(where: { $0.patron == .ra && $0.face.isAttack }),
               let target, enemies.indices.contains(target),
               enemies[target].burnTurns > 0, enemies[target].burnAmount > 0 {
                capstoneUsedThisTurn = true
                let stacks = enemies[target].burnAmount
                addFloat("SOLAR FLARE", color: Deity.ra.tint, onEnemy: false, big: true)
                damageEnemyDirect(enemies[target].id, stacks * 3, label: "Flare")
                applyBurn(2, turns: 2, targetIndex: target)
            }

            let pierce = attackPierce(comboBase: combo.pierce, step: step, crit: crit, targetIndex: target)
            let totalDealt: Int
            if twinBowstringApplies(step) {
                // Twin Bowstring: two hits at 60% each, splittable across foes.
                addFloat("TWIN BOWSTRING", color: Theme.ptahCopper, onEnemy: false, big: true)
                let perHit = GameData.scaleUp(raw, by: GameData.twinSplitFraction)
                let dealt1 = damageEnemy(perHit, pierce: pierce, targetIndex: target)
                firstFeastCheck(dealt1)
                let dealt2 = damageEnemy(perHit, pierce: pierce,
                                         targetIndex: secondaryTargetIndex(for: step, mainIndex: target))
                firstFeastCheck(dealt2)
                totalDealt = dealt1 + dealt2
            } else {
                let dealt = damageEnemy(raw, pierce: pierce, targetIndex: target)
                firstFeastCheck(dealt)
                if crescentApplies(step),
                   let splashIndex = secondaryTargetIndex(for: step, mainIndex: target),
                   splashIndex != resolveTarget(target) {
                    // Crescent Edge: a second foe takes a fraction of the
                    // damage — no healing, statuses or god triggers carry over.
                    let splash = max(1, Int(Double(raw) * GameData.crescentFraction))
                    addFloat("CRESCENT EDGE", color: Theme.ptahCopper, onEnemy: false)
                    _ = damageEnemy(splash, pierce: 0, targetIndex: splashIndex)
                }
                totalDealt = dealt
            }
            jawsOfTheNile(step: step, targetIndex: target)
            if combo.lifesteal, totalDealt > 0 {
                healPlayer(totalDealt, label: "Lifesteal")
            }
        } else {
            // Defensive chains still feed Sobek's capstone and held-face
            // rewards only through faces; no damage path here.
        }
        if combo.bleedAmount > 0 {
            applyBleed(GameData.scaleUp(combo.bleedAmount, by: multiplier),
                       turns: crit ? combo.bleedTurns + 1 : combo.bleedTurns, targetIndex: target)
        }
        if combo.poisonAmount > 0 {
            applyPoison(GameData.scaleUp(combo.poisonAmount, by: multiplier),
                        turns: crit ? combo.poisonTurns + 1 : combo.poisonTurns, targetIndex: target)
        }
        if combo.burnAmount > 0 {
            applyBurn(GameData.scaleUp(combo.burnAmount, by: multiplier),
                      turns: crit ? combo.burnTurns + 1 : combo.burnTurns, targetIndex: target)
        }
        if combo.heal > 0 {
            healPlayer(GameData.scaleUp(combo.heal, by: multiplier))
        }
        if combo.regenAmount > 0 {
            regenAmount = max(regenAmount, GameData.scaleUp(combo.regenAmount, by: multiplier))
            regenTurns = max(regenTurns, combo.regenTurns)
            addFloat("Regen", color: Theme.forest, onEnemy: false)
        }
        if combo.shield > 0 {
            gainShield(GameData.scaleUp(combo.shield, by: multiplier))
        }
        if combo.evadePercent > 0 {
            gainEvade(Double(combo.evadePercent) / 100.0)
        }
        if combo.stagger > 0, let target, enemies.indices.contains(target), enemies[target].isAlive {
            enemies[target].stagger = max(enemies[target].stagger, min(0.85, combo.stagger * (crit ? 1.3 : 1.0)))
            addFloat("Staggered", color: Theme.frost, onEnemy: true, foe: foeID)
        }
        if combo.reflect > 0 {
            reflectFraction = max(reflectFraction, combo.reflect)
            addFloat("Reflecting", color: Theme.gold, onEnemy: false)
        }
        let bank = GameData.comboStaminaBank(faces: step.faces.count)
        if bank > 0 {
            addFloat("+\(bank) Stamina", color: Theme.gold, onEnemy: false)
        }

        // Echoing Staff: half of this spell repeats at the start of your next
        // turn — damage, healing and shield, nothing else.
        if echoArmedComboID == combo.id,
           combo.damage > 0 || combo.heal > 0 || combo.shield > 0 {
            let echoBase = combo.damage > 0
                ? GameData.scaleUp(combo.damage, by: multiplier) + step.momentumBonus + step.focusBonus
                : 0
            pendingEcho = PendingEcho(
                damage: GameData.scaleUp(max(echoBase, 0), by: GameData.echoScale),
                heal: GameData.scaleUp(GameData.scaleUp(combo.heal, by: multiplier), by: GameData.echoScale),
                shield: GameData.scaleUp(GameData.scaleUp(combo.shield, by: multiplier), by: GameData.echoScale),
                foeID: target.flatMap { enemies.indices.contains($0) ? enemies[$0].id : nil }
            )
        }

        // Alternating Current: opposite rune kinds bank a stamina point.
        if hasChisel("ch_current"), combo.source == .weapon {
            let kinds = Set(step.faces.map(\.matchFace))
            let mixed = kinds.count > 1
            if let last = lastSpellWasMixed, last != mixed, !currentUsedThisTurn {
                currentUsedThisTurn = true
                nextTurnStamina += 1
                addFloat("Alternating Current +1", color: Theme.ptahCopper, onEnemy: false)
            }
            lastSpellWasMixed = mixed
        }
    }

    // MARK: - Applying single faces

    /// Returns true when the face dealt damage.
    @discardableResult
    private func applyFace(_ face: RolledFace, bonus: Int, targetIndex target: Int?) -> Bool {
        let foeID = target.flatMap { enemies.indices.contains($0) ? enemies[$0].id : nil }
        let multiplier = face.isCrit ? GameData.faceCritMultiplier : 1.0
        let value = GameData.scaleUp(face.face.soloValue, by: multiplier)
        if face.isCrit {
            addFloat("\(face.displayName.uppercased()) CRIT", color: Theme.gold, onEnemy: face.face.isAttack, foe: foeID)
            withAnimation(.linear(duration: 0.3)) { shakeTrigger += 0.6 }
            Haptics.heavy()
        }

        if face.face.isAttack {
            var raw = value + bonus
            raw = applyDamageBonuses(raw, step: PlanStep(faces: [face], combo: nil),
                                     scalesWithBleed: false, scalesWithWounds: false, scalesWithBurn: false,
                                     targetIndex: target)
            let dealt = damageEnemy(raw, pierce: attackPierce(comboBase: 0, step: nil, crit: face.isCrit, targetIndex: target),
                                    targetIndex: target)
            firstFeastCheck(dealt)
            lastAction = face.isCrit
                ? "\(face.displayName) crits for \(dealt)!"
                : "\(face.displayName) hits for \(dealt)."
            if face.face == .runeFrost, let target, enemies.indices.contains(target), enemies[target].isAlive {
                enemies[target].stagger = max(enemies[target].stagger, 0.2)
                addFloat("Slowed", color: Theme.frost, onEnemy: true, foe: foeID)
            }
            if face.face == .bomb {
                applyBurn(face.isCrit ? 6 : 4, turns: 2, targetIndex: target)
            }
            return true
        }

        switch face.face.soloKind {
        case .heal:
            healPlayer(value)
            lastAction = "You recover \(value) health."
        case .block:
            gainShield(value)
            lastAction = "Your shield grows by \(value)."
        case .evade:
            gainEvade(face.isCrit ? 0.20 : 0.15)
            lastAction = "You ready yourself — harder to hit this turn."
        case .poison:
            applyPoison(value, turns: 2, targetIndex: target)
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
        return false
    }

    // MARK: - Damage composition

    /// Every percentage and flat bonus on an attack adds together before it
    /// lands — nothing compounds. Primes are consumed here.
    private func applyDamageBonuses(
        _ base: Int,
        step: PlanStep,
        scalesWithBleed: Bool,
        scalesWithWounds: Bool,
        scalesWithBurn: Bool,
        targetIndex target: Int?
    ) -> Int {
        var damage = base
        var percentPoints = 0

        guard let target, enemies.indices.contains(target) else { return damage }
        let foe = enemies[target]

        // Consumed primes.
        if primeDamageFlat > 0 {
            damage += primeDamageFlat
            addFloat("+\(primeDamageFlat) primed", color: Theme.sunGold, onEnemy: false)
            primeDamageFlat = 0
        }
        if primePercentPoints > 0 {
            percentPoints += primePercentPoints
            primePercentPoints = 0
        }
        if primeBurnExtra > 0 {
            applyBurn(primeBurnExtra, turns: 2, targetIndex: target)
            primeBurnExtra = 0
        }
        if primeHealAmount > 0 {
            healPlayer(primeHealAmount, label: "Primed")
            primeHealAmount = 0
        }

        // Scales-with effects.
        if scalesWithBleed { damage += foe.bleedAmount * 2 }
        if scalesWithWounds { damage += (foe.def.maxHP - foe.hp) / 5 }
        if scalesWithBurn { damage += foe.burnAmount * 3 }

        // Upgrade damage riders.
        if hasUpgrade("sob_bloodScent"), foe.bleedTurns > 0 { percentPoints += 20 }
        if hasUpgrade("ba_pounce"), step.combo != nil, step.faces.count == 2 { damage += 6 }
        if hasUpgrade("ra_solarWind"),
           step.faces.contains(where: { $0.wasHeld && $0.patron == .ra && $0.face.isAttack }) {
            damage += 8
        }
        if hasUpgrade("ho_falconEye"),
           step.faces.contains(where: { $0.wasHeld && $0.patron == .horus && $0.face.isAttack }) {
            percentPoints += 25
        }
        if pairing?.id == "pair_sobek_horus", !pairingFiredThisTurn,
           foe.bleedTurns > 0,
           step.faces.contains(where: { $0.wasHeld && $0.patron == .horus }) {
            percentPoints += 25
            pairingFiredThisTurn = true
            addFloat("REED AND SKY", color: pairing?.tint.tint ?? Theme.nileGreen, onEnemy: false, big: true)
        }

        // Percentages add; only one multiplication happens.
        if percentPoints > 0 {
            damage = Int(Double(damage) * (1.0 + Double(percentPoints) / 100.0))
        }
        return damage
    }

    /// Pierce for this attack: the recipe's own fraction, plus upgrade and
    /// pairing riders, capped at total.
    private func attackPierce(comboBase: Double, step: PlanStep?, crit: Bool, targetIndex target: Int?) -> Double {
        var pierce = comboBase
        if let step { pierce += armedPierce(for: step) }
        guard let target, enemies.indices.contains(target) else { return min(pierce, 1.0) }
        let foe = enemies[target]

        // Capstone: Eye of the Falcon — once per turn, a chain holding a held
        // Horus face and containing a critical face ignores all defences.
        if capstoneID == "ho_eyeFalcon", !capstoneUsedThisTurn, let step, step.isCombo,
           step.faces.contains(where: { $0.wasHeld && $0.patron == .horus }),
           step.faces.contains(where: \.isCrit) {
            capstoneUsedThisTurn = true
            addFloat("EYE OF THE FALCON", color: Deity.horus.tint, onEnemy: false, big: true)
            return 1.0
        }
        // Pairing: Silent Descent — after an evade, the next chain holding a
        // Horus face ignores all defences.
        if silentDescentArmed, let step, step.isCombo, step.faces.count >= 2,
           step.faces.contains(where: { $0.patron == .horus }) {
            silentDescentArmed = false
            addFloat("SILENT DESCENT", color: Deity.horus.tint, onEnemy: false, big: true)
            return 1.0
        }

        if hasUpgrade("ra_sunEdge"), foe.burnTurns > 0 { pierce += 0.25 }
        if hasUpgrade("sob_riptide"), foe.hpFraction < 0.5 { pierce += 0.3 }
        return min(pierce, 1.0)
    }

    /// Where a step's chisel-granted second hit resolves: its allocation, or
    /// the weakest living foe other than the main target, falling back beside
    /// the main blow when nothing else stands.
    private func secondaryTargetIndex(for step: PlanStep, mainIndex: Int?) -> Int? {
        if let id = secondaryAllocations[step.id],
           let index = enemies.firstIndex(where: { $0.id == id && $0.isAlive }) {
            return index
        }
        let candidates = enemies.indices.filter { enemies[$0].isAlive && $0 != mainIndex }
        if let weakest = candidates.min(by: { enemies[$0].hp < enemies[$1].hp }) {
            return weakest
        }
        return resolveTarget(mainIndex)
    }

    /// The Echoing Staff: fire the stored half-cast at the start of your turn.
    /// No statuses, no stamina, no god effects, no further echoes.
    private func firePendingEcho() {
        guard let echo = pendingEcho else { return }
        pendingEcho = nil
        guard echo.damage > 0 || echo.heal > 0 || echo.shield > 0 else { return }
        addFloat("ECHO", color: Theme.ptahCopper, onEnemy: false, big: true)
        let index = echo.foeID.flatMap { id in enemies.firstIndex(where: { $0.id == id && $0.isAlive }) }
            ?? enemies.firstIndex(where: \.isAlive)
        if echo.damage > 0 {
            _ = damageEnemy(echo.damage, pierce: 0, targetIndex: index)
        }
        if echo.heal > 0 { healPlayer(echo.heal, label: "Echo") }
        if echo.shield > 0 { gainShield(echo.shield) }
    }

    /// Sobek's First Feast: the first attack each turn that draws blood heals 4.
    private func firstFeastCheck(_ dealt: Int) {
        guard dealt > 0, !bloodDrawnThisTurn, hasUpgrade("sob_firstFeast") else { return }
        bloodDrawnThisTurn = true
        healPlayer(4, label: "Sobek")
    }

    /// Sobek's capstone: once a turn, an attack against a bleeding foe bites
    /// its bleed early — one tick paid without shortening it.
    private func jawsOfTheNile(step: PlanStep, targetIndex target: Int?) {
        guard capstoneID == "sob_jaws", !capstoneUsedThisTurn,
              step.faces.contains(where: { $0.patron == .sobek }),
              step.faces.contains(where: { $0.face.isAttack }),
              let target, enemies.indices.contains(target),
              enemies[target].bleedTurns > 0, enemies[target].bleedAmount > 0 else { return }
        let foe = enemies[target]
        capstoneUsedThisTurn = true
        let paid = min(foe.bleedAmount, 8)
        addFloat("JAWS OF THE NILE", color: Deity.sobek.tint, onEnemy: false, big: true)
        damageEnemyDirect(foe.id, foe.bleedAmount, label: "Bleed")
        healPlayer(paid, label: "Sobek")
    }

    // MARK: - Blessings

    /// After an action lands, every god whose dice fed it answers the faces
    /// it read — once per role per action, in play order.
    private func resolveBlessings(in step: PlanStep, targetIndex target: Int?) {
        var fired: [Deity: Set<BlessingRole>] = [:]
        for face in step.faces {
            guard let god = face.patron else { continue }
            let role = BlessingRole.role(for: face.face)
            if fired[god]?.contains(role) == true { continue }
            fired[god, default: []].insert(role)

            // Bastet's evade answer is a once-per-turn slice, not per action.
            if god == .bastet, role == .evade, bastetEvadeUsed { continue }

            var answer = GodKit.blessing(for: god, role: role)
            switch god {
            case .ra where role == .attack || role == .evade:
                if hasUpgrade("ra_kindling") { answer.burn = max(answer.burn, 3) }
            case .anubis where role == .attack || role == .evade:
                if hasUpgrade("an_greatTally") { answer.judgement = answer.judgement == 6 ? 9 : answer.judgement + 3 }
            case .sobek where role == .attack:
                if hasUpgrade("sob_deepWater") { answer.bleed = sobekBleedBonus(answer.bleed) }
            case .bes where answer.shield > 0:
                if hasUpgrade("be_stout") { answer.shield += 2 }
            case .horus where role == .attack:
                if hasUpgrade("ho_keen") { answer.pierce = 0.4 }
            default:
                break
            }
            if god == .bastet, role == .evade { bastetEvadeUsed = true }

            land(answer, god: god, step: step, targetIndex: target)
        }

        // Held-face rewards ride the same action.
        if hasUpgrade("an_weighed"),
           step.faces.contains(where: { $0.wasHeld && $0.patron == .anubis && $0.face.isAttack }) {
            applyJudgement(6, targetIndex: target)
        }
        if hasUpgrade("ho_thermal"), !thermalUsedThisTurn,
           step.faces.contains(where: { $0.wasHeld && $0.patron == .horus }) {
            thermalUsedThisTurn = true
            nextTurnStamina += 1
            addFloat("+1 Stamina", color: Deity.horus.tint, onEnemy: false)
        }
    }

    /// Lands one god's answer: flat values first, primes banked for later.
    /// Everything that touches a foe lands on the step's own target.
    private func land(_ answer: GodAnswer, god: Deity, step: PlanStep, targetIndex target: Int?) {
        guard !answer.isEmpty else { return }
        let foeID = target.flatMap { enemies.indices.contains($0) ? enemies[$0].id : nil }
        addFloat(god.name.uppercased(), color: god.tint,
                 onEnemy: answer.damage > 0 || answer.burn > 0 || answer.bleed > 0 || answer.judgement > 0,
                 foe: foeID)
        if answer.damage > 0 {
            let raw = applyDamageBonuses(answer.damage, step: step,
                                         scalesWithBleed: false, scalesWithWounds: false, scalesWithBurn: false,
                                         targetIndex: target)
            let dealt = damageEnemy(raw, pierce: attackPierce(comboBase: answer.pierce, step: step, crit: false,
                                                              targetIndex: target),
                                    targetIndex: target)
            firstFeastCheck(dealt)
        } else if answer.pierce > 0 {
            // Horus's attack answer is pierce-only; it applies to this action.
            // It has already been folded through attackPierce for the damage
            // above when paired with damage; a pure-pierce answer primes nothing.
        }
        if answer.shield > 0 { gainShield(answer.shield) }
        if answer.heal > 0 { healPlayer(answer.heal) }
        if answer.burn > 0 { applyBurn(answer.burn, turns: 2, targetIndex: target) }
        if answer.bleed > 0 { applyBleed(answer.bleed, turns: 2, targetIndex: target) }
        if answer.judgement > 0 { applyJudgement(answer.judgement, targetIndex: target) }
        if answer.evadePercent > 0 { gainEvade(Double(answer.evadePercent) / 100.0) }
        if answer.primeDamage > 0 { primeBonus(damage: answer.primeDamage) }
        if answer.primePercent > 0 { primeBonus(percent: answer.primePercent) }
        if answer.primeBurn > 0 { primeBonus(burn: answer.primeBurn) }
        if answer.primeHeal > 0 { primeBonus(heal: answer.primeHeal) }
        if answer.staminaNext > 0 {
            nextTurnStamina += answer.staminaNext
            addFloat("+\(answer.staminaNext) Stamina", color: Theme.gold, onEnemy: false)
        }
    }

    private func primeBonus(damage: Int = 0, percent: Int = 0, burn: Int = 0, heal: Int = 0) {
        primeDamageFlat += damage
        primePercentPoints += percent
        primeBurnExtra += burn
        primeHealAmount += heal
        primeExpiryTurn = turnNumber + 1
    }

    // MARK: - Pairings

    /// Fires once an action has landed, for pairings keyed to the action
    /// itself. The rest fire on evades, shield absorptions and detonations.
    private func pairingAfterAction(step: PlanStep, dealtDamage: Bool, targetIndex target: Int?) {
        guard let pairing else { return }
        let heldHorus = step.faces.contains(where: { $0.wasHeld && $0.patron == .horus })
        let heldRaAttack = step.faces.contains(where: { $0.wasHeld && $0.patron == .ra && $0.face.isAttack })

        switch pairing.id {
        case "pair_ra_horus" where !pairingFiredThisTurn && heldRaAttack && heldHorus:
            pairingFiredThisTurn = true
            addFloat("SUNSTRIKE", color: pairing.tint.tint, onEnemy: false, big: true)
            earlyBurnTick(targetIndex: target)
        case "pair_anubis_horus" where !pairingFiredThisTurn && heldHorus:
            pairingFiredThisTurn = true
            addFloat("THE WEIGHING EYE", color: pairing.tint.tint, onEnemy: false, big: true)
            applyJudgement(6, targetIndex: target)
        case "pair_bes_horus" where !pairingFiredThisTurn && heldHorus:
            pairingFiredThisTurn = true
            addFloat("WATCHFUL GUARDIAN", color: pairing.tint.tint, onEnemy: false, big: true)
            gainShield(4)
        default:
            break
        }
        _ = dealtDamage
    }

    /// Pays one burn tick immediately, without shortening the burn.
    private func earlyBurnTick(targetIndex target: Int?) {
        guard let target, enemies.indices.contains(target),
              enemies[target].burnTurns > 0, enemies[target].burnAmount > 0 else { return }
        damageEnemyDirect(enemies[target].id, enemies[target].burnAmount, label: "Burn")
    }

    // MARK: - Shield, evade, healing, judgement

    private func gainShield(_ amount: Int) {
        guard amount > 0 else { return }
        playerShield += amount
        addFloat("+\(amount) Shield", color: Theme.steel, onEnemy: false)
    }

    private func gainEvade(_ chance: Double) {
        let before = evadeChance
        evadeChance = min(GameData.evadeCeiling, evadeChance + chance)
        if evadeChance > before {
            addFloat("+\(Int((evadeChance - before) * 100))% Evade", color: Theme.steel, onEnemy: false)
        } else {
            addFloat("Evade at its ceiling", color: Theme.steel, onEnemy: false)
        }
    }

    private func healPlayer(_ amount: Int, label: String? = nil) {
        guard amount > 0 else { return }
        let healed = min(playerMaxHP, playerHP + amount) - playerHP
        playerHP += healed
        if healed > 0 {
            addFloat("+\(healed)\(label.map { " \($0)" } ?? "")", color: Theme.forest, onEnemy: false)
        }
        // Pairing: Crocodile Hide — the first heal each turn hardens into shield.
        if pairing?.id == "pair_sobek_bes", !healGivenThisTurn, healed > 0 {
            healGivenThisTurn = true
            gainShield(5)
            addFloat("CROCODILE HIDE", color: Deity.sobek.tint, onEnemy: false, big: true)
        }
    }

    /// Anubis stores damage against a foe; it detonates at the end of your
    /// next turn. Additions to an already-pending pile join it at once —
    /// doubled for the Second Reading.
    private func applyJudgement(_ amount: Int, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        var value = amount
        if enemies[target].judgementPending, hasUpgrade("an_secondReading") {
            value *= 2
            addFloat("Second Reading", color: Deity.anubis.tint, onEnemy: false)
        }
        enemies[target].judgementAmount = min(GameData.judgementCap, enemies[target].judgementAmount + value)
        enemies[target].judgementPending = true
        addFloat("Judgement \(enemies[target].judgementAmount)", color: Deity.anubis.tint, onEnemy: true, foe: enemies[target].id)
    }

    /// The end of your turn: stored judgement falls against health directly,
    /// whatever armour or shield stands in the way.
    private func detonateJudgements() {
        for index in enemies.indices where enemies[index].isAlive && enemies[index].judgementPending {
            var amount = enemies[index].judgementAmount
            let foe = enemies[index]
            // Pairing: Funeral Pyre — detonations burn brighter with burn stacks.
            if pairing?.id == "pair_ra_anubis" {
                amount += foe.burnAmount * 2
            }
            // Capstone: Final Verdict.
            if capstoneID == "an_finalVerdict" {
                if foe.def.isBoss {
                    amount = Int(Double(amount) * 1.5)
                } else if foe.hpFraction < 0.25 {
                    amount *= 2
                }
            }
            // Pairing: The Crossing — a detonation against a bleeding foe heals 5.
            if pairing?.id == "pair_sobek_anubis", foe.bleedTurns > 0, !pairingFiredThisTurn {
                pairingFiredThisTurn = true
                healPlayer(5, label: "The Crossing")
            }
            enemies[index].judgementAmount = 0
            enemies[index].judgementPending = false
            damageEnemyDirect(foe.id, amount, label: "Judgement")
            withAnimation(.linear(duration: 0.35)) { shakeTrigger += 0.6 }
        }
    }

    /// Pairing: Boiling Nile — a foe burning and bleeding at once is scalded
    /// for its burn again at the end of your turn.
    private func boilingNileTick() {
        guard pairing?.id == "pair_ra_sobek", !pairingFiredThisTurn else { return }
        for foe in enemies where foe.isAlive && foe.burnTurns > 0 && foe.bleedTurns > 0 {
            pairingFiredThisTurn = true
            addFloat("BOILING NILE", color: Deity.ra.tint, onEnemy: false, big: true)
            damageEnemyDirect(foe.id, foe.burnAmount, label: "Burn")
            break
        }
    }

    // MARK: - Statuses

    private func applyBurn(_ amount: Int, turns: Int, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        enemies[target].burnAmount = min(12, max(enemies[target].burnAmount, amount))
        enemies[target].burnTurns = max(enemies[target].burnTurns, turns)
        addFloat("Burning!", color: Theme.ember, onEnemy: true, foe: enemies[target].id)
    }

    private func applyPoison(_ amount: Int, turns: Int, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        enemies[target].poisonAmount = max(enemies[target].poisonAmount, amount)
        enemies[target].poisonTurns = max(enemies[target].poisonTurns, turns)
        addFloat("Poisoned!", color: Theme.venom, onEnemy: true, foe: enemies[target].id)
    }

    private func applyBleed(_ amount: Int, turns: Int, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        enemies[target].bleedAmount = max(enemies[target].bleedAmount, amount)
        enemies[target].bleedTurns = max(enemies[target].bleedTurns, turns)
        addFloat("Bleeding!", color: Theme.blood, onEnemy: true, foe: enemies[target].id)
    }

    /// Sobek's Deep Water: his blessing's bleed ticks for 2 more.
    private func sobekBleedBonus(_ amount: Int) -> Int {
        hasUpgrade("sob_deepWater") ? amount + 2 : amount
    }

    @discardableResult
    private func damageEnemy(_ raw: Int, pierce: Double, targetIndex target: Int?) -> Int {
        guard let index = resolveTarget(target) else { return 0 }
        var foe = enemies[index]
        defer { enemies[index] = foe }

        var damage = Int(Double(raw) * foe.mark)
        if foe.mark > 1 { foe.mark = 1.0 }
        if foe.block > 0 {
            let ignored = Int(Double(foe.block) * pierce)
            let effectiveBlock = max(0, foe.block - ignored)
            let absorbed = min(effectiveBlock, damage)
            foe.block -= absorbed
            damage -= absorbed
            if absorbed > 0 { addFloat("Blocked \(absorbed)", color: Theme.steel, onEnemy: true, foe: foe.id) }
            if ignored > 0 { addFloat("Pierced!", color: Theme.gold, onEnemy: true, foe: foe.id) }
        }
        if foe.armour > 0 {
            let ignored = Int(Double(foe.armourMax) * pierce)
            let effectiveArmour = max(0, foe.armour - ignored)
            let absorbed = min(effectiveArmour, damage)
            foe.armour -= absorbed
            damage -= absorbed
            if absorbed > 0 {
                addFloat("Armour \(absorbed)", color: Theme.bronze, onEnemy: true, foe: foe.id)
                if foe.armour == 0 {
                    addFloat("ARMOUR BROKEN", color: Theme.boneWhite, onEnemy: true, big: true, foe: foe.id)
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
        onEnemyDamaged(foe)
        if damage >= 45 {
            withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
            Haptics.heavy()
        }
        return damage
    }

    /// Status and detonation damage: straight to health, under every plate.
    private func damageEnemyDirect(_ foeID: UUID, _ amount: Int, label: String) {
        guard amount > 0,
              let index = enemies.firstIndex(where: { $0.id == foeID && $0.isAlive }) else { return }
        enemies[index].hp = max(0, enemies[index].hp - amount)
        enemies[index].pose = .hurt
        damageDealt += amount
        addFloat("-\(amount) \(label)", color: Theme.blood, onEnemy: true, foe: foeID)
        onEnemyDamaged(enemies[index])
    }

    /// What happens whenever a foe takes real damage: burial gifts, burn
    /// spreading, and death checks.
    private func onEnemyDamaged(_ foe: EnemyState) {
        guard foe.hp <= 0 else { return }
        // Anubis's Sentence dies with the judge who passed it.
        if foe.isTrialChampion, trialAccepted, trial?.deity == .anubis, playerJudgementPending {
            playerJudgementPending = false
            playerJudgementAmount = 0
            addFloat("The Sentence dies with its judge", color: Deity.anubis.tint, onEnemy: false)
        }
        // Upgrade: Burial Gift — a judged enemy dying early pays out.
        if hasUpgrade("an_burialGift"), foe.judgementPending {
            healPlayer(8, label: "Burial")
            gainShield(8)
        }
        // Upgrade: Ashes to Ashes — a burning enemy's fire spreads on death.
        if hasUpgrade("ra_ashes"), foe.burnTurns > 0,
           let index = enemies.firstIndex(where: { $0.isAlive && $0.id != foe.id }) {
            enemies[index].burnAmount = max(enemies[index].burnAmount, foe.burnAmount)
            enemies[index].burnTurns = max(enemies[index].burnTurns, foe.burnTurns)
            addFloat("Ashes to Ashes", color: Deity.ra.tint, onEnemy: true, foe: enemies[index].id)
        }
    }

    // MARK: - Enemy turn

    private func enemyTurn() async {
        phase = .enemyActing
        enemyTurnCount += 1
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

        endOfEnemyTurn()
        try? await Task.sleep(for: .milliseconds(380))
        startPlayerTurn()
    }

    /// Once the last foe has swung: evade clears, Bes strikes back, Bastet
    /// rewards an unscathed turn.
    private func endOfEnemyTurn() {
        // Capstone: Unbroken House — retaliate for half of what the shield
        // absorbed, up to 20, at whoever hit hardest.
        if capstoneID == "be_unbroken", shieldAbsorbedThisEnemyTurn > 0,
           let foeID = hardestHitFoeID {
            let strike = min(20, shieldAbsorbedThisEnemyTurn / 2)
            if strike > 0 {
                addFloat("UNBROKEN HOUSE", color: Deity.bes.tint, onEnemy: false, big: true)
                damageEnemyDirect(foeID, strike, label: "Bes")
            }
        }
        // Upgrade: Unscathed — a turn with no health damage hardens into shield.
        if hasUpgrade("ba_unscathed"), !tookHealthDamageThisEnemyTurn,
           shieldAbsorbedThisEnemyTurn > 0 || hardestHitFoeID != nil {
            nextTurnStamina += 0
            // Shield lands at the start of the next turn so it reads fresh.
            gainShield(6)
        }
        shieldAbsorbedThisEnemyTurn = 0
        hardestHitFoeID = nil
        hardestHitAmount = 0
        tookHealthDamageThisEnemyTurn = false
        evadeChance = 0
        bastetEvadeUsed = false
        firstEvadeFired = false
        bloodDrawnThisTurn = false
        healGivenThisTurn = false
        pairingFiredThisTurn = false
        silentDescentArmed = false
        // Trial timers: the first-strike powers reset each enemy turn, and
        // Bastet's unspent evade charge expires with the turn.
        trialFirstStrikeUsed = false
        for index in enemies.indices where enemies[index].isTrialChampion {
            enemies[index].evadeCharges = 0
        }
    }

    /// The first time an incoming hit is actually slipped, several gods and
    /// pairings answer once.
    private func firstEvadeRewards(attacker: EnemyState) {
        guard !firstEvadeFired else { return }
        firstEvadeFired = true
        if hasUpgrade("ba_lightLanding") {
            nextTurnStamina += 1
            addFloat("+1 Stamina", color: Deity.bastet.tint, onEnemy: false)
        }
        if hasUpgrade("ba_claws") {
            primeBonus(damage: 10)
            addFloat("Claws Out", color: Deity.bastet.tint, onEnemy: false)
        }
        guard let pairing else { return }
        switch pairing.id {
        case "pair_ra_bastet":
            addFloat("DANCING FLAME", color: pairing.tint.tint, onEnemy: false, big: true)
            if let index = enemies.firstIndex(where: { $0.id == attacker.id }) {
                enemies[index].burnAmount = max(enemies[index].burnAmount, 2)
                enemies[index].burnTurns = max(enemies[index].burnTurns, 2)
            }
        case "pair_sobek_bastet" where !pairingFiredThisTurn:
            pairingFiredThisTurn = true
            addFloat("DEATH ROLL", color: pairing.tint.tint, onEnemy: false, big: true)
            if attacker.bleedAmount > 0 {
                damageEnemyDirect(attacker.id, attacker.bleedAmount, label: "Bleed")
            }
        case "pair_anubis_bastet":
            addFloat("BORROWED LIFE", color: pairing.tint.tint, onEnemy: false, big: true)
            if let index = enemies.firstIndex(where: { $0.id == attacker.id }) {
                enemies[index].judgementAmount = min(GameData.judgementCap, enemies[index].judgementAmount + 4)
                enemies[index].judgementPending = true
            }
        case "pair_bes_bastet":
            addFloat("WARM DOORSTEP", color: pairing.tint.tint, onEnemy: false, big: true)
            gainShield(4)
        default:
            break
        }
    }

    /// What fires when the shield soaks a hit: Bes's counter-swing, Forge
    /// Song and Guardian of the Tomb, and the absorbed tally.
    private func shieldAbsorbed(_ amount: Int, attacker: EnemyState) {
        shieldAbsorbedThisEnemyTurn += amount
        if amount > hardestHitAmount {
            hardestHitAmount = amount
            hardestHitFoeID = attacker.id
        }
        if hasUpgrade("be_counter") {
            primeBonus(damage: 10)
        }
        guard let pairing else { return }
        switch pairing.id {
        case "pair_ra_bes" where !pairingFiredThisTurn:
            pairingFiredThisTurn = true
            addFloat("FORGE SONG", color: pairing.tint.tint, onEnemy: false, big: true)
            if let index = enemies.firstIndex(where: { $0.id == attacker.id }) {
                enemies[index].burnAmount = max(enemies[index].burnAmount, 2)
                enemies[index].burnTurns = max(enemies[index].burnTurns, 2)
            }
        case "pair_anubis_bes" where !pairingFiredThisTurn:
            pairingFiredThisTurn = true
            addFloat("GUARDIAN OF THE TOMB", color: pairing.tint.tint, onEnemy: false, big: true)
            if let index = enemies.firstIndex(where: { $0.id == attacker.id }) {
                enemies[index].judgementAmount = min(GameData.judgementCap, enemies[index].judgementAmount + 4)
                enemies[index].judgementPending = true
            }
        default:
            break
        }
    }

    /// One foe takes its telegraphed turn. Returns true when the player died.
    private func foeActs(index: Int) async -> Bool {
        var foe = enemies[index]
        defer { enemies[index] = foe }

        let move = foe.intent
        lastAction = "\(foe.displayName) uses \(move.comboName ?? move.name)!"

        // Anubis's Sentence: every second turn the trial champion forgoes its
        // attack and weighs your heart instead.
        if isChampion(foe), trial?.deity == .anubis, enemyTurnCount % 2 == 0 {
            foe.pose = .telegraph
            try? await Task.sleep(for: .milliseconds(420))
            foe.pose = .attack
            addFloat("SENTENCE \(GameData.trialSentence)", color: Deity.anubis.tint, onEnemy: true, big: true, foe: foe.id)
            playerJudgementAmount = GameData.trialSentence
            playerJudgementPending = true
            lastAction = "\(foe.displayName) passes Sentence — it falls at the end of your next turn."
            try? await Task.sleep(for: .milliseconds(420))
            resetPoses()
            return false
        }

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
                foe.pose = .telegraph
                try? await Task.sleep(for: .milliseconds(300))
                foe.pose = .attack
                var hit = perHit + remainder
                remainder = 0

                // Evade rolls fresh for every hit: a chance, not a charge.
                if evadeChance > 0, Double.random(in: 0..<1) < evadeChance {
                    playerPose = .dodge
                    addFloat("Evaded!", color: Theme.steel, onEnemy: false)
                    Haptics.light()
                    firstEvadeRewards(attacker: foe)
                    try? await Task.sleep(for: .milliseconds(300))
                    resetPoses()
                    continue
                }

                if playerShield > 0 {
                    // Horus's trial blow ignores half of the guard.
                    var usableShield = playerShield
                    if isChampion(foe), trial?.deity == .horus, enemyTurnCount % 3 == 0 {
                        usableShield -= playerShield / 2
                        addFloat("Half the guard pierced!", color: Deity.horus.tint, onEnemy: false)
                    }
                    let absorbed = min(usableShield, hit)
                    playerShield -= absorbed
                    hit -= absorbed
                    if absorbed > 0 {
                        playerPose = .block
                        addFloat("Shield \(absorbed)", color: Theme.steel, onEnemy: false)
                        shieldAbsorbed(absorbed, attacker: foe)
                    }
                    if playerShield == 0, !shieldRebuiltThisBattle, hasUpgrade("be_rebuild") {
                        shieldRebuiltThisBattle = true
                        playerShield = 8
                        addFloat("Rebuild the Wall +8", color: Deity.bes.tint, onEnemy: false)
                    }
                    // Fully absorbed hits scorch back when a reflect stands.
                    if hit == 0, reflectFraction > 0 {
                        let back = Int(Double(absorbed) * reflectFraction)
                        if back > 0 {
                            foe.hp = max(0, foe.hp - back)
                            damageDealt += back
                            addFloat("-\(back) Riposte", color: Theme.gold, onEnemy: true, foe: foe.id)
                        }
                    }
                }
                guard hit > 0 else {
                    try? await Task.sleep(for: .milliseconds(300))
                    resetPoses()
                    continue
                }
                landedAnyHit = true
                tookHealthDamageThisEnemyTurn = true
                playerPose = .hurt
                playerHP = max(0, playerHP - hit)
                addFloat("-\(hit)", color: Theme.blood, onEnemy: false, big: hit >= 20)
                withAnimation(.linear(duration: 0.3)) { shakeTrigger += 1 }
                Haptics.heavy()

                // Ra's and Sobek's trials ride the champion's first hit that
                // reaches health each turn — blocked or evaded, nothing catches.
                if isChampion(foe), !trialFirstStrikeUsed, let trial {
                    if trial.deity == .ra {
                        trialFirstStrikeUsed = true
                        playerBurnAmount = 2
                        playerBurnTurns = 2
                        addFloat("BURNING SUN", color: Deity.ra.tint, onEnemy: false, big: true)
                    } else if trial.deity == .sobek {
                        trialFirstStrikeUsed = true
                        playerBleedAmount = max(playerBleedAmount, 2)
                        playerBleedTurns = max(playerBleedTurns, 2)
                        addFloat("HUNGRY RIVER", color: Deity.sobek.tint, onEnemy: false, big: true)
                        foe.hp = min(foe.def.maxHP, foe.hp + 4)
                        addFloat("+4", color: Theme.forest, onEnemy: true, foe: foe.id)
                    }
                }

                // Capstone: Nine Lives Unbound — once a battle, death waits.
                if playerHP <= 0 {
                    if capstoneID == "ba_nineLives", !nineLivesUsed {
                        nineLivesUsed = true
                        playerHP = 1
                        evadeChance = max(evadeChance, 0.85)
                        primeBonus(damage: 10)
                        addFloat("NINE LIVES UNBOUND", color: Deity.bastet.tint, onEnemy: false, big: true)
                        Haptics.heavy()
                    } else {
                        finishDefeat("\(foe.displayName) puts out the disc...")
                        return true
                    }
                }
                try? await Task.sleep(for: .milliseconds(300))
                resetPoses()
            }
        }

        if move.bleedAmount > 0 && landedAnyHit {
            playerBleedAmount = max(playerBleedAmount, move.bleedAmount)
            playerBleedTurns = max(playerBleedTurns, move.bleedTurns)
            addFloat("Bleeding!", color: Theme.blood, onEnemy: false)
        }

        // Bes's trial gift: after acting, the gate rises against your turn.
        if isChampion(foe), trial?.deity == .bes {
            foe.block += 8
            addFloat("UNBROKEN GATE +8", color: Deity.bes.tint, onEnemy: true, foe: foe.id)
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
        // The Echoing Staff's half-cast lands before anything else moves.
        firePendingEcho()

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

        // Ra's trial: the champion's first strike leaves you burning.
        if playerBurnTurns > 0 {
            playerHP = max(0, playerHP - playerBurnAmount)
            playerBurnTurns -= 1
            addFloat("-\(playerBurnAmount) Burn", color: Theme.ember, onEnemy: false)
            if playerHP <= 0 {
                finishDefeat("The burning sun consumes you...")
                return
            }
        }

        // Primes left unspent die after your next player turn.
        if turnNumber >= primeExpiryTurn {
            primeDamageFlat = 0
            primePercentPoints = 0
            primeBurnExtra = 0
            primeHealAmount = 0
        }

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
        dissolvedCombos = []
        forcedCombos = []
        capstoneUsedThisTurn = false
        thermalUsedThisTurn = false

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

        // Per-turn Chisel timers: the nock frees up, the current forgets and
        // the knife's promise is renewed.
        nockShiftedFaceID = nil
        currentUsedThisTurn = false
        returningKnifeUsedThisTurn = false

        // Bastet's trial gift: every second turn of yours the champion
        // vanishes behind one evade charge, gone at the turn's end.
        if trialAccepted, trial?.deity == .bastet, turnNumber % 2 == 0,
           let index = enemies.firstIndex(where: { $0.id == trialChampionID }), enemies[index].isAlive {
            enemies[index].evadeCharges = 1
            addFloat("EVASIVE — 1 CHARGE", color: Deity.bastet.tint, onEnemy: true, foe: enemies[index].id)
        }

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

    // MARK: - Unordered combo grouping

    /// Chisel-assisted matching: Prismatic Focus stands one Arcane rune in for
    /// Fire, Frost or Life; Concealed Blade counts one Evade as a Swift Slash.
    /// One assisted recipe per grouping pass — deterministic, order-free, and
    /// the substituted face keeps its true identity for the gods.
    private func chiselAssistedMatch(_ combo: ComboDef, kinds: [FaceKind]) -> (indices: [Int], substitution: (index: Int, kind: FaceKind))? {
        if hasChisel("ch_prismatic"), classID == "magician", combo.source == .weapon {
            let arcaneIndices = kinds.indices.filter { kinds[$0] == .runeArcane }
            for rune in [FaceKind.runeFire, .runeFrost, .runeLife] {
                for arcaneIndex in arcaneIndices {
                    var trial = kinds
                    trial[arcaneIndex] = rune
                    if let indices = combo.match(from: trial), indices.contains(arcaneIndex) {
                        return (indices, (arcaneIndex, rune))
                    }
                }
            }
        }
        if hasChisel("ch_concealedBlade"), classID == "rogue", combo.source == .weapon {
            let evadeIndices = kinds.indices.filter { kinds[$0] == .evade }
            for evadeIndex in evadeIndices {
                var trial = kinds
                trial[evadeIndex] = .swiftSlash
                if let indices = combo.match(from: trial), indices.contains(evadeIndex) {
                    return (indices, (evadeIndex, .swiftSlash))
                }
            }
        }
        return nil
    }

    /// Groups played faces into steps: every recipe that fits forms a single
    /// step, biggest and most specific first; everything left resolves alone.
    /// Order inside a step is play order; steps are ordered by their first
    /// member so the bar reads naturally.
    func buildPlan(from faces: [RolledFace]) -> [PlanStep] {
        var remaining = faces
        var groups: [(combo: ComboDef, members: [RolledFace])] = []

        var pool = comboPool.filter { !dissolvedCombos.contains($0.id) }
        // Forced recipes come first, in the order the player locked them.
        pool.sort { lhs, rhs in
            let lForced = forcedCombos.contains(lhs.id)
            let rForced = forcedCombos.contains(rhs.id)
            if lForced != rForced { return lForced }
            return false
        }

        var changed = true
        var substitutions = 0
        while changed {
            changed = false
            for combo in pool {
                guard combo.faceCount <= remaining.count else { continue }
                let kinds = remaining.map(\.matchFace)
                var indices = combo.match(from: kinds)
                var substituted: (index: Int, kind: FaceKind)? = nil
                if indices == nil, substitutions < 1,
                   let assisted = chiselAssistedMatch(combo, kinds: kinds) {
                    indices = assisted.indices
                    substituted = assisted.substitution
                }
                guard let indices else { continue }
                var members = indices.map { remaining[$0] }
                if let substituted {
                    substitutions += 1
                    if let local = indices.firstIndex(of: substituted.index) {
                        members[local].effectiveFace = substituted.kind
                    }
                }
                groups.append((combo, members))
                var next: [RolledFace] = []
                for (offset, face) in remaining.enumerated() where !indices.contains(offset) {
                    next.append(face)
                }
                remaining = next
                changed = true
                break
            }
        }

        var steps: [PlanStep] = []
        var attacksSoFar = 0
        var pendingFocus = 0
        var pendingMomentum = momentumCarry

        // Merge everything back into play order, combos carried with their
        // first member's position.
        var ordered: [(position: Int, step: PlanStep)] = []
        var consumed = Set<UUID>()
        for group in groups {
            let position = faces.firstIndex(where: { group.members.contains($0) && !consumed.contains($0.id) }) ?? 0
            for member in group.members { consumed.insert(member.id) }
            let momentum = group.combo.damage > 0 ? momentumBonus(for: attacksSoFar) + pendingMomentum : 0
            let focus = group.combo.damage > 0 ? pendingFocus : 0
            ordered.append((position, PlanStep(faces: group.members, combo: group.combo,
                                               momentumBonus: momentum, focusBonus: focus)))
            if group.combo.damage > 0 {
                pendingFocus = 0
                pendingMomentum = 0
                attacksSoFar += group.members.filter { $0.face.isAttack }.count
            }
        }
        for (index, face) in faces.enumerated() where !consumed.contains(face.id) {
            let isAttack = face.face.isAttack
            let momentum = isAttack ? momentumBonus(for: attacksSoFar) + pendingMomentum : 0
            let focus = isAttack ? pendingFocus : 0
            ordered.append((index, PlanStep(faces: [face], combo: nil,
                                            momentumBonus: momentum, focusBonus: focus)))
            if isAttack {
                pendingFocus = 0
                pendingMomentum = 0
                attacksSoFar += 1
            }
            if face.face == .focus { pendingFocus += 5 }
        }

        steps = ordered.sorted { $0.position < $1.position }.map(\.step)

        // Relentless Advance: the first weapon combo of the turn costs one
        // less stamina, never below one.
        if relentlessActive, let index = steps.firstIndex(where: { $0.combo?.source == .weapon }) {
            let step = steps[index]
            steps[index] = PlanStep(
                faces: step.faces, combo: step.combo,
                momentumBonus: step.momentumBonus, focusBonus: step.focusBonus,
                staminaDiscount: GameData.relentlessDiscount
            )
        }
        return steps
    }

    /// Warrior passive: each swing already thrown this turn adds damage.
    private func momentumBonus(for attacksSoFar: Int) -> Int {
        guard classID == "warrior", attacksSoFar > 0 else { return 0 }
        return attacksSoFar * 5
    }

    // MARK: - Chain spectacle

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
        let target = onEnemy ? foe : nil
        let event = FloatText(text: text, color: color, onEnemy: onEnemy, foeID: target, big: big)
        floaters.append(event)
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            floaters.removeAll { $0.id == event.id }
        }
    }
}
