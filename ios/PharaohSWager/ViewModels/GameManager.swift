import SwiftUI
import Observation

/// Something the player must aim at a specific die or face before the voyage continues.
enum PendingSelection: Equatable {
    /// Reforge one face of your choice into this kind.
    case reforge(FaceKind, title: String)
    /// Reroll every face on one die of your choice.
    case reforgeDie(title: String)
    /// A god claims one of your dice as its patron. `replace` marks the rare
    /// explicit card that may take a die away from another god.
    case patron(Deity, replace: Bool, title: String)
    /// Take one of a god's upgrades. Needs a blessed die of that god.
    case upgrade(GodUpgrade, title: String)
    /// Commit to a capstone — one per run. Needs two upgrades of that god.
    case capstone(GodCapstone, title: String)
    /// Commit to a pairing — one per run. Needs both gods blessed and an
    /// upgrade from each.
    case pairing(PairingDef, title: String)
    /// Raise one chosen face's crit chance by this much.
    case imbue(Double, title: String)
    /// This power's slot is full — pick which equipped power it replaces.
    case replaceBoon(GodBoonDef, rarity: BoonRarity)
    /// You are at the dice cap — pick which die this one replaces.
    case swapDie(Die)
}

/// Run-level state: class, permanent loadout, gold, the twelve hours of the
/// night, the landings between them, and the upgrade flows that hang off them.
@Observable
final class GameManager {
    enum Screen: Equatable {
        case title
        /// The opening briefing, before the first fight of a run.
        case tutorial
        case chart
        case battle
        case reward
        case shop
        case event
        case gameOver(won: Bool)
    }

    // MARK: Run state
    private(set) var screen: Screen = .title
    private(set) var heroClass: HeroClass?
    private(set) var loadout: Loadout?
    private(set) var gold = 0
    private(set) var maxHP = 100
    private(set) var currentHP = 100
    private(set) var critBonus = 0.0
    /// The god powers equipped this run, in their slots. This replaces patron
    /// dice, upgrades, capstones and pairings: a power belongs to the
    /// character, not to a die, and several gods may answer one action.
    private(set) var equippedBoons: [EquippedBoon] = []
    /// Legendary evolutions taken this run — the run allows one.
    private(set) var legendariesTaken = 0
    /// Upgrades earned this run, by id. Quiet for gods you no longer carry.
    private(set) var acquiredUpgrades: Set<String> = []
    /// The capstone this run committed to, if any — one per run.
    private(set) var capstoneID: String?
    /// The pairing this run committed to, if any — one per run.
    private(set) var pairingID: String?
    private(set) var totalDamage = 0
    private(set) var totalCombos = 0
    private(set) var totalCrits = 0

    // MARK: Ptah & the Trials
    /// Chisel ids carried this run — at most two, both active together.
    private(set) var ownedChisels: [String] = []
    /// True when the spoils screen is Ptah's forge rather than a god's
    /// audience: three Chisels laid out, one taken.
    private(set) var isPtahForge = false
    /// True once this run has fought (and won) a god's Trial — one per run.
    private(set) var trialUsed = false

    // MARK: The voyage
    private(set) var voyage = Voyage.generate()
    /// Stages the barque has already cleared.
    private(set) var clearedNodeIDs: Set<UUID> = []
    /// The last node cleared. The stop after it is the fork now open.
    private(set) var lastClearedNodeID: UUID?
    /// The node the barque is at right now, if any.
    private(set) var currentNodeID: UUID?
    /// Deepest hour the barque has entered, for the dial and records.
    private(set) var deepestHour = 1
    /// Set the moment the barque passes under a new gate, for the title card.
    var crossedGate: Gate?

    // MARK: Encounter state
    private(set) var battle: BattleEngine?
    private(set) var rewardOffers: [Offer] = []
    private(set) var shopStock: [Offer] = []
    private(set) var currentEvent: RunEvent?
    private(set) var eventOutcome: String?
    private(set) var pendingSelection: PendingSelection?
    private(set) var statusMessage: String?
    private var usedEventIDs: Set<String> = []
    private var returnToChartAfterSelection = false
    private var selectionQueue: [PendingSelection] = []

    // MARK: Pantheon
    /// The god presiding over the current spoils screen or shrine, if any.
    private(set) var visitingDeity: Deity?
    /// True when the offering screen is a bank shrine rather than post-battle spoils.
    private(set) var isShrine = false

    // MARK: Personal leaderboard
    private(set) var leaderboard: [RunRecord] = []
    /// The run that just finished, so it can be highlighted in the table.
    private(set) var latestRecordID: UUID?

    init() {
        leaderboard = LeaderboardStore.load()
    }

    // MARK: - Derived

    var classID: String { heroClass?.id ?? "archer" }

    var allDice: [Die] { loadout?.allDice ?? [] }

    /// The turn ceiling: the class maximum. Nothing raises it permanently any
    /// more — the round allowance is the whole stamina economy.

    var diceCount: Int { loadout?.diceCount ?? 0 }

    var bestRecord: RunRecord? { leaderboard.first }

    var activeNode: VoyageNode? { currentNodeID.flatMap { voyage.node($0) } }

    var lastClearedNode: VoyageNode? { lastClearedNodeID.flatMap { voyage.node($0) } }

    /// Which hour the barque is in: the node it sits at, or the next open water.
    var currentHour: Int {
        if let node = activeNode { return node.hour }
        if let last = lastClearedNode {
            return min(Voyage.totalHours, last.isHourEnd ? last.hour + 1 : last.hour)
        }
        return deepestHour
    }

    /// How many hours the barque has fully sailed through.
    var hoursCleared: Int {
        min(Voyage.totalHours, clearedNodeIDs.filter { voyage.node($0)?.isHourEnd ?? false }.count)
    }

    /// Which gate of the night the barque is passing through.
    var gate: Gate { Gate.forHour(currentHour) }

    /// How far along the night you are, 0 through 1.
    var progress: Double {
        Double(clearedNodeIDs.count) / Double(Voyage.totalStages)
    }

    /// How brightly Ra's disc is still burning — your health, dimmed by depth.
    var discGlow: Double {
        let health = maxHP > 0 ? Double(currentHP) / Double(maxHP) : 1
        return max(0.18, min(1, 0.35 + health * 0.65) * gate.discBrightness)
    }

    /// The stop the barque is sailing into next. An ordinary stop offers two
    /// channels; a herald or a serpent-lord is the only water there is.
    var availableNodes: [VoyageNode] {
        voyage.nodes(inStage: nextStage)
    }

    /// Which stop of the night is open now.
    var nextStage: Int {
        guard let last = lastClearedNode else { return 0 }
        return min(Voyage.totalStages - 1, last.stage + 1)
    }

    func isNodeAvailable(_ node: VoyageNode) -> Bool {
        availableNodes.contains { $0.id == node.id }
    }

    /// Gods with a claim on dice you carry.
    var patrons: Set<Deity> {
        Set(allDice.compactMap(\.patron))
    }

    /// Gods you follow, by number of claimed dice, strongest first.
    var followedDeities: [(deity: Deity, dice: Int)] {
        var counts: [Deity: Int] = [:]
        for die in allDice {
            if let patron = die.patron { counts[patron, default: 0] += 1 }
        }
        return counts.map { (deity: $0.key, dice: $0.value) }
            .sorted { $0.dice == $1.dice ? $0.deity.rawValue < $1.deity.rawValue : $0.dice > $1.dice }
    }

