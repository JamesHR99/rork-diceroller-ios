import Foundation

/// The complete god catalogue: 60 regular powers (ten per god), 15 duos and
/// six legendary evolutions. Every card's text and its Common level 1/2/3
/// values are transcribed from the design guide — the printed text is the
/// contract, so `%V` is substituted with the live value at the card's own
/// rarity and level rather than being recomputed anywhere else.
enum GodCatalog {
    /// Every card in the game, in catalogue order.
    static let all: [GodBoonDef] = ra + sobek + anubis + bes + horus + bastet + duos + legendaries

    private static let index: [String: GodBoonDef] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    static func boon(_ id: String) -> GodBoonDef? { index[id] }

    /// The everyday 60, which are what god meetings offer.
    static var regulars: [GodBoonDef] { all.filter { $0.kind == .regular } }

    static func regulars(of god: Deity) -> [GodBoonDef] {
        regulars.filter { $0.god == god }
    }

    static func duo(_ id: String) -> GodBoonDef? {
        duos.first { $0.id == id }
    }

    /// The legendary that evolves this regular boon, if one exists.
    static func legendary(evolving id: String) -> GodBoonDef? {
        legendaries.first { $0.evolves == id }
    }

    /// The duos a god may bring. A duo belongs to both gods who made it, so
    /// either of them can be the one holding the card.
    static func duos(of god: Deity) -> [GodBoonDef] {
        duos.filter { $0.offeringGods.contains(god) }
    }

    /// The legendaries a god may bring — their own, offered as a rare find
    /// rather than earned by assembling its source first.
    static func legendaries(of god: Deity) -> [GodBoonDef] {
        legendaries.filter { $0.god == god }
    }

    // MARK: - Ra — fire, commitment and rising power

    static let ra: [GodBoonDef] = [
        GodBoonDef(
            id: "RA-A1",
            god: .ra,
            slot: .attack,
            name: "Solar Flare",
            effect: "First 4–6 die Attack each round: +%V damage and 4 Burn on primary.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstLargeCombo,
            payload: BoonPayload(burn: 4),
            scales: .flatDamage,
            values: [6, 8, 10],
            minimumDice: 4
        ),
        GodBoonDef(
            id: "RA-A2",
            god: .ra,
            slot: .attack,
            name: "Scorching Sequence",
            effect: "First Attack: %V Burn. Second Attack adds 2 Burn if it targets that same living foe.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttack,
            payload: BoonPayload(),
            scales: .burn,
            values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-A3",
            god: .ra,
            slot: .attack,
            name: "Sun's Wrath",
            effect: "First Prepared Attack: +%V damage and 2 Burn.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(burn: 2),
            scales: .flatDamage,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "RA-A4",
            god: .ra,
            slot: .attack,
            name: "Noon Spear",
            effect: "First Focus-enhanced Attack: +%V percentage points Pierce and 3 Burn.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstFocusedAttack,
            payload: BoonPayload(burn: 3),
            scales: .pierce,
            values: [20, 25, 30]
        ),
        GodBoonDef(
            id: "RA-A5",
            god: .ra,
            slot: .attack,
            name: "Sun's Edge",
            effect: "All Attacks against an already Burning primary target gain +%V% damage. Each Attack adds 1 Burn per ingredient, stored charge maximum 2 per action.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .everyAttack,
            payload: BoonPayload(burn: 1, perIngredient: true, perIngredientCap: 3, bonusCondition: .targetBurning),
            scales: .bonusPercent,
            values: [10, 15, 20]
        ),
        GodBoonDef(
            id: "RA-D1",
            god: .ra,
            slot: .defence,
            name: "Solar Guard",
            effect: "First Guard action: +%V Shield. Arm the next hit absorbed by shield this round to apply 3 Burn to its attacker.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstGuard,
            payload: BoonPayload(burn: 3),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "RA-D2",
            god: .ra,
            slot: .defence,
            name: "Cinder Step",
            effect: "First Evade action arms the next successful Dodge this round to apply %V Burn to its attacker.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(),
            scales: .burn,
            values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-D3",
            god: .ra,
            slot: .defence,
            name: "Sunset Shelter",
            effect: "First Guard of 3+ dice: +%V Shield; arm the next shield-absorbed hit this round to apply 2 Burn to all living foes.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstGuard,
            payload: BoonPayload(burn: 2),
            scales: .shield,
            values: [6, 8, 10],
            minimumDice: 3
        ),
        GodBoonDef(
            id: "RA-U1",
            god: .ra,
            slot: .utility,
            name: "Dawn Breath",
            effect: "Start each encounter with 8 Shield. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .encounterStart,
            payload: BoonPayload(shield: 8)
        ),
        GodBoonDef(
            id: "RA-U2",
            god: .ra,
            slot: .utility,
            name: "Banked Embers",
            effect: "Resolve a 4–6 die Attack to gain one extra reroll pass next round, once per round; stored charge maximum 2. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .firstLargeCombo,
            payload: BoonPayload(rerollsNext: 1),
            minimumDice: 4
        ),
    ]

