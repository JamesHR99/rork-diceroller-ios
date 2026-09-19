import Foundation

/// Static game content and the rules that tie the classes together.
enum GameData {
    // MARK: - Classes

    static let classes: [HeroClass] = [
        HeroClass(
            id: "archer", name: "Archer", title: "Eyes of the Greenwood",
            symbol: "arrowshape.up.circle.fill", accentName: "Ember",
            maxHP: 100,
            weaponName: "Longbow", armorName: "Light Armour",
            blurb: "Arrow tiers stack into heavy volleys. Line up Arrow I, II and III for the legendary Perfect Shot.",
            playstyle: "Balanced · ranged · precision",

            battleIdentity: "Quick enough to answer, patient enough to line up the volley"
        ),
        HeroClass(
            id: "warrior", name: "Warrior", title: "The Standing Wall",
            symbol: "shield.fill", accentName: "Steel",
            maxHP: 130,
            weaponName: "Longsword", armorName: "Plate Armour",
            blurb: "Heavy swings build momentum. Carry up to 8 unused guard into the next round.",
            playstyle: "Tanky · heavy hits · momentum",

            battleIdentity: "Build momentum and carry up to 8 guard between rounds"
        ),
        HeroClass(
            id: "rogue", name: "Rogue", title: "Blade in the Smoke",
            symbol: "bolt.circle.fill", accentName: "Venom",
            maxHP: 82,
            weaponName: "Twin Daggers", armorName: "Leather Armour",
            blurb: "Fast, bleeding cuts with venom on the blades. Stack Evade faces to slip blows outright, then answer from the dark.",
            playstyle: "Fragile · precise dodges · bleed and venom",

            battleIdentity: "Bleed, venom and chosen dodges keep fragile blades alive"
        ),
        HeroClass(
            id: "magician", name: "Magician", title: "Keeper of Runes",
            symbol: "wand.and.stars", accentName: "Arcane",
            maxHP: 88,
            weaponName: "Magic Wand", armorName: "Robes",
            blurb: "No shield face, no evade, no bandage — every guard, escape and mend has to be spelled out of runes. Thirty spells live in six syllables.",
            playstyle: "Fragile · pure spellcraft · everything is a recipe",

            battleIdentity: "Weave damage, recovery and defence from the same runes"
        ),
    ]

    /// How many dice the collection holds: five weapon, three armour.
    static let ownedWeaponDice = 5
    static let ownedArmourDice = 3
    static let ownedDiceTotal = ownedWeaponDice + ownedArmourDice

    /// How many dice hit the table each turn, drawn at random from the whole
    /// loadout. You carry more than you draw, so the same collection produces
    /// a different hand every turn.
    static let diceDrawCount = 6

    /// Odds that a god brings one of their legendaries to a meeting at all.
    /// A legendary is found the same way as any other boon — it is simply a
    /// rare sight, so most nights never see one.
    static let legendaryOfferChance = 0.07

    // MARK: - Round economy

    /// The longest recipe in the game, which is also the widest weld the
    /// planner will ever offer.
    static let maxComboFaces = 5

    /// Number of physical dice consumed by a recipe.
    static func comboDiceCount(faces: Int) -> Int {
        max(1, faces)
    }

    // MARK: - Chain power

    /// How much of a face's printed value survives when it is played alone.
    /// A single attack face is 85% of its printed value — useful on its own and
    /// available for flexible targeting.
    static let soloAttackScale = 0.85
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

    /// The most Judgement a fighter may have stored on the scales at once.
    /// Nothing tips it on a timer: only a primary attack combo of
    /// `judgementReleaseIngredients` dice or more releases it.
    static let judgementCap = 30

    /// How many dice an attack combo must consume before it can release a
    /// stored verdict. Anubis rewards building, not waiting.
    static let judgementReleaseIngredients = 3

    /// A heavy verdict lands harder than a light one. Every whole step of
    /// stored Judgement past the first adds a share of itself again, so
    /// stacking the scales high is worth more than detonating early.
    static let judgementScaleStep = 5
    static let judgementScalePerStep = 0.2

    /// What a stored verdict actually takes when it falls: the pile, plus a
    /// fifth of itself again for every full \(judgementScaleStep) on the
    /// scales beyond the first.
    static func judgementVerdict(stored: Int) -> Int {
        guard stored > 0 else { return 0 }
        let steps = max(0, stored / judgementScaleStep - 1)
        guard steps > 0 else { return stored }
        return Int((Double(stored) * (1 + Double(steps) * judgementScalePerStep)).rounded())
    }

    /// How much of a verdict is the heavy-scales bonus rather than the pile
    /// itself — printed beside the burst so the scaling is visible.
    static func judgementBonus(stored: Int) -> Int {
        max(0, judgementVerdict(stored: stored) - stored)
    }

    /// The most a single burn tick may ever take.
    static let burnTickCap = 12

    // MARK: - Status ceilings

    /// Burn stacks up and halves after it bites, so it is fast pressure that
    /// fades rather than a slow drip.
    static let burnStackCap = 12

    /// Bleed never adds: the strongest wound on the target stands.
    static let bleedStackCap = 10