    /// Upgrades that are live right now: earned, and their god still carries
    /// a die. Upgrades tied to a god you no longer carry go quiet.
    var activeUpgrades: Set<String> {
        let gods = patrons
        return Set(acquiredUpgrades.filter { id in
            GodKit.upgrades.first { $0.id == id }.map { gods.contains($0.deity) } ?? false
        })
    }

    /// The capstone this run is riding, if its god is still equipped.
    var activeCapstone: GodCapstone? {
        guard let capstoneID,
              let capstone = GodKit.capstones.first(where: { $0.id == capstoneID }),
              patrons.contains(capstone.deity) else { return nil }
        return capstone
    }

    /// True when at least one earned upgrade belongs to this god.
    func carriesUpgrade(of deity: Deity) -> Bool {
        GodKit.upgrades(for: deity).contains { activeUpgrades.contains($0.id) }
    }

    /// True when the pairing's conditions hold right now: both gods blessed
    /// and at least one upgrade from each.
    func pairingReady(_ pairing: PairingDef) -> Bool {
        patrons.contains(pairing.first) && patrons.contains(pairing.second)
            && carriesUpgrade(of: pairing.first) && carriesUpgrade(of: pairing.second)
    }

    /// The pairing this run is riding, if its conditions still hold.
    var activePairing: PairingDef? {
        guard let pairingID,
              let pairing = PairingContent.pairings.first(where: { $0.id == pairingID }),
              pairingReady(pairing) else { return nil }
        return pairing
    }

    /// A capstone may be taken once two upgrades of its god are earned and a
    /// blessed die of that god is carried.
    func capstoneUnlocked(_ capstone: GodCapstone) -> Bool {
        GodKit.capstoneUnlocked(capstone, upgrades: activeUpgrades) && patrons.contains(capstone.deity)
    }

    /// Dice that could still take a first patron.
    var unblessedDice: [Die] { allDice.filter { $0.patron == nil } }

    /// Where the finished run placed, if it made the table.
    var latestRank: Int? {
        guard let latestRecordID,
              let index = leaderboard.firstIndex(where: { $0.id == latestRecordID }) else { return nil }
        return index + 1
    }

    // MARK: - Saved nights

    /// The saved night waiting to be picked up, if there is one. Read when the
    /// title screen appears so the Continue card can describe it.
    private(set) var savedRun: RunSave? = RunSaveStore.load()

    var hasSavedRun: Bool { savedRun != nil }

    /// True while the pause panel is up. The fight keeps its state; it simply
    /// stops being touchable behind the panel.
    var isPaused = false

    // MARK: - The opening briefing

    /// The demigod the briefing is teaching. Set before the run proper starts,
    /// so the demo and the class page read from the dice you actually picked.
    private(set) var tutorialHero: HeroClass?
    /// True when the briefing was opened from the title screen for a read
    /// rather than as the doorstep of a new run — closing it goes back to the
    /// title instead of casting off.
    private(set) var tutorialIsPreview = false

    /// Opens the briefing from the title screen, for a class you are looking
    /// at rather than one you have committed to.
    func openBriefing(for hero: HeroClass) {
        tutorialHero = hero
        tutorialIsPreview = true
        Audio.shared.play(.uiTap)
        withAnimation { screen = .tutorial }
    }

    /// Closes the briefing. A briefing that opened a run hands over to the
    /// first guardian; one opened from the title simply goes back.
    func finishBriefing(suppressFuture: Bool = false) {
        if suppressFuture { TutorialStore.suppress() }
        let wasPreview = tutorialIsPreview
        tutorialIsPreview = false
        Audio.shared.play(.uiConfirm)
        if wasPreview {
            withAnimation { screen = .title }
        } else {
            castOff()
        }
    }

    /// Writes the night down. Only ever called between fights — a rolled hand
    /// is never part of a save, so a saved night cannot be reloaded and
    /// re-rolled for a better result.
    ///
    /// `atNode` is the stage to resume at. While a fight is underway that is
    /// the fight's own node, so the night resumes at the *start* of it with
    /// the health and gear you walked in with.
    func saveRun(resumingAt node: UUID?) {
        guard let heroClass, let loadout, screen != .title else { return }
        let save = RunSave(
            classID: heroClass.id,
            loadout: loadout,
            maxHP: maxHP,
            currentHP: currentHP,
            gold: gold,
            critBonus: critBonus,
            equippedBoons: equippedBoons,
            legendariesTaken: legendariesTaken,
            acquiredUpgrades: Array(acquiredUpgrades),
            capstoneID: capstoneID,
            pairingID: pairingID,
            ownedChisels: ownedChisels,
            trialUsed: trialUsed,
            voyage: voyage,
            clearedNodeIDs: Array(clearedNodeIDs),
            lastClearedNodeID: lastClearedNodeID,
            currentNodeID: node,
            deepestHour: deepestHour,
            usedEventIDs: Array(usedEventIDs),
            totalDamage: totalDamage,
            totalCombos: totalCombos,
            totalCrits: totalCrits,
            savedAt: Date()
        )
        RunSaveStore.save(save)
        savedRun = save
    }

    /// The autosave taken every time the barque returns to open water: after a
    /// reward is claimed, and on leaving a shop or an omen.
    private func autosave() {
        // Nothing is in flight here, so the save resumes exactly where it is.
        saveRun(resumingAt: nil)
    }

    /// Puts the run away and returns to the title. A fight in progress is
    /// saved at its own doorstep rather than mid-blow.
    func saveAndExit() {
        let resumeNode = screen == .battle ? currentNodeID : nil
        saveRun(resumingAt: resumeNode)
        isPaused = false
        battle = nil
        pendingSelection = nil
        selectionQueue = []
        statusMessage = nil
        Audio.shared.play(.uiConfirm)
        withAnimation { screen = .title }
    }

    /// Throws the night away for good.
    func abandonRun() {
        clearSavedRun()
        isPaused = false
        battle = nil
        pendingSelection = nil
        selectionQueue = []
        statusMessage = nil
        Haptics.warning()
        withAnimation { screen = .title }
    }

    private func clearSavedRun() {
        RunSaveStore.clear()
        savedRun = nil
    }

    /// Picks a saved night back up. A fight that was underway resumes at its
    /// own start: the same creatures, but the dice roll fresh.
    func continueRun() {
        guard let save = savedRun, save.version == RunSave.currentVersion else {
            statusMessage = "This voyage uses the previous combat rules. Cast Off to start the same-face rework; your old save remains until you confirm."
            return
        }
        let hero = save.hero
        heroClass = hero
        loadout = save.loadout
        maxHP = save.maxHP
        currentHP = save.currentHP
        gold = save.gold
        critBonus = save.critBonus
        equippedBoons = save.equippedBoons
        legendariesTaken = save.legendariesTaken
        acquiredUpgrades = Set(save.acquiredUpgrades)
        capstoneID = save.capstoneID
        pairingID = save.pairingID
        ownedChisels = save.ownedChisels
        trialUsed = save.trialUsed
        voyage = save.voyage
        clearedNodeIDs = Set(save.clearedNodeIDs)
        lastClearedNodeID = save.lastClearedNodeID
        currentNodeID = nil
        deepestHour = save.deepestHour
        usedEventIDs = Set(save.usedEventIDs)
        totalDamage = save.totalDamage
        totalCombos = save.totalCombos
        totalCrits = save.totalCrits
        isPtahForge = false
        crossedGate = nil
        battle = nil
        rewardOffers = []
        shopStock = []
        currentEvent = nil
        eventOutcome = nil
        pendingSelection = nil
        selectionQueue = []
        visitingDeity = nil
        isShrine = false
        isPaused = false
        latestRecordID = nil
        statusMessage = "The night takes you back — \(save.placeLabel)."
        Haptics.success()

        // A fight that was underway is re-entered from its doorstep; anything
        // quiet simply hands the chart back.
        if let nodeID = save.currentNodeID, let node = voyage.node(nodeID) {
            currentNodeID = node.id
            deepestHour = max(deepestHour, node.hour)
            enterBattle()
        } else {
            withAnimation { screen = .chart }
        }
    }