    // MARK: - Sobek — wounds, pressure and survival

    static let sobek: [GodBoonDef] = [
        GodBoonDef(
            id: "SO-A1",
            god: .sobek,
            slot: .attack,
            name: "Twin Fangs",
            effect: "First two-die Attack: +%V damage and 3 Bleed.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstTwoFaceCombo,
            payload: BoonPayload(bleed: 3),
            scales: .flatDamage,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "SO-A2",
            god: .sobek,
            slot: .attack,
            name: "Blood Scent",
            effect: "First Attack applies 3 Bleed. All Attacks against an already Bleeding primary target gain +%V% damage.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .everyAttack,
            payload: BoonPayload(bleed: 3, bonusCondition: .targetBleeding),
            scales: .bonusPercent,
            values: [10, 15, 20]
        ),
        GodBoonDef(
            id: "SO-A3",
            god: .sobek,
            slot: .attack,
            name: "Death Grip",
            effect: "First Prepared Attack: +%V damage and 2 Poison.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(poison: 2),
            scales: .flatDamage,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "SO-A4",
            god: .sobek,
            slot: .attack,
            name: "Feeding Frenzy",
            effect: "Second Attack applies 3 Bleed; if its native direct damage removes any HP, heal %V.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .secondAttack,
            payload: BoonPayload(bleed: 3),
            scales: .heal,
            values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-A5",
            god: .sobek,
            slot: .attack,
            name: "Jaws of the Nile",
            effect: "First 3+ die Attack applies %V Bleed. If the target was already Bleeding, pay one early Bleed tick after application.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstLargeCombo,
            payload: BoonPayload(),
            scales: .bleed,
            values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "SO-D1",
            god: .sobek,
            slot: .defence,
            name: "Crocodile Armour",
            effect: "First Guard: +%V Shield; arm the next shield-absorbed hit this round to apply 3 Bleed to its attacker.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstGuard,
            payload: BoonPayload(bleed: 3),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "SO-D2",
            god: .sobek,
            slot: .defence,
            name: "River Slip",
            effect: "First Evade arms the next successful Dodge this round to heal %V.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(),
            scales: .heal,
            values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-D3",
            god: .sobek,
            slot: .defence,
            name: "Blood Shelter",
            effect: "First Prepared Guard: +%V Shield, and 3 healing.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstKeptGuard,
            payload: BoonPayload(heal: 3),
            scales: .shield,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "SO-U1",
            god: .sobek,
            slot: .utility,
            name: "Blood Reserve",
            effect: "Start a round at half HP or less to gain 6 Shield. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .roundStart,
            payload: BoonPayload(shield: 6),
            requires: .healthAtHalf
        ),
        GodBoonDef(
            id: "SO-U2",
            god: .sobek,
            slot: .utility,
            name: "Patient Hunter",
            effect: "First Prepared action each encounter heals 4 and grants 6 Shield. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .firstKeptAction,
            payload: BoonPayload(shield: 6, heal: 4)
        ),
    ]

    // MARK: - Anubis — sequences, preservation and timed verdicts

