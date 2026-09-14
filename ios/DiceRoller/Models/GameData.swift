import Foundation

/// Static game content and the rules that tie the classes together.
enum GameData {
    // MARK: - Classes

    static let classes: [HeroClass] = [
        HeroClass(
            id: "archer", name: "Archer", title: "Eyes of the Greenwood",
            symbol: "arrowshape.up.circle.fill", accentName: "Ember",
            maxHP: 100, maxStamina: 4,
            weaponName: "Longbow", armorName: "Light Armour",
            blurb: "Arrow tiers stack into heavy volleys. Line up Arrow I, II and III for the legendary Perfect Shot.",
            playstyle: "Balanced · ranged · precision"
        ),
        HeroClass(
            id: "warrior", name: "Warrior", title: "The Standing Wall",
            symbol: "shield.fill", accentName: "Steel",
            maxHP: 130, maxStamina: 4,
            weaponName: "Longsword", armorName: "Plate Armour",
            blurb: "Heavy swings behind a shield that stays until it breaks. Stack Block faces and become the wall.",
            playstyle: "Tanky · heavy hits · momentum"
        ),
        HeroClass(
            id: "rogue", name: "Rogue", title: "Blade in the Smoke",
            symbol: "bolt.circle.fill", accentName: "Venom",
            maxHP: 82, maxStamina: 5,
            weaponName: "Twin Daggers", armorName: "Leather Armour",
            blurb: "Fast, bleeding cuts. Stack Evade faces to slip blows outright, then answer from the dark.",
            playstyle: "Fragile · fastest · bleed"
        ),
        HeroClass(
            id: "magician", name: "Magician", title: "Keeper of Runes",
            symbol: "wand.and.stars", accentName: "Arcane",
            maxHP: 88, maxStamina: 4,
            weaponName: "Magic Wand", armorName: "Robes",
            blurb: "Runes are nothing alone. Fold them into Fireball, Ice Blast, Meteor and the Arcane Storm.",
            playstyle: "Fragile · spell recipes · utility"
        ),
    ]

    /// Dice you may freeze in a single turn. Freezing is free — the hold is
    /// the commitment. Two holds from the very first turn, so shaping a hand is
    /// on the table immediately; from the Fire Gate onward (hour five) the night
    /// is hot enough that a third face survives it.
    static func freezesPerTurn(hour: Int) -> Int {
        hour >= Gate.fire.firstHour ? 3 : 2
    }

    /// How many dice hit the table each turn, drawn at random from the whole
    /// loadout. You carry more than you draw, so the same collection produces
    /// a different hand every turn.
    static let diceDrawCount = 6

    /// How many Breath of Ra cards a single run may grant. The turn ceiling
    /// starts at the class maximum and can reach two points above it.
    static let maxStaminaGrants = 2

    // MARK: - Turn economy

    /// Stamina the bar recovers at the start of each turn. The bar never
    /// refills outright — unspent points carry over and this tops them back up,
    /// never past the class maximum on its own.
    static let staminaRecoveryPerTurn = 2

    /// Stamina a landed chain hands you for the next turn — and the only
    /// refund a combo pays. A pair gives nothing; three faces or more bank a
    /// single point. Recipes no longer pay their own printed refunds.
    static func comboStaminaBank(faces: Int) -> Int {
        faces >= 3 ? 1 : 0
    }

    /// What a fused combo step costs: three faces cost 2, four cost 3, five
    /// cost 4. Solo faces and two-face pairs stay full price.
    static func comboStaminaCost(faces: Int) -> Int {
        faces >= 3 ? faces - 1 : faces
    }

    // MARK: - Chain power

    /// How much of a face's printed value survives when it is played alone.
    /// A single attack face is roughly two thirds of itself — workable, never
    /// the best answer.
    static let soloAttackScale = 0.65
    /// Guards, heals and venom played alone keep almost everything, so a lone
    /// block face is a real play rather than a wasted point.
    static let soloGuardScale = 0.9

    /// Weight each critical face adds to the chain it feeds. A crit die is
    /// never wasted in a combo. Chains no longer scale by length — the recipe
    /// prints its own value.
    static let critComboWeight = 0.15

