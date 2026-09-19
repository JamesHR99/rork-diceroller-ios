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
    /// True when this result survived a selective reroll this round.
    var wasKept = false
    /// Chisel substitutions: Adjustable Nock shifts a held arrow a tier,
    /// Prismatic Focus stands an Arcane rune in for another, Concealed Blade
    /// counts an Evade as a Swift Slash. The true face keeps its god and crit.
    var effectiveFace: FaceKind?
    /// Returning Knife: this appearance has already come back once.

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
        wasKept: Bool = false,
        effectiveFace: FaceKind? = nil
    ) {
        self.id = id
        self.dieID = dieID
        self.dieName = dieName
        self.face = face
        self.patron = patron
        self.isCrit = isCrit
        self.critChance = critChance
        self.imbueTiers = imbueTiers
        self.wasKept = wasKept
        self.effectiveFace = effectiveFace
    }

    /// The face the engine matches recipes with and prints values from —
    /// the true face wherever no Chisel substitution stands.
    var matchFace: FaceKind { effectiveFace ?? face }
}

/// Visual + logical state of one reel in the tray. A slot has its own identity

/// the die it came from — the die itself rolls again.
struct DieSlot: Identifiable {
    let id: UUID
    let die: Die
    var state: SlotState

    /// Carried reels never tumble; they hand you their face and retire.

