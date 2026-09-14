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
            blurb: "Arrow tiers chain into a deeper and deeper draw. Line up Arrow I, II and III for the legendary Perfect Shot.",
            playstyle: "Balanced · ranged · precision"
        ),
        HeroClass(
            id: "warrior", name: "Warrior", title: "The Standing Wall",
            symbol: "shield.fill", accentName: "Steel",
            maxHP: 130, maxStamina: 4,
            weaponName: "Longsword", armorName: "Plate Armour",
            blurb: "Overhead and side swings mix into cleaves and the Whirlwind Crush, behind a wall of plate that reflects what it stops.",
            playstyle: "Tanky · heavy hits · momentum"
        ),
        HeroClass(
            id: "rogue", name: "Rogue", title: "Blade in the Smoke",
            symbol: "bolt.circle.fill", accentName: "Venom",
            maxHP: 82, maxStamina: 5,
            weaponName: "Twin Daggers", armorName: "Leather Armour",
            blurb: "Fast, bleeding cuts. Every escape is a face you played — dodge into a throw and a slash for the Vanishing Strike.",
            playstyle: "Fragile · fastest · bleed"
        ),
        HeroClass(
            id: "magician", name: "Magician", title: "Keeper of Runes",
            symbol: "wand.and.stars", accentName: "Arcane",
            maxHP: 88, maxStamina: 4,
            weaponName: "Magic Wand", armorName: "Robes",
            blurb: "Runes are nothing alone. Pair and triple them for Fireball, Ice Blast, Meteor and the Arcane Storm.",
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
    /// never past the class maximum on its own. Two points a turn keeps the
    /// pressure of an all-in turn affordable while chains and blessings remain
    /// the way to genuinely overcharge.
    static let staminaRecoveryPerTurn = 2

    /// Stamina a landed chain hands you for the next turn — and the only
    /// refund a combo pays. A pair gives nothing; three faces or more bank a
    /// single point. Recipes no longer pay their own printed refunds: the bar
    /// is meant to hold you to your base, and Focus and the gods' blessings are
    /// how you overcharge past it. The point rides above the cap for one turn.
    static func comboStaminaBank(faces: Int) -> Int {
        faces >= 3 ? 1 : 0
    }

    /// Crit chance a combo gains when one of its dice was carried over from a
    /// freeze — holds are best spent feeding the big chain.
    static let frozenFuelCritBonus = 0.10

    /// What a fused combo step costs: three faces cost 2, four cost 3, five
    /// cost 4. Solo faces and two-face pairs stay full price.
    static func comboStaminaCost(faces: Int) -> Int {
        faces >= 3 ? faces - 1 : faces
    }

    // MARK: - Chain power

    /// How much of a face's printed value survives when it is played alone.
    /// A single attack face is chip damage — the chain is the fight.
    static let soloAttackScale = 0.4
    /// Guards, heals and venom played alone keep almost everything, so a lone
    /// block face is a real play rather than a wasted point.
    static let soloGuardScale = 0.9

    /// Everything a combo does is multiplied by how long the chain is. Two
    /// faces pay as printed; each face past that bends the curve up hard.
    static func comboLengthScale(faces: Int) -> Double {
        switch faces {
        case ...2: 1.0
        case 3: 1.4
        case 4: 1.8
        default: 2.2
        }
    }

    /// Weight each critical face adds to the chain it feeds, on top of the
    /// chance the whole chain crits. A crit die is never wasted in a combo.
    static let critComboWeight = 0.15

    /// Total multiplier on a chain's output: its length, plus the crit dice
    /// feeding it, times the chain's own crit roll if it lands.
    static func comboOutputScale(faces: Int, critDice: Int, crit: Bool) -> Double {
        let base = comboLengthScale(faces: faces) + Double(critDice) * critComboWeight
        return crit ? base * comboCritMultiplier : base
    }

    /// Gift riders inside a chain scale far more gently than the chain itself,
    /// so a five-chain of gifted faces is strong rather than run-ending.
    static func comboRiderScale(faces: Int, critDice: Int, crit: Bool) -> Double {
        let base = 1.0 + 0.12 * Double(max(0, faces - 1)) + Double(critDice) * 0.1
        let withCrit = crit ? base * 1.35 : base
        return min(1.6, withCrit)
    }

    /// Three or more different gods in one chain: every gift rider in that
    /// chain fires at increased strength.
    static let pantheonFlourish = 1.5

    /// A god's own chain grows with the devotion behind it: the same Kindling
    /// at seven Ra hits harder than at two. +7% per point past the rung, cap
    /// 1.5 — enough to read, never enough to run away.
    static func devotionChainScale(devotion: Int, required: Int) -> Double {
        guard required > 0, devotion > required else { return 1 }
        return min(1.5, 1.0 + 0.07 * Double(devotion - required))
    }

    /// Flat damage the depth of the Duat adds to every enemy hit, offsetting
    /// the sharper player economy. The Reeds used to add nothing at all, which
    /// let the opening hours drift past as free practice — they now bite from
    /// the first real foe, so the extra stamina and the second hold are spent
    /// rather than banked. Steepens through the middle hours because gifts ride
    /// on top of ordinary faces instead of replacing them, and again in the
    /// Coils where a third hold and a wider bar exist.
    ///
    /// Only ever applied to moves that already deal damage, so the straw
    /// effigy of the first hour stays harmless.
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

    /// Every combo a class can perform: its weapon and armour set, the shared
    /// item combos, and whichever divine combos your devotion has unlocked.
    static func combos(for classID: String, devotion: [Deity: Int] = [:]) -> [ComboDef] {
        classCombos(classID) + SharedContent.combos + divineCombos(classID, devotion: devotion)
    }

    /// Divine combos available right now — signature combos need enough faces
    /// of that god in your loadout.
    static func divineCombos(_ classID: String, devotion: [Deity: Int]) -> [ComboDef] {
        DivineContent.combos(for: classID).filter { combo in
            guard combo.devotionRequired > 0 else { return true }
            guard let deity = combo.deity else { return true }
            return (devotion[deity] ?? 0) >= combo.devotionRequired
        }
    }

    /// Is this combo assemblable with the faces you currently carry, marks
    /// included? Marked faces fill both their own kind slots and their god's
    /// divine slots.
    static func isReachable(_ combo: ComboDef, loadout: Loadout?) -> Bool {
        guard let loadout else { return false }
        var owned: [(kind: FaceKind, mark: FaceMark?)] = []
        for die in loadout.allDice {
            for face in die.faces { owned.append((face.kind, face.mark)) }
        }
        return combo.required.allSatisfy { pattern in
            owned.contains { pattern.matches($0.kind, mark: $0.mark) }
        }
    }

    static func classCombos(_ classID: String) -> [ComboDef] {
        switch classID {
        case "archer": ArcherContent.combos
        case "warrior": WarriorContent.combos
        case "rogue": RogueContent.combos
        default: MagicianContent.combos
        }
    }

    /// Longest and most specific recipes are tested first so a three-face
    /// ultimate always beats the two-face combo hiding inside it.
    static func combosByPriority(for classID: String, devotion: [Deity: Int] = [:]) -> [ComboDef] {
        combos(for: classID, devotion: devotion).sorted { lhs, rhs in
            if lhs.required.count != rhs.required.count { return lhs.required.count > rhs.required.count }
            if lhs.specificity != rhs.specificity { return lhs.specificity > rhs.specificity }
            if lhs.devotionRequired != rhs.devotionRequired { return lhs.devotionRequired > rhs.devotionRequired }
            if lhs.blocksAll != rhs.blocksAll { return lhs.blocksAll }
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

    // MARK: - Devotion

    /// Burn duration and damage the gods add on top of a combo's printed value.
    static func burnBonus(_ devotion: [Deity: Int]) -> (amount: Int, turns: Int) {
        let count = devotion[.ra] ?? 0
        if count >= Devotion.deeperTier { return (2, 1) }
        if count >= Devotion.passiveTier { return (0, 1) }
        return (0, 0)
    }

    static func poisonBonus(_ devotion: [Deity: Int]) -> (amount: Int, turns: Int) {
        let count = devotion[.anubis] ?? 0
        if count >= Devotion.deeperTier { return (4, 1) }
        if count >= Devotion.passiveTier { return (2, 0) }
        return (0, 0)
    }

    /// Health Sobek returns each time you draw blood.
    static func bloodTithe(_ devotion: [Deity: Int]) -> Int {
        let count = devotion[.sobek] ?? 0
        if count >= Devotion.deeperTier { return 6 }
        if count >= Devotion.passiveTier { return 3 }
        return 0
    }

    static func openingBlock(_ devotion: [Deity: Int]) -> Int {
        let count = devotion[.bes] ?? 0
        if count >= Devotion.deeperTier { return 16 }
        if count >= Devotion.passiveTier { return 8 }
        return 0
    }

    static func openingEvades(_ devotion: [Deity: Int]) -> Int {
        let count = devotion[.bastet] ?? 0
        if count >= Devotion.deeperTier { return 2 }
        if count >= Devotion.passiveTier { return 1 }
        return 0
    }

    static func devotionCrit(_ devotion: [Deity: Int]) -> Double {
        let count = devotion[.horus] ?? 0
        if count >= Devotion.deeperTier { return 0.08 }
        if count >= Devotion.passiveTier { return 0.04 }
        return 0
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
}
