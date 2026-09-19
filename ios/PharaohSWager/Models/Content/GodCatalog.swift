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
            effect: "First Attack: +%V Burn. Second Attack on the same foe: +2 Burn again.",
            function: "Stacking Burn", kind: .regular, trigger: .firstAttack,
            payload: BoonPayload(bonusCondition: .sameTargetAsLast, burnBonus: 2),
            scales: .burn, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-A3", god: .ra, slot: .attack, name: "Sun's Wrath",
            effect: "First kept Attack: +%V damage, +3 Burn.",
            function: "Kept attacks", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(burn: 3), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "RA-A4", god: .ra, slot: .attack, name: "Noon Spear",
            effect: "Your first Focus-enhanced Attack gains %V percentage points of pierce and adds 4 Burn.",
            function: "Focused attacks", kind: .regular, trigger: .firstFocusedAttack,
            payload: BoonPayload(burn: 4), scales: .pierce, values: [30, 40, 50],
            requires: .focusedAction
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
            effect: "Your first Evade action each round arms your first successful dodge that round to add %V Burn to its attacker.",
            function: "Evade; reactive fire", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(dodgeCharges: 0), scales: .burn, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "RA-D3", god: .ra, slot: .defence, name: "Sunset Shelter",
            effect: "Your first kept Guard action each round grants %V extra shield and arms the first hit shield absorbs that round to add 2 Burn to every living foe.",
            function: "Kept defence; reactive area fire", kind: .regular, trigger: .firstKeptGuard,
            payload: BoonPayload(burn: 2), scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "RA-U1", god: .ra, slot: .utility, name: "Dawn Breath",
            effect: "Start each encounter with 8 Guard. Fixed.",
            function: "Opening protection", kind: .regular, trigger: .encounterStart,
            payload: BoonPayload(shield: 8)
        ),
        GodBoonDef(
            id: "RA-U2", god: .ra, slot: .utility, name: "Banked Embers",
            effect: "Your first Attack using a die kept through a reroll grants +1 reroll next round, up to 2 total. Fixed.",
            function: "Kept attack; next-round reroll", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(rerollsNext: 1)
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
            effect: "First kept Attack: +%V damage, +3 Poison.",
            function: "Kept attacks", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(poison: 3), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "SO-A4", god: .sobek, slot: .attack, name: "Feeding Frenzy",
            effect: "Your second Attack each round applies Bleed 3. If that action's native damage dealt positive HP damage, also heal %V.",
            function: "Multiple moves; sustain", kind: .regular, trigger: .secondAttack,
            payload: BoonPayload(bleed: 3), scales: .heal, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-A5", god: .sobek, slot: .attack, name: "Jaws of the Nile",
            effect: "First large attack combo: Bleed %V. Heal 4 if the target already bled.",
            function: "Large combos; sustain", kind: .regular, trigger: .firstLargeCombo,
            payload: BoonPayload(bonusCondition: .targetBleeding, bonusHeal: 4),
            scales: .bleed, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "SO-D1", god: .sobek, slot: .defence, name: "Crocodile Armour",
            effect: "First Guard: +%V shield. First hit it absorbs gives the attacker Bleed 3.",
            function: "Block; reactive wounds", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(bleed: 3), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "SO-D2", god: .sobek, slot: .defence, name: "River Slip",
            effect: "Your first Evade action each round arms your first successful dodge that round to heal %V.",
            function: "Evade; recovery", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(dodgeCharges: 0), scales: .heal, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "SO-D3", god: .sobek, slot: .defence, name: "Blood Shelter",
            effect: "Your first kept Guard action each round grants %V extra shield and heals 3.",
            function: "Kept defence; recovery", kind: .regular, trigger: .firstKeptGuard,
            payload: BoonPayload(heal: 3), scales: .shield, values: [5, 7, 9]
        ),
        GodBoonDef(
            id: "SO-U1", god: .sobek, slot: .utility, name: "Blood Reserve",
            effect: "At round start, gain 6 Guard if your HP is at or below half. Fixed.",
            function: "Protection while wounded", kind: .regular, trigger: .roundStart,
            payload: BoonPayload(shield: 6), requires: .healthAtHalf
        ),
        GodBoonDef(
            id: "SO-U2", god: .sobek, slot: .utility, name: "Patient Hunter",
            effect: "The first action using a kept die each encounter heals 3 and grants 6 Guard. Fixed.",
            function: "Kept dice; recovery", kind: .regular, trigger: .firstKeptAction,
            payload: BoonPayload(shield: 6, heal: 3)
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
            effect: "Your first kept Attack each round gains %V direct damage and adds 6 Judgement.",
            function: "Kept attacks", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(judgement: 6), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-A4", god: .anubis, slot: .attack, name: "Final Sentence",
            effect: "First large attack combo: +20% pierce, +%V Judgement. A 3+ die combo releases the pile.",
            function: "Large combo; releases verdicts", kind: .regular, trigger: .firstLargeCombo,
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
            effect: "Your first Evade action each round arms your first successful dodge that round to add %V Judgement to its attacker.",
            function: "Evade; delayed retaliation", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(dodgeCharges: 0), scales: .judgement, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-D3", god: .anubis, slot: .defence, name: "Burial Cloth",
            effect: "First kept Guard: +%V shield, and clears your Burn and Bleed.",
            function: "Kept defence; cleanse", kind: .regular, trigger: .firstKeptGuard,
            payload: BoonPayload(cleansesSelf: true), scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "AN-U1", god: .anubis, slot: .utility, name: "Last Measure",
            effect: "Use all six dice in your committed plan to gain +1 reroll next round, up to 2 total. Fixed.",
            function: "Full hand; next-round reroll", kind: .regular, trigger: .roundEnd,
            payload: BoonPayload(rerollsNext: 1), requires: .usedAllDice
        ),
        GodBoonDef(
            id: "AN-U2", god: .anubis, slot: .utility, name: "Preserved Moment",
            effect: "Gain one additional selective reroll every round, up to 2 total. Unused rerolls expire. Fixed.",
            function: "Additional reroll", kind: .regular, trigger: .roundStart,
            payload: BoonPayload(rerollsNext: 1)
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
            effect: "Once per round, your next Attack after a separate Guard action gains %V direct damage and grants 4 shield. Requires a separate Guard in this round.",
            function: "Guard → Attack sequence", kind: .regular, trigger: .firstAttackAfterGuard,
            payload: BoonPayload(shield: 4), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "BE-A3", god: .bes, slot: .attack, name: "Guardian's Hand",
            effect: "Your first kept Attack each round gains %V direct damage and grants 6 shield.",
            function: "Kept attack; protection", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(shield: 6), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-A4", god: .bes, slot: .attack, name: "Stalwart Advance",
            effect: "First two-die attack combo: +%V damage, Weaken 25%.",
            function: "Small combo; blunt the answer", kind: .regular, trigger: .firstTwoFaceCombo,
            payload: BoonPayload(weakenPercent: 25), scales: .flatDamage, values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BE-A5", god: .bes, slot: .attack, name: "Unbroken Rhythm",
            effect: "Your second Attack each round gains %V direct damage and grants 4 shield.",
            function: "Multiple moves", kind: .regular, trigger: .secondAttack,
            payload: BoonPayload(shield: 4), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-D1", god: .bes, slot: .defence, name: "The Stout Door",
            effect: "Every Guard action gains %V extra shield per Block ingredient. The gain is pooled once per action and expires at round end.",
            function: "Single and combined blocks", kind: .regular, trigger: .everyGuard,
            payload: BoonPayload(perIngredient: true), scales: .shield, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "BE-D2", god: .bes, slot: .defence, name: "Rebuild the Wall",
            effect: "Start each encounter with %V shield. The first time shield breaks in that encounter, regain 8 shield after the hit finishes; it cannot undo HP damage from that hit.",
            function: "Opening safety; recovery", kind: .regular, trigger: .encounterStart,
            scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BE-D3", god: .bes, slot: .defence, name: "Steady Footing",
            effect: "Your first Evade action each round grants %V extra Guard before attacks.",
            function: "Dodge and Guard together", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(dodgeCharges: 0), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "BE-U1", god: .bes, slot: .utility, name: "Hearth Breath",
            effect: "End a round with at least 8 Guard to start the next with 6 Guard. Fixed.",
            function: "Defensive preparation", kind: .regular, trigger: .roundEnd,
            payload: BoonPayload(guardNext: 6), requires: .endedWithEightShield
        ),
        GodBoonDef(
            id: "BE-U2", god: .bes, slot: .utility, name: "Safe Keeping",
            effect: "Your first Guard action using a kept die each round grants 4 additional Guard. Fixed.",
            function: "Kept defence", kind: .regular, trigger: .firstKeptGuard,
            payload: BoonPayload(shield: 4)
        ),
    ]

    // MARK: - Horus — precision, timing and prepared power

    static let horus: [GodBoonDef] = [
        GodBoonDef(
            id: "HO-A1", god: .horus, slot: .attack, name: "Falcon's Eye",
            effect: "Your first kept Attack each round gains %V% direct damage and 20 percentage points of pierce.",
            function: "Kept attacks", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(pierce: 20), scales: .percentDamage, values: [25, 30, 35]
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
            effect: "First Attack after a separate Guard or Support: +%V% damage, +30% pierce, Mark +25%.",
            function: "Action order; Mark", kind: .regular, trigger: .firstAttackAfterSupport,
            payload: BoonPayload(pierce: 30, markPercent: 25),
            scales: .percentDamage, values: [20, 25, 30]
        ),
        GodBoonDef(
            id: "HO-A5", god: .horus, slot: .attack, name: "High Flight",
            effect: "Your first Focus-enhanced Attack gains %V% direct damage and 20 percentage points of pierce.",
            function: "Focused attack; overcharge", kind: .regular, trigger: .firstFocusedAttack,
            payload: BoonPayload(pierce: 20), scales: .percentDamage, values: [20, 25, 30],
            requires: .focusedAction
        ),
        GodBoonDef(
            id: "HO-D1", god: .horus, slot: .defence, name: "Watchful Guard",
            effect: "Your first kept Guard action each round gains %V extra shield and reduces the next non-evaded hit by 20%. Reduction expires next round.",
            function: "Kept defence", kind: .regular, trigger: .firstKeptGuard,
            scales: .shield, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "HO-D2", god: .horus, slot: .defence, name: "Feather Step",
            effect: "Your first Evade action each round grants %V Guard. If it uses a kept die, gain 3 more Guard.",
            function: "Kept evasion", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .usesKeptFace, bonusShield: 3),
            scales: .shield, values: [3, 5, 7]
        ),
        GodBoonDef(
            id: "HO-D3", god: .horus, slot: .defence, name: "High Perch",
            effect: "Your first Guard action each round grants %V extra shield. If that action uses a kept die, gain 4 further shield.",
            function: "Preserve or spend a kept face", kind: .regular, trigger: .firstGuard,
            payload: BoonPayload(bonusCondition: .usesKeptFace, bonusShield: 4), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "HO-U1", god: .horus, slot: .utility, name: "Thermal",
            effect: "Your first action using a kept die each round strengthens your next attack by 20%. If it attacks, it receives the bonus itself. Fixed.",
            function: "Kept dice; precision", kind: .regular, trigger: .firstKeptAction,
            payload: BoonPayload(percentDamage: 20)
        ),
        GodBoonDef(
            id: "HO-U2", god: .horus, slot: .utility, name: "Perfect Timing",
            effect: "Your first Attack using a kept die each encounter prepares 1 Dodge. Fixed.",
            function: "Kept attack; protection", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(dodgeCharges: 1)
        ),
    ]

    // MARK: - Bastet — short techniques, evasion and movement

    static let bastet: [GodBoonDef] = [
        GodBoonDef(
            id: "BA-A1", god: .bastet, slot: .attack, name: "Pounce",
            effect: "Your first two-face attack combo each round gains %V direct damage and grants 1 Dodge.",
            function: "Small combo", kind: .regular, trigger: .firstTwoFaceCombo,
            payload: BoonPayload(dodgeCharges: 1), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BA-A2", god: .bastet, slot: .attack, name: "Quick Claws",
            effect: "Your first two solo Attacks each round gain %V direct damage each. If the second targets the same living foe as the first, it gains 2 additional direct damage.",
            function: "Solo sequence; focus fire", kind: .regular, trigger: .firstTwoSoloAttacks,
            payload: BoonPayload(bonusCondition: .sameTargetAsLast, bonusFlatDamage: 2),
            scales: .flatDamage, values: [3, 4, 5]
        ),
        GodBoonDef(
            id: "BA-A3", god: .bastet, slot: .attack, name: "Silent Approach",
            effect: "First kept Attack: +%V damage, Mark +25%.",
            function: "Kept offence; Mark", kind: .regular, trigger: .firstKeptAttack,
            payload: BoonPayload(markPercent: 25), scales: .flatDamage, values: [6, 8, 10]
        ),
        GodBoonDef(
            id: "BA-A4", god: .bastet, slot: .attack, name: "Dancing Blades",
            effect: "Once per round, your next Attack after a separate Evade action gains %V direct damage and 40 percentage points of pierce. Requires a separate Evade in this round.",
            function: "Evade → Attack sequence", kind: .regular, trigger: .firstAttackAfterEvade,
            payload: BoonPayload(pierce: 40), scales: .flatDamage, values: [8, 10, 12]
        ),
        GodBoonDef(
            id: "BA-A5", god: .bastet, slot: .attack, name: "Ninefold Flurry",
            effect: "Your third Attack action each round gains %V direct damage and grants 1 Dodge. Ingredients inside one combo do not count as separate attacks.",
            function: "Multiple moves; Dodge", kind: .regular, trigger: .thirdAttack,
            payload: BoonPayload(dodgeCharges: 1), scales: .flatDamage, values: [10, 12, 14]
        ),
        GodBoonDef(
            id: "BA-D1", god: .bastet, slot: .defence, name: "Hunting Step",
            effect: "Your first Evade action each round grants %V Guard. If it is a two-die combo, gain 3 more Guard.",
            function: "Evasive pairs", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusShield: 3),
            scales: .shield, values: [3, 5, 7]
        ),
        GodBoonDef(
            id: "BA-D2", god: .bastet, slot: .defence, name: "Light Landing",
            effect: "Your first Evade action each round arms your first successful dodge that round to grant %V shield.",
            function: "Dodge; protection", kind: .regular, trigger: .firstEvade,
            payload: BoonPayload(dodgeCharges: 0), scales: .shield, values: [4, 5, 6]
        ),
        GodBoonDef(
            id: "BA-D3", god: .bastet, slot: .defence, name: "Unscathed",
            effect: "Start the encounter with %V shield. At round-end settlement, if an incoming hit was attempted and you lost no HP that round, start the next with 4 shield.",
            function: "Avoid all health damage", kind: .regular, trigger: .encounterStart,
            payload: BoonPayload(bonusCondition: .lostNoHealth, bonusShield: 4),
            scales: .shield, values: [4, 6, 8]
        ),
        GodBoonDef(
            id: "BA-U1", god: .bastet, slot: .utility, name: "Light Feet",
            effect: "Your first successful dodge each round grants +1 reroll next round, up to 2 total. Fixed.",
            function: "Dodge; next-round reroll", kind: .regular, trigger: .onDodge,
            payload: BoonPayload(rerollsNext: 1)
        ),
        GodBoonDef(
            id: "BA-U2", god: .bastet, slot: .utility, name: "Slip Through",
            effect: "Your first individual Attack each round gains 6 damage. A combo does not consume this benefit. Fixed.",
            function: "Individual attacks", kind: .regular, trigger: .firstSoloAttack,
            payload: BoonPayload(flatDamage: 6)
        ),
    ]

    // MARK: - The fifteen duos

    static let duos: [GodBoonDef] = [
        GodBoonDef(
            id: "DU-01", god: .ra, slot: .attack, name: "Boiling Nile",
            effect: "Round end: the burning, bleeding foe takes its Burn again, up to 6. Once per round.",
            function: "Ra + Sobek", kind: .duo, trigger: .roundEnd,
            sources: [.raBurn, .sobekBleed]
        ),
        GodBoonDef(
            id: "DU-02", god: .ra, slot: .attack, name: "Funeral Pyre",
            effect: "A released verdict on a burning foe deals twice its Burn again, up to 12.",
            function: "Ra + Anubis", kind: .duo, trigger: .everyAttack,
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
            effect: "First kept Attack: +6 damage. Against a burning foe, +4 Burn.",
            function: "Ra + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(flatDamage: 6, bonusCondition: .targetBurning, burnBonus: 4),

            sources: [.raBurn, .horusKept]
        ),
        GodBoonDef(
            id: "DU-05", god: .ra, slot: .defence, name: "Dancing Flame",
            effect: "Your first successful dodge each round adds 4 Burn to the attacker and grants 2 shield.",
            function: "Ra + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(burn: 4, shield: 2), sources: [.raBurn, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-06", god: .sobek, slot: .utility, name: "The Crossing",
            effect: "A released verdict on a bleeding foe heals 3 and grants +1 reroll next round (maximum 2).",
            function: "Sobek + Anubis", kind: .duo, trigger: .everyAttack,
            payload: BoonPayload(heal: 3, rerollsNext: 1), sources: [.sobekBleed, .anubisJudgement]
        ),
        GodBoonDef(
            id: "DU-07", god: .sobek, slot: .defence, name: "Crocodile Hide",
            effect: "Your first positive healing event each round grants 5 shield. Eligible healing comes from native actions, consumables or regular/legendary boons, never another duo. Overheal does not qualify.",
            function: "Sobek + Bes", kind: .duo, trigger: .roundStart,
            payload: BoonPayload(shield: 5), sources: [.sobekHealing, .besShield]
        ),
        GodBoonDef(
            id: "DU-08", god: .sobek, slot: .attack, name: "Reed and Sky",
            effect: "Your first kept Attack against an already-bleeding foe each round gains +25% direct damage and 20 percentage points of pierce.",
            function: "Sobek + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(percentDamage: 25, pierce: 20), requires: .targetBleeding, sources: [.sobekBleed, .horusKept]
        ),
        GodBoonDef(
            id: "DU-09", god: .sobek, slot: .defence, name: "Death Roll",
            effect: "First dodge of a bleeding attacker: Bleed 3 on it, heal 2.",
            function: "Sobek + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(bleed: 3, heal: 2), sources: [.sobekBleed, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-10", god: .anubis, slot: .defence, name: "Guardian of the Tomb",
            effect: "The first incoming hit shield absorbs each round adds 6 Judgement to the attacker.",
            function: "Anubis + Bes", kind: .duo, trigger: .onShieldAbsorb,
            payload: BoonPayload(judgement: 6), sources: [.anubisJudgement, .besShield]
        ),
        GodBoonDef(
            id: "DU-11", god: .anubis, slot: .attack, name: "The Weighing Eye",
            effect: "First kept Attack: +8 Judgement. If the foe was already judged, +4 shield.",
            function: "Anubis + Horus", kind: .duo, trigger: .firstKeptAttack,
            payload: BoonPayload(judgement: 8, bonusCondition: .targetJudged, bonusShield: 4),
            sources: [.anubisJudgement, .horusKept]
        ),
        GodBoonDef(
            id: "DU-12", god: .anubis, slot: .defence, name: "Borrowed Life",
            effect: "Your first successful dodge each round adds 6 Judgement to the attacker and heals 2.",
            function: "Anubis + Bastet", kind: .duo, trigger: .onDodge,
            payload: BoonPayload(judgement: 6, heal: 2), sources: [.anubisJudgement, .bastetEvade]
        ),
        GodBoonDef(
            id: "DU-13", god: .bes, slot: .defence, name: "Watchful Guardian",
            effect: "Your first action using a kept face each round grants 6 shield. If that action is Guard, it also reduces the next non-evaded hit by 25%, expiring at the next round.",
            function: "Bes + Horus", kind: .duo, trigger: .firstKeptAction,
            payload: BoonPayload(shield: 6), sources: [.besShield, .horusKept]
        ),
        GodBoonDef(
            id: "DU-14", god: .bes, slot: .defence, name: "Warm Doorstep",
            effect: "Your first successful dodge each round grants 6 shield. The first time shield breaks that round, gain 1 Dodge for that round.",
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
            effect: "First large attack combo: +%V damage, spends the target's Burn for twice its value (max 20), then +6 Burn.",
            function: "Evolves Solar Flare", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(burn: 6), scales: .flatDamage, values: [10, 12, 14],
            evolves: "RA-A1"
        ),
        GodBoonDef(
            id: "LG-SO", god: .sobek, slot: .legendary, name: "Lord of the Bloodied Nile",
            effect: "First large attack combo: Bleed %V. Against a bleeding foe, +20% damage and heal 6.",
            function: "Evolves Jaws of the Nile", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(bonusCondition: .targetBleeding, bonusPercentDamage: 20, bonusHeal: 6),
            scales: .bleed, values: [6, 7, 8], evolves: "SO-A5"
        ),
        GodBoonDef(
            id: "LG-AN", god: .anubis, slot: .legendary, name: "Final Verdict",
            effect: "First large attack combo: +20% pierce, +%V Judgement. Released verdicts hit bosses for half again, and double a foe under a quarter health.",
            function: "Evolves Final Sentence", kind: .legendary, trigger: .firstLargeCombo,
            payload: BoonPayload(pierce: 20), scales: .judgement, values: [14, 16, 18],
            evolves: "AN-A4"
        ),
        GodBoonDef(
            id: "LG-BE", god: .bes, slot: .legendary, name: "Unbroken House",
            effect: "Keeps Sheltering Blow. Round end: strike back for half the shield spent that round, up to 15.",
            function: "Evolves Sheltering Blow", kind: .legendary, trigger: .roundEnd,
            payload: BoonPayload(perIngredient: true, perIngredientCap: 8), evolves: "BE-A1"
        ),
        GodBoonDef(
            id: "LG-HO", god: .horus, slot: .legendary, name: "Eye of the Falcon",
            effect: "First kept Attack: +%V% damage, ignores all guard and plate.",
            function: "Evolves Falcon's Eye", kind: .legendary, trigger: .firstKeptAttack,
            payload: BoonPayload(pierce: 100), scales: .percentDamage, values: [35, 40, 45],
            evolves: "HO-A1"
        ),
        GodBoonDef(
            id: "LG-BA", god: .bastet, slot: .legendary, name: "Nine Lives Unbound",
            effect: "First Evade: +%V Guard, plus 3 if it is a two-die combo. Once a fight, a killing blow leaves you at 1 HP and prepares 2 Dodges.",
            function: "Evolves Hunting Step", kind: .legendary, trigger: .firstEvade,
            payload: BoonPayload(bonusCondition: .isTwoFaceCombo, bonusShield: 3),
            scales: .shield, values: [5, 7, 9], evolves: "BA-D1"
        ),
    ]
}