    static let anubis: [GodBoonDef] = [
        GodBoonDef(
            id: "AN-A1",
            god: .anubis,
            slot: .attack,
            name: "Scales of War",
            effect: "First Attack after a separate Guard this round: add %V Judgement and gain 4 Shield.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttackAfterGuard,
            payload: BoonPayload(shield: 4),
            scales: .judgement,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-A2",
            god: .anubis,
            slot: .attack,
            name: "Second Reading",
            effect: "Every Attack adds %V Judgement per ingredient, maximum 12 per action.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .everyAttack,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 12),
            scales: .judgement,
            values: [1, 2, 3]
        ),
        GodBoonDef(
            id: "AN-A3",
            god: .anubis,
            slot: .attack,
            name: "Sealed Fate",
            effect: "First Prepared Attack: +%V damage and 5 Judgement.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(judgement: 5),
            scales: .flatDamage,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "AN-A4",
            god: .anubis,
            slot: .attack,
            name: "Final Sentence",
            effect: "First 3+ die Attack: +20 percentage points Pierce and %V Judgement before its normal release.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 20),
            scales: .judgement,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-A5",
            god: .anubis,
            slot: .attack,
            name: "Borrowed Time",
            effect: "First Attack against a target already below half HP: +%V damage and 4 Judgement if it survives.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttackOnWounded,
            payload: BoonPayload(judgement: 4),
            scales: .flatDamage,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-D1",
            god: .anubis,
            slot: .defence,
            name: "Tomb Ward",
            effect: "First Guard: +%V Shield; arm the next shield-absorbed hit this round to apply 5 Judgement to its attacker.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstGuard,
            payload: BoonPayload(judgement: 5),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "AN-D2",
            god: .anubis,
            slot: .defence,
            name: "Passing Shadow",
            effect: "First Evade arms the next successful Dodge this round to add %V Judgement to its attacker.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(),
            scales: .judgement,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "AN-D3",
            god: .anubis,
            slot: .defence,
            name: "Burial Cloth",
            effect: "First Prepared Guard: +%V Shield and cleanse one status.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstKeptGuard,
            payload: BoonPayload(cleansesSelf: true),
            scales: .shield,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "AN-U1",
            god: .anubis,
            slot: .utility,
            name: "Last Measure",
            effect: "Resolve actions using all six physical dice this round to earn one extra reroll pass next round, stored charge maximum 2. Wind-up alone is insufficient. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .roundEnd,
            payload: BoonPayload(rerollsNext: 1),
            requires: .usedAllDice
        ),
        GodBoonDef(
            id: "AN-U2",
            god: .anubis,
            slot: .utility,
            name: "Preserved Moment",
            effect: "Once each encounter, after rolling, select one result to become Prepared without spending a reroll. It does not change its face or crit. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .atCommitment,
            payload: BoonPayload()
        ),
    ]

    // MARK: - Bes — protection that lets you keep fighting