    // MARK: - Flow

    func startRun(with hero: HeroClass) {
        heroClass = hero
        loadout = hero.startingLoadout
        maxHP = hero.maxHP
        currentHP = hero.maxHP
        gold = 40
        critBonus = 0
        equippedBoons = []
        legendariesTaken = 0
        acquiredUpgrades = []
        capstoneID = nil
        pairingID = nil
        totalDamage = 0
        totalCombos = 0
        totalCrits = 0
        ownedChisels = []
        isPtahForge = false
        trialUsed = false
        voyage = Voyage.generate()
        clearedNodeIDs = []
        lastClearedNodeID = nil
        currentNodeID = nil
        deepestHour = 1
        crossedGate = .reeds
        usedEventIDs = []
        battle = nil
        rewardOffers = []
        shopStock = []
        currentEvent = nil
        pendingSelection = nil
        selectionQueue = []
        visitingDeity = nil
        isShrine = false
        latestRecordID = nil
        statusMessage = nil
        isPaused = false
        // A fresh voyage writes over any night that was still waiting.
        clearSavedRun()
        Haptics.success()

        // The briefing comes first, taught in this demigod's own dice, unless
        // the player has asked never to see it again.
        tutorialHero = hero
        if TutorialStore.isSuppressed {
            castOff()
        } else {
            tutorialIsPreview = false
            withAnimation { screen = .tutorial }
        }
    }

    /// The barque casts off straight into the mouth of the river — the chart
    /// opens once that first guardian is down.
    private func castOff() {
        if let entry = voyage.entryNode {
            enter(entry)
        } else {
            withAnimation { screen = .chart }
        }
    }

    /// Sail into a stage of the river and take whatever waits there.
    var canRerollDestination: Bool {
        availableNodes.contains { voyage.canReroll($0) }
    }

    @discardableResult
    func rerollDestination(_ nodeID: UUID) -> Bool {
        guard screen == .chart, availableNodes.contains(where: { $0.id == nodeID }),
              voyage.rerollDestination(nodeID) else { return false }
        autosave()
        return true
    }

    func enter(_ proposedNode: VoyageNode) {
        guard let node = availableNodes.first(where: { $0.id == proposedNode.id }) else { return }
        currentNodeID = node.id
        deepestHour = max(deepestHour, node.hour)
        Haptics.medium()
        switch node.kind {
        case .battle, .herald, .boss:
            enterBattle()
        case .ferryman:
            shopStock = makeShopStock()
            withAnimation { screen = .shop }
        case .omen:
            let event = EventContent.random(excluding: usedEventIDs)
            usedEventIDs.insert(event.id)
            currentEvent = event
            eventOutcome = nil
            withAnimation { screen = .event }
        case .shrine:
            enterShrine()
        }
    }

    /// A god holds court on the bank. Shrines are the reliable place to
    /// receive a god's favour: a patron claim, upgrades, a capstone once it
    /// is unlocked, or the pairing with a god you already follow.
    private func enterShrine() {
        let deity = Deity.allCases.randomElement() ?? .ra
        visitingDeity = deity
        isShrine = true
        rewardOffers = makeGodFavourOffers(deity: deity, count: 3, progress: progress)
        statusMessage = deity.greeting
        withAnimation { screen = .reward }
    }

    private func enterBattle() {
        guard let hero = heroClass, let loadout, let node = activeNode else { return }
        let enemies: [EnemyDef]
        switch node.kind {
        case .boss:
            enemies = [EnemyContent.enemy(hour: node.hour, isHerald: false)]
        case .herald:
            let base = EnemyContent.gateRoster(node.gate).randomElement()
                ?? EnemyContent.enemy(hour: node.hour, isHerald: false)
            enemies = [base.herald()]
        default:
            if isOpeningEncounter {
                // The night opens on the practice bank: a straw effigy that
                // never fights back, and a god's first audience for spoils.
                enemies = [EnemyContent.trainingDummy]
            } else {
                enemies = makePack(gate: node.gate, allowPack: true)
            }
        }
        // Any ordinary fight can quietly turn out to be a god's Trial — never
        // before a blessing is carried, never on a herald,
        // a serpent-lord or the last quiet water before one.
        var trial: DivineTrial? = nil
        if node.kind == .battle, !isOpeningEncounter, !trialUsed, !patrons.isEmpty,
           !leadsToBoss(node), Double.random(in: 0..<1) < GameData.trialChance {
            trial = DivineTrial.random()
        }

        battle = BattleEngine(
            enemies: enemies,
            dice: loadout.allDice,
            classID: hero.id,
            maxHP: maxHP,
            startHP: currentHP,

            hour: node.hour,
            critBonus: critBonus,
            boons: equippedBoons,
            patrons: patrons,
            upgrades: activeUpgrades,
            capstoneID: activeCapstone?.id,
            pairing: activePairing,
            chisels: Set(ownedChisels),
            trial: trial
        )
        withAnimation { screen = .battle }
    }

    /// The last quiet water before a serpent-lord never hosts a Trial.
    private func leadsToBoss(_ node: VoyageNode) -> Bool {
        let next = node.stage + 1
        guard next < Voyage.totalStages else { return false }
        return Voyage.spine(ofStage: next) == .boss
    }

    /// The very first fight of a run — nothing cleared behind you yet. The
    /// night always opens on a single foe so a fresh loadout gets one clean
    /// look at its own dice before the reeds start sending pairs.
    private var isOpeningEncounter: Bool { clearedNodeIDs.isEmpty }

    /// Draws the foes for a regular battle: usually one, sometimes a pack of
    /// two or three from the same gate. One foe may rise armoured. When packs
    /// are barred the fight is always a lone foe, still able to wear a plate.
    private func makePack(gate: Gate, allowPack: Bool) -> [EnemyDef] {
        let roster = EnemyContent.gateRoster(gate)
        func solo() -> [EnemyDef] {
            var foe = roster.randomElement() ?? EnemyContent.reedLurker
            if Double.random(in: 0..<1) < GameData.eliteArmourChance { foe = foe.armoured() }
            return [foe]
        }
        guard allowPack else { return solo() }
        guard Double.random(in: 0..<1) < GameData.packChance else { return solo() }
        let count = Double.random(in: 0..<1) < GameData.packTrioChance ? 3 : 2
        let members = roster.shuffled().prefix(count).map { $0.packMember() }
        guard members.count > 1 else { return solo() }
        // Occasionally one of the pack wears a plate as well.
        var result = members
        if Double.random(in: 0..<1) < GameData.eliteArmourChance {
            result[0] = members[0].armoured()
        }
        return result
    }