    /// Total multiplier on a chain's output: the crit dice feeding it, times
    /// the chain's own crit roll if it lands.
    static func comboOutputScale(faces: Int, critDice: Int, crit: Bool) -> Double {
        let base = 1.0 + Double(critDice) * critComboWeight
        return crit ? base * comboCritMultiplier : base
    }

    /// Ceiling on evade chance — stacking Evade faces can never make you
    /// untouchable. Sixty percent is the wall.
    static let evadeCeiling = 0.6

    /// Chance a successful evade fires a "first evade this turn" reward.
    /// (Not a chance — a marker: the first roll that actually saves you.)
    static let judgementCap = 30

    /// How much harder enemies are at reading your chains now that solo
    /// attacks hit for two thirds and recipes no longer multiply by length.
    static let enemyHealthTune = 1.12

    /// Flat damage the depth of the Duat adds to every enemy hit, offsetting
    /// the sharper player economy. Only ever applied to moves that already
    /// deal damage, so the straw effigy of the first hour stays harmless.
    static func enemyDamageBonus(hour: Int) -> Int {
        hour >= 9 ? 6 : (hour >= 5 ? 4 : (hour >= 3 ? 3 : 2))
    }

    /// How much harder the later hours hit, as a multiplier on enemy damage.
    static func enemyDamageScale(hour: Int) -> Double {
        hour >= 9 ? 1.25 : (hour >= 6 ? 1.15 : 1.0)
    }

    /// How much sooner a staged boss re-coils, as a health-fraction head start.
    static let bossStageShift = 0.06

    static func heroClass(id: String) -> HeroClass {
        classes.first { $0.id == id } ?? classes[0]
    }

    // MARK: - Combos

    /// Every combo a class can perform: its weapon and armour set plus the
    /// shared item combos. Gods speak through blessings now, not recipes.
    static func combos(for classID: String) -> [ComboDef] {
        classCombos(classID) + SharedContent.combos
    }

    /// Is this combo assemblable with the faces you currently carry?
    static func isReachable(_ combo: ComboDef, loadout: Loadout?) -> Bool {
        guard let loadout else { return false }
        var owned: [FaceKind] = []
        for die in loadout.allDice {
            for face in die.faces { owned.append(face.kind) }
        }
        var pool: [FaceKind] = []
        for line in combo.required {
            for _ in 0..<line.count {
                guard let index = owned.firstIndex(where: { line.pattern.matches($0) }) else { return false }
                pool.append(owned.remove(at: index))
            }
        }
        return combo.matches(pool)
    }

    static func classCombos(_ classID: String) -> [ComboDef] {
        switch classID {
        case "archer": ArcherContent.combos
        case "warrior": WarriorContent.combos
        case "rogue": RogueContent.combos
        default: MagicianContent.combos
        }
    }

    /// Biggest and most specific recipes are tested first so a five-face
    /// signature always beats the two-face combo hiding inside it.
    static func combosByPriority(for classID: String) -> [ComboDef] {
        combos(for: classID).sorted { lhs, rhs in
            if lhs.faceCount != rhs.faceCount { return lhs.faceCount > rhs.faceCount }
            if lhs.specificity != rhs.specificity { return lhs.specificity > rhs.specificity }
            if lhs.damage != rhs.damage { return lhs.damage > rhs.damage }
            return lhs.id < rhs.id
        }
    }

    // MARK: - Offer pools

    static func diceOffers(_ classID: String, _ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch classID {
        case "archer": ArcherContent.diceOffers(rarity)
        case "warrior": WarriorContent.diceOffers(rarity)
        case "rogue": RogueContent.diceOffers(rarity)
        default: MagicianContent.diceOffers(rarity)
        }
    }

    static func faceOffers(_ classID: String, _ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch classID {
        case "archer": ArcherContent.faceOffers(rarity)
        case "warrior": WarriorContent.faceOffers(rarity)
        case "rogue": RogueContent.faceOffers(rarity)
        default: MagicianContent.faceOffers(rarity)
        }
    }

    static func imbueName(_ classID: String) -> String {
        switch classID {
        case "archer": ArcherContent.imbueName
        case "warrior": WarriorContent.imbueName
        case "rogue": RogueContent.imbueName
        default: MagicianContent.imbueName
        }
    }