    /// Poison stacks and then grows by one on its own every round, so it
    /// strangles slowly instead of expiring.
    static let poisonStackCap = 8
    static let poisonGrowth = 1

    /// Weaken can never take more than half an attack away.
    static let weakenCeiling = 0.5

    /// Burn halves at the natural round-end tick, rounding down.
    static func burnAfterTick(_ amount: Int) -> Int {
        amount / 2
    }

    /// Poison grows after it bites, up to its ceiling.
    static func poisonAfterTick(_ amount: Int) -> Int {
        min(poisonStackCap, amount + poisonGrowth)
    }

    /// How much harder enemies are at reading your chains now that solo
    /// attacks hit for two thirds and recipes no longer multiply by length.
    static let enemyHealthTune = 1.35

    /// Flat damage the depth of the PharaohSWager adds to every enemy hit, offsetting
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
    /// chains every class shares. Gods speak through blessings now, not recipes.
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

    // MARK: - Enemy rounds

    /// What an ordinary creature can spend in one round, and what a
    /// serpent-lord can. A jab costs 1 and a three-face recipe 3, so three
    /// points buys one heavy recipe or a guard and a couple of quick cuts,
    /// while a serpent-lord can reliably do two real things a round.
    static let enemyRoundStamina = 3
    static let bossRoundStamina = 5

    /// The most separate actions any creature may take in one round, however

    static let enemyMaxActionsPerRound = 3

    /// What each blow in a chained round is worth. A creature that swings
    /// three times hits for less each time than one that commits everything
    /// to a single blow — more chances to block or slip, less behind each.
    ///
    /// The totals climb only slightly (one action 100%, two 116%, three 126%)
    /// because the real change is the shape of the round, not its weight: a
    /// blow you can answer is worth more to the fight than a bigger number.
    static func enemyChainScale(actions: Int) -> Double {
        switch actions {
        case ...1: return 1.0
        case 2: return 0.58
        default: return 0.42
        }
    }

    /// How much a wind-up multiplies the blow that follows it, when a
    /// creature's move does not author its own figure.
    static let enemyChargeDefault = 1.8

    // MARK: - Enemy situational weights

    /// How much more likely a creature is to mend when it is badly hurt, and
    /// how much less when it is nearly untouched.
    static let enemyHealUrgentBoost = 3.4
    static let enemyHealHealthyDamp = 0.15
    /// Health fraction under which a creature starts looking for a mend.
    static let enemyHurtThreshold = 0.45
    /// Health fraction over which mending is close to a wasted round.
    static let enemyHealthyThreshold = 0.8

    /// How much more likely a bare creature is to raise guard, and how much
    /// less when it is already standing behind a deep one.
    static let enemyGuardBareBoost = 2.2
    static let enemyGuardStackedDamp = 0.2

    /// How much more likely a creature is to go for the throat when you are
    /// nearly out, and the health fraction that counts as nearly out.
    static let enemyFinisherBoost = 2.6
    static let enemyFinisherThreshold = 0.3

    /// How much more likely a heavy blow is when you are standing bare, with
    /// no shield to eat it.
    static let enemyUnguardedBoost = 1.5

    /// How much more likely a creature is to wind up when it is healthy,
    /// unhurried and you are not about to die — and how much less otherwise.
    static let enemyChargeBoost = 2.0
    static let enemyChargeDamp = 0.12

    // MARK: - Chisels of Ptah

    /// Different Chisels a single run may carry — both stay active together.
    static let chiselMaxPerRun = 2

    /// A first Chisel is guaranteed somewhere inside this in-game hour window.
    /// Ptah only ever works at the end of a fight, and when he comes he takes
    /// the whole reward, so these are odds per won encounter.
    static let chiselFirstGuaranteeHour = 4

    /// Odds of the first Chisel inside the guarantee window, before the
    /// window's back half makes it certain.
    static let chiselEarlyChance = 0.14

    /// Odds of the first Chisel after the window has closed.
    static let chiselLateChance = 0.05

    /// Odds of a second Chisel once one is carried — a small share of runs
    /// ever see one.
    static let chiselSecondChance = 0.07

    /// Twin Bowstring: each of the two hits, as a fraction of the combo.
    static let twinSplitFraction = 0.6

    static let siegeRerollCost = 1
    static let siegeDamageBonus = 0.4
    static let siegePierce = 0.5

    /// Crescent Edge: the splash a second foe takes, as a fraction.
    static let crescentFraction = 0.35

    static let relentlessDamage = 6

    /// Counterweight: shield spend ceiling and damage per point spent.
    static let counterweightMaxSpend = 10
    static let counterweightDamagePerPoint = 2

    /// Assassin's Commitment: the evade charge it burns and what it buys.
    static let assassinDodgeCost = 1
    static let assassinDamageBonus = 0.4
    static let assassinPierce = 0.5

    static let echoRerollCost = 1
    static let echoScale = 0.5

    // MARK: - Divine Trials

    /// Chance an eligible ordinary fight is secretly a god's Trial.
    static let trialChance = 0.12

    /// Anubis's Sentence: the judgement a trial champion stores.
    static let trialSentence = 6
}