    func concludeBattle() {
        guard let battle else { return }
        totalDamage += battle.damageDealt
        totalCombos += battle.combosLanded
        totalCrits += battle.critsLanded
        currentHP = battle.playerHP

        if battle.phase == .lost {
            self.battle = nil
            recordRun(sawDawn: false)
            // Going under ends the night for good — a finished run can never be
            // reloaded to farm the table.
            clearSavedRun()
            withAnimation { screen = .gameOver(won: false) }
            return
        }

        // Apep falls and the sun comes up.
        if activeNode?.isBoss == true && currentHour >= Voyage.totalHours {
            self.battle = nil
            recordRun(sawDawn: true)
            clearSavedRun()
            withAnimation { screen = .gameOver(won: true) }
            return
        }

        // Roughly twice as many stages as the old voyage, so the purse is tuned down.
        // Packs pay a little better than a single foe, but not per-member full.
        let baseGold = battle.enemies.reduce(0) { $0 + $1.def.goldReward }
        let earned = max(6, Int(Double(GameData.goldReward(base: baseGold, progress: progress)) * 0.6))
        gold += earned
        // A won Trial hands the turn over to its god: the spoils become a
        // choice of three of that god's own boons.
        let wonTrial = battle.trialAccepted && battle.phase == .won
        let trialGod = wonTrial ? battle.trial?.deity : nil
        if wonTrial { trialUsed = true }
        self.battle = nil

        // The practice bout ends at your first god's audience: one god, chosen
        // at random, offering three of their powers. The collection stays at
        // eight dice and the gods speak through powers now.
        if isOpeningEncounter {
            let deity = Deity.allCases.randomElement() ?? .ra
            visitingDeity = deity
            isShrine = false
            rewardOffers = makeGodFavourOffers(deity: deity, count: 3, progress: progress)
            statusMessage = deity.greeting
            withAnimation { screen = .reward }
            return
        }

        let kind = activeNode?.kind
        // The collection stays at eight dice, so a serpent-lord pays out in a
        // god's audience rather than more gear. Bosses and heralds are where a
        // god reliably comes to the water's edge.
        let godAttends = kind == .boss
            || (kind == .herald && Int.random(in: 0..<100) < 62)
            || Int.random(in: 0..<100) < 42

        // Ptah is the one craftsman who only ever works at the end of a fight,
        // and he takes the whole reward when he comes: three Chisels on the
        // bench instead of a god's three boons. A Trial's own god outranks him.
        let unownedChisels = ChiselCatalog.chisels(for: classID)
            .filter { !ownedChisels.contains($0.id) }
        let ptahAttends = trialGod == nil
            && ownedChisels.count < GameData.chiselMaxPerRun
            && !unownedChisels.isEmpty
            && shouldDropChisel()

        var spoils: [Offer]
        if ptahAttends {
            visitingDeity = nil
            isShrine = false
            isPtahForge = true
            spoils = unownedChisels.shuffled().prefix(3).map(makeChiselOffer)
        } else if let trialGod {
            visitingDeity = trialGod
            isShrine = false
            spoils = makeGodFavourOffers(deity: trialGod, count: 3, progress: progress)
        } else if godAttends {
            let deity = Deity.allCases.randomElement() ?? .ra
            visitingDeity = deity
            isShrine = false
            spoils = makeGodFavourOffers(deity: deity, count: 3, progress: progress)
        } else {
            visitingDeity = nil
            isShrine = false
            spoils = makeMundaneSpoils(count: 3)
        }
        rewardOffers = spoils
        statusMessage = "+\(earned) gold · \(currentHP)/\(maxHP) health"
        if let trialGod {
            statusMessage = "The trial is won — \(trialGod.name) offers a boon."
        }
        withAnimation { screen = .reward }
    }

    /// Ptah rarely turns up in the spoils. One Chisel is guaranteed somewhere
    /// in the first four hours; a second only reaches a small share of runs.
    private func shouldDropChisel() -> Bool {
        if ownedChisels.isEmpty { return currentHour >= 3 }
        return ownedChisels.count == 1 && currentHour >= 7
    }

    /// One Chisel on Ptah's bench, read like a god's boon card. The worked
    /// example folds into the main text rather than being squeezed into a
    /// footnote capsule, so a Chisel reads as one block: what it changes,
    /// then what that looks like in practice.
    private func makeChiselOffer(_ chisel: ChiselDef) -> Offer {
        Offer(
            name: chisel.name,
            detail: "\(chisel.detail)\n\n\(chisel.example)",
            symbol: chisel.symbol,
            rarity: .signature,
            comboHint: chisel.example,
            price: 0,
            kind: .chiselPick(chisel)
        )
    }

    /// The river's own spoils: gold in hand, a little health, or — rarely —
    /// the chance to change one face on a die. Always three usable choices.
    private func makeMundaneSpoils(count: Int) -> [Offer] {
        var offers: [Offer] = []
        let gold = 25 + Int(progress * 40)
        offers.append(Offer(
            name: "Grave-Goods",
            detail: "+\(gold) gold, pried from the river's leavings.",
            symbol: "creditcard.fill",
            rarity: .common,
            comboHint: "The Ferryman takes gold",
            price: 0,
            kind: .gold(gold)
        ))
        let heal = 15 + Int(progress * 20)
        offers.append(Offer(
            name: "Bandages and Beer",
            detail: "Restore \(heal) health right now.",
            symbol: "cross.vial.fill",
            rarity: .common,
            comboHint: "Live long enough to combo",
            price: 0,
            kind: .heal(heal)
        ))
        if Double.random(in: 0..<1) < 0.18,
           let pick = GameData.faceOffers(classID, Rarity.roll(progress: progress)).randomElement() {
            offers.append(Offer(
                name: "Reforge → \(pick.face.label)",
                detail: "Turn any one face on any die into \(pick.face.label). \(pick.face.soloEffect).",
                symbol: pick.face.symbol,
                rarity: .uncommon,
                comboHint: pick.hint,
                price: 0,
                kind: .reforge(pick.face)
            ))
        }
        while offers.count < count, let fill = makeOffer(rarity: Rarity.roll(progress: progress), priced: false, index: offers.count) {
            offers.append(fill)
        }
        return Array(offers.prefix(max(count, 3)))
    }

    /// Closes out whatever the barque just did and points it back at the chart.
    func completeEncounter() {
        if let node = activeNode {
            clearedNodeIDs.insert(node.id)
            lastClearedNodeID = node.id
            currentNodeID = nil
            if node.isBoss, node.hour < Voyage.totalHours {
                let nextGate = Gate.forHour(node.hour + 1)
                crossedGate = nextGate
                if nextGate == .fire {
                    statusMessage = "The Fire Gate — you may hold three faces between turns now."
                }
            }
        }
        rewardOffers = []
        shopStock = []
        currentEvent = nil
        eventOutcome = nil
        statusMessage = nil
        visitingDeity = nil
        isShrine = false
        isPtahForge = false
    }

    func leaveEncounter() {
        completeEncounter()
        // Back on open water with nothing in flight: the honest moment to
        // write the night down.
        autosave()
        withAnimation { screen = .chart }
    }

    func returnToTitle() {
        battle = nil
        pendingSelection = nil
        withAnimation { screen = .title }
    }

    // MARK: - Leaderboard

    /// Files the finished run into the device's personal top ten.
    private func recordRun(sawDawn: Bool) {
        guard let hero = heroClass else { return }
        let reached = sawDawn ? Voyage.totalHours : currentHour
        let cleared = sawDawn ? Voyage.totalHours : hoursCleared
        let record = RunRecord(
            id: UUID(),
            classID: hero.id,
            className: hero.name,
            classSymbol: hero.symbol,
            hourReached: reached,
            hoursCleared: cleared,
            sawDawn: sawDawn,
            damageDealt: totalDamage,
            combos: totalCombos,
            crits: totalCrits,
            date: Date()
        )
        latestRecordID = record.id
        leaderboard = LeaderboardStore.insert(record)
    }