    init(die: Die, state: SlotState) {
        self.id = die.id
        self.die = die
        self.state = state
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
    let focusFaceID: UUID?
    /// Chance the whole combo crits, from how many crit dice fed it.
    let comboCritChance: Double


    init(
        faces: [RolledFace],
        combo: ComboDef?,
        momentumBonus: Int = 0,
        focusBonus: Int = 0,
        focusFaceID: UUID? = nil
    ) {
        self.id = faces.first?.id ?? UUID()
        self.faces = faces
        self.combo = combo
        self.momentumBonus = momentumBonus
        self.focusBonus = focusBonus
        self.focusFaceID = focusFaceID
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

    var isPreparedSupport: Bool {
        guard combo == nil, let face = faces.first else { return false }
        return [.block, .evade, .focus, .channel, .energize].contains(face.matchFace)
    }
    var isFocus: Bool {
        combo == nil && faces.first.map { [.focus, .channel, .energize].contains($0.matchFace) } == true
    }
    var isCombo: Bool { combo != nil }
    var critDice: Int { faces.filter(\.isCrit).count }
    var hasCritFace: Bool { critDice > 0 }
    var isGuaranteedCrit: Bool { combo?.guaranteedCrit == true }
    var title: String { combo?.name ?? faces.first?.displayName ?? "" }
    /// Fused combos cost less than their faces played apart. Relentless
    /// Advance shaves one more off the first weapon combo of a turn.
    var diceCount: Int {
        faces.count
    }

    /// True when this step touches a foe — direct damage or an enemy status —
    /// so it is listed in the allocation overlay and needs a target.
    var targetsEnemy: Bool {
        if damage > 0 { return true }
        if let combo {
            return combo.bleedAmount > 0 || combo.poisonAmount > 0
                || combo.burnAmount > 0 || combo.weaken > 0 || combo.markPercent > 0
        }
        guard let face = faces.first else { return false }
        return face.matchFace.soloKind == .poison || face.matchFace == .runeFrost
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
        guard let face = faces.first, face.matchFace.isAttack else { return 0 }
        let base = face.isCrit
            ? GameData.scaleUp(face.matchFace.soloValue, by: GameData.faceCritMultiplier)
            : face.matchFace.soloValue
        return base + momentumBonus + focusBonus
    }

    /// Damage if the combo lands critical (single faces already show their crit).
    var critDamage: Int {
        guard let combo, combo.damage > 0 else { return damage }
        let base = GameData.scaleUp(combo.damage, by: comboCritScale)
        return base + momentumBonus + (focusFaceID == nil ? 0 : BattleRules.focusedBonus(damage: base))
    }

    /// Short non-damage effects, e.g. "+24 HP", "Bleed 8×3".
    var effects: [String] {
        if let combo {
            let scale = comboScale
            func scaled(_ value: Int) -> Int { GameData.scaleUp(value, by: scale) }
            var parts: [String] = []
            if combo.bleedAmount > 0 { parts.append("Bleed \(scaled(combo.bleedAmount))") }
            if combo.poisonAmount > 0 { parts.append("Poison \(scaled(combo.poisonAmount))") }
            if combo.burnAmount > 0 { parts.append("Burn \(scaled(combo.burnAmount))") }
            if combo.heal > 0 { parts.append("+\(scaled(combo.heal)) HP") }
            if combo.regenAmount > 0 { parts.append("Regen \(scaled(combo.regenAmount))×\(combo.regenTurns)") }
            if combo.lifesteal { parts.append("Lifesteal") }
            if combo.shield > 0 { parts.append("+\(scaled(combo.shield)) Shield") }
            if combo.dodgeCharges > 0 { parts.append("\(combo.dodgeCharges) Dodge") }
            if combo.pierce > 0 { parts.append("Pierce \(Int(combo.pierce * 100))%") }
            if combo.weaken > 0 { parts.append("Weaken \(Int(combo.weaken * 100))%") }
            if combo.markPercent > 0 { parts.append("Mark +\(combo.markPercent)%") }
            if combo.reflect > 0 { parts.append("Reflect \(Int(combo.reflect * 100))%") }
            return parts
        }
        guard let face = faces.first else { return [] }
        let multiplier = face.isCrit ? GameData.faceCritMultiplier : 1.0
        let value = GameData.scaleUp(face.matchFace.soloValue, by: multiplier)
        var list: [String] = []
        switch face.matchFace.soloKind {
        case .heal: list = ["+\(value) HP"]
        case .block: list = ["+\(value) Shield"]
        case .evade: list = ["1 Dodge"]
        case .poison: list = ["Poison \(value)×2"]

        case .focus: list = ["Next attack +50%"]
        case .damage:
            if face.matchFace == .runeFrost { list = ["Slow"] }
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

/// The banner, shockwave and sparks thrown by a chain as it resolves.
struct ComboFlash: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let chain: Int
    let summary: String
    let tint: Color
    let crit: Bool
}

/// The scales tipping on one creature: Anubis's verdict landing, drawn as a
/// ring of jackal-dark light bursting off the figure it fell on. Distinct from
/// ordinary damage so a verdict can never be mistaken for a normal hit.
struct VerdictBurst: Identifiable, Equatable {
    let id = UUID()
    /// The creature the scales tipped against.
    let foeID: UUID
    /// What the verdict actually took.
    let amount: Int
    /// True when the pile was heavy enough to earn the scaling bonus.
    let heavy: Bool
}

/// One god's answer to an action, named and totalled, for the card that rises
/// in the middle of the deck before the blows land.
struct DivineFlashEntry: Identifiable, Equatable {
    let id = UUID()
    let god: Deity
    /// The power's own name, e.g. "Sheltering Blow".
    let name: String
    /// What it actually did, e.g. "+8 shield".
    let effect: String
}

/// One hit waiting to be pointed at a creature during the aiming phase.
///
/// Aiming happens after you commit rather than while you plan: the deck
/// drops, the stage is uncovered, and each attack in turn asks which creature
/// it should strike. One tap per blow, on the thing you want it to hit.
struct AimRequest: Identifiable, Equatable {
    let id = UUID()
    /// The plan step this hit belongs to.
    let stepID: UUID
    /// True for a chisel-granted second hit rather than the blow itself.
    let isSecondary: Bool
    let title: String
    let detail: String
    let damage: Int
    let faces: [FaceKind]
    let tint: Color
}

/// One action, named and totalled before it resolves — whoever is acting.
///
/// A fight used to be legible only if you could read floaters while numbers
/// were still moving: you saw a colour fly past and never learned which blow
/// it belonged to or what it was worth. This card holds the whole action
/// still for a beat: who is acting, what they are doing, the faces that fed
/// it, what it will cost, and every god power riding it — all in one place
/// and all at the same time.
struct ActionSpotlight: Identifiable, Equatable {
    let id = UUID()
    /// Who is acting — the demigod, or the thing out of the river.
    let actor: String
    let isPlayer: Bool
    /// The action's own name: a recipe, a face played alone, or a foe's move.
    let title: String
    /// What it will do, in the same words the plan card uses.
    let detail: String
    /// The foe it is pointed at, when more than one is standing.
    let target: String?
    /// The faces welded into it, drawn in order.
    let faces: [FaceKind]
    let crit: Bool
    /// A wind-up's multiplier, when this action is a creature gathering itself.
    let charge: Double
    /// "2 of 3" for a creature spending its round on a sequence.
    let sequence: String?
    /// Every god power that answered this action, named and totalled.
    let entries: [DivineFlashEntry]
    let tint: Color
    /// True the first time a chain ever lands: the card announces it as a find
    /// and the codex keeps it from then on.
    var isDiscovery: Bool = false
}

/// How long the arena holds each beat of a fight, in milliseconds.
///
/// Every one of these used to be a magic number tuned against single drawings
/// that only had to register for an instant. The heroes are now animated
/// frame by frame — a swing is eight plates and the better part of a second —
/// so the beats are stretched to let a drawn action finish before the board
/// moves on. Change the pace of the whole fight here rather than in fifteen
/// scattered sleeps.
enum BattleBeat {
    /// Pause before a planned step steps into the light.
    static let stepLeadIn = 70
    /// A single face resolving on its own: long enough to play its clip out.
    static let soloStep = 400
    /// A chain landing — the floor, before its length and crit bonus.
    static let comboBase = 430
    /// Added per face welded into the chain.
    static let comboPerFace = 65
    /// Added when the chain crits, so the flash has room.
    static let comboCrit = 180
    /// After the last step, before statuses tick.
    static let turnSettle = 150
    /// Either side of a poison, burn or bleed tick.
    static let statusTick = 160
    /// Pause before a foe takes its turn.
    static let foeLeadIn = 80
    /// A foe raising its guard or licking its wounds.
    static let foeSupport = 350
    /// The tell before a blow — matches the drawn wind-up.
    static let telegraph = 300
    /// A blow landing, long enough for the recoil animation to play.
    static let strike = 400
    /// A blow slipped or swallowed whole by the shield.
    static let deflect = 330
    /// Either side of the champion's Sentence.
    static let sentence = 420
    /// The breath between the last foe acting and the drums spinning again.
    static let handover = 200

    /// How long the card that names an action is held before the action
    /// resolves. This is the beat that makes a fight readable: the name of
    /// the blow, what it is worth, the faces that fed it and every god power
    /// riding it are all on screen together, and they stay long enough to
    /// actually be read.
    static let spotlight = 400
    /// Added per god power named on the card, so a heavily blessed action
    /// holds longer than a plain one.
    static let spotlightPerGod = 90
    /// Added the first time a chain ever lands. Finding a recipe is the one
    /// moment in a fight worth stopping the board for.
    static let spotlightDiscovery = 650
    /// A fallen creature's last moment on the deck before it sinks out of
    /// the fight.
    static let sink = 380
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

/// One foe on the deck: its own health, guard, statuses, telegraphed intent
/// and pose. A battle holds one for every enemy in the fight.
struct EnemyState: Identifiable {
    let id = UUID()
    let def: EnemyDef
    var hp: Int
    /// The deepest this foe's guard has ever stood, which is what its bar is
    /// drawn against. Raising guard mid-fight raises the mark with it.
    var armourMax: Int
    /// The one guard pool. Worn plate and a raised block are the same
    /// resource: direct damage chips it before health, statuses seep under it,
    /// and what is left stands until something breaks it — exactly like your
    /// own shield.
    var armour: Int
    /// Bleed never adds: the strongest wound stands. It bites just before this
    /// creature attacks, so aggression costs it blood.
    var bleedAmount = 0
    var bleedTurns = 0
    /// Poison stacks and grows by one every round end. It never expires.
    var poisonAmount = 0
    var poisonTurns = 0
    /// Burn stacks up and halves after each round-end bite: fast pressure
    /// that fades on its own.
    var burnAmount = 0
    var burnTurns = 0
    /// How much the creature's next attack is softened by, 0–0.5.
    var weaken = 0.0
    /// How much harder the next attack on this creature lands, as a bonus
    /// fraction added to the hit rather than multiplied over it.
    var markBonus = 0.0
    var pose: FighterPose = .idle
    /// Everything this creature has told you it is going to do this round, in

    /// do, so a round can be one heavy blow or a guard and two quick cuts —
    /// and every one of them is on the board before you commit.
    var intents: [EnemyMove]
    /// A wind-up it is holding: what its next attack is multiplied by.
    var chargeBonus = 0.0
    /// Which stage a multi-stage serpent-lord is currently in.
    var stageIndex = 0
    /// Damage Anubis has stored against this foe. The scales hold it for a
    /// few of your turns before tipping, so the pile is worth feeding;
    /// further additions join it and do not restart the count.
    var judgementAmount = 0
    var judgementPending = false

    init(def: EnemyDef) {
        self.def = def
        self.hp = def.maxHP
        self.armourMax = def.armour
        self.armour = def.armour
        self.intents = EnemyPlanner.plan(def: def, hpFraction: 1, context: .opening)
    }

    /// The first thing this creature is going to do. Kept so every read that
    /// only cares about the opening blow stays honest.
    var intent: EnemyMove {
        intents.first ?? def.moves.first
            ?? EnemyMove(id: "wait", name: "Waits", faces: [], weight: 1)
    }

    /// True when this round is a sequence rather than a single blow.
    var hasChainedIntents: Bool { intents.count > 1 }

    var isAlive: Bool { hp > 0 }
    var hpFraction: Double { def.maxHP > 0 ? Double(hp) / Double(def.maxHP) : 0 }

    /// Raises the guard, carrying the bar's mark up with it so a foe that
    /// blocks past its authored plate still reads honestly.
    mutating func gainGuard(_ amount: Int) {
        guard amount > 0 else { return }
        armour += amount
        armourMax = max(armourMax, armour)
    }

    /// True when this creature is standing behind a guard worth the name —
    /// used by the planner to stop it stacking walls it does not need.
    var isWellGuarded: Bool {
        armour >= max(12, Int(Double(def.maxHP) * 0.18))
    }
    /// Divine Trials: this foe carries the attending god's lent power.
    var isTrialChampion = false
    /// Bastet's trial gift: a charge that slips one blow this turn.
    var evadeCharges = 0
    /// Bosses re-coil a little sooner under the tighter economy.
    var stagedHPFraction: Double {
        def.isBoss ? min(1, hpFraction + GameData.bossStageShift) : hpFraction
    }
    var displayName: String { def.displayName(hpFraction: stagedHPFraction) }
    /// Which stage a serpent-lord is wearing right now — each one was drawn
    /// its own sheet, so the art follows the body it has re-coiled into.
    var stageID: String? { def.stage(hpFraction: stagedHPFraction)?.id }
    /// The painted sheet this foe animates from, or nil when it was never drawn.
    var sheetID: String? { CharacterArt.foeSheetID(def.id, stageID: stageID) }
}

/// faces, per-face crits, unordered class combos, persistent shield, rolling
/// evade chance, god blessings, and weighted enemy AI.
@Observable
final class BattleEngine {
    enum Phase: Equatable {
        case player
        /// Between committing and the blows: every attack that needs a target
        /// is pointed by tapping the foe it should strike, on the stage.
        case aiming
        case resolving
        case enemyActing
        case won
        case lost
    }

    // MARK: Config
    /// The foes in this fight, in the order they rose. Solo fights are a pack of one.
    private(set) var enemies: [EnemyState]
    let classID: String
    /// The demigod's name, for the cards that say who is acting.
    var heroName: String { GameData.heroClass(id: classID).name }
    let critBonus: Double

    /// and the lower total acts first.
    /// The god powers carried into this fight, in their slots.
    let boons: [EquippedBoon]
    /// How deep into the PharaohSWager this fight sits — scales enemy pressure.
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
    /// it. Unused guard expires at round end; Warriors retain up to 8.
    private(set) var playerShield = 0
    /// Guaranteed single-hit dodges, optionally reserved for announced strikes.
    var dodgeCharges: Int { dodgeReservations.count }
    private(set) var reflectFraction = 0.0
    private(set) var playerBleedAmount = 0
    private(set) var playerBleedTurns = 0
    private(set) var regenAmount = 0
    private(set) var regenTurns = 0

    private(set) var nextRoundRerolls = 0
    /// Damage banked onto next turn's first swing (momentum recipes).
    private(set) var momentumCarry = 0

    // Primes: bonuses banked onto the next damaging action. They expire after
    // your next player turn if left unspent.
    private var primeDamageFlat = 0
    private var primePercentPoints = 0
    private var primeBurnExtra = 0
    private var primeHealAmount = 0
    private var primeExpiryTurn = 0
    private var primePierceBonus = 0.0

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
    //
    // Siege Draw is the exception: it arms onto a single arrow *die* in the
    // plan, because a chain is hidden until it fires and you cannot overdraw a
    // recipe you have not been told you built. Whatever step that die ends up
    // in carries the overdraw — so a die that fuses into a chain hands the
    // bonus to the whole chain.
    private(set) var siegeArmedFaceIDs: Set<UUID> = []
    private(set) var counterweightArmed: Set<String> = []
    private(set) var assassinArmed: Set<String> = []
    private(set) var echoArmedComboID: String?
    /// The optional Chisel the copper mark by the turn count has picked up,
    /// waiting for you to name the chain it rides. Tap the mark, tap a chain.
    private(set) var armingChiselID: String?
    /// Twin Bowstring's second arrow, Crescent Edge's splash and the echo's
    /// retargets: step ID → foe ID, defaulted to the weakest living foe.
    private(set) var secondaryAllocations: [UUID: UUID] = [:]
    /// Adjustable Nock: the one held arrow shifted a tier this turn.
    private(set) var nockShiftedFaceID: UUID?
    private var returningKnifeUsedThisTurn = false
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
    /// The attacks still waiting to be pointed, in play order. Aiming happens
    /// after you commit: the deck drops, the stage is uncovered, and each
    /// attack is sent by tapping the foe it should strike.
    private(set) var aimQueue: [AimRequest] = []
    /// The foe the blow currently being thrown was sent at.
    private(set) var activeTargetID: UUID?
    /// Creatures that have gone under. A fallen foe holds the deck for a beat
    /// and then leaves it, so the stage only ever shows the fight you still
    /// have on your hands.
    private(set) var sunkFoeIDs: Set<UUID> = []
    /// Set for a beat when a boss re-coils, so the arena can announce it.
    private(set) var stageAnnouncement: String?

    // MARK: Board state
    private let loadoutDice: [Die]
    private(set) var slots: [DieSlot]
    private(set) var drawnDieIDs: Set<UUID> = []
    private(set) var rolled: [RolledFace] = []
    private(set) var hasRolled = false
    private(set) var rollID = UUID()
    private(set) var rollStartedAt: TimeInterval = 0
    private(set) var rollUsesReducedMotion = false
    @ObservationIgnored private var rollTask: Task<Void, Never>?
    private var pendingRolls: [UUID: RolledFace] = [:]
    private(set) var rerollSelection: Set<UUID> = []
    private(set) var rerollsUsed = 0
    private(set) var rerollBonus = 0
    var selectingReroll = false
    private(set) var evadeAssignments: [UUID: String] = [:]
    private var dodgeReservations: [String?] = []
    private var nextRoundGuard = 0
    private var preparedFocusUsed: Set<UUID> = []
    private(set) var pendingEntries: [TimelineEntry] = []
    private(set) var playOrder: [UUID] = []
    /// Dice you have explicitly welded together, each entry the face ids of one
    /// combined action in plan order. Nothing fuses on its own any more: a
    /// recipe only becomes a combo because you chose to combine it, and
    /// Separate gives the dice straight back.
    private(set) var weldedGroups: [[UUID]] = []
    private(set) var phase: Phase = .player
    private(set) var turnNumber = 1
    private(set) var committedPlan: [PlanStep] = []
    private(set) var activeStepIndex: Int?
    private(set) var lastAction = "Roll your dice."

    // MARK: The shared clock
    /// Anubis's Preserved Moment, armed in planning: this one commitment may
    /// hold three faces instead of two.


    // MARK: God powers, per round
    /// Completed primary player actions this round, by role. Every
    /// "first/second/third" counter in the catalogue reads these — never
    /// ingredient count, never animation hits.
    private var attacksThisRound = 0
    private var guardsThisRound = 0
    private var soloAttacksThisRound = 0
    private var lastSoloFoeID: UUID?
    private var separateGuardPlayed = false
    private var separateEvadePlayed = false
    private var separateSupportPlayed = false
    private var nextHitReduction = 0.0
    private var shieldBrokeThisRound = false
    private var pendingBoonEffects: [(payload: BoonPayload, target: Int?)] = []
    private var pendingHealOnHit = 0
    private var healingFromDuo = false
    private var boonStartShield: Int?
    private var boonStartFoe: EnemyState?
    private var evaluatingBoons = false
    /// Boon ids that have already answered this round, for once-a-round cards.
    private var boonsFiredThisRound: Set<String> = []
    /// Boon ids that have answered this encounter, for once-a-fight cards.
    private var boonsFiredThisEncounter: Set<String> = []
    /// The foe the last attack was pointed at, for "same target" clauses.
    private var lastAttackFoeID: UUID?
    /// Reactions armed by Guard/Evade actions, expiring at round end.
    private var armedOnShieldAbsorb: [String] = []
    private var armedOnDodge: [String] = []
    private var patronDodgeAnswers: [(answer: GodAnswer, god: Deity, step: PlanStep)] = []
    /// Set once the round has dealt the player any health damage, for Unscathed.
    private var lostHealthThisRound = false
    private var incomingAttemptedThisRound = false

    /// Pierce banked by god powers onto the action currently resolving.
    private var boonPierceBonus = 0.0
    /// Delay the player has pushed onto each foe's pending action this round.
    private(set) var foeDelays: [UUID: Int] = [:]
    /// The beat the resolution has reached, for the strip's playhead.
    private(set) var currentBeat = 0
    /// Enemies that caught you stepping off the barque, quicker for round one.

    /// Chains the player has landed for the first time this fight, so the
    /// battle can announce a find once and the codex can keep it for good.
    private(set) var chainsDiscoveredThisFight: [String] = []

    /// Every chain the player has ever landed, read once at the start of the
    /// fight and kept in memory so the plan bar is not hitting storage on
    /// every redraw. Discoveries made mid-fight are folded in as they land.
    private var knownChainIDs: Set<String> = ComboLore.known()

    // MARK: Fighter animation
    private(set) var playerPose: FighterPose = .idle
    /// The gods whose blessings ride the blow currently being thrown.
    private(set) var strikeGods: [Deity] = []


    // MARK: Effects & stats
    /// Shots crossing the deck right now: arrows, thrown knives, cast runes and
    /// lobbed bombs, each flying from the fighter who threw it to the one it
    /// was aimed at.
    private(set) var shots: [ProjectileShot] = []
    /// Marks burning on the bodies that were just struck: gashes, punctures,
    /// impact stars, scorches, ice crusts, lattices and healing blooms.
    private(set) var impacts: [ImpactMark] = []
    private(set) var comboFlash: ComboFlash?
    /// The scales tipping on a creature right now, if a verdict just fell.
    private(set) var verdictBurst: VerdictBurst?
    /// The action about to land, named and totalled mid-deck.
    private(set) var spotlight: ActionSpotlight?
    /// Collected while a step's powers resolve, then raised as one card.
    private var pendingDivineEntries: [DivineFlashEntry] = []
    private(set) var floaters: [FloatText] = []
    private(set) var shakeTrigger: CGFloat = 0
    private(set) var slamPulse: Int = 0
    private(set) var lastReelLocked = false
    private(set) var damageDealt = 0
    private(set) var combosLanded = 0
    private(set) var critsLanded = 0

    // MARK: Scoring attribution
    /// Where the round's output actually came from. The guide is explicit that
    /// an echo, an animation hit or a status tick is not a new combo, and that
    /// holding the same die again is not new preparation — so each source is
    /// tallied separately rather than lumped into one number.
    private(set) var nativeDamage = 0
    private(set) var divineDamage = 0
    /// Ticks, verdicts, retaliation and echoes. Counted for honesty, never
    /// credited as a combo.
    private(set) var indirectDamage = 0
    /// Output from actions that spent a face held from an earlier round.
    private(set) var preparedDamage = 0

    /// What the damage currently being dealt should be credited to.
    private enum DamageSource {
        case native
        case divine
        case indirect
    }

    private var attributing: DamageSource = .native
    /// Set while an action using a held face resolves.
    private var attributingPrepared = false

    /// Books a damaging hit against whatever is resolving right now. Preparation
    /// is credited alongside its source rather than instead of it, so a held
    /// combo reads as both native output and preparation paying off.
    private func credit(_ amount: Int) {
        guard amount > 0 else { return }
        switch attributing {
        case .native: nativeDamage += amount
        case .divine: divineDamage += amount
        case .indirect: indirectDamage += amount
        }
        if attributingPrepared { preparedDamage += amount }
    }

    init(
        enemies: [EnemyDef],
        dice: [Die],
        classID: String,
        maxHP: Int,
        startHP: Int,


        hour: Int = 1,
        critBonus: Double,
        boons: [EquippedBoon] = [],
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


        self.boons = boons
        self.hour = hour
        self.playerMaxHP = maxHP
        self.playerHP = startHP
        // The round's allowance, not a carried bar: every encounter opens on 3.


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

        // Opening shield and opening stamina land before the first timeline
        // begins, so Rebuild the Wall and Unscathed are already standing when
        // the first blow is scheduled.
        for boon in boons {
            guard let def = boon.def, def.trigger == .encounterStart else { continue }
            let payload = boon.payload
            if payload.shield > 0 { self.playerShield += payload.shield }
            if payload.rerollsNext > 0 {
                self.rerollBonus = min(1, self.rerollBonus + payload.rerollsNext)

            }
        }

        applyRoundStartBoons()
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

    /// What one of this foe's telegraphed moves will actually do if it
    /// resolves right now — hour depth, heat, a held wind-up and any pending
    /// Weaken already applied.
    func projectedStrike(
        for foe: EnemyState,
        move: EnemyMove,
        spendingCharge: Bool = false
    ) -> (damage: Int, heal: Int, block: Int) {
        var damage = 0
        if move.damage > 0 {
            damage = scaledDamage(move.damage, heat: heatDamage(for: foe))
            if spendingCharge, foe.chargeBonus > 0 {
                damage = Int(Double(damage) * foe.chargeBonus)
            }
            if foe.weaken > 0 {
                damage = Int(Double(damage) * (1 - foe.weaken))
            }
            damage = max(0, damage)
        }
        return (damage, move.heal, move.block)
    }

    /// The opening blow of this foe's round, which is what the slim reads use.
    func projectedStrike(for foe: EnemyState) -> (damage: Int, heal: Int, block: Int) {
        projectedStrike(for: foe, move: foe.intent, spendingCharge: foe.intent.damage > 0)
    }

    /// Every telegraphed move of this foe's round, each with the beat it lands
    /// on and what it will do — the whole read, in order.
    private func projectedMoves(for foe: EnemyState) -> [(move: EnemyMove, strike: (damage: Int, heal: Int, block: Int))] {
        var projectedFoe = foe
        return foe.intents.map { move in
            let strike = projectedStrike(for: projectedFoe, move: move, spendingCharge: move.damage > 0)
            if move.charge > 0 { projectedFoe.chargeBonus = move.charge }
            if move.damage > 0 { projectedFoe.chargeBonus = 0; projectedFoe.weaken = 0 }
            return (move, strike)
        }
    }

    func projectedRound(for foe: EnemyState) -> [(move: EnemyMove, beat: Int, strike: (damage: Int, heal: Int, block: Int))] {
        projectedMoves(for: foe).enumerated().map { index, entry in
            (entry.move, beat(for: foe, moveIndex: index), entry.strike)
        }
    }

    /// Everything this foe's round adds up to, for the one-glance read on a
    /// crowded deck: total damage coming, total guard going up, total mending.
    func projectedRoundTotals(for foe: EnemyState) -> (damage: Int, heal: Int, block: Int) {
        projectedRound(for: foe).reduce(into: (damage: 0, heal: 0, block: 0)) { total, entry in
            total.damage += entry.strike.damage
            total.heal += entry.strike.heal
            total.block += entry.strike.block
        }
    }

    var enemyDisplayName: String {
        livingFoes.first?.displayName ?? enemies.last?.displayName ?? ""
    }

    // MARK: - The shared clock

    /// Position in the visible, alternating action order.
    func beat(for foe: EnemyState, moveIndex: Int) -> Int {
        let entries = (phase == .resolving || phase == .enemyActing) ? pendingEntries : timeline
        return entries.first { $0.sourceID == foe.id && $0.chainIndex == moveIndex }?.beat ?? 0
    }

    /// What a step *is*, which decides which powers answer it.
    func roles(for step: PlanStep) -> ActionRole {
        if let combo = step.combo { return combo.roles }
        guard let face = step.faces.first else { return .none }
        var roles: ActionRole = .none
        switch face.matchFace.soloKind {
        case .damage: roles.insert(.attack)
        case .block: roles.insert(.guardian)
        case .evade: roles.insert(.evade)
        case .heal, .focus: roles.insert(.support)
        case .poison: roles.insert(.attack)
        }
        return roles
    }

    /// The round's shared clock: your plan and every living foe's telegraphed
    /// intent on one line. Your actions run in sequence — the second starts
    /// when the first finishes — while each foe's move lands on its own beat.
    /// At equal beats you resolve first; enemy ties keep the order they rose.
    var timeline: [TimelineEntry] {
        let player = displayedPlan.filter { !$0.isPreparedSupport }.map { step in
            TimelineEntry(side: .player, beat: 0, duration: 1, title: planTitle(for: step),
                detail: step.valueLine, targetID: allocations[step.id], roles: roles(for: step), sourceID: step.id)
        }
        var enemy: [TimelineEntry] = []
        let foes = livingFoes
        for moveIndex in 0..<(foes.map { $0.intents.count }.max() ?? 0) {
            for foe in foes where foe.intents.indices.contains(moveIndex) {
                let projected = projectedMoves(for: foe)[moveIndex]
                enemy.append(TimelineEntry(side: .foe(foe.id), beat: 0, duration: 1,
                    title: projected.move.name, detail: intentDetail(strike: projected.strike, move: projected.move),
                    targetID: foe.id, roles: projected.strike.damage > 0 ? .attack : .guardian,
                    sourceID: foe.id, chainIndex: moveIndex))
            }
        }
        return BattleRules.alternating(player: player, enemy: enemy).enumerated().map { index, entry in
            TimelineEntry(side: entry.side, beat: index + 1, duration: 1, title: entry.title,
                detail: entry.detail, targetID: entry.targetID, roles: entry.roles,
                sourceID: entry.sourceID, chainIndex: entry.chainIndex)
        }
    }

    func planDetail(for step: PlanStep) -> String {
        if step.isFocus {
            if let attack = displayedPlan.first(where: { $0.focusFaceID == step.id }) {
                return "\(attack.title) +\(attack.focusBonus) damage"
            }
            return "Move before an attack to use Focus"
        }
        if step.isPreparedSupport, step.faces.first?.matchFace == .evade {
            return "1 Dodge · " + evadeTargetLabel(faceID: step.id)
        }
        return step.valueLine
    }

    /// What a foe's telegraphed move will do when it comes round.
    private func intentDetail(strike: (damage: Int, heal: Int, block: Int), move: EnemyMove) -> String {
        var parts: [String] = []
        if strike.damage > 0 { parts.append("\(strike.damage) dmg") }
        if strike.block > 0 { parts.append("+\(strike.block) guard") }
        if strike.heal > 0 { parts.append("+\(strike.heal) hp") }
        if move.charge > 0 { parts.append("winding up ×\(String(format: "%.1f", move.charge))") }
        if move.bleedAmount > 0 {
            parts.append("bleed \(move.bleedAmount)×\(move.bleedTurns)")
        }
        return parts.isEmpty ? "no harm" : parts.joined(separator: " · ")
    }

    /// The beat a step is scheduled to land on, for its plan card's chip.
    func beat(for step: PlanStep) -> Int? {
        timeline.first { $0.isPlayer && $0.sourceID == step.id }?.beat
    }

    /// the per-round counters are applied when the plan actually resolves.
    private func qualifies(step: PlanStep, for def: GodBoonDef) -> Bool {
        let roles = roles(for: step)
        let frozen = step.faces.contains { $0.wasKept }
        switch def.trigger {
        case .firstFocusedAttack: return roles.contains(.attack) && step.focusFaceID != nil
        case .firstAttackAfterGuard, .firstAttackAfterSupport, .firstAttackAfterEvade:
            return roles.contains(.attack)
        case .firstTwoSoloAttacks, .firstSoloAttack: return roles.contains(.attack) && !step.isCombo
        case .everyAttack, .firstAttack, .secondAttack, .thirdAttack:
            return roles.contains(.attack)
        case .firstLargeCombo:
            return step.isCombo && step.faces.count >= 3 && roles.contains(.attack)
        case .firstTwoFaceCombo:
            return step.isCombo && step.faces.count == 2 && roles.contains(.attack)
        case .firstKeptAttack:
            return frozen && roles.contains(.attack)
        case .firstComboWithBlock:
            return step.isCombo && roles.contains(.attack)
                && step.faces.contains { $0.matchFace == .block }
        case .firstAttackOnWounded:
            return roles.contains(.attack)
        case .everyGuard, .firstGuard:
            return roles.contains(.guardian)
        case .firstKeptGuard:
            return frozen && roles.contains(.guardian)
        case .firstEvade:
            return roles.contains(.evade)
        case .firstKeptAction:
            return frozen
        default:
            return false
        }
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

    /// True when a Siege Draw armed onto one of this step's dice rides it. A
    /// lone overdrawn arrow keeps the bonus; an overdrawn arrow that fused into
    /// a chain hands the bonus to the whole chain.
    func siegeApplies(_ step: PlanStep) -> Bool {
        step.faces.contains { siegeArmedFaceIDs.contains($0.id) }
    }

    /// Multiplier on a step's raw damage from its armed optional Chisels.
    private func armedDamageMultiplier(for step: PlanStep) -> Double {
        var multiplier = 1.0
        if siegeApplies(step) { multiplier += GameData.siegeDamageBonus }
        if let combo = step.combo, assassinArmed.contains(combo.id) {
            multiplier += GameData.assassinDamageBonus
        }
        return multiplier
    }

    /// Extra pierce this step's armed Chisels grant.
    private func armedPierce(for step: PlanStep) -> Double {
        var pierce = 0.0
        if siegeApplies(step) { pierce += GameData.siegePierce }
        if let combo = step.combo, assassinArmed.contains(combo.id) {
            pierce += GameData.assassinPierce
        }
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
        // Siege Draw rides a die, so it can light up a lone arrow that never
        // became a chain — this line has to survive a step with no recipe.
        guard step.combo != nil || siegeApplies(step) else { return nil }
        var parts: [String] = []
        if siegeApplies(step) { parts.append("SIEGE +40% · PIERCE 50%") }
        guard let combo = step.combo else { return parts.isEmpty ? nil : parts.joined(separator: " · ") }
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
        if hasChisel("ch_counterweight"), combo.damage > 0, plannedGuard > 0 {
            return ChiselCatalog.def("ch_counterweight")
        }
        if hasChisel("ch_assassin"), combo.damage > 0,
           plannedDodges > 0 {
            return ChiselCatalog.def("ch_assassin")
        }
        if hasChisel("ch_echoingStaff"), combo.source == .weapon {
            return ChiselCatalog.def("ch_echoingStaff")
        }
        return nil
    }

    func isArmed(_ chisel: ChiselDef, comboID: String) -> Bool {
        switch chisel.id {
        case "ch_counterweight": counterweightArmed.contains(comboID)
        case "ch_assassin": assassinArmed.contains(comboID)
        case "ch_echoingStaff": echoArmedComboID == comboID
        default: false
        }
    }

    // MARK: Arming a Chisel from the copper mark

    /// The Chisel currently held up waiting for a chain to ride.
    var armingChisel: ChiselDef? {
        armingChiselID.flatMap { ChiselCatalog.def($0) }
    }

    /// True when this run carries the Chisel and it is the sort you choose to
    /// spend rather than one that reshapes the weapon on its own.
    func isOptionalChiselCarried(_ id: String) -> Bool {
        chisels.contains(id) && ChiselCatalog.def(id)?.isOptional == true
    }

    /// Picks the copper mark up, or puts it back down. While one is held every
    /// chain in the plan it could ride lights up, and tapping one arms it.
    func beginArming(_ id: String) {
        guard phase == .player, isOptionalChiselCarried(id) else {
            // A passive Chisel has nothing to arm — say what it does instead.
            if let def = ChiselCatalog.def(id), chisels.contains(id) {
                lastAction = "\(def.name): \(def.detail)"
            }
            return
        }
        armingChiselID = armingChiselID == id ? nil : id
        Haptics.light()
    }

    func cancelArming() {
        guard armingChiselID != nil else { return }
        armingChiselID = nil
    }

    /// The Chisel being held, if it can ride this step's recipe. Siege Draw is
    /// not offered here — it rides a die, not a recipe.
    func armableChisel(for step: PlanStep) -> ChiselDef? {
        guard let armingChiselID, let combo = step.combo,
              let chisel = badgeChisel(for: combo.id),
              chisel.id == armingChiselID else { return nil }
        return chisel
    }

    /// True when Siege Draw could be overdrawn onto this particular die: it has
    /// to be an arrow, and it has to be in the plan so there is an action for
    /// the overdraw to ride.
    func siegeArmable(faceID: UUID) -> Bool {
        guard hasChisel("ch_siegeDraw"), phase == .player,
              let face = playedFaces.first(where: { $0.id == faceID }) else { return false }
        return face.matchFace.isArrow
    }

    /// The hidden step a die in the plan belongs to. The plan only shows an
    /// order now, so anything that used to act on a chain card acts through
    /// one of its dice instead.
    func step(containing faceID: UUID) -> PlanStep? {
        turnPlan.first { $0.faces.contains { $0.id == faceID } }
    }

    /// The held Chisel, if this die can carry it. Siege Draw answers for the
    /// die itself; everything else answers for the hidden chain the die is part
    /// of, so the die glows copper without ever naming that chain.
    func armableChisel(forFace faceID: UUID) -> ChiselDef? {
        if armingChiselID == "ch_siegeDraw" {
            return siegeArmable(faceID: faceID) ? ChiselCatalog.def("ch_siegeDraw") : nil
        }
        guard let step = step(containing: faceID) else { return nil }
        return armableChisel(for: step)
    }

    /// True when this die itself is overdrawn, or the chain it belongs to
    /// already carries an armed Chisel.
    func isChiselArmed(onFace faceID: UUID) -> Bool {
        if siegeArmedFaceIDs.contains(faceID) { return true }
        guard let step = step(containing: faceID) else { return false }
        return isComboArmed(step)
    }

    /// Arms the held Chisel onto this die — or, for the recipe-keyed Chisels,
    /// onto whatever chain the die is part of. Returns true when the tap was
    /// spent arming rather than taking the die back out of the plan.
    @discardableResult
    func armHeldChisel(ontoFace faceID: UUID) -> Bool {
        if armingChiselID == "ch_siegeDraw" {
            guard siegeArmable(faceID: faceID) else { return false }
            if siegeArmedFaceIDs.contains(faceID) {
                siegeArmedFaceIDs.remove(faceID)
            } else {
                guard rerollsRemaining > 0 || !siegeArmedFaceIDs.isEmpty else {
                    lastAction = "Siege Draw needs one unused reroll."
                    return false
                }
                siegeArmedFaceIDs = [faceID]
            }
            armingChiselID = nil
            Haptics.light()
            return true
        }
        guard let step = step(containing: faceID) else { return false }
        return armHeldChisel(onto: step)
    }

    /// Arms the held Chisel onto this step, then puts the mark down. Tapping
    /// an already-armed chain takes the Chisel back off it.
    /// Returns true when the tap was spent on arming rather than on the
    /// step's ordinary "return these faces to the tray" job.
    @discardableResult
    func armHeldChisel(onto step: PlanStep) -> Bool {
        guard let chisel = armableChisel(for: step), let combo = step.combo else { return false }
        toggleArmed(chisel, comboID: combo.id)
        armingChiselID = nil
        return true
    }

    func toggleArmed(_ chisel: ChiselDef, comboID: String) {
        guard phase == .player else { return }
        switch chisel.id {
        case "ch_counterweight":
            guard plannedGuard > 0 || counterweightArmed.contains(comboID) else { return }
            if counterweightArmed.contains(comboID) { counterweightArmed.remove(comboID) } else { counterweightArmed.insert(comboID) }
        case "ch_assassin":
            guard plannedDodges > 0 || assassinArmed.contains(comboID) else { return }
            if assassinArmed.contains(comboID) { assassinArmed.remove(comboID) } else { assassinArmed.insert(comboID) }
        case "ch_echoingStaff":
            guard echoArmedComboID != nil || rerollsRemaining > 0 else {
                lastAction = "Echoing Staff needs one unused reroll."
                return
            }
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
        return face.wasKept && face.matchFace.isArrow
            && (nockShiftedFaceID == nil || nockShiftedFaceID == faceID)
    }

    func nockShift(faceID: UUID, up: Bool) {
        guard nockAvailable(for: faceID),
              let index = rolled.firstIndex(where: { $0.id == faceID }) else { return }
        if nockShiftedFaceID == faceID, rolled[index].effectiveFace != nil {
            rolled[index].effectiveFace = nil
            nockShiftedFaceID = nil
            Haptics.light()
            return
        }
        let tiers: [FaceKind] = [.arrow1, .arrow2, .arrow3]
        guard let tier = tiers.firstIndex(of: rolled[index].matchFace) else { return }
        let shifted = tier + (up ? 1 : -1)
        guard tiers.indices.contains(shifted) else { return }
        rolled[index].effectiveFace = tiers[shifted]
        nockShiftedFaceID = faceID
        Haptics.light()
    }

    // MARK: - What a held die is worth

    /// The god power waiting on this held face, if one is. A held die is only
    /// worth holding because some blessing answers it, so the die itself says
    /// which god is watching and what they will add — no more holding a Guard
    /// and hoping the extra shield actually arrives.
    ///
    /// Read in planning, so it tests role and shape only; the per-round
    /// counters are applied when the plan resolves.
    func heldBoon(forFace faceID: UUID) -> (god: Deity, name: String, effect: String)? {
        guard phase == .player,
              let face = rolled.first(where: { $0.id == faceID }), face.wasKept else { return nil }

        // Judge the die as the action it would be on its own, which is what a
        // held-face blessing keys off.
        let step = PlanStep(faces: [face], combo: nil)
        let roles = roles(for: step)
        guard !roles.isEmpty else { return nil }

        for boon in boons {
            guard let def = boon.def else { continue }
            let answers: Bool
            switch def.trigger {
            case .firstKeptAttack: answers = roles.contains(.attack)
            case .firstKeptGuard: answers = roles.contains(.guardian)
            case .firstKeptAction: answers = true
            default: answers = false
            }
            guard answers, def.kind != .duo || duoActive(def) else { continue }
            return (def.god, def.name, summary(of: boon.payload))
        }
        return nil
    }

    /// True when any equipped blessing answers held faces at all — used to

    var hasHeldFaceBoon: Bool {
        boons.contains { boon in
            switch boon.def?.trigger {
            case .firstKeptAttack, .firstKeptGuard, .firstKeptAction: true
            default: false
            }
        }
    }

    var hasEchoPending: Bool { pendingEcho != nil }

    /// True when this Chisel is armed onto any chain in the plan right now —
    /// read by the copper mark beside the tray title.
    func isChiselArmed(_ id: String) -> Bool {
        switch id {
        case "ch_siegeDraw": !siegeArmedFaceIDs.isEmpty
        case "ch_counterweight": !counterweightArmed.isEmpty
        case "ch_assassin": !assassinArmed.isEmpty
        case "ch_echoingStaff": echoArmedComboID != nil
        default: false
        }
    }

    /// True when any optional Chisel is armed onto this step's recipe — the
    /// copper hammer worn by the plan card.
    func isComboArmed(_ step: PlanStep) -> Bool {
        if siegeApplies(step) { return true }
        guard let combo = step.combo else { return false }
        return counterweightArmed.contains(combo.id)
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

    // MARK: - Aiming

    /// True when the fight has enough foes standing for aiming to mean
    /// anything — with one foe every blow has only one place to go.
    var canTarget: Bool {
        livingFoes.count > 1 && turnPlan.contains(where: \.targetsEnemy)
    }

    /// The steps that need a target, in play order.
    var allocatableSteps: [PlanStep] {
        turnPlan.filter(\.targetsEnemy)
    }

    /// The attack waiting to be pointed right now, during the aiming phase.
    var activeAim: AimRequest? { aimQueue.first }

    /// True while the stage is uncovered and waiting for you to send blows.
    var isAiming: Bool { phase == .aiming }

    /// The foe a step is currently pointed at, falling back to the first
    /// living foe whenever the assignment is missing or has fallen.
    func allocatedFoeID(for step: PlanStep) -> UUID? {
        if let id = allocations[step.id],
           enemies.contains(where: { $0.id == id && $0.isAlive }) {
            return id
        }
        return livingFoes.first?.id
    }

    /// Damage already sent at one foe, built up as blows are pointed during
    /// the aiming phase.
    func allocatedDamage(for foeID: UUID) -> Int {
        committedPlan.reduce(0) { total, step in
            guard step.targetsEnemy, step.damage > 0 else { return total }
            var sum = total
            // Only blows actually pointed count — the queue is what is left.
            if allocations[step.id] == foeID { sum += mainDamage(for: step) }
            if secondaryAllocations[step.id] == foeID { sum += secondaryDamage(for: step) }
            return sum
        }
    }

    /// Who wears the gold ring: while aiming, nobody until you choose;
    /// during resolution, the foe the blow in flight was actually sent at.
    func isTargeted(foeID: UUID) -> Bool {
        phase == .aiming ? false : activeTargetID == foeID
    }

    /// Commit entry point. If the plan has attacks and more than one foe is
    /// standing, the deck drops and the stage takes over for aiming: each
    /// attack is sent by tapping the creature it should strike. Otherwise the
    /// turn fires straight away.
    func beginCommit() {
        guard canCommit else { return }
        let queue = buildAimQueue()
        guard !queue.isEmpty else {
            commitTurn()
            return
        }
        committedPlan = buildPlan(from: playedFaces)
        aimQueue = queue
        allocations = [:]
        secondaryAllocations = [:]
        phase = .aiming
        lastAction = "Tap the creature this blow should strike."
        Haptics.medium()
    }

    /// Every hit in the committed plan that needs pointing, in play order —
    /// each attack, plus any chisel-granted second hit it carries.
    private func buildAimQueue() -> [AimRequest] {
        guard livingFoes.count > 1 else { return [] }
        var queue: [AimRequest] = []
        for step in buildPlan(from: playedFaces) where step.targetsEnemy {
            queue.append(
                AimRequest(stepID: step.id, isSecondary: false, title: step.title,
                           detail: step.valueLine, damage: mainDamage(for: step),
                           faces: step.faces.map(\.matchFace), tint: step.tint)
            )
            if hasSecondaryHit(step) {
                queue.append(
                    AimRequest(stepID: step.id, isSecondary: true,
                               title: "\(step.title) — second hit",
                               detail: "\(secondaryDamage(for: step)) DMG",
                               damage: secondaryDamage(for: step),
                               faces: step.faces.map(\.matchFace), tint: Theme.ptahCopper)
                )
            }
        }
        return queue
    }

    /// Tap a creature to send the blow currently being aimed at it. When the
    /// last one has been pointed, the turn fires on its own.
    func aim(at foeID: UUID) {
        guard phase == .aiming, let request = aimQueue.first,
              enemies.contains(where: { $0.id == foeID && $0.isAlive }) else { return }
        if request.isSecondary {
            secondaryAllocations[request.stepID] = foeID
        } else {
            allocations[request.stepID] = foeID
        }
        aimQueue.removeFirst()
        Haptics.light()
        if let next = aimQueue.first {
            lastAction = "Now aim \(next.title)."
        } else {
            lastAction = "Every blow is aimed."
            commitTurn()
        }
    }

    /// Abandon aiming and go back to the plan — nothing has resolved yet.
    func cancelAiming() {
        guard phase == .aiming else { return }
        aimQueue = []
        allocations = [:]
        secondaryAllocations = [:]
        committedPlan = []
        phase = .player
        lastAction = "Back to the plan."
        Haptics.light()
    }

    /// Clears the aiming queue when the plan is torn down or the turn fires.
    func resetTargetingSelection() {
        aimQueue = []
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

    var hasCombo: Bool { turnPlan.contains { $0.isCombo } }

    /// True when the player has already landed this step's chain at some point
    /// and so is allowed to see its name while planning. An undiscovered chain
    /// stays anonymous until it fires.
    func isChainKnown(_ step: PlanStep) -> Bool {
        guard let combo = step.combo else { return true }
        return knownChainIDs.contains(combo.id)
    }

    /// True when this recipe has been landed before and may be named openly.
    func knowsCombo(_ combo: ComboDef) -> Bool {
        knownChainIDs.contains(combo.id)
    }

    /// What a step calls itself in the plan. A chain you know is named; one you
    /// have never landed reads as a sealed thing you built but cannot yet
    /// identify — it will name itself when it lands.
    func planTitle(for step: PlanStep) -> String {
        guard step.isCombo else { return step.title }
        return isChainKnown(step) ? step.title : "Unknown Chain"
    }

    // MARK: - Chains in hand

    /// Faces a chain could still be built out of *right now*.
    var availableFaces: [RolledFace] {
        rolled.filter { !playOrder.contains($0.id) }
    }

    var isRolling: Bool { slots.contains { $0.state == .rolling } }

    var lockedReelCount: Int {
        slots.filter { if case .rolled = $0.state { return true } else { return false } }.count
    }

    func lockTime(slotID: UUID) -> Double {
        let order = rollableDice
        return DiceRollTiming.stopTime(index: order.firstIndex(of: slotID) ?? 0,
                                       count: order.count, reduceMotion: rollUsesReducedMotion)
    }

    func landingFace(slotID: UUID) -> FaceKind? { pendingRolls[slotID]?.face }

    var canRoll: Bool { phase == .player && !hasRolled && !slots.isEmpty }
    var reservedRerolls: Int {
        let plan = displayedPlan
        let siege = plan.contains { siegeApplies($0) } ? 1 : 0
        let echo = plan.contains { $0.combo?.id == echoArmedComboID && echoArmedComboID != nil } ? 1 : 0
        return siege + echo
    }
    var rerollsRemaining: Int {
        max(0, min(BattleRules.maximumRerolls, BattleRules.baseRerolls + rerollBonus) - rerollsUsed - reservedRerolls)
    }
    private var plannedDodges: Int {
        dodgeCharges + displayedPlan.filter { $0.isPreparedSupport && $0.faces.first?.matchFace == .evade }.count
    }
    private var plannedGuard: Int {
        playerShield + displayedPlan.filter { $0.isPreparedSupport && $0.faces.first?.matchFace == .block }
            .reduce(0) { $0 + ($1.faces.first?.face.soloValue ?? 0) }
    }
    var canReroll: Bool { phase == .player && hasRolled && !isRolling && rerollsRemaining > 0 && !rerollSelection.isEmpty }
    private var rollingSlotIDs: [UUID] = []
    private var rollableDice: [UUID] { rollingSlotIDs.isEmpty ? slots.map(\.id) : rollingSlotIDs }

    func toggleReroll(slotID: UUID) {
        guard phase == .player, hasRolled, !isRolling, rerollsRemaining > 0,
              let slot = slots.first(where: { $0.id == slotID }),
              case .rolled(let face) = slot.state, !playOrder.contains(face.id) else { return }
        if !rerollSelection.insert(slotID).inserted { rerollSelection.remove(slotID) }
        Haptics.light()
    }

    func rerollSelected(reduceMotion: Bool = false) {
        guard canReroll else { return }
        let selected = rerollSelection
        rerollsUsed += 1
        // Only results retained through a real reroll qualify as kept dice.
        for index in slots.indices where !selected.contains(slots[index].id) {
            if case .rolled(var face) = slots[index].state {
                face.wasKept = true
                slots[index].state = .rolled(face)
                if let resultIndex = rolled.firstIndex(where: { $0.id == face.id }) { rolled[resultIndex] = face }
            }
        }
        rerollSelection = []
        selectingReroll = false
        startRoll(slotIDs: selected, reduceMotion: reduceMotion)
    }

    var incomingStrikes: [EnemyStrike] {
        livingFoes.flatMap { foe in
            projectedRound(for: foe).enumerated().flatMap { moveIndex, entry -> [EnemyStrike] in
                guard entry.strike.damage > 0 else { return [] }
                let hits = max(1, entry.move.faces.filter(\.isAttack).count)
                return (0..<hits).map { hitIndex in
                    EnemyStrike(foeID: foe.id, moveIndex: moveIndex, hitIndex: hitIndex,
                        title: "\(foe.displayName) · \(entry.move.name) \(hitIndex + 1)/\(hits)",
                        damage: entry.strike.damage / hits + (hitIndex == 0 ? entry.strike.damage % hits : 0))
                }
            }
        }
    }

    func assignEvade(faceID: UUID, strikeID: String?) {
        guard phase == .player, !isRolling, turnPlan.contains(where: {
            $0.id == faceID && !$0.isCombo && $0.faces.first?.matchFace == .evade
        }) else { return }
        if let strikeID {
            for (otherID, assigned) in evadeAssignments where otherID != faceID && assigned == strikeID {
                evadeAssignments.removeValue(forKey: otherID)
            }
        }
        evadeAssignments[faceID] = strikeID
    }

    func evadeTargetLabel(faceID: UUID) -> String {
        guard let id = evadeAssignments[faceID], let strike = incomingStrikes.first(where: { $0.id == id }) else { return "Next strike" }
        return strike.title
    }

    private func slotID(showing faceID: UUID) -> UUID? {
        slots.first { slot in
            if case .rolled(let face) = slot.state { return face.id == faceID }
            return false
        }?.id
    }

    var undrawnCount: Int { max(0, loadoutDice.count - drawnDieIDs.count) }

    /// The dice left in the bag this round — shown so the randomness is
    /// understandable rather than hidden.
    var undrawnDice: [Die] {
        let onTable = Set(slots.map { $0.die.id })
        return loadoutDice.filter { !onTable.contains($0.id) }
    }

    /// Draws without replacement to fill the round's six slots. Held dice take
    /// slots of their own, so holding two means drawing four from the other
    /// six — a hold spends a slot rather than adding one.
    static func draw(count: Int, from dice: [Die], excluding heldIDs: Set<UUID>) -> [Die] {
        guard count > 0 else { return [] }
        let bag = dice.filter { !heldIDs.contains($0.id) }
        guard bag.count > count else { return bag }
        return Array(bag.shuffled().prefix(count))
    }

    var canCommit: Bool { phase == .player && hasRolled && !isRolling }

    /// True when the turn may actually fire: from the plan, or from the aiming
    /// phase once the last blow has been pointed. The FIGHT slab tests
    /// `canCommit`; resolution tests this, so aiming can hand off to it.
    private var canResolve: Bool {
        (phase == .player || phase == .aiming) && hasRolled && !isRolling
    }

    // MARK: - Player actions

    func rollAll(reduceMotion: Bool = false) {
        guard canRoll else { return }
        hasRolled = true
        shuffleRow()
        startRoll(slotIDs: Set(slots.map(\.id)), reduceMotion: reduceMotion)
    }

    private func startRoll(slotIDs: Set<UUID>, reduceMotion: Bool) {
        Audio.shared.prepareDiceRoll()
        rollTask?.cancel()
        rollingSlotIDs = slots.filter { slotIDs.contains($0.id) }.map(\.id)
        let tumbling = rollingSlotIDs
        let oldFaces = Set(slots.compactMap { slot -> UUID? in
            guard slotIDs.contains(slot.id), case .rolled(let face) = slot.state else { return nil }
            return face.id
        })
        rolled.removeAll { oldFaces.contains($0.id) }
        oldFaces.forEach { evadeAssignments.removeValue(forKey: $0) }
        pendingRolls = Dictionary(uniqueKeysWithValues: slots.filter { slotIDs.contains($0.id) }.map {
            ($0.id, rollResult(for: $0.die))
        })
        rollID = UUID()
        rollUsesReducedMotion = reduceMotion
        rollStartedAt = ProcessInfo.processInfo.systemUptime
        let currentRoll = rollID
        let clock = ContinuousClock()
        let start = clock.now
        for index in slots.indices where slotIDs.contains(slots[index].id) { slots[index].state = .rolling }
        lastAction = "The drums spin..."
        lastReelLocked = false
        Haptics.medium()
        Audio.shared.play(.diceRoll)
        rollTask = Task { [weak self] in
            for (offset, slotID) in tumbling.enumerated() {
                let deadline = DiceRollTiming.stopTime(index: offset, count: tumbling.count, reduceMotion: reduceMotion)
                do { try await clock.sleep(until: start.advanced(by: .seconds(deadline))) } catch { return }
                guard let self, self.rollID == currentRoll, self.phase == .player else { return }
                self.settle(slotID: slotID, isLast: offset == tumbling.count - 1)
            }
            guard let self, self.rollID == currentRoll, self.phase == .player else { return }
            self.lastAction = "Build attacks, prepare reactions, or reroll selected dice."
        }
    }

    private func shuffleRow() {
        slots.shuffle()
    }

    private func rollResult(for die: Die) -> RolledFace {
        var extra = 0.0
        if die.patron == .horus, hasUpgrade("ho_windRead") { extra += 0.08 }
        let outcome = die.roll(critBonus: critBonus + extra)
        return RolledFace(
            id: UUID(),
            dieID: die.id,
            dieName: die.name,
            face: outcome.face.kind,
            patron: die.patron,
            isCrit: outcome.isCrit,
            critChance: outcome.chance,
            imbueTiers: outcome.face.imbueTiers
        )
    }

    private func settle(slotID: UUID, isLast: Bool = false) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }),
              slots[index].state == .rolling,
              let result = pendingRolls.removeValue(forKey: slotID) else { return }
        slots[index].state = .rolled(result)
        rolled.append(result)
        slamPulse += 1
        lastReelLocked = isLast
        if isLast { Audio.shared.stopDiceRoll() }

        // A die landing should be felt. The last reel and any critical hit
        // the tray noticeably harder than the ones in between.
        // The reel supplies its own impact. Reserve camera shake for combat;
        // six overlapping whole-screen shakes make the roll read as dropped frames.
        if result.isCrit {
            critsLanded += 1
            Haptics.heavy()
            Audio.shared.play(.diceLock)
            Audio.shared.play(.crit, after: 0.06, volumeScale: 0.7)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(55))
                Haptics.heavy()
            }
        } else if isLast {
            Haptics.heavy()
            Audio.shared.play(.diceLock)
        } else {
            Haptics.medium()
            Audio.shared.play(.diceLock, volumeScale: 0.8)
        }
    }

    /// Place a rolled face into the play bar. Where it lands is the whole
    /// decision now: a die only chains with the dice standing next to it, so
    /// dropping one between two others can weld a chain — or break one.
    func placeInPlayBar(faceID: UUID, before targetID: UUID? = nil) {
        guard phase == .player, !isRolling, let face = rolled.first(where: { $0.id == faceID }) else { return }
        guard faceID != targetID else { return }

        var prospective = playOrder
        prospective.removeAll { $0 == faceID }
        if let targetID, let targetIndex = prospective.firstIndex(of: targetID) {
            prospective.insert(faceID, at: targetIndex)
        } else {
            prospective.append(faceID)
        }


        if let slotID = slotID(showing: face.id) { rerollSelection.remove(slotID) }
        playOrder = prospective
        Haptics.light()
        // The knock climbs a step for each die already in the plan, so a long
        // turn builds audibly as you lay it out.
        Audio.shared.planKnock(position: playOrder.count - 1)
    }

    /// Send a chip from the play bar back to the tray. The bar reprices the

    func returnToTray(faceID: UUID) {
        guard phase == .player, playOrder.contains(faceID) else { return }
        playOrder.removeAll { $0 == faceID }
        // A die leaving the plan takes its weld with it: the rest of that
        // combined action goes back to being separate dice rather than
        // silently re-forming into something smaller.
        weldedGroups.removeAll { $0.contains(faceID) }
        pruneWelds()
        Haptics.light()
        Audio.shared.play(.diceTake)
    }

    // MARK: - Combining, by choice

    /// A run of adjacent dice in the plan that would make a real recipe, and
    /// what it would make. Offered as a seam you may tap — never applied for
    /// you, and never ranked or auto-highlighted as "the best" one.
    struct WeldCandidate: Identifiable {
        let faceIDs: [UUID]
        let combo: ComboDef
        /// Where the run starts in the plan, for drawing the seam.
        let position: Int

        var id: String { combo.id + "@" + faceIDs.map(\.uuidString).joined() }
    }

    /// Every seam currently on offer: maximal adjacent runs of un-welded dice
    /// that complete a recipe. Longer runs are listed first so a five-die
    /// working is visible, but nothing is chosen for you.
    var weldCandidates: [WeldCandidate] {
        guard phase == .player else { return [] }
        let faces = playedFaces
        let welded = Set(weldedGroups.flatMap { $0 })
        var found: [WeldCandidate] = []

        // Walk every adjacent window, largest first, and keep the ones that
        // make something. A die already welded into another action is not
        // available, so seams never overlap an existing combined card.
        var length = min(faces.count, GameData.maxComboFaces)
        while length >= 2 {
            for start in 0...(max(0, faces.count - length)) where start + length <= faces.count {
                let window = Array(faces[start..<(start + length)])
                guard !window.contains(where: { welded.contains($0.id) }) else { continue }
                guard !found.contains(where: { candidate in
                    window.contains { candidate.faceIDs.contains($0.id) }
                }) else { continue }
                guard let resolved = resolveWeld(window) else { continue }
                found.append(WeldCandidate(faceIDs: window.map(\.id),
                                           combo: resolved.combo,
                                           position: start))
            }
            length -= 1
        }
        return found
    }

    /// The seam covering this die, if one is on offer.
    func weldCandidate(forFace faceID: UUID) -> WeldCandidate? {
        weldCandidates.first { $0.faceIDs.contains(faceID) }
    }

    /// Every recipe a seam could make, smallest first. A run of four dice may
    /// hide a two-die recipe and a four-die one; both are real choices, so the
    /// seam offers them rather than silently taking the biggest.
    func weldOptions(openingAt faceID: UUID, including secondID: UUID) -> [WeldCandidate] {
        guard phase == .player else { return [] }
        let faces = playedFaces
        let welded = Set(weldedGroups.flatMap { $0 })
        guard let start = faces.firstIndex(where: { $0.id == faceID }) else { return [] }

        var options: [WeldCandidate] = []
        var length = 2
        while length <= min(GameData.maxComboFaces, faces.count - start) {
            let window = Array(faces[start..<(start + length)])
            defer { length += 1 }
            guard window.contains(where: { $0.id == secondID }) else { continue }
            guard !window.contains(where: { welded.contains($0.id) }) else { continue }
            guard let resolved = resolveWeld(window) else { continue }
            options.append(WeldCandidate(faceIDs: window.map(\.id),
                                         combo: resolved.combo,
                                         position: start))
        }
        return options
    }

    /// True when this die is part of an action you welded yourself.
    func isWelded(faceID: UUID) -> Bool {
        weldedGroups.contains { $0.contains(faceID) }
    }

    /// Weld a run together into one action. Costs nothing on its own — the

    /// right up until you commit the turn.
    @discardableResult
    func combine(_ candidate: WeldCandidate) -> Bool {
        guard phase == .player else { return false }
        let welded = Set(weldedGroups.flatMap { $0 })
        guard !candidate.faceIDs.contains(where: { welded.contains($0) }) else { return false }
        guard candidate.faceIDs.allSatisfy({ playOrder.contains($0) }) else { return false }

        weldedGroups.append(candidate.faceIDs)
        // A recipe you have never landed names itself the moment you assemble
        // it, so nobody has to commit blind to find out what they built.
        if !knownChainIDs.contains(candidate.combo.id) {
            _ = ComboLore.discover(candidate.combo.id)
            knownChainIDs.insert(candidate.combo.id)
            lastAction = "\(candidate.combo.name) — \(candidate.combo.flavor)"
        } else {
            lastAction = "\(candidate.combo.name) assembled."
        }
        Haptics.chain(length: candidate.faceIDs.count, crit: false)
        Audio.shared.play(.diceFreeze)
        return true
    }

    /// Pull a combined action back apart. The dice return to the plan in the
    /// order they went in, and nothing has been spent.
    @discardableResult
    func separate(faceID: UUID) -> Bool {
        guard phase == .player,
              let index = weldedGroups.firstIndex(where: { $0.contains(faceID) }) else { return false }
        weldedGroups.remove(at: index)
        pruneWelds()
        lastAction = "Separated — the dice are yours again."
        Haptics.light()
        Audio.shared.play(.diceTake)
        return true
    }

    /// A bigger recipe that this combined action could become by swallowing an
    /// adjacent die. Offered explicitly, never applied quietly.
    func transformOffer(faceID: UUID) -> WeldCandidate? {
        guard phase == .player,
              let group = weldedGroups.first(where: { $0.contains(faceID) }) else { return nil }
        let faces = playedFaces
        guard let start = faces.firstIndex(where: { $0.id == group.first }) else { return nil }
        let end = start + group.count
        let welded = Set(weldedGroups.flatMap { $0 }).subtracting(group)

        // Only the dice immediately either side can join, and only if they are
        // not already part of another combined action.
        var windows: [(start: Int, end: Int)] = []
        if start > 0, !welded.contains(faces[start - 1].id) {
            windows.append((start - 1, end))
        }
        if end < faces.count, !welded.contains(faces[end].id) {
            windows.append((start, end + 1))
        }
        if start > 0, end < faces.count,
           !welded.contains(faces[start - 1].id), !welded.contains(faces[end].id) {
            windows.append((start - 1, end + 1))
        }

        for window in windows.sorted(by: { ($0.end - $0.start) > ($1.end - $1.start) }) {
            let candidateFaces = Array(faces[window.start..<window.end])
            guard candidateFaces.count <= GameData.maxComboFaces,
                  let resolved = resolveWeld(candidateFaces),
                  resolved.combo.faceCount > group.count else { continue }
            return WeldCandidate(faceIDs: candidateFaces.map(\.id),
                                 combo: resolved.combo,
                                 position: window.start)
        }
        return nil
    }

    /// Swap a combined action for the bigger recipe it could become.
    @discardableResult
    func transform(into candidate: WeldCandidate) -> Bool {
        guard phase == .player else { return false }
        weldedGroups.removeAll { group in
            group.contains { candidate.faceIDs.contains($0) }
        }
        return combine(candidate)
    }

    /// Drops any weld whose dice have left the plan or no longer make a
    /// recipe, so a stale weld can never hold a combo together invisibly.
    private func pruneWelds() {
        let faces = playedFaces
        siegeArmedFaceIDs.formIntersection(Set(faces.map(\.id)))
        weldedGroups.removeAll { group in
            let members = group.compactMap { id in faces.first { $0.id == id } }
            return members.count != group.count || resolveWeld(members) == nil
        }
        let combos = Set(turnPlan.compactMap { $0.combo?.id })
        counterweightArmed.formIntersection(combos)
        assassinArmed.formIntersection(combos)
        if let echoArmedComboID, !combos.contains(echoArmedComboID) { self.echoArmedComboID = nil }
    }

    /// What a combined action would do against what the same dice would do
    /// played separately — the whole point of the preview card. Uses the real
    /// battle rules and never touches live state.
    struct WeldPreview {
        let combo: ComboDef
        let ingredients: [RolledFace]
        let diceCount: Int
        let combined: PlanStep
        /// The same dice as individual actions, for the "or leave them apart"
        /// column.
        let separateSteps: [PlanStep]
        /// God powers that would answer the combined action.
        let qualifyingGods: [Deity]

        var separateDamage: Int { separateSteps.reduce(0) { $0 + $1.damage } }
        var separateDice: Int { separateSteps.reduce(0) { $0 + $1.diceCount } }
    }

    /// Builds the preview for a seam, using the same PlanStep maths the fight
    /// itself uses so the numbers cannot drift from reality.
    func preview(for candidate: WeldCandidate) -> WeldPreview? {
        let faces = playedFaces
        let members = candidate.faceIDs.compactMap { id in faces.first { $0.id == id } }
        guard members.count == candidate.faceIDs.count,
              let resolved = resolveWeld(members) else { return nil }

        let combined = PlanStep(faces: resolved.members, combo: resolved.combo)
        let separate = members.map { PlanStep(faces: [$0], combo: nil) }
        let gods = boons.compactMap { held -> Deity? in
            guard let def = held.def else { return nil }
            return qualifies(step: combined, for: def) ? def.god : nil
        }
        var seen: [Deity] = []
        for god in gods where !seen.contains(god) { seen.append(god) }

        return WeldPreview(
            combo: resolved.combo,
            ingredients: resolved.members,
            diceCount: combined.diceCount,
            combined: combined,
            separateSteps: separate,
            qualifyingGods: seen
        )
    }

    func commitTurn() {
        guard canResolve else { return }
        resetTargetingSelection()
        phase = .resolving
        Task { await resolveTurn() }
    }

    // MARK: - Turn resolution

    private func resolveTurn() async {
        let steps = buildPlan(from: playedFaces)
        committedPlan = steps
        momentumCarry = 0
        weaponComboLandedThisTurn = false

        for index in slots.indices { slots[index].state = .spent }
        rolled = []
        playOrder = []
        weldedGroups = []
        preparedFocusUsed = []
        for step in steps where step.isPreparedSupport {
            if step.isFocus { continue }
            attributing = .divine
            resolveBoons(in: step, targetIndex: nil)
            attributing = .native
            if let face = step.faces.first {
                _ = applyFace(face, bonus: 0, targetIndex: nil)
                if face.matchFace == .evade, !dodgeReservations.isEmpty {
                    dodgeReservations[dodgeReservations.count - 1] = evadeAssignments[step.id]
                }
            }
            attributing = .divine
            resolveBlessings(in: step, targetIndex: nil)
            attributing = .native
            pendingDivineEntries = []
        }
        pendingEntries = timeline

        // One action of yours, resolved at the beat it was scheduled for.
        // Returns true when the fight ended inside it.
        func resolvePlayerStep(_ step: PlanStep, index: Int) async -> Bool {
            activeStepIndex = index
            try? await Task.sleep(for: .milliseconds(BattleBeat.stepLeadIn))
            let target = targetIndex(for: step)
            if let focusID = step.focusFaceID,
               preparedFocusUsed.insert(focusID).inserted,
               let support = steps.first(where: { $0.id == focusID }) {
                resolveBoons(in: support, targetIndex: target)
                resolveBlessings(in: support, targetIndex: target)
                addFloat("FOCUS +\(step.focusBonus)", color: Theme.gold, onEnemy: false)
            }
            activeTargetID = target.map { enemies[$0].id }

            // Assassin's Commitment: the evade charge burns before the blow
            // lands, so the combo's own evasion can never pay for it.
            if let combo = step.combo, assassinArmed.contains(combo.id), !dodgeReservations.isEmpty {
                dodgeReservations.removeFirst()
                addFloat("Commitment −1 Dodge", color: Theme.ptahCopper, onEnemy: false)
            } else if let combo = step.combo {
                assassinArmed.remove(combo.id)
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
                // Preparation is credited alongside whatever it produced: an
                // action spending a held face reads as both native output and
                // preparation paying off, never as a separate combo.
                attributingPrepared = step.faces.contains { $0.wasKept }

                // God powers answer before the native action, so "already
                // burning", "already bleeding", missing HP and shield clauses
                // are tested against the board as the action started on.
                attributing = .divine
                resolveBoons(in: step, targetIndex: target)
                attributing = .native

                // The action is named before it lands: what you are doing,
                // what it is worth, and every god power riding it, all held
                // together long enough to read.
                await raiseSpotlight(for: step, targetIndex: target)

                let healthBefore = target.map { enemies[$0].hp } ?? 0
                if let combo = step.combo {
                    let didCrit = Double.random(in: 0..<1) < step.comboCritChance
                    playerPose = combo.damage > 0 ? .attack : (combo.shield > 0 ? .block : .heal)
                    noteStrikeGods(in: step.faces)
                    if combo.damage > 0 {
                        launchShots(faces: step.faces.map(\.matchFace),
                                    fromPlayer: true, foeID: activeTargetID,
                                    magnitude: step.faces.count, isCrit: didCrit)
                    }
                    applyCombo(combo, step: step, crit: didCrit, targetIndex: target)
                    // Concealed Blade: the substituted Evade still grants its
                    // evasion, and its god still answered it as a defensive face.
                    if hasChisel("ch_concealedBlade"),
                       step.faces.contains(where: { $0.face == .evade && $0.effectiveFace == .swiftSlash }) {
                        gainDodges(1)
                        addFloat("Concealed Blade", color: Theme.ptahCopper, onEnemy: false)
                    }
                    if combo.source == .weapon, combo.damage > 0 {
                        weaponComboLandedThisTurn = true
                    }
                    attributing = .divine
                    resolveBlessings(in: step, targetIndex: target)
                    pairingAfterAction(step: step, dealtDamage: combo.damage > 0, targetIndex: target)
                    attributing = .native
                    let hang = BattleBeat.comboBase
                        + min(step.faces.count, 5) * BattleBeat.comboPerFace
                        + (didCrit ? BattleBeat.comboCrit : 0)
                    try? await Task.sleep(for: .milliseconds(hang))
                } else if let face = step.faces.first {
                    playerPose = pose(for: face.face)
                    noteStrikeGods(in: [face])
                    if face.matchFace.isAttack || face.matchFace == .poison {
                        launchShots(faces: [face.matchFace], fromPlayer: true,
                                    foeID: activeTargetID, isCrit: face.isCrit)
                    }
                    let dealt = applyFace(face, bonus: step.momentumBonus + step.focusBonus, targetIndex: target)
                    attributing = .divine
                    resolveBlessings(in: step, targetIndex: target)
                    pairingAfterAction(step: step, dealtDamage: dealt, targetIndex: target)
                    attributing = .native
                    try? await Task.sleep(for: .milliseconds(BattleBeat.soloStep))
                }
                let dealtHealthDamage = target.map { enemies[$0].hp < healthBefore } ?? false
                if dealtHealthDamage && pendingHealOnHit > 0 { healPlayer(pendingHealOnHit, label: "Feeding Frenzy") }
                pendingHealOnHit = 0
                applyPendingBoonEffects()
                if hasChisel("ch_returningKnife"), !returningKnifeUsedThisTurn,
                   step.faces.contains(where: { $0.matchFace == .daggerThrow }) {
                    returningKnifeUsedThisTurn = true
                    momentumCarry += 6
                    addFloat("Returning Knife +6 next round", color: Theme.ptahCopper, onEnemy: false)
                }
            }
            attributingPrepared = false
            resetPoses()
            if !hasLivingFoes {
                activeStepIndex = nil
                finishVictory()
                return true
            }
            await sinkTheFallen()
            return false
        }

        // Resolve the finite alternating queue. Delay effects may move pending entries.
        enemyTurnCount += 1
        while !pendingEntries.isEmpty {
            let entry = pendingEntries.removeFirst()
            currentBeat += 1
            switch entry.side {
            case .player:
                guard let index = steps.firstIndex(where: { $0.id == entry.sourceID }) else { continue }
                phase = .resolving
                if await resolvePlayerStep(steps[index], index: index) { return }
            case .foe(let foeID):
                guard let index = enemies.firstIndex(where: { $0.id == foeID }),
                      enemies[index].isAlive else { continue }
                // Retaliation and reflected hits are the enemy's doing, never
                // a combo of yours.
                attributing = .indirect
                phase = .enemyActing
                activeStepIndex = nil
                try? await Task.sleep(for: .milliseconds(BattleBeat.foeLeadIn))
                if await foeActs(index: index, moveIndex: entry.chainIndex) { return }
                if !hasLivingFoes { finishVictory(); return }
            }
            await sinkTheFallen()
        }
        phase = .resolving

        // Relentless Advance strengthens next round's first weapon combo.
        relentlessActive = weaponComboLandedThisTurn
        returningKnifeUsedThisTurn = false

        activeStepIndex = nil
        currentBeat = 0
        try? await Task.sleep(for: .milliseconds(BattleBeat.turnSettle))
        boilingNileTick()
        // Anubis's Sentence: stored by a trial champion, it falls against
        // health at the end of your next turn.
        if playerJudgementPending {
            playerJudgementPending = false
            let amount = playerJudgementAmount
            playerJudgementAmount = 0
            playerHP = max(0, playerHP - amount)
            if amount > 0 { lostHealthThisRound = true }
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

        // Settlement, in the guide's order: verdicts and duo damage have been
        // paid, so the ordinary status ticks come last, for survivors, in
        // visible order.
        await settleStatusTicks()
        if !hasLivingFoes {
            finishVictory()
            return
        }
        endOfRound()
        if !hasLivingFoes { finishVictory(); return }
        try? await Task.sleep(for: .milliseconds(BattleBeat.handover))
        startPlayerTurn()
    }

    /// Burn, bleed and poison ticks at the end of the round. Statuses seep
    /// under armour — they always come off health directly.
    private func settleStatusTicks() async {
        for index in enemies.indices where enemies[index].isAlive {
            for tick in statusTicks(index: index) {
                try? await Task.sleep(for: .milliseconds(BattleBeat.statusTick))
                enemies[index].pose = .hurt
                enemies[index].hp = max(0, enemies[index].hp - tick.amount)
                damageDealt += tick.amount
                addFloat("-\(tick.amount) \(tick.label)", color: tick.color, onEnemy: true,
                         foe: enemies[index].id)
                lastAction = "\(enemies[index].displayName) takes \(tick.amount) \(tick.label.lowercased()) damage."
                try? await Task.sleep(for: .milliseconds(BattleBeat.statusTick))
                resetPoses()
                if !hasLivingFoes { return }
            }
        }
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

    /// A fallen creature holds the deck for one beat with its defeat pose, then
    /// goes under and leaves the stage. The fight you are looking at is only
    /// ever the fight you still have on your hands.
    private func sinkTheFallen() async {
        let fallen = enemies.filter { !$0.isAlive && !sunkFoeIDs.contains($0.id) }
        guard !fallen.isEmpty, hasLivingFoes else { return }
        for foe in fallen {
            if let index = enemies.firstIndex(where: { $0.id == foe.id }) {
                enemies[index].pose = .defeat
            }
            addFloat("SLAIN", color: Theme.boneWhite, onEnemy: true, big: true, foe: foe.id)
        }
        Haptics.medium()
        try? await Task.sleep(for: .milliseconds(BattleBeat.sink))
        withAnimation(.easeInOut(duration: 0.4)) {
            sunkFoeIDs.formUnion(fallen.map(\.id))
        }
        try? await Task.sleep(for: .milliseconds(260))
    }

    /// The creatures actually standing on the deck: everything that has not
    /// yet gone under. Victory and defeat keep the whole pack on screen so the
    /// closing tableau still reads.
    var stagedFoes: [EnemyState] {
        guard phase != .won, phase != .lost else { return enemies }
        return enemies.filter { !sunkFoeIDs.contains($0.id) }
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
        announce(combo: combo, step: step, crit: crit)
        let multiplier = GameData.comboOutputScale(
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

        // A staged recipe puts its guard up *before* it swings, which is the
        // whole reason to build one: the shield is standing when the creature
        // answers rather than arriving after the blow has already landed.
        var defenceApplied = false
        func applyDefence() {
            guard !defenceApplied else { return }
            defenceApplied = true
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
            if combo.dodgeCharges > 0 {
                gainDodges(combo.dodgeCharges)
            }
            if combo.reflect > 0 {
                reflectFraction = max(reflectFraction, combo.reflect)
                addFloat("Reflecting", color: Theme.gold, onEnemy: false)
            }
        }
        if combo.shield > 0 || combo.dodgeCharges > 0 || combo.reflect > 0 {
            addFloat("GUARD UP", color: Theme.steel, onEnemy: false, big: true)
            applyDefence()
        }

        if combo.damage > 0 {
            let base = GameData.scaleUp(combo.damage, by: multiplier)
            let focus = step.focusFaceID == nil ? 0 : BattleRules.focusedBonus(damage: base)
            var raw = base + step.momentumBonus + focus
            // Armed Chisels ride the action they were spent on. This has to
            // happen here as well as in the forecast, or an overdrawn arrow
            // reads as +40% in the plan and lands for its plain value.
            let armedScale = armedDamageMultiplier(for: step)
            if armedScale != 1.0 {
                raw = GameData.scaleUp(raw, by: armedScale)
            }
            raw = applyDamageBonuses(raw, step: step, scalesWithBleed: combo.scalesWithBleed,
                                     scalesWithWounds: combo.scalesWithWounds, scalesWithBurn: combo.scalesWithBurn,
                                     targetIndex: target)
            if siegeApplies(step) {
                addFloat("SIEGE DRAW", color: Theme.ptahCopper, onEnemy: false, big: true)
            }

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
               enemies[target].burnAmount > 0 {
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
            // The scales fall last: a 3+ die attack combo pays its own damage
            // first, then releases whatever verdict was already stored. Any
            // Judgement this combo applies is added afterwards, so a combo can
            // never detonate the weight it just put on.
            if canReleaseJudgement(step) {
                releaseJudgement(targetIndex: target)
            }
        } else {
            // Defensive chains still feed Sobek's capstone and held-face
            // rewards only through faces; no damage path here.
        }
        if combo.bleedAmount > 0 {
            applyBleed(GameData.scaleUp(combo.bleedAmount, by: multiplier), targetIndex: target)
        }
        if combo.poisonAmount > 0 {
            applyPoison(GameData.scaleUp(combo.poisonAmount, by: multiplier), targetIndex: target)
        }
        if combo.burnAmount > 0 {
            applyBurn(GameData.scaleUp(combo.burnAmount, by: multiplier), targetIndex: target)
        }
        // A single-impact recipe applies everything together, here.
        applyDefence()
        if combo.weaken > 0, let target, enemies.indices.contains(target), enemies[target].isAlive {
            applyWeaken(combo.weaken * (crit ? 1.3 : 1.0), targetIndex: target)
        }
        if combo.markPercent > 0, let target, enemies.indices.contains(target), enemies[target].isAlive {
            pendingBoonEffects.append((BoonPayload(markPercent: combo.markPercent), target))
        }

        // Ice Blast, Glacier and Earthshaker shove a creature's pending action
        // later on the clock — the one thing in the game that buys you a beat
        // back after the round has already been telegraphed.
        if Timing.delayGranting.contains(combo.id) {
            delayFoe(targetIndex: target)
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
            echoArmedComboID = nil
        }

        // Alternating Current: opposite rune kinds bank a stamina point.
        if hasChisel("ch_current"), combo.source == .weapon {
            let kinds = Set(step.faces.map(\.matchFace))
            let mixed = kinds.count > 1
            if let last = lastSpellWasMixed, last != mixed, !currentUsedThisTurn {
                currentUsedThisTurn = true
                nextRoundRerolls += 1
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
        let value = GameData.scaleUp(face.matchFace.soloValue, by: multiplier)
        if face.isCrit {
            addFloat("\(face.displayName.uppercased()) CRIT", color: Theme.gold, onEnemy: face.matchFace.isAttack, foe: foeID)
            withAnimation(.linear(duration: 0.3)) { shakeTrigger += 0.6 }
            Haptics.heavy()
        }

        if face.matchFace.isAttack {
            let soloStep = PlanStep(faces: [face], combo: nil)
            var raw = GameData.scaleUp(value + bonus, by: armedDamageMultiplier(for: soloStep))
            raw = applyDamageBonuses(raw, step: PlanStep(faces: [face], combo: nil),
                                     scalesWithBleed: false, scalesWithWounds: false, scalesWithBurn: false,
                                     targetIndex: target)
            let dealt = damageEnemy(raw, pierce: attackPierce(comboBase: 0, step: soloStep, crit: face.isCrit, targetIndex: target),
                                    targetIndex: target)
            firstFeastCheck(dealt)
            lastAction = face.isCrit
                ? "\(face.displayName) crits for \(dealt)!"
                : "\(face.displayName) hits for \(dealt)."
            if face.matchFace == .runeFrost, let target, enemies.indices.contains(target), enemies[target].isAlive {
                applyWeaken(0.2, targetIndex: target)
            }
            return true
        }

        switch face.matchFace.soloKind {
        case .heal:
            healPlayer(value)
            lastAction = "You recover \(value) health."
        case .block:
            gainShield(value)
            lastAction = "Your shield grows by \(value)."
        case .evade:
            gainDodges(1)
            lastAction = "One Dodge prepared for an incoming hit."
        case .poison:
            applyPoison(value, turns: 2, targetIndex: target)
            lastAction = "A drop of venom finds its mark."
        case .focus:
            lastAction = "Focus strengthens the next attack in your plan."


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
        if hasUpgrade("sob_bloodScent"), foe.bleedAmount > 0 { percentPoints += 20 }
        if hasUpgrade("ba_pounce"), step.combo != nil, step.faces.count == 2 { damage += 6 }
        if hasUpgrade("ra_solarWind"),
           step.faces.contains(where: { $0.wasKept && $0.patron == .ra && $0.face.isAttack }) {
            damage += 8
        }
        if hasUpgrade("ho_falconEye"),
           step.faces.contains(where: { $0.wasKept && $0.patron == .horus && $0.face.isAttack }) {
            percentPoints += 25
        }
        if pairing?.id == "pair_sobek_horus", !pairingFiredThisTurn,
           foe.bleedTurns > 0,
           step.faces.contains(where: { $0.wasKept && $0.patron == .horus }) {
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
        if let step {
            pierce += armedPierce(for: step)
            if step.faces.contains(where: { $0.patron == .horus && $0.face.isAttack }) {
                pierce += hasUpgrade("ho_keen") ? 0.4 : 0.2
            }
        }
        if primePierceBonus > 0 { pierce += primePierceBonus; primePierceBonus = 0 }
        // Pierce granted by god powers for this action, spent as it lands.
        if boonPierceBonus > 0 {
            pierce += boonPierceBonus
            boonPierceBonus = 0
        }
        guard let target, enemies.indices.contains(target) else { return min(pierce, 1.0) }
        let foe = enemies[target]

        // Capstone: Eye of the Falcon — once per turn, a chain holding a held
        // Horus face and containing a critical face ignores all defences.
        if capstoneID == "ho_eyeFalcon", !capstoneUsedThisTurn, let step, step.isCombo,
           step.faces.contains(where: { $0.wasKept && $0.patron == .horus }),
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

        if hasUpgrade("ra_sunEdge"), foe.burnAmount > 0 { pierce += 0.25 }
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
              enemies[target].bleedAmount > 0 else { return }
        let foe = enemies[target]
        capstoneUsedThisTurn = true
        let paid = min(foe.bleedAmount, 8)
        addFloat("JAWS OF THE NILE", color: Deity.sobek.tint, onEnemy: false, big: true)
        damageEnemyDirect(foe.id, foe.bleedAmount, label: "Bleed")
        healPlayer(paid, label: "Sobek")
    }

    // MARK: - God powers

    /// Every equipped power that answers this action, resolved at the beat the
    /// action lands on. Counters are per round and per role; a card fires once
    /// however many qualifying ingredients it contains.
    ///
    /// Called *before* the native action so "already burning", "already
    /// bleeding", missing HP and shield conditions are tested against the
    /// board as it stood when the action started.
    private func resolveBoons(in step: PlanStep, targetIndex target: Int?) {
        let roles = roles(for: step)
        guard !roles.isEmpty else { return }
        let frozen = step.faces.contains { $0.wasKept }

        boonStartShield = playerShield
        boonStartFoe = target.map { enemies[$0] }
        evaluatingBoons = true
        defer { evaluatingBoons = false; boonStartShield = nil; boonStartFoe = nil }
        if roles.contains(.attack) {
            attacksThisRound += 1
            if !step.isCombo { soloAttacksThisRound += 1 }
        }
        if roles.contains(.guardian) { guardsThisRound += 1 }

        if roles.contains(.attack), let evolved = activeBoon("LG-BE") {
            let count = step.faces.filter { $0.matchFace.isAttack }.count
            if (boonStartShield ?? 0) >= 8 { primeBonus(percent: 15) }
            gainShield(min(8, count * (2 + evolved.rarity.rawValue)))
        }
        for boon in boons {
            guard let def = boon.def else { continue }
            guard boonAnswers(def, step: step, roles: roles, frozen: frozen, targetIndex: target) else { continue }
            guard claimBoon(def) else { continue }
            land(boon: boon, def: def, step: step, targetIndex: target)
        }

        if roles.contains(.attack), let target, enemies.indices.contains(target) {
            if attacksThisRound == 2, lastAttackFoeID == enemies[target].id, activeBoon("RA-A2") != nil {
                pendingBoonEffects.append((BoonPayload(burn: 2), target))
            }
            lastAttackFoeID = enemies[target].id
            if !step.isCombo { lastSoloFoeID = enemies[target].id }
        }
        if !step.isCombo {
            if roles.contains(.guardian) { separateGuardPlayed = true }
            if roles.contains(.evade) { separateEvadePlayed = true }
            if roles.contains(.support) { separateSupportPlayed = true }
        }
    }

    /// Does this card's trigger and its own extra clause hold for this action?
    private func boonAnswers(
        _ def: GodBoonDef,
        step: PlanStep,
        roles: ActionRole,
        frozen: Bool,
        targetIndex target: Int?
    ) -> Bool {
        // Duos need every source group still equipped.
        if def.kind == .duo, !duoActive(def) { return false }
        if ["DU-02", "DU-06"].contains(def.id) { return false }

        let triggered: Bool
        switch def.trigger {
        case .everyAttack: triggered = roles.contains(.attack)
        case .firstAttack: triggered = roles.contains(.attack) && attacksThisRound == 1
        case .firstFocusedAttack: triggered = roles.contains(.attack) && step.focusFaceID != nil
        case .firstAttackAfterGuard: triggered = roles.contains(.attack) && separateGuardPlayed
        case .firstAttackAfterSupport: triggered = roles.contains(.attack) && (separateGuardPlayed || separateSupportPlayed)
        case .firstAttackAfterEvade: triggered = roles.contains(.attack) && separateEvadePlayed
        case .firstTwoSoloAttacks: triggered = roles.contains(.attack) && !step.isCombo && soloAttacksThisRound <= 2
        case .firstSoloAttack: triggered = roles.contains(.attack) && !step.isCombo
        case .secondAttack: triggered = roles.contains(.attack) && attacksThisRound == 2
        case .thirdAttack: triggered = roles.contains(.attack) && attacksThisRound == 3
        case .firstLargeCombo:
            triggered = roles.contains(.attack) && step.isCombo && step.faces.count >= 3
        case .firstTwoFaceCombo:
            triggered = roles.contains(.attack) && step.isCombo && step.faces.count == 2
        case .firstKeptAttack: triggered = roles.contains(.attack) && frozen
        case .firstComboWithBlock:
            triggered = roles.contains(.attack) && step.isCombo
                && step.faces.contains { $0.matchFace == .block }
        case .firstAttackOnWounded:
            guard roles.contains(.attack), let target, enemies.indices.contains(target) else { return false }
            triggered = enemies[target].hpFraction < 0.5
        case .everyGuard: triggered = roles.contains(.guardian)
        case .firstGuard: triggered = roles.contains(.guardian) && guardsThisRound == 1
        case .firstKeptGuard: triggered = roles.contains(.guardian) && frozen
        case .firstEvade: triggered = roles.contains(.evade)
        case .firstKeptAction: triggered = frozen
        case .onDodge, .onShieldAbsorb, .encounterStart, .roundStart, .roundEnd, .atCommitment:
            // These are armed or settled elsewhere, never by an action landing.
            return false
        }
        guard triggered else { return false }
        guard let requirement = def.requires else { return true }
        return conditionHolds(requirement, step: step, frozen: frozen, targetIndex: target)
    }

    /// The catalogue's extra clauses, all tested before the action changes the
    /// board so "already burning" can never mean "burning because of this".
    private func conditionHolds(
        _ condition: BoonCondition,
        step: PlanStep?,
        frozen: Bool,
        targetIndex target: Int?
    ) -> Bool {
        let foe = evaluatingBoons ? boonStartFoe : target.flatMap { enemies.indices.contains($0) ? enemies[$0] : nil }
        switch condition {
        case .targetBurning: return (foe?.burnAmount ?? 0) > 0
        case .targetBleeding: return (foe?.bleedAmount ?? 0) > 0
        case .targetJudged: return foe?.judgementPending == true
        case .hadEightShield: return (boonStartShield ?? playerShield) >= 8
        case .hasCritIngredient: return step?.faces.contains { $0.isCrit } ?? false
        case .focusedAction: return step?.focusFaceID != nil
        case .usesKeptFace: return frozen
        case .sameTargetAsLast:
            guard let foe, let last = lastAttackFoeID else { return false }
            return foe.id == last
        case .isTwoFaceCombo: return step?.isCombo == true && step?.faces.count == 2
        case .lostNoHealth: return !lostHealthThisRound && incomingAttemptedThisRound
        case .healthAtHalf: return playerHP * 2 <= playerMaxHP
        case .endedWithEightShield: return playerShield >= 8
        case .usedAllDice: return committedPlan.flatMap(\.faces).count == BattleRules.handSize
        }
    }

    /// Claims a card's activation, honouring its own counter. Returns false
    /// when it has already answered as often as it is allowed to.
    private func claimBoon(_ def: GodBoonDef) -> Bool {
        switch def.trigger {
        case .everyAttack, .everyGuard, .firstTwoSoloAttacks:
            return true
        case _ where def.id == "SO-U2" || def.id == "HO-U2":
            // Patient Hunter is once per encounter, not per round.
            guard !boonsFiredThisEncounter.contains(def.id) else { return false }
            boonsFiredThisEncounter.insert(def.id)
            return true
        default:
            guard !boonsFiredThisRound.contains(def.id) else { return false }
            boonsFiredThisRound.insert(def.id)
            return true
        }
    }

    /// Are all of a duo's source groups still equipped? A duo never satisfies
    /// its own prerequisite, and a legendary counts as the boon it evolved.
    private func duoActive(_ def: GodBoonDef) -> Bool {
        let owned = Set(boons.compactMap { boon -> String? in
            guard let ownedDef = boon.def else { return nil }
            return ownedDef.kind == .legendary ? ownedDef.evolves : ownedDef.id
        })
        return def.sources.allSatisfy { !$0.members.isDisjoint(with: owned) }
    }

    /// Lands one power's payload on the action that earned it.
    private func land(boon: EquippedBoon, def: GodBoonDef, step: PlanStep, targetIndex target: Int?) {
        var payload = boon.payload
        let frozen = step.faces.contains { $0.wasKept }

        // Per-ingredient clauses count their qualifying ingredients once and
        // pool the result, so a long chain never multiplies a god's patience.
        if payload.perIngredient {
            let count: Int
            switch def.scales {
            case .shield where def.id == "BE-D1":
                count = step.faces.filter { $0.matchFace == .block }.count
            default:
                count = step.faces.filter { $0.matchFace.isAttack }.count
            }
            let pooled = max(1, count)
            payload.shield *= pooled
            payload.burn *= pooled
            payload.judgement *= pooled
            if payload.perIngredientCap > 0 {
                payload.shield = min(payload.shield, payload.perIngredientCap)
            }
        }

        if def.id == "SO-A2", attacksThisRound > 1 { payload.bleed = 0 }
        if def.id == "AN-A2", boonsFiredThisRound.contains("AN-A2-bonus") { payload.bonusJudgement = 0 }
        if def.id == "BA-A2" {
            payload.bonusCondition = nil
            if soloAttacksThisRound == 2, let target, lastSoloFoeID == enemies[target].id { payload.flatDamage += 2 }
        }

        // The card's own conditional extra.
        if let bonus = payload.bonusCondition,
           conditionHolds(bonus, step: step, frozen: frozen, targetIndex: target) {
            payload.percentDamage += payload.bonusPercentDamage
            payload.flatDamage += payload.bonusFlatDamage
            payload.shield += payload.bonusShield
            payload.dodgeCharges += payload.bonusDodges
            payload.judgement += payload.bonusJudgement
            payload.heal += payload.bonusHeal
            payload.burn += payload.burnBonus
            if def.id == "AN-A2" { boonsFiredThisRound.insert("AN-A2-bonus") }
        }

        if def.id == "LG-RA", let target {
            payload.flatDamage += min(20, enemies[target].burnAmount * 2)
            enemies[target].burnAmount = 0
            enemies[target].burnTurns = 0
        }
        if def.id == "HO-D1" { nextHitReduction = max(nextHitReduction, 0.2) }
        if def.id == "DU-13", roles(for: step).contains(.guardian) { nextHitReduction = max(nextHitReduction, 0.25) }
        if def.id == "SO-A4" { pendingHealOnHit += payload.heal; payload.heal = 0 }
        let dodgeReaction = ["RA-D2", "SO-D2", "AN-D2", "BA-D2"].contains(def.id)
        let guardReaction = [.firstGuard, .firstKeptGuard, .everyGuard].contains(def.trigger)
            && (payload.burn > 0 || payload.bleed > 0 || payload.judgement > 0)
        if dodgeReaction {
            armedOnDodge.append(def.id)
            pendingDivineEntries.append(DivineFlashEntry(god: def.god, name: def.name, effect: "On dodge: " + summary(of: payload)))
            return
        }
        if guardReaction { armedOnShieldAbsorb.append(def.id) }

        let touchesFoe = payload.flatDamage > 0 || payload.burn > 0
            || payload.bleed > 0 || payload.poison > 0 || payload.judgement > 0
            || payload.weakenPercent > 0 || payload.markPercent > 0
        let foeID = target.flatMap { enemies.indices.contains($0) ? enemies[$0].id : nil }
        addFloat(def.name.uppercased(), color: def.god.tint, onEnemy: touchesFoe, foe: foeID)

        // Held for the card that rises before the action lands, so what the
        // gods contributed this turn is stated rather than guessed at.
        pendingDivineEntries.append(
            DivineFlashEntry(god: def.god, name: def.name, effect: summary(of: payload))
        )

        // Flat and percentage damage are banked onto this action rather than
        // dealt separately, so one hit lands once with everything folded in.
        if payload.flatDamage > 0 { primeBonus(damage: payload.flatDamage) }
        if payload.percentDamage > 0 { primeBonus(percent: payload.percentDamage) }
        if payload.pierce > 0 { boonPierceBonus += Double(payload.pierce) / 100.0 }

        if payload.shield > 0 { gainShield(payload.shield) }
        if payload.heal > 0 { healPlayer(min(payload.heal, 8), label: def.god.name) }
        if !guardReaction { pendingBoonEffects.append((payload, target)) }
        if payload.cleansesSelf { cleanseSelf(label: def.god.name) }
        if payload.dodgeCharges > 0 { gainDodges(payload.dodgeCharges) }
        if payload.rerollsNext > 0 {
            nextRoundRerolls += payload.rerollsNext
            addFloat("+\(payload.rerollsNext) Reroll Next", color: Theme.gold, onEnemy: false)
        }

    }

    private func activeBoon(_ id: String) -> EquippedBoon? {
        boons.first { boon in
            guard boon.defID == id, let def = boon.def else { return false }
            return def.kind != .duo || duoActive(def)
        }
    }

    private func applyPendingBoonEffects() {
        let effects = pendingBoonEffects
        pendingBoonEffects = []
        for (payload, target) in effects {
            if payload.burn > 0 { applyBurn(payload.burn, targetIndex: target) }
            if payload.bleed > 0 { applyBleed(payload.bleed, targetIndex: target) }
            if payload.poison > 0 { applyPoison(payload.poison, targetIndex: target) }
            if payload.judgement > 0 { applyJudgement(payload.judgement, targetIndex: target) }
            if payload.weakenPercent > 0 { applyWeaken(Double(payload.weakenPercent) / 100, targetIndex: target) }
            if payload.markPercent > 0 { applyMark(Double(payload.markPercent) / 100, targetIndex: target) }
        }
    }

    /// What one power actually did, in the shortest honest phrasing. Only the
    /// parts of the payload that carry a value are named, so a card never
    /// claims an effect it did not produce.
    private func summary(of payload: BoonPayload) -> String {
        var parts: [String] = []
        if payload.flatDamage > 0 { parts.append("+\(payload.flatDamage) dmg") }
        if payload.percentDamage > 0 { parts.append("+\(payload.percentDamage)% dmg") }
        if payload.pierce > 0 { parts.append("\(payload.pierce)% pierce") }
        if payload.shield > 0 { parts.append("+\(payload.shield) shield") }
        if payload.heal > 0 { parts.append("+\(min(payload.heal, 8)) health") }
        if payload.burn > 0 { parts.append("burn \(payload.burn)") }
        if payload.bleed > 0 { parts.append("bleed \(payload.bleed)") }
        if payload.poison > 0 { parts.append("poison \(payload.poison)") }
        if payload.judgement > 0 { parts.append("judge \(payload.judgement)") }
        if payload.weakenPercent > 0 { parts.append("weaken \(payload.weakenPercent)%") }
        if payload.markPercent > 0 { parts.append("mark +\(payload.markPercent)%") }
        if payload.cleansesSelf { parts.append("cleansed") }
        if payload.dodgeCharges > 0 { parts.append("+\(payload.dodgeCharges) Dodge") }
        if payload.rerollsNext > 0 { parts.append("+\(payload.rerollsNext) reroll next") }
        return parts.isEmpty ? "answers" : parts.joined(separator: " · ")
    }

    /// Names one of your actions before it resolves: what you are doing, what
    /// it is worth, which faces fed it, who it is pointed at, and every god
    /// power riding it — all held together long enough to read.
    private func raiseSpotlight(for step: PlanStep, targetIndex target: Int?) async {
        let entries = pendingDivineEntries
        pendingDivineEntries = []
        let targetName = livingFoes.count > 1
            ? target.flatMap { enemies.indices.contains($0) ? enemies[$0].displayName : nil }
            : nil

        // A chain names itself here and nowhere earlier. This is the moment
        // the player finds out what they built, and the first time one lands
        // it is written into the codex for good.
        var found = false
        if let combo = step.combo, ComboLore.discover(combo.id) {
            found = true
            knownChainIDs.insert(combo.id)
            chainsDiscoveredThisFight.append(combo.id)
        }

        await hold(
            ActionSpotlight(
                actor: heroName,
                isPlayer: true,
                title: step.title,
                detail: step.valueLine,
                target: step.targetsEnemy ? targetName : nil,
                faces: step.faces.map(\.matchFace),
                crit: false,
                charge: 0,
                sequence: nil,
                entries: entries,
                tint: step.tint,
                isDiscovery: found
            )
        )
    }

    /// Names one creature's action before it resolves, in the same shape as
    /// your own — so what is being done to you is as legible as what you are
    /// doing to it.
    private func raiseFoeSpotlight(
        foe: EnemyState,
        move: EnemyMove,
        moveIndex: Int,
        strike: (damage: Int, heal: Int, block: Int)
    ) async {
        var parts: [String] = []
        if move.charge > 0 {
            parts.append("winding up — next blow ×\(String(format: "%.1f", move.charge))")
        }
        if strike.damage > 0 { parts.append("\(strike.damage) DMG") }
        if strike.block > 0 { parts.append("+\(strike.block) Guard") }
        if strike.heal > 0 { parts.append("+\(strike.heal) HP") }
        if move.bleedAmount > 0 { parts.append("Bleed \(move.bleedAmount)×\(move.bleedTurns)") }
        await hold(
            ActionSpotlight(
                actor: foe.displayName,
                isPlayer: false,
                title: move.comboName ?? move.name,
                detail: parts.isEmpty ? "no effect" : parts.joined(separator: " · "),
                target: nil,
                faces: move.faces,
                crit: false,
                charge: move.charge,
                sequence: foe.hasChainedIntents
                    ? "\(moveIndex + 1) of \(foe.intents.count)"
                    : nil,
                entries: [],
                tint: move.charge > 0 ? Theme.ember : Theme.blood
            )
        )
    }

    /// Holds one action's card on screen, then clears it. The hold grows with
    /// the number of god powers named, so a heavily blessed blow gets the time
    /// its card actually needs.
    private func hold(_ card: ActionSpotlight) async {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
            spotlight = card
        }
        if card.isDiscovery { Haptics.success() } else { Haptics.light() }
        // A find holds longer than an action you already knew — it is the one
        // card in a fight worth stopping for.
        let wait = BattleBeat.spotlight + min(card.entries.count, 3) * BattleBeat.spotlightPerGod
            + (card.isDiscovery ? BattleBeat.spotlightDiscovery : 0)
        try? await Task.sleep(for: .milliseconds(wait))
        guard spotlight?.id == card.id else { return }
        withAnimation(.easeOut(duration: 0.24)) { spotlight = nil }
        try? await Task.sleep(for: .milliseconds(200))
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

            if role == .evade {
                patronDodgeAnswers.append((answer, god, step))
            } else {
                land(answer, god: god, step: step, targetIndex: target)
            }
        }

        // Held-face rewards ride the same action.
        if hasUpgrade("an_weighed"),
           step.faces.contains(where: { $0.wasKept && $0.patron == .anubis && $0.face.isAttack }) {
            applyJudgement(6, targetIndex: target)
        }
        if hasUpgrade("ho_thermal"), !thermalUsedThisTurn,
           step.faces.contains(where: { $0.wasKept && $0.patron == .horus }) {
            thermalUsedThisTurn = true
            nextRoundRerolls += 1
            addFloat("+1 Reroll Next", color: Deity.horus.tint, onEnemy: false)
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
        if answer.dodgeCharges > 0 { gainDodges(answer.dodgeCharges) }
        if answer.primeDamage > 0 { primeBonus(damage: answer.primeDamage) }
        if answer.primePercent > 0 { primeBonus(percent: answer.primePercent) }
        if answer.primeBurn > 0 { primeBonus(burn: answer.primeBurn) }
        if answer.primeHeal > 0 { primeBonus(heal: answer.primeHeal) }
        if answer.rerollsNext > 0 {
            nextRoundRerolls += answer.rerollsNext
            addFloat("+\(answer.rerollsNext) Reroll", color: Theme.gold, onEnemy: false)
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
        let heldHorus = step.faces.contains(where: { $0.wasKept && $0.patron == .horus })
        let heldRaAttack = step.faces.contains(where: { $0.wasKept && $0.patron == .ra && $0.face.isAttack })

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
              enemies[target].burnAmount > 0 else { return }
        damageEnemyDirect(enemies[target].id, enemies[target].burnAmount, label: "Burn")
    }

    // MARK: - Shield, evade, healing, judgement

    private func gainShield(_ amount: Int) {
        guard amount > 0 else { return }
        playerShield += amount
        addFloat("+\(amount) Shield", color: Theme.steel, onEnemy: false)
    }

    private func gainDodges(_ charges: Int) {
        guard charges > 0 else { return }
        for _ in 0..<min(charges, max(0, BattleRules.maximumDodges - dodgeReservations.count)) {
            dodgeReservations.append(nil)
        }

        addFloat("+\(charges) Dodge", color: Theme.steel, onEnemy: false)
    }

    private func consumeDodge(foeID: UUID, moveIndex: Int, hitIndex: Int) -> Bool {
        let key = "\(foeID.uuidString):\(moveIndex):\(hitIndex)"
        return BattleRules.consumeDodge(reservations: &dodgeReservations, strikeID: key)

    }



    private func healPlayer(_ amount: Int, label: String? = nil) {
        guard amount > 0 else { return }
        let healed = min(playerMaxHP, playerHP + amount) - playerHP
        playerHP += healed
        if healed > 0, !healingFromDuo, let boon = activeBoon("DU-07"), let def = boon.def, claimBoon(def) {
            gainShield(boon.payload.shield)
        }
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

    /// Anubis stores damage against a foe. Nothing tips the scales on a clock:
    /// the pile sits there until one of your own attack combos of
    /// `judgementReleaseIngredients` dice or more releases it, so feeding the
    /// scales is a choice rather than a wait.
    private func applyJudgement(_ amount: Int, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        var value = amount
        if enemies[target].judgementPending, hasUpgrade("an_secondReading") {
            value *= 2
            addFloat("Second Reading", color: Deity.anubis.tint, onEnemy: false)
        }
        enemies[target].judgementAmount = min(GameData.judgementCap, enemies[target].judgementAmount + value)
        enemies[target].judgementPending = true
        addFloat("Judgement \(enemies[target].judgementAmount)", color: Deity.anubis.tint,
                 onEnemy: true, foe: enemies[target].id)
    }

    /// True when this action is a primary attack combo big enough to pull the
    /// scales down.
    private func canReleaseJudgement(_ step: PlanStep) -> Bool {
        guard let combo = step.combo, combo.roles.contains(.attack) else { return false }
        return step.faces.count >= GameData.judgementReleaseIngredients
    }

    /// A big attack combo pulls the scales down. Called *after* the combo's own
    /// damage has landed, so the verdict is the finish rather than the opener,
    /// and before the combo applies any Judgement of its own — a combo can
    /// never detonate weight it just added.
    private func releaseJudgement(targetIndex target: Int?) {
        guard let index = target, enemies.indices.contains(index), enemies[index].isAlive,
              enemies[index].judgementPending, enemies[index].judgementAmount > 0 else { return }

        let foe = enemies[index]
        let stored = foe.judgementAmount
        // Heavy scales tip harder: every full step past the first adds a
        // share of the pile again.
        var amount = GameData.judgementVerdict(stored: stored)
        let scaleBonus = GameData.judgementBonus(stored: stored)
        // Pairing: Funeral Pyre — verdicts burn brighter with burn stacks.
        if pairing?.id == "pair_ra_anubis" {
            amount += foe.burnAmount * 2
        }
        // Capstone: Final Verdict.
        if capstoneID == "an_finalVerdict" || activeBoon("LG-AN") != nil {
            if foe.def.isBoss {
                amount = Int(Double(amount) * 1.5)
            } else if foe.hpFraction < 0.25 {
                amount *= 2
            }
        }
        // Pairing: The Crossing — a verdict on a bleeding foe heals 5.
        if pairing?.id == "pair_sobek_anubis", foe.bleedAmount > 0, !pairingFiredThisTurn {
            pairingFiredThisTurn = true
            healPlayer(5, label: "The Crossing")
        }
        if activeBoon("DU-02") != nil { amount += min(12, foe.burnAmount * 2) }
        if activeBoon("DU-06") != nil, foe.bleedAmount > 0 {
            healingFromDuo = true
            healPlayer(3, label: "The Crossing")
            healingFromDuo = false
            nextRoundRerolls = min(1, nextRoundRerolls + 1)
        }
        enemies[index].judgementAmount = 0
        enemies[index].judgementPending = false
        announceVerdict(foe: foe, stored: stored, total: amount, scaleBonus: scaleBonus)
        damageEnemyDirect(foe.id, amount, label: "Judgement")
        withAnimation(.linear(duration: 0.35)) { shakeTrigger += 0.9 }
    }

    /// The scales tipping, made unmistakable: Anubis's own banner across the
    /// deck, a burst on the creature it fell on, and the arithmetic spelled
    /// out so a heavy verdict visibly pays more than a light one.
    private func announceVerdict(foe: EnemyState, stored: Int, total: Int, scaleBonus: Int) {
        let flash = ComboFlash(
            name: "The Scales Tip",
            chain: max(1, stored / GameData.judgementScaleStep),
            summary: scaleBonus > 0
                ? "\(stored) stored +\(scaleBonus) heavy scales · \(total) through guard"
                : "\(stored) stored · \(total) through guard",
            tint: Deity.anubis.tint,
            crit: scaleBonus > 0
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            comboFlash = flash
        }
        verdictBurst = VerdictBurst(foeID: foe.id, amount: total, heavy: scaleBonus > 0)
        addFloat("VERDICT \(total)", color: Deity.anubis.tint,
                 onEnemy: true, big: true, foe: foe.id)
        if scaleBonus > 0 {
            addFloat("HEAVY SCALES +\(scaleBonus)", color: Theme.gold, onEnemy: true, foe: foe.id)
        }
        Haptics.chain(length: 4, crit: scaleBonus > 0)
        Audio.shared.play(.chain)
        let flashID = flash.id
        Task {
            try? await Task.sleep(for: .milliseconds(1100))
            if comboFlash?.id == flashID {
                withAnimation(.easeOut(duration: 0.25)) { comboFlash = nil }
            }
            withAnimation(.easeOut(duration: 0.3)) { verdictBurst = nil }
        }
    }

    /// Pairing: Boiling Nile — a foe burning and bleeding at once is scalded
    /// for its burn again at the end of your turn.
    private func boilingNileTick() {
        guard pairing?.id == "pair_ra_sobek", !pairingFiredThisTurn else { return }
        for foe in enemies where foe.isAlive && foe.burnAmount > 0 && foe.bleedAmount > 0 {
            pairingFiredThisTurn = true
            addFloat("BOILING NILE", color: Deity.ra.tint, onEnemy: false, big: true)
            damageEnemyDirect(foe.id, foe.burnAmount, label: "Burn")
            break
        }
    }

    // MARK: - Statuses

    /// Burn stacks up to its ceiling. It is fast pressure that fades: the
    /// round-end tick halves it rather than counting rounds down.
    private func applyBurn(_ amount: Int, turns: Int = 0, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        let before = enemies[target].burnAmount
        enemies[target].burnAmount = min(GameData.burnStackCap, before + amount)
        enemies[target].burnTurns = 1
        let gained = enemies[target].burnAmount - before
        addFloat(gained > 0 ? "Burn +\(gained)" : "Burn at max",
                 color: Theme.ember, onEnemy: true, foe: enemies[target].id)
    }

    /// Pushes one foe's telegraphed action a beat later, capped per round so a

    private func delayFoe(targetIndex target: Int?) {
        guard let index = resolveTarget(target), enemies[index].isAlive else { return }
        let foeID = enemies[index].id
        let already = foeDelays[foeID] ?? 0
        guard already < Timing.maxDelayPerEnemy else { return }
        guard let index = pendingEntries.firstIndex(where: { $0.sourceID == foeID && !$0.isPlayer }) else { return }
        let delayed = pendingEntries.remove(at: index)
        let nextPlayer = pendingEntries.indices.first { $0 >= index && pendingEntries[$0].isPlayer }
        pendingEntries.insert(delayed, at: nextPlayer.map { $0 + 1 } ?? pendingEntries.count)
        foeDelays[foeID] = already + 1
        addFloat("Delayed", color: Theme.frost, onEnemy: true, foe: foeID)
    }

    /// Poison stacks and then grows on its own every round. It never expires,
    /// so it is the slow strangle rather than a timed drip.
    private func applyPoison(_ amount: Int, turns: Int = 0, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        let before = enemies[target].poisonAmount
        enemies[target].poisonAmount = min(GameData.poisonStackCap, before + amount)
        enemies[target].poisonTurns = 1
        let gained = enemies[target].poisonAmount - before
        addFloat(gained > 0 ? "Poison +\(gained)" : "Poison at max",
                 color: Theme.venom, onEnemy: true, foe: enemies[target].id)
    }

    /// Bleed never adds: the strongest wound on the target stands. It has no
    /// round count because it bites when the creature attacks, not on a clock.
    private func applyBleed(_ amount: Int, turns: Int = 0, targetIndex target: Int?) {
        guard amount > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        let capped = min(GameData.bleedStackCap, amount)
        guard capped > enemies[target].bleedAmount else {
            addFloat("Bleed holds at \(enemies[target].bleedAmount)",
                     color: Theme.blood, onEnemy: true, foe: enemies[target].id)
            return
        }
        enemies[target].bleedAmount = capped
        enemies[target].bleedTurns = 1
        addFloat("Bleed \(capped)", color: Theme.blood, onEnemy: true, foe: enemies[target].id)
    }

    /// Anubis's Burial Cloth: a held guard washes your own wounds away.
    private func cleanseSelf(label: String) {
        let carried = playerBleedTurns > 0 || playerBurnTurns > 0
        playerBleedAmount = 0
        playerBleedTurns = 0
        playerBurnAmount = 0
        playerBurnTurns = 0
        if carried {
            addFloat("Cleansed", color: Deity.anubis.tint, onEnemy: false)
        }
        _ = label
    }

    /// Weaken softens the creature's next attack. Only the strongest counts,
    /// and it can never take more than half the blow away.
    private func applyWeaken(_ fraction: Double, targetIndex target: Int?) {
        guard fraction > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        let value = min(GameData.weakenCeiling, fraction)
        guard value > enemies[target].weaken else { return }
        enemies[target].weaken = value
        addFloat("Weaken \(Int(value * 100))%", color: Theme.frost,
                 onEnemy: true, foe: enemies[target].id)
    }

    /// Marks a creature so your next attack on it lands harder. A mark cannot
    /// be cashed in by the same action that applied it.
    private func applyMark(_ fraction: Double, targetIndex target: Int?) {
        guard fraction > 0, let target, enemies.indices.contains(target), enemies[target].isAlive else { return }
        guard fraction > enemies[target].markBonus else { return }
        enemies[target].markBonus = fraction
        addFloat("Marked +\(Int(fraction * 100))%", color: Theme.venom,
                 onEnemy: true, foe: enemies[target].id)
    }

    /// Sobek's Deep Water: his blessing's bleed ticks for 2 more.
    private func sobekBleedBonus(_ amount: Int) -> Int {
        hasUpgrade("sob_deepWater") ? amount + 2 : amount
    }

    @discardableResult
    private func damageEnemy(_ raw: Int, pierce: Double, targetIndex target: Int?) -> Int {
        guard let index = resolveTarget(target) else { return 0 }
        var foe: EnemyState {
            get { enemies[index] }
            set { enemies[index] = newValue }
        }

        // Marked is additive on the hit, never multiplied over it, and it is
        // spent by the attack that cashes it in.
        var damage = raw
        if foe.markBonus > 0 {
            let bonus = Int((Double(raw) * foe.markBonus).rounded())
            damage += bonus
            addFloat("Marked +\(bonus)", color: Theme.venom, onEnemy: true, foe: foe.id)
            foe.markBonus = 0
        }
        // One pool to chew through, whether the foe was born wearing it or
        // raised it on the spot. Pierce is measured against the mark, so
        // punching through deep plate is worth the same as it ever was.
        if foe.armour > 0 {
            let ignored = Int(Double(foe.armourMax) * pierce)
            let effectiveArmour = max(0, foe.armour - ignored)
            let absorbed = min(effectiveArmour, damage)
            foe.armour -= absorbed
            damage -= absorbed
            if absorbed > 0 {
                addFloat("Guard \(absorbed)", color: Theme.bronze, onEnemy: true, foe: foe.id)
                if foe.armour == 0 {
                    addFloat("GUARD BROKEN", color: Theme.boneWhite, onEnemy: true, big: true, foe: foe.id)
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
        credit(damage)
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
        // Ticks, verdicts, retaliation and echoes are never a new combo.
        indirectDamage += amount
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
        if hasUpgrade("ra_ashes"), foe.burnAmount > 0,
           let index = enemies.firstIndex(where: { $0.isAlive && $0.id != foe.id }) {
            enemies[index].burnAmount = min(GameData.burnStackCap,
                                            max(enemies[index].burnAmount, foe.burnAmount))
            enemies[index].burnTurns = 1
            addFloat("Ashes to Ashes", color: Deity.ra.tint, onEnemy: true, foe: enemies[index].id)
        }
    }

    // MARK: - Round settlement

    /// Once the whole interleaved round has played out: retaliation, the
    /// unscathed reward, then the expiring effects are cleared. Evade and

    private func endOfRound() {
        // The round's banks and retaliation, checked against what the round
        // actually ended on — shield still standing, stamina actually spent.
        applyRoundEndBoons()

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
            nextRoundGuard += 6
        }
        if activeBoon("BA-D3") != nil, incomingAttemptedThisRound, !lostHealthThisRound { nextRoundGuard += 4 }
        shieldAbsorbedThisEnemyTurn = 0
        hardestHitFoeID = nil
        hardestHitAmount = 0
        tookHealthDamageThisEnemyTurn = false
        playerShield = BattleRules.guardAfterRound(playerShield, warrior: classID == "warrior")
        reflectFraction = 0
        dodgeReservations = []

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

    // MARK: - Reactions

    /// Powers armed by an Evade action, paid out when a hit is actually
    /// slipped. Armed reactions expire at round end if never used.
    private func boonsOnDodge(attacker: EnemyState) {
        let attackerIndex = enemies.firstIndex { $0.id == attacker.id }
        for boon in boons {
            guard let def = boon.def else { continue }
            let armed = armedOnDodge.contains(def.id)
            let onDodge = def.trigger == .onDodge
            guard armed || onDodge else { continue }
            if def.kind == .duo, !duoActive(def) { continue }
            if def.id == "DU-09", attacker.bleedAmount <= 0 { continue }
            if onDodge, !claimBoon(def) { continue }

            let payload = boon.payload
            healingFromDuo = def.kind == .duo
            defer { healingFromDuo = false }
            addFloat(def.name.uppercased(), color: def.god.tint, onEnemy: false)
            if payload.shield > 0 { gainShield(payload.shield) }
            if payload.heal > 0 { healPlayer(min(payload.heal, 8), label: def.god.name) }
            if payload.rerollsNext > 0 {
                nextRoundRerolls = min(1, nextRoundRerolls + payload.rerollsNext)
                addFloat("+\(payload.rerollsNext) Reroll Next", color: Theme.gold, onEnemy: false)
            }
            if payload.percentDamage > 0 { primeBonus(percent: payload.percentDamage) }
            if payload.pierce > 0 {
                primePierceBonus = max(primePierceBonus, Double(payload.pierce) / 100)
                primeExpiryTurn = turnNumber + 1
            }
            guard let attackerIndex else { continue }
            if payload.burn > 0 {
                if def.id == "RA-D3" {
                    for index in enemies.indices where enemies[index].isAlive { applyBurn(payload.burn, targetIndex: index) }
                } else { applyBurn(payload.burn, targetIndex: attackerIndex) }
            }
            if payload.bleed > 0 { applyBleed(payload.bleed, turns: 2, targetIndex: attackerIndex) }
            if payload.judgement > 0 { applyJudgement(payload.judgement, targetIndex: attackerIndex) }
        }
        armedOnDodge = []
    }

    /// Powers that answer the first hit your shield absorbs each round.
    private func boonsOnShieldAbsorb(attacker: EnemyState) {
        guard let attackerIndex = enemies.firstIndex(where: { $0.id == attacker.id }) else { return }
        for boon in boons {
            guard let def = boon.def else { continue }
            let armed = armedOnShieldAbsorb.contains(def.id)
            let onAbsorb = def.trigger == .onShieldAbsorb
            guard armed || onAbsorb else { continue }
            if def.kind == .duo, !duoActive(def) { continue }
            if onAbsorb, !claimBoon(def) { continue }

            let payload = boon.payload
            addFloat(def.name.uppercased(), color: def.god.tint, onEnemy: true, foe: attacker.id)
            if payload.burn > 0 {
                if def.id == "RA-D3" {
                    for index in enemies.indices where enemies[index].isAlive { applyBurn(payload.burn, targetIndex: index) }
                } else { applyBurn(payload.burn, targetIndex: attackerIndex) }
            }
            if payload.bleed > 0 { applyBleed(payload.bleed, turns: 2, targetIndex: attackerIndex) }
            if payload.judgement > 0 { applyJudgement(payload.judgement, targetIndex: attackerIndex) }
            if onAbsorb && payload.shield > 0 { gainShield(payload.shield) }
        }
        armedOnShieldAbsorb = []
    }

    /// Encounter-opening powers: shield laid before the first timeline begins,

    private func applyEncounterStartBoons() {
        for boon in boons {
            guard let def = boon.def, def.trigger == .encounterStart else { continue }
            if def.kind == .duo, !duoActive(def) { continue }
            let payload = boon.payload
            if payload.shield > 0 { gainShield(payload.shield) }
            if payload.rerollsNext > 0 {
                rerollBonus = min(1, rerollBonus + payload.rerollsNext)

            }
        }
    }

    /// reads the board once the previous round has fully settled.
    private func applyRoundStartBoons() {
        for boon in boons {
            guard let def = boon.def, def.trigger == .roundStart else { continue }
            if def.kind == .duo, !duoActive(def) { continue }
            if def.id == "DU-07" { continue }
            if let requirement = def.requires,
               !conditionHolds(requirement, step: nil, frozen: false, targetIndex: nil) { continue }
            let payload = boon.payload
            if payload.rerollsNext > 0 {
                rerollBonus = min(1, rerollBonus + payload.rerollsNext)
                addFloat("\(def.name.uppercased()) +\(payload.rerollsNext)", color: def.god.tint, onEnemy: false)
            }
            if payload.shield > 0 { gainShield(payload.shield) }
        }

    }

    /// Round-end powers: the banks that check what the round actually ended
    /// on, and Unbroken House's retaliation.
    private func applyRoundEndBoons() {
        for boon in boons {
            guard let def = boon.def else { continue }
            guard def.trigger == .roundEnd else { continue }
            if def.kind == .duo, !duoActive(def) { continue }
            if def.id == "DU-07" { continue }
            if let requirement = def.requires,
               !conditionHolds(requirement, step: nil, frozen: false, targetIndex: nil) { continue }
            guard claimBoon(def) else { continue }

            // The legendary Unbroken House pays back half the shield the round
            // absorbed, at whoever consumed the most of it.
            if def.id == "LG-BE" {
                guard shieldAbsorbedThisEnemyTurn > 0, let foeID = hardestHitFoeID,
                      enemies.contains(where: { $0.id == foeID && $0.isAlive }) else { continue }
                let strike = min(15, shieldAbsorbedThisEnemyTurn / 2)
                guard strike > 0 else { continue }
                addFloat("UNBROKEN HOUSE", color: Deity.bes.tint, onEnemy: false, big: true)
                damageEnemyDirect(foeID, strike, label: "Bes")
                continue
            }

            // Boiling Nile: the foe burning and bleeding at once, with the
            // most burn, is scalded for its burn again.
            if def.id == "DU-01" {
                let candidates = enemies.filter { $0.isAlive && $0.burnAmount > 0 && $0.bleedAmount > 0 }
                guard let foe = candidates.max(by: { $0.burnAmount < $1.burnAmount }) else { continue }
                addFloat("BOILING NILE", color: Deity.ra.tint, onEnemy: true, big: true, foe: foe.id)
                damageEnemyDirect(foe.id, min(6, foe.burnAmount), label: "Burn")
                continue
            }

            let payload = boon.payload
            nextRoundGuard += payload.guardNext
            addFloat(def.name.uppercased(), color: def.god.tint, onEnemy: false)
            if payload.shield > 0 { gainShield(payload.shield) }
            if payload.bonusShield > 0, let bonus = payload.bonusCondition,
               conditionHolds(bonus, step: nil, frozen: false, targetIndex: nil) {
                gainShield(payload.bonusShield)
            }
            if payload.heal > 0 { healPlayer(min(payload.heal, 8), label: def.god.name) }
            if payload.rerollsNext > 0 {
                nextRoundRerolls = min(1, nextRoundRerolls + payload.rerollsNext)
                addFloat("+\(payload.rerollsNext) Reroll Next", color: Theme.gold, onEnemy: false)
            }
        }
    }

    /// The first time an incoming hit is actually slipped, several gods and
    /// pairings answer once.
    private func firstEvadeRewards(attacker: EnemyState) {
        let answers = patronDodgeAnswers
        patronDodgeAnswers = []
        let target = enemies.firstIndex { $0.id == attacker.id }
        for answer in answers { land(answer.answer, god: answer.god, step: answer.step, targetIndex: target) }
        boonsOnDodge(attacker: attacker)
        guard !firstEvadeFired else { return }
        firstEvadeFired = true
        if hasUpgrade("ba_lightLanding") {
            nextRoundRerolls += 1
            addFloat("+1 Reroll Next", color: Deity.bastet.tint, onEnemy: false)
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
        boonsOnShieldAbsorb(attacker: attacker)
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

    /// One foe performs one of its telegraphed moves. A creature that spent
    /// its round on three actions comes through here three times, each on its
    /// own beat of the shared clock. Returns true when the player died.
    private func foeActs(index: Int, moveIndex: Int = 0) async -> Bool {
        var foe: EnemyState {
            get { enemies[index] }
            set { enemies[index] = newValue }
        }

        guard foe.intents.indices.contains(moveIndex) else { return false }
        let move = foe.intents[moveIndex]
        if foe.hasChainedIntents {
            lastAction = "\(foe.displayName) — \(move.comboName ?? move.name) (\(moveIndex + 1)/\(foe.intents.count))"
        } else {
            lastAction = "\(foe.displayName) uses \(move.comboName ?? move.name)!"
        }

        // The creature's action is named before it resolves, in the same shape
        // as your own, so what is being done to you is as legible as what you
        // are doing to it.
        enemies[index] = foe
        await raiseFoeSpotlight(
            foe: foe,
            move: move,
            moveIndex: moveIndex,
            strike: projectedStrike(for: foe, move: move,
                                   spendingCharge: move.damage > 0 && foe.chargeBonus > 0)
        )

        // A wind-up: it spends the round gathering itself and the blow that
        // follows is a great deal worse. That window is the whole point.
        if move.charge > 0 {
            foe.pose = .telegraph
            foe.chargeBonus = move.charge
            addFloat("WINDING UP ×\(String(format: "%.1f", move.charge))",
                     color: Theme.ember, onEnemy: true, big: true, foe: foe.id)
            lastAction = "\(foe.displayName) is winding up — break it before it lands."
            Haptics.heavy()
            try? await Task.sleep(for: .milliseconds(BattleBeat.sentence))
            resetPoses()
            return false
        }

        // Anubis's Sentence: every second turn the trial champion forgoes its
        // attack and weighs your heart instead.
        if isChampion(foe), trial?.deity == .anubis, enemyTurnCount % 2 == 0, moveIndex == 0 {
            foe.pose = .telegraph
            try? await Task.sleep(for: .milliseconds(BattleBeat.sentence))
            foe.pose = .attack
            addFloat("SENTENCE \(GameData.trialSentence)", color: Deity.anubis.tint, onEnemy: true, big: true, foe: foe.id)
            playerJudgementAmount = GameData.trialSentence
            playerJudgementPending = true
            lastAction = "\(foe.displayName) passes Sentence — it falls at the end of your next turn."
            try? await Task.sleep(for: .milliseconds(BattleBeat.sentence))
            resetPoses()
            return false
        }

        if move.block > 0 {
            foe.pose = .block
            foe.gainGuard(move.block)
            addFloat("+\(move.block) Guard", color: Theme.bronze, onEnemy: true, foe: foe.id)
            try? await Task.sleep(for: .milliseconds(BattleBeat.foeSupport))
            resetPoses()
        }
        if move.heal > 0 {
            foe.pose = .heal
            foe.hp = min(foe.def.maxHP, foe.hp + move.heal)
            addFloat("+\(move.heal)", color: Theme.forest, onEnemy: true, foe: foe.id)
            try? await Task.sleep(for: .milliseconds(BattleBeat.foeSupport))
            resetPoses()
        }

        let heat = heatDamage(for: foe)
        let attackFaces = max(1, move.faces.filter(\.isAttack).count)
        var landedAnyHit = false
        if move.damage > 0 {
            incomingAttemptedThisRound = true
            // Bleed punishes aggression: the wound opens as the creature
            // commits to the swing, once for the whole action however many
            // hits it holds, and whether or not the blow ever lands. If it
            // bleeds out here the attack never happens at all.
            if foe.bleedAmount > 0 {
                enemies[index] = foe
                let survived = payBleedBeforeAttack(foeID: foe.id)
                guard survived, let refreshed = enemies.first(where: { $0.id == foe.id }) else {
                    resetPoses()
                    return false
                }
                foe = refreshed
            }
            var total = scaledDamage(move.damage, heat: heat)
            if heat > 0 {
                addFloat("+\(heat) Heat", color: Theme.ember, onEnemy: true, foe: foe.id)
            }
            // A held wind-up is spent on the first blow that follows it.
            if foe.chargeBonus > 0 {
                total = Int(Double(total) * foe.chargeBonus)
                addFloat("UNLEASHED!", color: Theme.ember, onEnemy: true, big: true, foe: foe.id)
                foe.chargeBonus = 0
            }
            if foe.weaken > 0 {
                total = Int(Double(total) * (1 - foe.weaken))
                addFloat("Weakened!", color: Theme.frost, onEnemy: true, foe: foe.id)
                foe.weaken = 0
            }
            let perHit = total / attackFaces
            var remainder = total - perHit * attackFaces
            for hitIndex in 0..<attackFaces {
                guard foe.isAlive else { break }
                foe.pose = .telegraph
                try? await Task.sleep(for: .milliseconds(BattleBeat.telegraph))
                foe.pose = .attack
                launchShots(faces: move.faces, fromPlayer: false, foeID: foe.id)
                var hit = perHit + remainder
                remainder = 0

                // One reservation cancels one hit; a selected later hit waits.
                if consumeDodge(foeID: foe.id, moveIndex: moveIndex, hitIndex: hitIndex) {
                    playerPose = .dodge
                    addFloat("Evaded!", color: Theme.steel, onEnemy: false)
                    Haptics.light()
                    Audio.shared.play(.evade)
                    firstEvadeRewards(attacker: foe)
                    try? await Task.sleep(for: .milliseconds(BattleBeat.deflect))
                    resetPoses()
                    continue
                }

                if nextHitReduction > 0 {
                    hit = Int(ceil(Double(hit) * (1 - nextHitReduction)))
                    nextHitReduction = 0
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
                        Audio.shared.play(.block)
                    }
                    if playerShield == 0, absorbed > 0, !shieldBrokeThisRound {
                        shieldBrokeThisRound = true
                        if activeBoon("DU-14") != nil { gainDodges(1) }
                    }
                    if playerShield == 0, !shieldRebuiltThisBattle,
                       hasUpgrade("be_rebuild") || activeBoon("BE-D2") != nil {
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
                    try? await Task.sleep(for: .milliseconds(BattleBeat.deflect))
                    resetPoses()
                    continue
                }
                landedAnyHit = true
                tookHealthDamageThisEnemyTurn = true
                lostHealthThisRound = true
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
                    if (capstoneID == "ba_nineLives" || activeBoon("LG-BA") != nil), !nineLivesUsed {
                        nineLivesUsed = true
                        playerHP = 1
                        gainDodges(2)
                        primeBonus(damage: 10)
                        addFloat("NINE LIVES UNBOUND", color: Deity.bastet.tint, onEnemy: false, big: true)
                        Haptics.heavy()
                    } else {
                        finishDefeat("\(foe.displayName) puts out the disc...")
                        return true
                    }
                }
                try? await Task.sleep(for: .milliseconds(BattleBeat.strike))
                resetPoses()
            }
        }

        if move.bleedAmount > 0 && landedAnyHit {
            playerBleedAmount = max(playerBleedAmount, move.bleedAmount)
            playerBleedTurns = max(playerBleedTurns, move.bleedTurns)
            addFloat("Bleeding!", color: Theme.blood, onEnemy: false)
        }

        // Bes's trial gift: after acting, the gate rises against your turn.
        // Once a round, not once per action in a chained round.
        if isChampion(foe), trial?.deity == .bes, moveIndex == foe.intents.count - 1 {
            foe.gainGuard(8)
            addFloat("UNBROKEN GATE +8", color: Deity.bes.tint, onEnemy: true, foe: foe.id)
        }

        if playerHP <= 0 {
            finishDefeat("\(foe.displayName) puts out the disc...")
            return true
        }
        return false
    }

    /// Everything a creature can see when it decides what to do with its
    /// round — its own condition, its guard, and how close you are to going
    /// over the side.
    private func turnContext(for foe: EnemyState) -> EnemyTurnContext {
        EnemyTurnContext(
            hpFraction: foe.hpFraction,
            isBare: foe.armour <= 0,
            isWellGuarded: foe.isWellGuarded,
            playerHPFraction: playerMaxHP > 0 ? Double(playerHP) / Double(playerMaxHP) : 0,
            playerHasShield: playerShield > 0,
            isCharging: foe.chargeBonus > 0
        )
    }

    private struct StatusTick {
        let amount: Int
        let label: String
        let color: Color
    }

    /// Round end, for one creature. Bleed is absent on purpose: it bites when
    /// the creature attacks, not on the clock. Burn pays and then halves;
    /// poison pays and then grows.
    private func statusTicks(index: Int) -> [StatusTick] {
        var ticks: [StatusTick] = []
        if enemies[index].poisonAmount > 0 {
            let amount = enemies[index].poisonAmount
            ticks.append(StatusTick(amount: amount, label: "Poison", color: Theme.venom))
            enemies[index].poisonAmount = GameData.poisonAfterTick(amount)
            enemies[index].poisonTurns = 1
        }
        if enemies[index].burnAmount > 0 {
            let amount = enemies[index].burnAmount
            ticks.append(StatusTick(amount: amount, label: "Burn", color: Theme.ember))
            let left = GameData.burnAfterTick(amount)
            enemies[index].burnAmount = left
            enemies[index].burnTurns = left > 0 ? 1 : 0
        }
        return ticks
    }

    /// Bleed bites just before this creature swings, whether or not the blow
    /// it was about to throw ever lands. Returns false when the wound killed
    /// it, so the caller drops the attack entirely.
    private func payBleedBeforeAttack(foeID: UUID) -> Bool {
        guard let index = enemies.firstIndex(where: { $0.id == foeID }),
              enemies[index].isAlive, enemies[index].bleedAmount > 0 else { return true }
        let amount = enemies[index].bleedAmount
        damageEnemyDirect(foeID, amount, label: "Bleed")
        return enemies.first(where: { $0.id == foeID })?.isAlive ?? false
    }

    private func startPlayerTurn() {
        // The Echoing Staff's half-cast lands before anything else moves.
        firePendingEcho()
        if !hasLivingFoes { finishVictory(); return }

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
            primePierceBonus = 0
        }

        rerollsUsed = 0
        rerollBonus = min(1, nextRoundRerolls)
        rerollSelection = []
        selectingReroll = false
        evadeAssignments = [:]
        rollingSlotIDs = []
        preparedFocusUsed = []
        pendingEntries = []




        foeDelays = [:]
        currentBeat = 0



        // Every "first/second/third" counter in the catalogue is per round.
        attacksThisRound = 0
        guardsThisRound = 0
        soloAttacksThisRound = 0
        lastSoloFoeID = nil
        separateGuardPlayed = false
        separateEvadePlayed = false
        separateSupportPlayed = false
        nextHitReduction = 0
        shieldBrokeThisRound = false
        pendingBoonEffects = []
        pendingHealOnHit = 0
        boonsFiredThisRound = []
        lastAttackFoeID = nil
        armedOnShieldAbsorb = []
        armedOnDodge = []
        patronDodgeAnswers = []
        lostHealthThisRound = false
        incomingAttemptedThisRound = false
        boonPierceBonus = 0

        if nextRoundRerolls > 0 {
            addFloat("Extra reroll ready", color: Theme.gold, onEnemy: false)
        }
        nextRoundRerolls = 0
        if nextRoundGuard > 0 { gainShield(nextRoundGuard); nextRoundGuard = 0 }
        playOrder = []
        weldedGroups = []
        committedPlan = []
        activeStepIndex = nil
        capstoneUsedThisTurn = false
        thermalUsedThisTurn = false

        let drawn = Self.draw(count: BattleRules.handSize, from: loadoutDice, excluding: [])
        slots = drawn.map { DieSlot(die: $0, state: .idle) }
        drawnDieIDs = Set(drawn.map(\.id))
        rolled = []
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
            // Every creature plans its whole round now, reading its own
            // condition and yours: a hurt one looks for a mend, a bare one
            // raises guard, one standing over a nearly-dead enemy presses,
            // and a healthy one with time to spare winds something up.
            enemies[index].intents = EnemyPlanner.plan(
                def: enemies[index].def,
                hpFraction: fraction,
                context: turnContext(for: enemies[index])
            )
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

        // Round-start powers read the board once the previous round has fully
        // settled — Blood Reserve's risk stamina, Safe Keeping's scheduled
        // shield — and they set what "began the round with" means.
        applyRoundStartBoons()

        if reCoiled {
            withAnimation(.linear(duration: 0.5)) { shakeTrigger += 1 }
            Haptics.heavy()
        } else {
            stageAnnouncement = nil
            lastAction = "Round \(turnNumber) — six dice, one plan."
        }
        phase = .player
        resetPoses()
    }

    private func finishVictory() {
        phase = .won
        playerPose = .victory
        for index in enemies.indices { enemies[index].pose = .defeat }
        Haptics.success()
        Audio.shared.play(.death)
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
        Audio.shared.play(.death)
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

    /// Which recipe a welded run of dice actually makes, with any
    /// Chisel substitution already written onto the copy of the face that
    /// rides the combo. Returns nil when the run no longer makes anything,
    /// which is how a weld quietly dissolves if its dice change.
    ///
    /// Order inside the run never matters, so a weld is not a memory test
    /// about which die you tapped first.
    func resolveWeld(_ members: [RolledFace]) -> (combo: ComboDef, members: [RolledFace])? {
        let kinds = members.map(\.matchFace)
        for combo in comboPool where combo.faceCount == members.count {
            if combo.match(from: kinds) != nil {
                return (combo, members)
            }
            if let assisted = chiselAssistedMatch(combo, kinds: kinds) {
                var window = members
                let substitution = assisted.substitution
                if window.indices.contains(substitution.index) {
                    window[substitution.index].effectiveFace = substitution.kind
                }
                return (combo, window)
            }
        }
        return nil
    }

    /// Groups played faces into steps. Combos come only from welds you made
    /// yourself; everything else resolves as the single die it is.
    func buildPlan(from faces: [RolledFace]) -> [PlanStep] {
        var grouped: [UUID: (ComboDef, [RolledFace])] = [:]
        var consumed: Set<UUID> = []
        for ids in weldedGroups {
            let members = ids.compactMap { id in faces.first { $0.id == id } }
            guard members.count == ids.count, let first = members.first,
                  let match = resolveWeld(members) else { continue }
            grouped[first.id] = (match.combo, match.members)
            consumed.formUnion(ids.dropFirst())
        }
        var steps: [PlanStep] = []
        var focus: [RolledFace] = []
        var attacksSoFar = 0
        var momentum = momentumCarry
        var relentlessReady = relentlessActive && hasChisel("ch_relentless")
        for face in faces where !consumed.contains(face.id) {
            let group = grouped[face.id]
            let members = group?.1 ?? [face]
            let plain = PlanStep(faces: members, combo: group?.0)
            let focusDie = plain.damage > 0 && !focus.isEmpty ? focus.removeFirst() : nil
            let focusBonus = focusDie == nil ? 0 : BattleRules.focusedBonus(damage: plain.damage)
            var bonus = plain.damage > 0 ? momentumBonus(for: attacksSoFar) + momentum : 0
            if relentlessReady, group?.0.source == .weapon, plain.damage > 0 {
                bonus += GameData.relentlessDamage
                relentlessReady = false
            }
            let step = PlanStep(faces: members, combo: group?.0,
                momentumBonus: bonus, focusBonus: focusBonus, focusFaceID: focusDie?.id)
            steps.append(step)
            if step.isFocus { focus.append(face) }
            if plain.damage > 0 {
                attacksSoFar += members.filter { $0.matchFace.isAttack }.count
                momentum = 0
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
        Audio.shared.play(.chain)
        Task {
            try? await Task.sleep(for: .milliseconds(crit ? 1250 : 1000))
            guard comboFlash?.id == flash.id else { return }
            withAnimation(.easeOut(duration: 0.25)) { comboFlash = nil }
        }
    }

    // MARK: - Projectiles

    /// Sends whatever in this action actually leaves the fighter's hand across
    /// the deck. Faces swung where the fighter stands — an axe, a guard, a
    /// heal — have no flight and are simply skipped. Several shots in one
    /// action cadence so a volley reads as a volley.
    private func launchShots(
        faces: [FaceKind],
        fromPlayer: Bool,
        foeID: UUID?,
        magnitude: Int = 1,
        isCrit: Bool = false
    ) {
        guard let foeID else { return }
        let landsOn: FighterAnchorID = fromPlayer ? .foe(foeID) : .player

        // Faces swung where the fighter stands never cross the deck — an axe
        // lands where it is swung. They still whistle, and they still leave a
        // mark at the point of contact.
        for (index, face) in faces.prefix(4).enumerated() where face.projectile == nil {
            let delay = Double(index) * 0.1
            if let cue = face.launchCue { Audio.shared.play(cue, after: delay) }
            if let impact = face.impactCue { Audio.shared.play(impact, after: delay + 0.22) }
            landMark(face: face, on: landsOn, after: delay + 0.22,
                     magnitude: magnitude, isCrit: isCrit, fromPlayer: fromPlayer)
        }

        let flying = faces.compactMap { face -> ProjectileShot? in
            guard let style = face.projectile else { return nil }
            return ProjectileShot(face: face, style: style, tint: face.tint,
                                  fromPlayer: fromPlayer, foeID: foeID,
                                  magnitude: magnitude, isCrit: isCrit)
        }
        guard !flying.isEmpty else { return }
        for (index, shot) in flying.prefix(4).enumerated() {
            Task {
                try? await Task.sleep(for: .milliseconds(index * 120))
                shots.append(shot)
                // Fires as it leaves the hand, lands as it arrives.
                if let cue = shot.face.launchCue { Audio.shared.play(cue) }
                if let impact = shot.face.impactCue {
                    Audio.shared.play(impact, after: shot.style.flight)
                }
                landMark(face: shot.face, on: landsOn, after: shot.style.flight,
                         magnitude: magnitude, isCrit: isCrit, fromPlayer: fromPlayer)
                try? await Task.sleep(for: .seconds(shot.style.flight + 0.2))
                shots.removeAll { $0.id == shot.id }
            }
        }
    }

    /// Burns a mark onto whoever was struck, once the blow has had time to
    /// arrive. Every attack leaves one, so a hit can be read on the body.
    private func landMark(
        face: FaceKind,
        on target: FighterAnchorID,
        after delay: Double,
        magnitude: Int,
        isCrit: Bool,
        fromPlayer: Bool
    ) {
        guard let form = face.impactForm else { return }
        let mark = ImpactMark(
            form: form,
            tint: face.impactTint,
            target: target,
            // Blows from the player arrive travelling right; the river's own
            // come back the other way.
            angle: fromPlayer ? 0 : 180,
            isCrit: isCrit,
            magnitude: magnitude
        )
        Task {
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            impacts.append(mark)
            try? await Task.sleep(for: .seconds(mark.lifetime + 0.15))
            impacts.removeAll { $0.id == mark.id }
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