    static func imbueSymbol(_ classID: String) -> String {
        switch classID {
        case "archer": ArcherContent.imbueSymbol
        case "warrior": WarriorContent.imbueSymbol
        case "rogue": RogueContent.imbueSymbol
        default: MagicianContent.imbueSymbol
        }
    }

    // MARK: - Crit rules

    /// Chance a whole combo crits, given how many of its dice landed critical.
    static func comboCritChance(critDice: Int, totalDice: Int) -> Double {
        guard critDice > 0, totalDice > 0 else { return 0 }
        if critDice >= totalDice { return 1.0 }
        switch critDice {
        case 1: return 0.35
        case 2: return 0.70
        default: return 0.85
        }
    }

    /// A critical face is worth one and a half times its normal value.
    static let faceCritMultiplier = 1.5
    /// A critical combo doubles the whole chain's output.
    static let comboCritMultiplier = 2.0

    static func scaleUp(_ value: Int, by multiplier: Double) -> Int {
        value == 0 ? 0 : Int((Double(value) * multiplier).rounded(.up))
    }

    // MARK: - Economy

    /// What a reward or shop offer is worth at a given tier.
    static func price(base: Int, rarity: Rarity) -> Int {
        Int((Double(base) * rarity.priceMultiplier / 5).rounded()) * 5
    }

    /// Gold handed out for winning a fight this deep into the run.
    static func goldReward(base: Int, progress: Double) -> Int {
        Int(Double(base) * (1.0 + progress * 0.8))
    }

    /// Winning a fight heals nothing. Wounds carry from stage to stage and the
    /// only ways back up are rests, shrines, events and your own healing faces.
    static let postBattleHeal = 0

    // MARK: - Enemy packs & armour

    /// Chance a regular battle node becomes a pack fight (2–3 foes).
    static let packChance = 0.25

    /// Within a pack, the chance it is a trio rather than a pair.
    static let packTrioChance = 0.15

    /// Health each pack member arrives with, as a fraction of its solo value —
    /// so a fight against three foes is not triple the fight against one.
    static let packHealthScale = 0.55

    /// Chance a regular fight's foe (or one pack member) spawns as an
    /// armoured elite wearing a bronze plate over its health.
    static let eliteArmourChance = 0.12

    // MARK: - Chisels of Ptah

    /// Different Chisels a single run may carry — both stay active together.
    static let chiselMaxPerRun = 2

    /// A first Chisel is guaranteed somewhere inside this in-game hour window.
    static let chiselFirstGuaranteeHour = 4

    /// Per-spoils odds of the first Chisel inside the guarantee window, before
    /// the window's back half makes it certain.
    static let chiselEarlyChance = 0.14

    /// Per-spoils odds of the first Chisel after the window has closed.
    static let chiselLateChance = 0.05

    /// Per-spoils odds of a second Chisel once one is carried — a small share
    /// of runs ever see one.
    static let chiselSecondChance = 0.07

    /// Twin Bowstring: each of the two hits, as a fraction of the combo.
    static let twinSplitFraction = 0.6

    /// Siege Draw: the overdraw's stamina cost, damage bonus and pierce.
    static let siegeStaminaCost = 1
    static let siegeDamageBonus = 0.4
    static let siegePierce = 0.5

    /// Crescent Edge: the splash a second foe takes, as a fraction.
    static let crescentFraction = 0.35

    /// Relentless Advance: stamina shaved off next turn's first weapon combo.
    static let relentlessDiscount = 1

    /// Counterweight: shield spend ceiling and damage per point spent.
    static let counterweightMaxSpend = 10
    static let counterweightDamagePerPoint = 2

    /// Assassin's Commitment: the evade charge it burns and what it buys.
    static let assassinEvadeCost = 0.15
    static let assassinDamageBonus = 0.4
    static let assassinPierce = 0.5

    /// Echoing Staff: the extra stamina and the echo's output fraction.
    static let echoStaminaCost = 1
    static let echoScale = 0.5

    // MARK: - Divine Trials

    /// Chance an eligible ordinary fight is secretly a god's Trial.
    static let trialChance = 0.12

    /// Anubis's Sentence: the judgement a trial champion stores.
    static let trialSentence = 6
}