    func clearLeaderboard() {
        LeaderboardStore.clear()
        leaderboard = []
        latestRecordID = nil
        Haptics.warning()
    }

    // MARK: - Rewards & the Ferryman

    /// Claim a free reward card after a fight or at a shrine.
    func claimReward(_ offer: Offer) {
        returnToChartAfterSelection = true
        apply(offer)
        if pendingSelection == nil {
            leaveEncounter()
        }
    }

    func skipReward() {
        gold += 15
        leaveEncounter()
    }

    /// Buy something from the Ferryman's boat.
    func purchase(_ offer: Offer) {
        guard gold >= offer.price else {
            statusMessage = "Not enough gold."
            Haptics.warning()
            return
        }
        gold -= offer.price
        shopStock.removeAll { $0.id == offer.id }
        returnToChartAfterSelection = false
        apply(offer)
        if pendingSelection == nil {
            statusMessage = "\(offer.name) acquired."
        }
    }

    // MARK: - Applying an offer

    private func apply(_ offer: Offer) {
        Haptics.success()
        // A god's favour rings in its own register; the river's own spoils
        // just land on the deck.
        Audio.shared.play(offer.deity == nil ? .uiConfirm : .boon)
        switch offer.kind {
        case .die(let die):
            grant(die: die.instantiated())
        case .reforge(let face):
            pendingSelection = .reforge(face, title: offer.name)
        case .boon(let def, let rarity):
            equip(boon: def, rarity: rarity)
        case .boonLevel(let owned):
            levelUp(owned)
        case .legendary(let def, let rarity):
            evolve(into: def, rarity: rarity)
        case .patron(let deity, let replace):
            pendingSelection = .patron(deity, replace: replace, title: offer.name)
        case .upgrade(let upgrade):
            applyUpgrade(upgrade)
        case .capstone(let capstone):
            applyCapstone(capstone)
        case .pairing(let pairing):
            applyPairing(pairing)
        case .imbue(let amount):
            pendingSelection = .imbue(amount, title: offer.name)
        case .heal(let amount):
            currentHP = min(maxHP, currentHP + amount)
            statusMessage = "+\(amount) health"
        case .maxHP(let amount):
            maxHP += amount
            currentHP = min(maxHP, currentHP + amount)
            statusMessage = "+\(amount) max health"
        case .gold(let amount):
            gold += amount
            statusMessage = "+\(amount) gold"
        case .reforgeDie:
            pendingSelection = .reforgeDie(title: offer.name)
        case .chiselPick(let chisel):
            guard !ownedChisels.contains(chisel.id) else { return }
            ownedChisels.append(chisel.id)
            statusMessage = "\(chisel.name) struck — Ptah reshapes your weapon."
        }
    }

    private func grant(die: Die) {
        guard var loadout else { return }
        if loadout.add(die) {
            self.loadout = loadout
            statusMessage = "\(die.name) added to your \(die.slot.label.lowercased())."
        } else {
            pendingSelection = .swapDie(die)
        }
    }

    // MARK: - Resolving pending selections

    func applyReforge(dieID: UUID, faceID: UUID, to kind: FaceKind) {
        guard var loadout, SameFaceCatalog.palette(for: classID).contains(kind),
              let selected = loadout.die(id: dieID),
              selected.faces.filter({ $0.kind == kind && $0.id != faceID }).count < 3 else {
            statusMessage = "A die can carry at most three sides of the same face. Choose another die."
            return
        }
        loadout.mutate(dieID: dieID) { die in
            if let index = die.faces.firstIndex(where: { $0.id == faceID }) {
                die.faces[index] = die.faces[index].reforged(to: kind)
            }
        }
        self.loadout = loadout
        finishSelection("Face reforged into \(kind.label).")
    }

    /// The Ferryman's deep whetstone: every face on the chosen die is rolled
    /// anew from the class's pool at the die's rarity. The patron claim rides
    /// through untouched — a new face is the same claim.
    func applyDieReforge(dieID: UUID) {
        guard var loadout, let die = loadout.die(id: dieID) else { return }
        guard let pick = GameData.diceOffers(classID, die.rarity).randomElement()
                ?? GameData.diceOffers(classID, .common).randomElement() else { return }
        let fresh = pick.die.instantiated().faces
        var index = 0
        loadout.mutate(dieID: dieID) { target in
            target.faces = target.faces.map { face in
                guard index < fresh.count else { return face }
                defer { index += 1 }
                return face.reforged(to: fresh[index].kind)
            }
        }
        self.loadout = loadout
        finishSelection("\(die.name) is rolled anew — every face redrawn at \(die.rarity.label) tier.")
    }

    func applyImbue(dieID: UUID, faceID: UUID, amount: Double) {
        guard var loadout else { return }
        var newChance = 0.0
        loadout.mutate(dieID: dieID) { die in
            if let index = die.faces.firstIndex(where: { $0.id == faceID }) {
                die.faces[index] = die.faces[index].imbued(by: amount)
                newChance = die.faces[index].critChance
            }
        }
        self.loadout = loadout
        finishSelection("Crit chance now \(Int(newChance * 100))%.")
    }

    /// A god claims a die as its patron. The faces never change; the god
    /// simply answers whatever those faces do from now on. Taking a die from
    /// another god only happens through the explicit replace cards.
    func applyPatron(dieID: UUID, deity: Deity, replace: Bool) {
        guard var loadout else { return }
        var line = ""
        loadout.mutate(dieID: dieID) { die in
            if let current = die.patron {
                guard replace, current != deity else { return }
                die.patron = deity
                line = "\(die.name) is taken from \(current.name) — \(deity.name) claims it now. \(current.name)'s upgrades go quiet."
            } else {
                die.patron = deity
                line = "\(deity.name) claims \(die.name). Their blessing now answers every face it plays."
            }
        }
        self.loadout = loadout
        finishSelection(line.isEmpty ? "That die cannot take this claim." : line)
    }

    /// Take one of a god's upgrades. Needs a blessed die of that god.
    func applyUpgrade(_ upgrade: GodUpgrade) {
        guard patrons.contains(upgrade.deity) else {
            finishSelection("That upgrade needs a blessed die of \(upgrade.deity.name)'s.")
            return
        }
        guard !acquiredUpgrades.contains(upgrade.id) else {
            finishSelection("You have already earned \(upgrade.name).")
            return
        }
        acquiredUpgrades.insert(upgrade.id)
        var line = "\(upgrade.name) earned — \(upgrade.detail)"
        if let capstone = GodKit.capstone(for: upgrade.deity),
           capstoneID == nil, capstoneUnlocked(capstone) {
            line += " · \(capstone.name) is unlocked."
        }
        if pairingID == nil {
            for pairing in PairingContent.pairings
            where pairing.first == upgrade.deity || pairing.second == upgrade.deity {
                if pairingReady(pairing) {
                    line += " · \(pairing.name) is available."
                    break
                }
            }
        }
        finishSelection(line)
    }

    // MARK: - God powers

    /// Powers equipped in one slot right now.
    func boons(in slot: BoonSlot) -> [EquippedBoon] {
        equippedBoons.filter { $0.def?.slot == slot }
    }