    static let bes: [GodBoonDef] = [
        GodBoonDef(
            id: "BE-A1",
            god: .bes,
            slot: .attack,
            name: "Sheltering Blow",
            effect: "Every Attack grants %V Shield per ingredient, maximum 8 Shield per action. If the hero had at least 8 Shield before the action, gain +10% damage.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .everyAttack,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 8, bonusCondition: .hadEightShield, bonusPercentDamage: 10),
            scales: .shield,
            values: [1, 2, 3]
        ),
        GodBoonDef(
            id: "BE-A2",
            god: .bes,
            slot: .attack,
            name: "Counter-Swing",
            effect: "First Attack after a separate Guard this round: +%V damage and 4 Shield.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttackAfterGuard,
            payload: BoonPayload(shield: 4),
            scales: .flatDamage,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-A3",
            god: .bes,
            slot: .attack,
            name: "Guardian's Hand",
            effect: "First Prepared Attack: +%V damage and 5 Shield.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(shield: 5),
            scales: .flatDamage,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "BE-A4",
            god: .bes,
            slot: .attack,
            name: "Stalwart Advance",
            effect: "First two-die Attack: +%V damage and 20 Weaken on primary.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstTwoFaceCombo,
            payload: BoonPayload(weakenPercent: 20),
            scales: .flatDamage,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BE-A5",
            god: .bes,
            slot: .attack,
            name: "Unbroken Rhythm",
            effect: "Second Attack: +%V damage and 4 Shield.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .secondAttack,
            payload: BoonPayload(shield: 4),
            scales: .flatDamage,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "BE-D1",
            god: .bes,
            slot: .defence,
            name: "The Stout Door",
            effect: "Every Guard action gains %V Shield per ingredient, maximum 12 Shield per action. Applies to native Frost/Channel/Life Guards as well as Block.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .everyGuard,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 12),
            scales: .shield,
            values: [2, 3, 4]
        ),
        GodBoonDef(
            id: "BE-D2",
            god: .bes,
            slot: .defence,
            name: "Rebuild the Wall",
            effect: "Encounter start: %V Shield. First time shield breaks this encounter, gain 8 Shield after that hit; it cannot undo HP damage.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .encounterStart,
            payload: BoonPayload(),
            scales: .shield,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-D3",
            god: .bes,
            slot: .defence,
            name: "Steady Footing",
            effect: "First Evade action: +%V Shield.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BE-U1",
            god: .bes,
            slot: .utility,
            name: "Hearth Breath",
            effect: "End a round with at least 8 Shield to start the next with 6 Shield in addition to native carry, shield cap 100. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .roundEnd,
            payload: BoonPayload(guardNext: 6),
            requires: .endedWithEightShield
        ),
        GodBoonDef(
            id: "BE-U2",
            god: .bes,
            slot: .utility,
            name: "Safe Keeping",
            effect: "First Prepared Guard each round gains 5 Shield. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .firstKeptGuard,
            payload: BoonPayload(shield: 5)
        ),
    ]

    // MARK: - Horus — precision, timing and prepared power

    static let horus: [GodBoonDef] = [
        GodBoonDef(
            id: "HO-A1",
            god: .horus,
            slot: .attack,
            name: "Falcon's Eye",
            effect: "First Prepared Attack: +%V% damage and +20 percentage points Pierce.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(pierce: 20),
            scales: .percentDamage,
            values: [15, 20, 25]
        ),
        GodBoonDef(
            id: "HO-A2",
            god: .horus,
            slot: .attack,
            name: "Keen Edge",
            effect: "First Attack containing a critical ingredient: +%V damage and +20 percentage points Pierce.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .everyAttack,
            payload: BoonPayload(pierce: 20),
            scales: .flatDamage,
            values: [5, 7, 9],
            requires: .hasCritIngredient
        ),
        GodBoonDef(
            id: "HO-A3",
            god: .horus,
            slot: .attack,
            name: "Patient Aim",
            effect: "First 4–6 die Attack: +%V% damage and +30 percentage points Pierce.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 30),
            scales: .percentDamage,
            values: [15, 20, 25],
            minimumDice: 4
        ),
        GodBoonDef(
            id: "HO-A4",
            god: .horus,
            slot: .attack,
            name: "Watchful Strike",
            effect: "First Attack after a separate Guard or Support this round: +%V% damage; apply 25 Marked after damage.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttackAfterSupport,
            payload: BoonPayload(markPercent: 25),
            scales: .percentDamage,
            values: [10, 15, 20]
        ),
        GodBoonDef(
            id: "HO-A5",
            god: .horus,
            slot: .attack,
            name: "High Flight",
            effect: "First Focus-enhanced Attack: +%V% damage and +20 percentage points Pierce.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstFocusedAttack,
            payload: BoonPayload(pierce: 20),
            scales: .percentDamage,
            values: [15, 20, 25]
        ),
        GodBoonDef(
            id: "HO-D1",
            god: .horus,
            slot: .defence,
            name: "Watchful Guard",
            effect: "First Prepared Guard: +%V Shield and arm 20% reduction on the next non-dodged enemy damage action, expiring this round.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstKeptGuard,
            payload: BoonPayload(),
            scales: .shield,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "HO-D2",
            god: .horus,
            slot: .defence,
            name: "Feather Step",
            effect: "First Evade: +%V Shield; if Prepared, gain another 3 Shield.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .usesKeptFace, bonusShield: 3),
            scales: .shield,
            values: [3, 5, 7]
        ),
        GodBoonDef(
            id: "HO-D3",
            god: .horus,
            slot: .defence,
            name: "High Perch",
            effect: "First Guard: +%V Shield. If it contains a critical ingredient, mark one chosen foe 20 Marked.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstGuard,
            payload: BoonPayload(),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "HO-U1",
            god: .horus,
            slot: .utility,
            name: "Thermal",
            effect: "First Prepared action each round primes +15% damage for the next separate Attack; expires at end of next round. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .firstKeptAction,
            payload: BoonPayload()
        ),
        GodBoonDef(
            id: "HO-U2",
            god: .horus,
            slot: .utility,
            name: "Perfect Timing",
            effect: "Once per encounter, turn one rolled result critical before commitment. Uses the same deterministic contribution rule and does not reroll the face. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .atCommitment,
            payload: BoonPayload()
        ),
    ]

