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
            id: "RA-A1", god: .ra, slot: .attack, name: "Solar Flare",
            effect: "Your first large attack combo each round gains %V direct damage and adds 4 Burn to its primary surviving target.",
            function: "Large combos", kind: .regular, trigger: .firstLargeCombo,
            payload: BoonPayload(burn: 4), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "RA-A2", god: .ra, slot: .attack, name: "Scorching Sequence",
            effect: "Your first Attack each round adds %V Burn. If your second Attack that round targets the same living foe, it pays one early Burn tick after its status applications.",
            function: "Multiple moves; order", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(bonusCondition: .sameTargetAsLast), scales: .burn, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-A3", god: .ra, slot: .attack, name: "Sun's Judgement",
            effect: "Your first frozen Attack each round gains %V direct damage and adds 3 Burn.",
            function: "Freezes; prepared attacks", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(burn: 3), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "RA-A4", god: .ra, slot: .attack, name: "Noon Spear",
            effect: "If you began the round with at least 5 stamina, your first Attack gains %V percentage points of pierce and adds 4 Burn.",
            function: "Rising stamina; Focus", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(burn: 4), scales: .pierce, values: [30, 40, 50],
            requires: .openedRoundWithFive
        ),
        GodBoonDef(
            id: "RA-A5", god: .ra, slot: .attack, name: "Sun's Edge",
            effect: "Every Attack adds 1 Burn per Attack ingredient. Against an already-burning target, it also gains %V% direct damage.",
            function: "Ingredient scaling; setup", kind: .regular, trigger: .everyAttack,
            payload: BoonPayload(burn: 1, perIngredient: true, bonusCondition: .targetBurning),
            scales: .bonusPercent, values: [15, 20, 25]
        ),
        GodBoonDef(
            id: "RA-D1", god: .ra, slot: .defence, name: "Solar Guard",
            effect: "Your first Guard action each round grants %V extra shield and arms retaliation: the first incoming hit shield absorbs that round adds 4 Burn to its attacker.",
            function: "Block; retaliation", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(burn: 4), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "RA-D2", god: .ra, slot: .defence, name: "Cinder Step",
            effect: "Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to add %V Burn to its attacker.",
            function: "Evade; reactive fire", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(evadePoints: 10), scales: .burn, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-D3", god: .ra, slot: .defence, name: "Sunset Shelter",
            effect: "Your first frozen Guard action each round grants %V extra shield and arms the first hit shield absorbs that round to add 2 Burn to every living foe.",
            function: "Frozen defence; reactive area fire", kind: .regular, trigger: .firstFrozenGuard,
            payload: BoonPayload(burn: 2), scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "RA-U1", god: .ra, slot: .utility, name: "Dawn Breath",
            effect: "Start each encounter with +1 temporary stamina: the opening budget becomes 4. Fixed; it does not alter later base allowances.",
            function: "Early tempo", kind: .regular, trigger: .encounterStart,
            payload: BoonPayload(staminaNext: 1)
        ),
        GodBoonDef(
            id: "RA-U2", god: .ra, slot: .utility, name: "Banked Embers",
            effect: "At commitment, newly freeze at least one Attack face to bank +1 stamina for next round. Once per round; re-freezing a carried face does not qualify. Fixed.",
            function: "Freezes; next-turn stamina", kind: .regular, trigger: .atCommitment,
            payload: BoonPayload(staminaNext: 1)
        ),
    ]

    // MARK: - Sobek — wounds, pressure and survival

    static let sobek: [GodBoonDef] = [
        GodBoonDef(
            id: "SO-A1", god: .sobek, slot: .attack, name: "Twin Fangs",
            effect: "Your first two-face attack combo each round gains %V direct damage and applies Bleed 4.",
            function: "Small combos", kind: .regular, trigger: .firstTwoFaceCombo,
            payload: BoonPayload(bleed: 4), scales: .flatDamage, values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "SO-A2", god: .sobek, slot: .attack, name: "Blood Scent",
            effect: "Your first Attack each round applies Bleed 3. All your Attacks against already-bleeding targets gain %V% direct damage.",
            function: "Setup; multiple moves", kind: .regular, trigger: .everyAttack,
            payload: BoonPayload(bleed: 3, bonusCondition: .targetBleeding),
            scales: .bonusPercent, values: [20, 25, 30]
        ),
        GodBoonDef(
            id: "SO-A3", god: .sobek, slot: .attack, name: "Death Grip",
            effect: "Your first frozen Attack each round gains %V direct damage and applies Bleed 5.",
            function: "Frozen attacks", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(bleed: 5), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "SO-A4", god: .sobek, slot: .attack, name: "Feeding Frenzy",
            effect: "Your second Attack each round applies Bleed 3. If that action's native damage dealt positive HP damage, also heal %V.",
            function: "Multiple moves; sustain", kind: .regular, trigger: .secondAttack,
            payload: BoonPayload(bleed: 3), scales: .heal, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-A5", god: .sobek, slot: .attack, name: "Jaws of the Nile",
            effect: "Your first large attack combo each round applies Bleed %V, then pays one early Bleed tick and heals for HP actually lost to that tick, up to 4.",
            function: "Large combos; sustain", kind: .regular, trigger: .firstLargeCombo,
            payload: BoonPayload(heal: 4), scales: .bleed, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "SO-D1", god: .sobek, slot: .defence, name: "Crocodile Armour",
            effect: "Your first Guard action each round grants %V extra shield and arms the first hit shield absorbs that round to apply Bleed 3 to its attacker.",
            function: "Block; reactive wounds", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(bleed: 3), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "SO-D2", god: .sobek, slot: .defence, name: "River Slip",
            effect: "Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to heal %V.",
            function: "Evade; recovery", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(evadePoints: 10), scales: .heal, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-D3", god: .sobek, slot: .defence, name: "Blood Shelter",
            effect: "Your first frozen Guard action each round grants %V extra shield and heals 3.",
            function: "Frozen defence; recovery", kind: .regular, trigger: .firstFrozenGuard,
            payload: BoonPayload(heal: 3), scales: .shield, values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "SO-U1", god: .sobek, slot: .utility, name: "Blood Reserve",
            effect: "At round start, after the previous round has fully settled, gain +1 temporary stamina if HP is at or below half maximum. Subject to the total budget cap of 6. Fixed.",
            function: "Risk; stamina", kind: .regular, trigger: .roundStart,
            payload: BoonPayload(staminaNext: 1), requires: .healthAtHalf
        ),
        GodBoonDef(
            id: "SO-U2", god: .sobek, slot: .utility, name: "Patient Hunter",
            effect: "The first action using a frozen face each encounter heals 3 and banks +1 stamina for the following round. Any action role qualifies. Fixed.",
            function: "Freezes; delayed stamina", kind: .regular, trigger: .firstFrozenAction,
            payload: BoonPayload(heal: 3, staminaNext: 1)
        ),
    ]

    // MARK: - Anubis — sequences, preservation and timed verdicts

    static let anubis: [GodBoonDef] = [
        GodBoonDef(
            id: "AN-A1", god: .anubis, slot: .attack, name: "Scales of War",
            effect: "Your first attack combo containing a Block ingredient each round adds %V Judgement and grants 4 shield.",
            function: "Mixed attack/guard combo", kind: .regular, trigger: .firstComboWithBlock,
            payload: BoonPayload(shield: 4), scales: .judgement, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "AN-A2", god: .anubis, slot: .attack, name: "Second Reading",
            effect: "Every Attack adds %V Judgement per Attack ingredient. Once per round, an Attack against an already-judged foe adds 4 further Judgement.",
            function: "Ingredient scaling; sequence", kind: .regular, trigger: .everyAttack,
            payload: BoonPayload(perIngredient: true, bonusCondition: .targetJudged, bonusJudgement: 4),
            scales: .judgement, values: [2, 3, 4]
        ),
        GodBoonDef(
            id: "AN-A3", god: .anubis, slot: .attack, name: "Sealed Fate",
            effect: "Your first frozen Attack each round gains %V direct damage and adds 6 Judgement.",
            function: "Frozen attacks", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(judgement: 6), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-A4", god: .anubis, slot: .attack, name: "Final Sentence",
            effect: "Your first large attack combo each round gains 20 percentage points of pierce and adds %V Judgement.",
            function: "Large combo; delayed payoff", kind: .regular, trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 20), scales: .judgement, values: [10, 12, 14]
        ),
        GodBoonDef(
            id: "AN-A5", god: .anubis, slot: .attack, name: "Borrowed Time",
            effect: "Your first Attack against a target already below half HP each round gains %V direct damage and adds 4 Judgement if it survives.",
            function: "Finishing; target choice", kind: .regular, trigger: .firstAttackOnWounded,
            payload: BoonPayload(judgement: 4), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "AN-D1", god: .anubis, slot: .defence, name: "Tomb Ward",
            effect: "Your first Guard action each round grants %V extra shield and arms the first hit shield absorbs that round to add 6 Judgement to its attacker.",
            function: "Block; retaliation", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(judgement: 6), scales: .shield, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "AN-D2", god: .anubis, slot: .defence, name: "Passing Shadow",
            effect: "Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to add %V Judgement to its attacker.",
            function: "Evade; delayed retaliation", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(evadePoints: 10), scales: .judgement, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-D3", god: .anubis, slot: .defence, name: "Burial Cloth",
            effect: "Your first frozen Guard action each round grants %V extra shield and removes one player damage-over-time status, chosen in planning.",
            function: "Frozen defence; cleanse", kind: .regular, trigger: .firstFrozenGuard,
            scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-U1", god: .anubis, slot: .utility, name: "Last Measure",
            effect: "Finish the round with exactly zero stamina to bank +1 for next round. Once per round; checks actual paid costs, including Chisel and boon adjustments. Fixed.",
            function: "Full commitment; stamina", kind: .regular, trigger: .roundEnd,
            payload: BoonPayload(staminaNext: 1), requires: .endedWithZeroStamina
        ),
        GodBoonDef(
            id: "AN-U2", god: .anubis, slot: .utility, name: "Preserved Moment",
            effect: "Adds a third pip to your freeze bar for the encounter. Nothing to switch on — hold three faces whenever you like, and the pip is spent only by a commitment that actually carries a third face over. Still six active slots from eight owned dice. Fixed.",
            function: "One extra hold, once per fight", kind: .regular, trigger: .atCommitment
        ),
    ]

    // MARK: - Bes — protection that lets you keep fighting

    static let bes: [GodBoonDef] = [
        GodBoonDef(
            id: "BE-A1", god: .bes, slot: .attack, name: "Sheltering Blow",
            effect: "Every Attack grants %V shield per Attack ingredient, up to 8 shield per action. If you had at least 8 shield before the action, it also gains +15% direct damage.",
            function: "Shield offence; ingredient scaling", kind: .regular, trigger: .everyAttack,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 8,
                                 bonusCondition: .hadEightShield, bonusPercentDamage: 15),
            scales: .shield, values: [2, 3, 4]
        ),
        GodBoonDef(
            id: "BE-A2", god: .bes, slot: .attack, name: "Counter-Swing",
            effect: "Once per round, your next Attack after a separate Guard action gains %V direct damage and grants 4 shield. The armed bonus expires after the next round.",
            function: "Guard → Attack sequence", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(shield: 4), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "BE-A3", god: .bes, slot: .attack, name: "Guardian's Hand",
            effect: "Your first frozen Attack each round gains %V direct damage and grants 6 shield.",
            function: "Frozen attack; protection", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(shield: 6), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-A4", god: .bes, slot: .attack, name: "Stalwart Advance",
            effect: "Your first two-face attack combo each round gains %V direct damage and grants 6 shield.",
            function: "Small combo; protection", kind: .regular, trigger: .firstTwoFaceCombo,
            payload: BoonPayload(shield: 6), scales: .flatDamage, values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BE-A5", god: .bes, slot: .attack, name: "Unbroken Rhythm",
            effect: "Your second Attack each round gains %V direct damage and grants 4 shield.",
            function: "Multiple moves", kind: .regular, trigger: .secondAttack,
            payload: BoonPayload(shield: 4), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-D1", god: .bes, slot: .defence, name: "The Stout Door",
            effect: "Every Guard action gains %V extra shield per Block ingredient. This applies once as a pooled shield gain, subject to the shield cap. The first Guard action each round has 1 beat of Haste, even if it has no Block ingredient.",
            function: "Single and combined blocks", kind: .regular, trigger: .everyGuard,
            payload: BoonPayload(haste: 1, perIngredient: true), scales: .shield, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "BE-D2", god: .bes, slot: .defence, name: "Rebuild the Wall",
            effect: "Start each encounter with %V shield. The first time shield breaks in that encounter, regain 8 shield after the hit finishes; it cannot undo HP damage from that hit.",
            function: "Opening safety; recovery", kind: .regular, trigger: .encounterStart,
            scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-D3", god: .bes, slot: .defence, name: "Steady Footing",
            effect: "Your first Evade action each round gains +10 percentage points of evade chance and grants %V shield.",
            function: "Reliable and uncertain defence together", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(evadePoints: 10), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "BE-U1", god: .bes, slot: .utility, name: "Hearth Breath",
            effect: "End the round with at least 8 shield to bank +1 stamina for next round. Once per round. Fixed.",
            function: "Defensive preparation; stamina", kind: .regular, trigger: .roundEnd,
            payload: BoonPayload(staminaNext: 1), requires: .endedWithEightShield
        ),
        GodBoonDef(
            id: "BE-U2", god: .bes, slot: .utility, name: "Safe Keeping",
            effect: "At commitment, newly freeze at least one Block, Evade or Support face to schedule 4 shield at the start of your next round. Once per round; re-freezing does not qualify. Fixed.",
            function: "Defensive freezes", kind: .regular, trigger: .atCommitment,
            payload: BoonPayload(shield: 4)
        ),
    ]

    // MARK: - Horus — precision, timing and prepared power

    static let horus: [GodBoonDef] = [
        GodBoonDef(
            id: "HO-A1", god: .horus, slot: .attack, name: "Falcon's Eye",
            effect: "Your first frozen Attack each round gains %V% direct damage and 20 percentage points of pierce. This qualifying action has 2 beats of Haste.",
            function: "Frozen attacks", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(pierce: 20, haste: 2), scales: .percentDamage, values: [25, 30, 35]
        ),
        GodBoonDef(
            id: "HO-A2", god: .horus, slot: .attack, name: "Keen Edge",
            effect: "Your first Attack each round gains %V percentage points of pierce. If it contains a critical ingredient, it also gains 6 direct damage.",
            function: "Crit selection; armour", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(bonusCondition: .hasCritIngredient, bonusFlatDamage: 6),
            scales: .pierce, values: [20, 30, 40]
        ),
        GodBoonDef(
            id: "HO-A3", god: .horus, slot: .attack, name: "Patient Aim",
            effect: "Your first large attack combo each round gains %V% direct damage and 40 percentage points of pierce.",
            function: "Large combo", kind: .regular, trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 40), scales: .percentDamage, values: [20, 25, 30]
        ),
        GodBoonDef(
            id: "HO-A4", god: .horus, slot: .attack, name: "Watchful Strike",
            effect: "Once per round, your next Attack after a separate Guard or Support action gains %V% direct damage and 30 percentage points of pierce. Prime expires after the next round.",
            function: "Action order; Focus", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(pierce: 30), scales: .percentDamage, values: [20, 25, 30]
        ),
        GodBoonDef(
            id: "HO-A5", god: .horus, slot: .attack, name: "High Flight",
            effect: "If you began the round with at least 5 stamina, your first Attack gains %V% direct damage and 20 percentage points of pierce.",
            function: "Stamina ramp; early overcharge", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(pierce: 20), scales: .percentDamage, values: [20, 25, 30],
            requires: .openedRoundWithFive
        ),
        GodBoonDef(
            id: "HO-D1", god: .horus, slot: .defence, name: "Watchful Guard",
            effect: "Your first frozen Guard action each round gains %V extra shield and reduces the next non-evaded hit by 20%. Reduction expires next round.",
            function: "Frozen defence", kind: .regular, trigger: .firstFrozenGuard,
            scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "HO-D2", god: .horus, slot: .defence, name: "Feather Step",
            effect: "Your first Evade action each round grants %V extra percentage points of evade chance. If it uses a frozen face, gain 5 further percentage points, still capped at 60%.",
            function: "Frozen evasion", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .usesFrozenFace, bonusEvadePoints: 5),
            scales: .evadePoints, values: [10, 15, 20]
        ),
        GodBoonDef(
            id: "HO-D3", god: .horus, slot: .defence, name: "High Perch",
            effect: "Your first Guard action each round grants %V extra shield. If a different face carried from a prior turn is still unused when the Guard action starts, gain 4 further shield.",
            function: "Preserve or spend a frozen face", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(bonusShield: 4), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "HO-U1", god: .horus, slot: .utility, name: "Thermal",
            effect: "Your first action using a frozen face each round banks +1 stamina for next round. Fixed.",
            function: "Spend freezes to sustain tempo", kind: .regular, trigger: .firstFrozenAction,
            payload: BoonPayload(staminaNext: 1)
        ),
        GodBoonDef(
            id: "HO-U2", god: .horus, slot: .utility, name: "Perfect Timing",
            effect: "Once per encounter, you may reduce the cost of a combo using a frozen face by 1, to a minimum of 1. Toggle it in planning before commitment. Fixed.",
            function: "Freeze; immediate efficiency", kind: .regular, trigger: .atCommitment
        ),
    ]

    // MARK: - Bastet — short techniques, evasion and movement

    static let bastet: [GodBoonDef] = [
        GodBoonDef(
            id: "BA-A1", god: .bastet, slot: .attack, name: "Pounce",
            effect: "Your first two-face attack combo each round gains %V direct damage and grants +10 percentage points of evade chance.",
            function: "Small combo", kind: .regular, trigger: .firstTwoFaceCombo,
            payload: BoonPayload(evadePoints: 10), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BA-A2", god: .bastet, slot: .attack, name: "Quick Claws",
            effect: "Your first two solo Attacks each round gain %V direct damage each. If the second targets the same living foe as the first, it gains 2 additional direct damage.",
            function: "Solo sequence; focus fire", kind: .regular, trigger: .everyAttack,
            payload: BoonPayload(bonusCondition: .sameTargetAsLast, bonusFlatDamage: 2),
            scales: .flatDamage, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "BA-A3", god: .bastet, slot: .attack, name: "Silent Approach",
            effect: "Your first frozen Attack each round gains %V direct damage and grants +15 percentage points of evade chance.",
            function: "Frozen offence", kind: .regular, trigger: .firstFrozenAttack,
            payload: BoonPayload(evadePoints: 15), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BA-A4", god: .bastet, slot: .attack, name: "Dancing Blades",
            effect: "Once per round, your next Attack after a separate Evade action gains %V direct damage and 40 percentage points of pierce. Prime expires after the next round. The primed Attack also has 1 beat of Haste.",
            function: "Evade → Attack sequence", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(pierce: 40, haste: 1), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "BA-A5", god: .bastet, slot: .attack, name: "Ninefold Flurry",
            effect: "Your third Attack action each round gains %V direct damage and grants +10 percentage points of evade chance. Ingredients inside one combo do not count as separate attacks.",
            function: "Multiple moves; stamina", kind: .regular, trigger: .thirdAttack,
            payload: BoonPayload(evadePoints: 10), scales: .flatDamage, values: [10, 12, 14]
        ),
        GodBoonDef(
            id: "BA-D1", god: .bastet, slot: .defence, name: "Hunting Step",
            effect: "Your first Evade action each round grants %V extra percentage points of evade chance. If it is a two-face combo, gain 5 further percentage points, capped at 60%.",
            function: "Evasive pairs", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusEvadePoints: 5),
            scales: .evadePoints, values: [10, 15, 20]
        ),
        GodBoonDef(
            id: "BA-D2", god: .bastet, slot: .defence, name: "Light Landing",
            effect: "Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to grant %V shield.",
            function: "Dodge; protection", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(evadePoints: 10), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "BA-D3", god: .bastet, slot: .defence, name: "Unscathed",
            effect: "Start the encounter with %V shield. At round-end settlement, if at least one incoming hit was attempted and you lost no HP anywhere in that round, gain 4 shield.",
            function: "Avoid all health damage", kind: .regular, trigger: .encounterStart,
            payload: BoonPayload(bonusCondition: .lostNoHealth, bonusShield: 4),
            scales: .shield, values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BA-U1", god: .bastet, slot: .utility, name: "Light Feet",
            effect: "Your first successful dodge each round banks +1 stamina for the next round. Fixed.",
            function: "Evade; stamina", kind: .regular, trigger: .onDodge,
            payload: BoonPayload(staminaNext: 1)
        ),
        GodBoonDef(
            id: "BA-U2", god: .bastet, slot: .utility, name: "Slip Through",
            effect: "Once per encounter, you may play one solo face carried from a previous turn for 0 stamina. Toggle it in planning. This is an explicit exception to the usual minimum action cost. Fixed.",
            function: "Freeze; an extra move", kind: .regular, trigger: .atCommitment
        ),
    ]

    // MARK: - The fifteen duos

    static let duos: [GodBoonDef] = [
        GodBoonDef(
            id: "DU-01", god: .ra, slot: .attack, name: "Boiling Nile",
            effect: "At end of the round, the living foe with both Burn and Bleed and the greatest Burn takes extra direct HP damage equal to its Burn, capped at 6. Once per round; does not consume or decay either status. Ties use visible enemy order.",
            function: "Ra + Sobek", kind: .duo, trigger: .roundEnd,
            sources: [.raBurn, .sobekBleed]
        ),
        GodBoonDef(
            id: "DU-02", god: .ra, slot: .attack, name: "Funeral Pyre",
            effect: "The first scheduled Judgement verdict against a burning foe each round deals extra HP damage equal to twice that foe's current Burn, capped at 12.",
            function: "Ra + Anubis", kind: .duo, trigger: .roundEnd,
            sources: [.raBurn, .anubisJudgement]
        ),
        GodBoonDef(
            id: "DU-03", god: .ra, slot: .defence, name: "Forge Song",
            effect: "The first incoming hit shield absorbs each round adds 4 Burn to the attacker.",
            function: "Ra + Bes", kind: .duo, trigger: .onShieldAbsorb,
            payload: BoonPayload(burn: 4), sources: [.raBurn, .besShield]
        ),
        GodBoonDef(
            id: "DU-04", god: .ra, slot: .attack, name: "Sunstrike",
            effect: "Your first frozen Attack each round gains 6 direct damage. If its target was already burning, pay one early Burn tick after status applications, capped at 6 HP damage.",
            function: "Ra + Horus", kind: .duo, trigger: .firstFrozenAttack,
            payload: BoonPayload(flatDamage: 6), sources: [.raBurn, .horusFrozen]
        ),
        GodBoonDef(
            id: "DU-05", god: .ra, slot: .defence, name: "Dancing Flame",
            effect: "Your first successful dodge each round adds 4 Burn to the attacker and grants 2 shield.",
            function: "Ra + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(burn: 4, shield: 2), sources: [.raBurn, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-06", god: .sobek, slot: .utility, name: "The Crossing",
            effect: "Your first scheduled Judgement verdict against a bleeding foe each round heals 3 and banks +1 stamina for the next round. Check Bleed immediately before the verdict, even if the verdict kills.",
            function: "Sobek + Anubis", kind: .duo, trigger: .roundEnd,
            payload: BoonPayload(heal: 3, staminaNext: 1), sources: [.sobekBleed, .anubisJudgement]
        ),
        GodBoonDef(
            id: "DU-07", god: .sobek, slot: .defence, name: "Crocodile Hide",
            effect: "Your first positive healing event each round grants 5 shield. Eligible healing comes from native actions, consumables or regular/legendary boons, never another duo. Overheal does not qualify.",
            function: "Sobek + Bes", kind: .duo, trigger: .roundStart,
            payload: BoonPayload(shield: 5), sources: [.sobekHealing, .besShield]
        ),
        GodBoonDef(
            id: "DU-08", god: .sobek, slot: .attack, name: "Reed and Sky",
            effect: "Your first frozen Attack against an already-bleeding foe each round gains +25% direct damage and 20 percentage points of pierce.",
            function: "Sobek + Horus", kind: .duo, trigger: .firstFrozenAttack,
            payload: BoonPayload(percentDamage: 25, pierce: 20), sources: [.sobekBleed, .horusFrozen]
        ),
        GodBoonDef(
            id: "DU-09", god: .sobek, slot: .defence, name: "Death Roll",
            effect: "Your first successful dodge against a bleeding attacker each round pays one early Bleed tick against it and heals 2.",
            function: "Sobek + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(heal: 2), sources: [.sobekBleed, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-10", god: .anubis, slot: .defence, name: "Guardian of the Tomb",
            effect: "The first incoming hit shield absorbs each round adds 6 Judgement to the attacker.",
            function: "Anubis + Bes", kind: .duo, trigger: .onShieldAbsorb,
            payload: BoonPayload(judgement: 6), sources: [.anubisJudgement, .besShield]
        ),
        GodBoonDef(
            id: "DU-11", god: .anubis, slot: .attack, name: "The Weighing Eye",
            effect: "Your first frozen Attack each round adds 8 Judgement. If a verdict was already pending on that foe before the action, gain 4 shield as well.",
            function: "Anubis + Horus", kind: .duo, trigger: .firstFrozenAttack,
            payload: BoonPayload(judgement: 8, bonusCondition: .targetJudged, bonusShield: 4),
            sources: [.anubisJudgement, .horusFrozen]
        ),
        GodBoonDef(
            id: "DU-12", god: .anubis, slot: .defence, name: "Borrowed Life",
            effect: "Your first successful dodge each round adds 6 Judgement to the attacker and heals 2.",
            function: "Anubis + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(judgement: 6, heal: 2), sources: [.anubisJudgement, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-13", god: .bes, slot: .defence, name: "Watchful Guardian",
            effect: "Your first action using a frozen face each round grants 6 shield. If that action is Guard, it also reduces the next non-evaded hit by 25%, expiring at the next round.",
            function: "Bes + Horus", kind: .duo, trigger: .firstFrozenAction,
            payload: BoonPayload(shield: 6), sources: [.besShield, .horusFrozen]
        ),
        GodBoonDef(
            id: "DU-14", god: .bes, slot: .defence, name: "Warm Doorstep",
            effect: "Your first successful dodge each round grants 6 shield. The first time shield breaks that round, gain +10 percentage points of evade chance for the rest of that round, capped at 60%.",
            function: "Bes + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(shield: 6), sources: [.besShield, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-15", god: .horus, slot: .attack, name: "Silent Descent",
            effect: "Your first successful dodge each round primes the next Attack for +20% direct damage and 100% pierce. It expires after the next round and does not stack with itself.",
            function: "Horus + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(percentDamage: 20, pierce: 100), sources: [.horusPierce, .bastetEvade]
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
            id: "LG-RA", god: .ra, slot: .legendary, name: "Crown of Noon",
            effect: "Your first large attack combo each round gains %V direct damage. If its primary target survives the native hit, consume that target's pre-action Burn for twice that potency as direct HP damage, capped at 20; then, if it still survives, add 6 Burn.",
            function: "Evolves Solar Flare", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(burn: 6), scales: .flatDamage, values: [10, 12, 14],
            evolves: "RA-A1"
        ),
        GodBoonDef(
            id: "LG-SO", god: .sobek, slot: .legendary, name: "Lord of the Bloodied Nile",
            effect: "Your first large attack combo each round applies Bleed %V, pays one early Bleed tick, and heals for HP actually lost to that tick up to 6. If the target was already below half HP before the action, the native attack also gains +20% direct damage.",
            function: "Evolves Jaws of the Nile", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(heal: 6, bonusCondition: .targetBleeding, bonusPercentDamage: 20),
            scales: .bleed, values: [6, 7, 8], evolves: "SO-A5"
        ),
        GodBoonDef(
            id: "LG-AN", god: .anubis, slot: .legendary, name: "Final Verdict",
            effect: "Your first large attack combo each round gains 20 percentage points of pierce, adds %V Judgement and advances that target's entire pending ledger to the end of the current round. Further additions this turn join it. It still resolves only once for that target at the scheduled phase.",
            function: "Evolves Final Sentence", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 20), scales: .judgement, values: [14, 16, 18],
            evolves: "AN-A4"
        ),
        GodBoonDef(
            id: "LG-BE", god: .bes, slot: .legendary, name: "Unbroken House",
            effect: "Retain Sheltering Blow at its current level. At round-end settlement, retaliate for half the shield absorbed during that round, rounded down and capped at 15 direct HP damage, against the living enemy whose hits consumed most shield. If no shield-damaging attacker survives, no retaliation occurs.",
            function: "Evolves Sheltering Blow", kind: .legendary, trigger: .roundEnd,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 8), evolves: "BE-A1"
        ),
        GodBoonDef(
            id: "LG-HO", god: .horus, slot: .legendary, name: "Eye of the Falcon",
            effect: "Your first frozen Attack each round gains %V% direct damage and ignores all block and armour. It is still a single once-per-round activation, even with several frozen ingredients.",
            function: "Evolves Falcon's Eye", kind: .legendary, trigger: .firstFrozenAttack,
            payload: BoonPayload(pierce: 100, haste: 2), scales: .percentDamage, values: [35, 40, 45],
            evolves: "HO-A1"
        ),
        GodBoonDef(
            id: "LG-BA", god: .bastet, slot: .legendary, name: "Nine Lives Unbound",
            effect: "Retain Hunting Step at its current level. Once per encounter, a lethal hit or damage-over-time event leaves you at 1 HP instead. Set evade chance to its normal 60% cap through the end of the current round; later hits or damage-over-time can still kill you.",
            function: "Evolves Hunting Step", kind: .legendary, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusEvadePoints: 5),
            scales: .evadePoints, values: [10, 15, 20], evolves: "BA-D1"
        ),
    ]
}