    /// Is there room for another power of this slot?
    func hasRoom(for slot: BoonSlot) -> Bool {
        boons(in: slot).count < slot.capacity
    }

    func owns(boon id: String) -> Bool {
        equippedBoons.contains { $0.defID == id }
    }

    /// Equip a new power. A card arrives at the rarity it was offered at and
    /// always starts on level 1 — rarity sets the ceiling, level climbs inside
    /// it. When its slot is full the player chooses what it replaces.
    func equip(boon def: GodBoonDef, rarity: BoonRarity) {
        guard !owns(boon: def.id) else {
            finishSelection("\(def.name) is already equipped.")
            return
        }
        guard hasRoom(for: def.slot) else {
            pendingSelection = .replaceBoon(def, rarity: rarity)
            return
        }
        equippedBoons.append(EquippedBoon(defID: def.id, rarity: rarity, level: 1))
        finishSelection("\(def.name) equipped — \(rarity.label) · \(def.slot.label).")
    }

    /// A repeat offer is explicitly a level, never a second copy: same slot,
    /// same rarity, one step stronger.
    func levelUp(_ owned: EquippedBoon) {
        guard let index = equippedBoons.firstIndex(where: { $0.defID == owned.defID }) else { return }
        guard equippedBoons[index].canLevel else {
            finishSelection("\(owned.def?.name ?? "That power") is already at its highest level.")
            return
        }
        equippedBoons[index].level += 1
        let now = equippedBoons[index]
        finishSelection("\(now.def?.name ?? "Power") → level \(now.level) (\(now.rarity.label)).")
    }

    /// A legendary goes into the run's single Legendary slot, so it never
    /// costs an Attack or Defence place. Carrying the power it evolved from
    /// consumes that copy and hands its rarity and level across; otherwise the
    /// card simply arrives at the rarity it was offered at. One per run.
    func evolve(into legendary: GodBoonDef, rarity: BoonRarity) {
        guard legendaryOfferable(legendary), let sourceID = legendary.evolves,
              let index = equippedBoons.firstIndex(where: { $0.defID == sourceID }) else { return }
        let source = equippedBoons[index]
        equippedBoons[index] = EquippedBoon(defID: legendary.id, rarity: source.rarity, level: source.level)
        legendariesTaken += 1
        finishSelection("\(legendary.name) evolves \(source.def?.name ?? "its source") in the same slot.")
    }

    /// Swap a new power in for one already equipped in that slot.
    func replaceBoon(_ oldID: String, with def: GodBoonDef, rarity: BoonRarity) {
        guard let index = equippedBoons.firstIndex(where: { $0.defID == oldID }) else { return }
        if def.kind == .duo {
            let remaining = Set(equippedBoons.filter { $0.defID != oldID }.compactMap { $0.def?.evolves ?? $0.def?.id })
            guard def.sources.allSatisfy({ !$0.members.isDisjoint(with: remaining) }) else {
                statusMessage = "Choose a replacement that keeps this duo’s source powers."
                return
            }
        }
        let replaced = equippedBoons[index].def?.name ?? "a power"
        equippedBoons[index] = EquippedBoon(defID: def.id, rarity: rarity, level: 1)
        finishSelection("\(def.name) takes the place of \(replaced).")
    }

    /// Can a legendary still turn up? The run allows one, and its slot must
    /// be free. No prerequisite: it is a rare find, not an assembly.
    func legendaryOfferable(_ legendary: GodBoonDef) -> Bool {
        guard legendariesTaken == 0, let source = legendary.evolves, owns(boon: source), !owns(boon: legendary.id) else { return false }
        return equippedBoons.contains { $0.defID != source && $0.def?.kind == .regular && $0.def?.god == legendary.god }
    }

    /// Commit to a capstone — one per run.
    func applyCapstone(_ capstone: GodCapstone) {
        guard capstoneID == nil else {
            finishSelection("You have already committed to a capstone this run.")
            return
        }
        guard capstoneUnlocked(capstone) else {
            finishSelection("Two upgrades of \(capstone.deity.name) are needed first.")
            return
        }
        capstoneID = capstone.id
        finishSelection("\(capstone.name) — \(capstone.detail)")
    }

    /// Commit to a pairing — one per run. Needs both gods blessed and an
    /// upgrade from each.
    func applyPairing(_ pairing: PairingDef) {
        guard pairingID == nil else {
            finishSelection("You have already committed to a pairing this run.")
            return
        }
        guard pairingReady(pairing) else {
            finishSelection("Both gods need a blessed die and one upgrade each.")
            return
        }
        pairingID = pairing.id
        finishSelection("\(pairing.name) — \(pairing.detail)")
    }

    func applySwap(replacing oldDieID: UUID, with newDie: Die) {
        guard var loadout else { return }
        loadout.remove(dieID: oldDieID)
        _ = loadout.add(newDie)
        self.loadout = loadout
        finishSelection("\(newDie.name) takes its place.")
    }

    /// Queues one or more targeting steps; a shrine pairing uses two.
    private func enqueue(_ selections: [PendingSelection]) {
        guard let first = selections.first else { return }
        selectionQueue = Array(selections.dropFirst())
        pendingSelection = first
    }

    func cancelSelection() {
        pendingSelection = nil
        selectionQueue = []
        if returnToChartAfterSelection {
            returnToChartAfterSelection = false
            leaveEncounter()
        }
    }

    private func finishSelection(_ message: String) {
        statusMessage = message
        Haptics.success()
        if !selectionQueue.isEmpty {
            pendingSelection = selectionQueue.removeFirst()
            return
        }
        pendingSelection = nil
        if returnToChartAfterSelection {
            returnToChartAfterSelection = false
            leaveEncounter()
        }
    }

    // MARK: - Omens

    func choose(_ choice: EventChoice) {
        guard let event = currentEvent else { return }
        if choice.goldCost > gold {
            statusMessage = "You cannot afford that."
            Haptics.warning()
            return
        }
        gold -= choice.goldCost
        if choice.maxHPChange != 0 {
            maxHP = max(20, maxHP + choice.maxHPChange)
            currentHP = min(currentHP, maxHP)
        }
        if choice.hpCost > 0 {
            currentHP = max(1, currentHP - choice.hpCost)
        }

        let rarity = Rarity.roll(progress: progress)
        var lines: [String] = []
        if choice.goldCost > 0 { lines.append("-\(choice.goldCost) gold") }
        if choice.hpCost > 0 { lines.append("-\(choice.hpCost) health") }
        if choice.maxHPChange != 0 { lines.append("\(choice.maxHPChange > 0 ? "+" : "")\(choice.maxHPChange) max health") }

        returnToChartAfterSelection = true
        switch choice.reward {
        case .none:
            break
        case .gold(let amount):
            gold += amount
            lines.append("+\(amount) gold")
        case .heal(let amount):
            currentHP = min(maxHP, currentHP + amount)
            lines.append("+\(amount) health")
        case .reforge:
            let pick = GameData.faceOffers(classID, rarity).randomElement()
            pendingSelection = .reforge(pick?.face ?? .heal, title: event.title)
        case .imbue:
            pendingSelection = .imbue(SharedContent.imbueAmount(rarity), title: event.title)
        case .die:
            if let pick = GameData.diceOffers(classID, rarity).randomElement() {
                grant(die: pick.die.instantiated())
                lines.append("Gained \(pick.die.name)")
            }
        case .patronOffer:
            // Gods no longer claim dice — an omen hands over one of their
            // powers instead, at a rarity rolled for this point in the night.
            let deity = Deity.allCases.randomElement() ?? .ra
            let pool = GodCatalog.regulars(of: deity).filter { !owns(boon: $0.id) }
            if let def = pool.randomElement() {
                let rarity = BoonRarity.roll(progress: progress)
                equip(boon: def, rarity: rarity)
                lines.append("\(deity.name) grants \(def.name) (\(rarity.label))")
            } else {
                let gift = 30 + Int(progress * 30)
                gold += gift
                lines.append("\(deity.name) has nothing left to teach you: +\(gift) gold")
            }
        case .gamble(let chance, let damage):
            if Double.random(in: 0..<1) < chance {
                let winnings = 40 + Int(progress * 50)
                gold += winnings
                lines.append("It pays off: +\(winnings) gold")
                Haptics.success()
            } else {
                currentHP = max(1, currentHP - damage)
                lines.append("It goes badly: -\(damage) health")
                Haptics.failure()
            }
        }

        eventOutcome = lines.isEmpty ? "The river carries you on, unchanged." : lines.joined(separator: " · ")
        if pendingSelection == nil {
            returnToChartAfterSelection = false
        }
    }