    // MARK: - Bastet — short techniques, evasion and movement

    static let bastet: [GodBoonDef] = [
        GodBoonDef(
            id: "BA-A1",
            god: .bastet,
            slot: .attack,
            name: "Pounce",
            effect: "First two-die Attack: +%V damage and 1 Dodge.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstTwoFaceCombo,
            payload: BoonPayload(dodgeCharges: 1),
            scales: .flatDamage,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BA-A2",
            god: .bastet,
            slot: .attack,
            name: "Quick Claws",
            effect: "First two solo Attacks each gain +%V damage.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstTwoSoloAttacks,
            payload: BoonPayload(),
            scales: .flatDamage,
            values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "BA-A3",
            god: .bastet,
            slot: .attack,
            name: "Silent Approach",
            effect: "First Prepared Attack: +%V damage; apply 20 Marked after damage.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstKeptAttack,
            payload: BoonPayload(markPercent: 20),
            scales: .flatDamage,
            values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "BA-A4",
            god: .bastet,
            slot: .attack,
            name: "Dancing Blades",
            effect: "First Attack after a separate Evade this round: +%V damage and +30 percentage points Pierce.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .firstAttackAfterEvade,
            payload: BoonPayload(pierce: 30),
            scales: .flatDamage,
            values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BA-A5",
            god: .bastet,
            slot: .attack,
            name: "Ninefold Flurry",
            effect: "Third Attack action this round: +%V damage and 1 Dodge. One six-die group counts as one action.",
            function: "Same-face attack",
            kind: .regular,
            trigger: .thirdAttack,
            payload: BoonPayload(dodgeCharges: 1),
            scales: .flatDamage,
            values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "BA-D1",
            god: .bastet,
            slot: .defence,
            name: "Hunting Step",
            effect: "First Evade: +%V Shield. If it uses exactly two dice, gain another 3 Shield.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusShield: 3),
            scales: .shield,
            values: [3, 5, 7]
        ),
        GodBoonDef(
            id: "BA-D2",
            god: .bastet,
            slot: .defence,
            name: "Light Landing",
            effect: "First Evade arms the next successful Dodge this round to grant %V Shield.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .firstEvade,
            payload: BoonPayload(),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BA-D3",
            god: .bastet,
            slot: .defence,
            name: "Unscathed",
            effect: "Encounter start: %V Shield. If at least one enemy strike was attempted and the hero lost no HP from any source that round, begin the next with 4 Shield.",
            function: "Same-face defence",
            kind: .regular,
            trigger: .encounterStart,
            payload: BoonPayload(),
            scales: .shield,
            values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BA-U1",
            god: .bastet,
            slot: .utility,
            name: "Light Feet",
            effect: "First successful Dodge each round earns one extra reroll pass next round, stored charge maximum 2. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .onDodge,
            payload: BoonPayload(rerollsNext: 1)
        ),
        GodBoonDef(
            id: "BA-U2",
            god: .bastet,
            slot: .utility,
            name: "Slip Through",
            effect: "First solo Attack each round gains +4 damage. Combos do not consume the benefit. Fixed.",
            function: "Same-face utility",
            kind: .regular,
            trigger: .firstSoloAttack,
            payload: BoonPayload(flatDamage: 4)
        ),
    ]

    // MARK: - The fifteen duos