    // MARK: - Offer generation

    /// Rolls a set of class-appropriate offers for the current depth.
    func makeOffers(count: Int, progress: Double, priced: Bool) -> [Offer] {
        var offers: [Offer] = []
        var seenNames: Set<String> = []
        var attempts = 0
        while offers.count < count && attempts < count * 12 {
            attempts += 1
            let rarity = Rarity.roll(progress: progress)
            guard let offer = makeOffer(rarity: rarity, priced: priced, index: offers.count) else { continue }
            guard !seenNames.contains(offer.name) else { continue }
            seenNames.insert(offer.name)
            offers.append(offer)
        }
        return offers
    }

    private func makeOffer(rarity: Rarity, priced: Bool, index: Int) -> Offer? {
        // Items are gone, so their share of the shelf goes to the work that
        // always does something: reforges, crit etchings and restoratives.
        let roll = Int.random(in: 0..<100)
        let category: Int
        switch roll {
        case 0..<40: category = 1   // face reforge
        case 40..<74: category = 2  // crit imbue
        default: category = 4       // restorative
        }

        switch category {
        case 1:
            guard let pick = GameData.faceOffers(classID, rarity).randomElement() else { return nil }
            return Offer(
                name: "Reforge → \(pick.face.label)",
                detail: "Turn any one face on any die into \(pick.face.label). \(pick.face.soloEffect).",
                symbol: pick.face.symbol,
                rarity: rarity,
                comboHint: pick.hint,
                price: priced ? GameData.price(base: 30, rarity: rarity) : 0,
                kind: .reforge(pick.face)
            )
        case 2:
            let amount = SharedContent.imbueAmount(rarity)
            return Offer(
                name: GameData.imbueName(classID),
                detail: "Permanently add +\(Int(amount * 100))% crit chance to one face of your choosing.",
                symbol: GameData.imbueSymbol(classID),
                rarity: rarity,
                comboHint: "Crit dice make your combos crit",
                price: priced ? GameData.price(base: 40, rarity: rarity) : 0,
                kind: .imbue(amount)
            )
        default:
            if index % 2 == 0 {
                let amount = 25 + Int(progress * 30)
                return Offer(
                    name: "Bread and Beer",
                    detail: "Restore \(amount) health right now.",
                    symbol: "fork.knife",
                    rarity: .common,
                    comboHint: "Live long enough to combo",
                    price: priced ? GameData.price(base: 20, rarity: .common) : 0,
                    kind: .heal(amount)
                )
            }
            let amount = 12 + Int(progress * 14)
            return Offer(
                name: "Funerary Rations",
                detail: "Permanently raise your maximum health by \(amount).",
                symbol: "heart.circle.fill",
                rarity: .uncommon,
                comboHint: "The later hours need deeper reserves",
                price: priced ? GameData.price(base: 35, rarity: .uncommon) : 0,
                kind: .maxHP(amount)
            )
        }
    }

    // MARK: - Divine offerings

    /// A god's favour: a patron claim on an unblessed die, upgrades from their
    /// path, their capstone once it is unlocked, or the pairing with a god you
    /// already follow. Only the god standing there gives — every card is their
    /// own to make. Mundane offers fill any shortfall, so the screen always
    /// presents choices you can actually take.
    func makeGodFavourOffers(deity: Deity, count: Int, progress: Double) -> [Offer] {
        var cards: [Offer] = []

        // A level on a power of this god you already carry. A repeat is
        // explicitly an upgrade: same slot, same rarity, one step stronger.
        let levelable = equippedBoons.filter { owned in
            owned.def?.god == deity && owned.canLevel
        }.shuffled()
        if let owned = levelable.first, cards.count < count {
            cards.append(makeLevelOffer(owned))
        }

        // Everything else this god is holding, drawn from one pool: their ten
        // regulars, whichever duos they had a hand in making, and — rarely —
        // one of their legendaries. A duo and a legendary are ordinary cards
        // now, found the same way as anything else rather than earned through
        // a separate ceremony.
        var fresh = offerablePowers(of: deity).shuffled()
        while cards.count < count, !fresh.isEmpty {
            let def = fresh.removeFirst()
            if def.kind == .legendary {
                cards.append(makeLegendaryOffer(def, progress: progress))
            } else {
                cards.append(makeBoonOffer(def, rarity: BoonRarity.roll(progress: progress)))
            }
        }

        // Never force a no-op duplicate to fill the template — the river's own
        // spoils top up any shortfall instead.
        while cards.count < count,
              let fill = makeOffer(rarity: Rarity.roll(progress: progress),
                                   priced: false, index: cards.count) {
            cards.append(fill)
        }
        return Array(cards.prefix(max(count, 3)))
    }

    /// Every card this god could put on the table: their regulars, the duos
    /// they helped make, and their legendaries at the guide's rare odds. A
    /// legendary is rolled for once per meeting, so most nights never see one.
    private func usableBoon(_ def: GodBoonDef) -> Bool {
        guard let loadout else { return false }
        let reachable = SameFaceCatalog.actions(for: classID).filter { GameData.isReachable($0, loadout: loadout) && $0.faceCount >= def.minimumDice }
        switch def.trigger {
        case .onNativeHeal: return reachable.contains { $0.heal > 0 }
        case .firstEvade, .onDodge, .firstAttackAfterEvade: return reachable.contains { $0.roles.contains(.evade) }
        case .firstGuard, .everyGuard, .firstKeptGuard, .onShieldAbsorb, .firstAttackAfterGuard: return reachable.contains { $0.roles.contains(.guardian) }
        case .firstLargeCombo: return reachable.contains { $0.faceCount >= max(3, def.minimumDice) && $0.roles.contains(.attack) }
        case .firstTwoFaceCombo: return reachable.contains { $0.faceCount == 2 && $0.roles.contains(.attack) }
        default: return true
        }
    }

    private func offerablePowers(of deity: Deity) -> [GodBoonDef] {
        var pool = GodCatalog.regulars(of: deity).filter { !owns(boon: $0.id) && usableBoon($0) }
        pool += GodCatalog.duos(of: deity).filter { duo in
            !owns(boon: duo.id) && duoOfferable(duo)
        }
        if Double.random(in: 0..<1) < GameData.legendaryOfferChance {
            pool += GodCatalog.legendaries(of: deity)
                .filter { legendaryOfferable($0) }
                .shuffled().prefix(1)
        }
        return pool
    }