    static let duos: [GodBoonDef] = [
        GodBoonDef(
            id: "DU-01", god: .ra, slot: .attack, name: "Boiling Nile",
            effect: "At round end before normal ticks, the living foe with both Burn and Bleed and the greatest Burn takes extra HP damage equal to Burn, maximum 6. Ties use visible order.",
            function: "Ra + Sobek", kind: .duo, trigger: .roundEnd,
            sources: [.raBurn, .sobekBleed]
        ),
        GodBoonDef(
            id: "DU-02", god: .ra, slot: .attack, name: "Funeral Pyre",
            effect: "First released Judgement on a Burning foe deals additional HP damage equal to twice its current Burn, maximum 10.",
            function: "Ra + Anubis", kind: .duo, trigger: .everyAttack,
            sources: [.raBurn, .anubisJudgement]
        ),
        GodBoonDef(
            id: "DU-03", god: .ra, slot: .defence, name: "Forge Song",
            effect: "First hit absorbed by shield applies 3 Burn to its attacker.",
            function: "Ra + Bes", kind: .duo, trigger: .onShieldAbsorb,
            payload: BoonPayload(burn: 3), sources: [.raBurn, .besShield]
        ),
        GodBoonDef(
            id: "DU-04", god: .ra, slot: .attack, name: "Sunstrike",
            effect: "First Prepared Attack: +6 damage. If primary was already Burning, add 3 Burn after damage.",
            function: "Ra + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(flatDamage: 6, bonusCondition: .targetBurning, burnBonus: 3),

            sources: [.raBurn, .horusKept]
        ),
        GodBoonDef(
            id: "DU-05", god: .ra, slot: .defence, name: "Dancing Flame",
            effect: "First successful Dodge applies 3 Burn to its attacker and grants 3 Shield.",
            function: "Ra + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(burn: 3, shield: 3), sources: [.raBurn, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-06", god: .sobek, slot: .utility, name: "The Crossing",
            effect: "First Judgement release on an already Bleeding foe heals 3 and earns one reroll pass next round, stored charge maximum 2. Evaluate Bleed before the verdict even if it kills.",
            function: "Sobek + Anubis", kind: .duo, trigger: .everyAttack,
            payload: BoonPayload(heal: 3, rerollsNext: 1), sources: [.sobekBleed, .anubisJudgement]
        ),
        GodBoonDef(
            id: "DU-07", god: .sobek, slot: .defence, name: "Crocodile Hide",
            effect: "First positive healing event from a native action, item or regular/evolved boon grants 5 Shield. Overheal, Regen and other duos do not trigger it.",
            function: "Sobek + Bes", kind: .duo, trigger: .roundStart,
            payload: BoonPayload(shield: 5), sources: [.sobekHealing, .besShield]
        ),
        GodBoonDef(
            id: "DU-08", god: .sobek, slot: .attack, name: "Reed and Sky",
            effect: "First Prepared Attack against an already Bleeding primary gains +20% damage and +20 percentage points Pierce.",
            function: "Sobek + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(percentDamage: 20, pierce: 20), requires: .targetBleeding, sources: [.sobekBleed, .horusKept]
        ),
        GodBoonDef(
            id: "DU-09", god: .sobek, slot: .defence, name: "Death Roll",
            effect: "First Dodge against a Bleeding attacker pays one early Bleed tick on it and heals 2.",
            function: "Sobek + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(heal: 2), sources: [.sobekBleed, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-10", god: .anubis, slot: .defence, name: "Guardian of the Tomb",
            effect: "First hit absorbed by shield adds 5 Judgement to its attacker.",
            function: "Anubis + Bes", kind: .duo, trigger: .onShieldAbsorb,
            payload: BoonPayload(judgement: 5), sources: [.anubisJudgement, .besShield]
        ),
        GodBoonDef(
            id: "DU-11", god: .anubis, slot: .attack, name: "The Weighing Eye",
            effect: "First Prepared Attack adds 6 Judgement. If primary already had Judgement before this action, gain 4 Shield.",
            function: "Anubis + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(judgement: 6, bonusCondition: .targetJudged, bonusShield: 4),
            sources: [.anubisJudgement, .horusKept]
        ),
        GodBoonDef(
            id: "DU-12", god: .anubis, slot: .defence, name: "Borrowed Life",
            effect: "First successful Dodge adds 5 Judgement to its attacker and heals 2.",
            function: "Anubis + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(judgement: 5, heal: 2), sources: [.anubisJudgement, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-13", god: .bes, slot: .defence, name: "Watchful Guardian",
            effect: "First Prepared action grants 6 Shield. If natively Guard, arm 20% reduction for the next non-dodged enemy damage action this round.",
            function: "Bes + Horus", kind: .duo, trigger: .firstKeptAction,
            payload: BoonPayload(shield: 6), sources: [.besShield, .horusKept]
        ),
        GodBoonDef(
            id: "DU-14", god: .bes, slot: .defence, name: "Warm Doorstep",
            effect: "First successful Dodge grants 5 Shield. If shield later breaks this round, gain 1 Dodge after the hit, once.",
            function: "Bes + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(shield: 5), sources: [.besShield, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-15", god: .horus, slot: .attack, name: "Silent Descent",
            effect: "First successful Dodge primes next separate Attack for +20% damage and +50 percentage points Pierce; expires end of next round.",
            function: "Horus + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(percentDamage: 20, pierce: 50), sources: [.horusPierce, .bastetEvade]
        ),
    ]

    // MARK: - The six legendary evolutions
    //
    // Each one is a very rare find on an ordinary god's card, not a reward for
    // assembling its source first. It lands in the run's single Legendary slot,
    // so it never costs an Attack or Defence place; for a duo's prerequisites
    // it still counts as the power it evolved from.

    static let legendaries: [GodBoonDef] = [
        GodBoonDef(
            id: "LG-RA", god: .ra, slot: .attack, name: "Crown of Noon",
            effect: "First 4–6 die Attack: +%V damage, spends the target's pre-action Burn for twice its value (max 20), then +6 Burn.",
            function: "Evolves Solar Flare", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(burn: 6), scales: .flatDamage, values: [10, 12, 14],
            evolves: "RA-A1", minimumDice: 4
        ),
        GodBoonDef(
            id: "LG-SO", god: .sobek, slot: .attack, name: "Lord of the Bloodied Nile",
            effect: "First 3+ die Attack: Bleed %V and one early Bleed tick; heal actual HP damage up to 6. Against an already Bleeding foe, +15% damage.",
            function: "Evolves Jaws of the Nile", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(),
            scales: .bleed, values: [6, 7, 8], evolves: "SO-A5"
        ),
        GodBoonDef(
            id: "LG-AN", god: .anubis, slot: .attack, name: "Final Verdict",
            effect: "First 3+ die Attack: +20 points Pierce, +%V Judgement. This release deals 25% extra Judgement damage, maximum 8 extra.",
            function: "Evolves Final Sentence", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 20), scales: .judgement, values: [10, 12, 14],
            evolves: "AN-A4"
        ),
        GodBoonDef(
            id: "LG-BE", god: .bes, slot: .attack, name: "Unbroken House",
            effect: "Keeps Sheltering Blow. Round end: strike back for half the shield spent that round, up to 15.",
            function: "Evolves Sheltering Blow", kind: .legendary, trigger: .roundEnd,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 8), evolves: "BE-A1"
        ),
        GodBoonDef(
            id: "LG-HO", god: .horus, slot: .attack, name: "Eye of the Falcon",
            effect: "First kept Attack: +%V% damage, ignores all guard and plate.",
            function: "Evolves Falcon's Eye", kind: .legendary, trigger: .firstKeptAttack,
            payload: BoonPayload(pierce: 100), scales: .percentDamage, values: [25, 30, 35],
            evolves: "HO-A1"
        ),
        GodBoonDef(
            id: "LG-BA", god: .bastet, slot: .defence, name: "Nine Lives Unbound",
            effect: "First Evade: +%V Guard, plus 3 if it is a two-die combo. Once a fight, a killing blow leaves you at 1 HP and prepares 2 Dodges.",
            function: "Evolves Hunting Step", kind: .legendary, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusShield: 3),
            scales: .shield, values: [3, 5, 7], evolves: "BA-D1"
        ),
    ]
}