    /// Could this duo be equipped right now while keeping its prerequisites?
    /// Never offered when there is no legal way to hold it and its sources.
    private func duoOfferable(_ duo: GodBoonDef) -> Bool {
        let owned = Set(equippedBoons.compactMap { boon -> String? in
            guard let def = boon.def else { return nil }
            return def.kind == .legendary ? def.evolves : def.id
        })
        guard duo.sources.allSatisfy({ !$0.members.isDisjoint(with: owned) }) else { return false }
        // Two equipped duos at most, and it still needs a legal slot.
        let duoCount = equippedBoons.filter { $0.def?.kind == .duo }.count
        guard duoCount < 2 else { return false }
        return hasRoom(for: duo.slot) || sourcesSurviveReplacement(duo)
    }

    /// When a duo's slot is full, at least one power in it must be safe to
    /// replace without breaking that duo's own prerequisites.
    private func sourcesSurviveReplacement(_ duo: GodBoonDef) -> Bool {
        let inSlot = boons(in: duo.slot)
        return inSlot.contains { candidate in
            let remaining = Set(equippedBoons.compactMap { boon -> String? in
                guard boon.defID != candidate.defID, let def = boon.def else { return nil }
                return def.kind == .legendary ? def.evolves : def.id
            })
            return duo.sources.allSatisfy { !$0.members.isDisjoint(with: remaining) }
        }
    }

    /// A new power, with its rarity rolled and printed before the choice.
    private func makeBoonOffer(_ def: GodBoonDef, rarity: BoonRarity) -> Offer {
        let slotNote = hasRoom(for: def.slot)
            ? "\(def.slot.label) slot"
            : "\(def.slot.label) slot is full — you choose what it replaces"
        return Offer(
            name: def.name,
            detail: def.text(rarity: rarity, level: 1),
            symbol: def.god.symbol,
            rarity: .rare,
            comboHint: "\(rarity.label) · level 1 · \(slotNote)",
            price: 0,
            kind: .boon(def, rarity),
            deity: def.god
        )
    }

    /// A level on a power already carried: before and after, plainly stated.
    private func makeLevelOffer(_ owned: EquippedBoon) -> Offer {
        let next = min(owned.level + 1, boonMaxLevel)
        let def = owned.def
        let after = def?.text(rarity: owned.rarity, level: next) ?? ""
        return Offer(
            name: "\(def?.name ?? "Power") → \(next)",
            detail: after,
            symbol: def?.god.symbol ?? "sparkles",
            rarity: .uncommon,
            comboHint: "Level \(owned.level) → \(next) · keeps \(owned.rarity.label) · same slot",
            price: 0,
            kind: .boonLevel(owned),
            deity: def?.god
        )
    }

    /// A legendary: a rare find in its own slot. Carrying the power it evolved
    /// from hands that copy's rarity and level across; without it the card
    /// simply arrives at the rarity it rolled.
    private func makeLegendaryOffer(_ def: GodBoonDef, progress: Double) -> Offer {
        let source = equippedBoons.first { $0.defID == def.evolves }
        let rarity = source?.rarity ?? BoonRarity.roll(progress: progress)
        let level = source?.level ?? 1
        let note = source == nil
            ? "Legendary · \(rarity.label) level \(level) · its own slot"
            : "Legendary · carries \(GodCatalog.boon(def.evolves ?? "")?.name ?? "its source") at \(rarity.label) level \(level)"
        return Offer(
            name: def.name,
            detail: def.text(rarity: rarity, level: level),
            symbol: def.god.symbol,
            rarity: .signature,
            comboHint: note,
            price: 0,
            kind: .legendary(def, rarity),
            deity: def.god
        )
    }

    /// A patron claim: the god takes an unblessed die of your choosing. Their
    /// faces never change — the blessing simply starts answering them.
    private func makePatronOffer(deity: Deity, priced: Bool) -> Offer {
        Offer(
            name: "\(deity.name)'s Claim",
            detail: "\(deity.name) claims one of your unblessed dice. The faces never change — from then on, their blessing answers every face that die plays. \(deity.pitch)",
            symbol: deity.symbol,
            rarity: .rare,
            comboHint: "Blessed dice open this god's upgrades",
            price: priced ? GameData.price(base: 70, rarity: .rare) : 0,
            kind: .patron(deity, replace: false),
            deity: deity
        )
    }

    /// One upgrade card from a god's path.
    private func makeUpgradeOffer(_ upgrade: GodUpgrade) -> Offer {
        Offer(
            name: upgrade.name,
            detail: "\(upgrade.deity.name)'s upgrade — \(upgrade.detail) Needs a blessed die of \(upgrade.deity.name)'s.",
            symbol: upgrade.symbol,
            rarity: .uncommon,
            comboHint: "Builds toward \(upgrade.deity.name)'s capstone",
            price: 0,
            kind: .upgrade(upgrade),
            deity: upgrade.deity
        )
    }

    /// A capstone card: the last word of a god's path, once it is unlocked.
    private func makeCapstoneOffer(_ capstone: GodCapstone) -> Offer {
        Offer(
            name: capstone.name,
            detail: "\(capstone.deity.name)'s capstone — \(capstone.detail) One capstone per run.",
            symbol: capstone.symbol,
            rarity: .signature,
            comboHint: "One per run",
            price: 0,
            kind: .capstone(capstone),
            deity: capstone.deity
        )
    }

    /// A pairing card: two gods standing together, once per run.
    private func makePairingOffer(_ pairing: PairingDef) -> Offer {
        Offer(
            name: pairing.name,
            detail: "\(pairing.first.name) & \(pairing.second.name) — \(pairing.detail) One pairing per run.",
            symbol: pairing.symbol,
            rarity: .rare,
            comboHint: "Needs both gods equipped",
            price: 0,
            kind: .pairing(pairing),
            deity: pairing.first
        )
    }

    /// The deep whetstone: reroll every unclaimed face on one die.
    private func makeReforgeDieOffer() -> Offer {
        Offer(
            name: "Whetstone Ritual",
            detail: "Pick one of your dice — every face the gods have not claimed is rolled anew from your class's pool, at that die's rarity. Fix a weak die instead of carrying it.",
            symbol: "arrow.triangle.2.circlepath",
            rarity: .uncommon,
            comboHint: "A weak die in the pool dilutes every draw",
            price: GameData.price(base: 55, rarity: .uncommon),
            kind: .reforgeDie
        )
    }

    private func makeShopStock() -> [Offer] {
        var stock = makeOffers(count: 5, progress: progress, priced: true)
        // Roughly one crossing in three, the deep whetstone is out: a whole
        // die's unclaimed faces rolled anew.
        if Int.random(in: 0..<100) < 35 {
            stock.insert(makeReforgeDieOffer(), at: 0)
        }
        let healAmount = 30 + Int(progress * 30)
        stock.append(Offer(
            name: "Ferryman's Flask",
            detail: "Restore \(healAmount) health.",
            symbol: "cup.and.saucer.fill",
            rarity: .common,
            comboHint: "Straight to the bones",
            price: GameData.price(base: 22, rarity: .common),
            kind: .heal(healAmount)
        ))
        return stock
    }

    private func faceSummary(_ die: Die) -> String {
        var counts: [FaceKind: Int] = [:]
        for face in die.faces { counts[face.kind, default: 0] += 1 }
        return counts
            .sorted { $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value }
            .map { "\($0.value)× \($0.key.label)" }
            .joined(separator: ", ")
    }
}


