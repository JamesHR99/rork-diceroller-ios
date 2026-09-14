import SwiftUI
import Observation

/// Something the player must aim at a specific die or face before the voyage continues.
enum PendingSelection: Equatable {
    /// Reforge one face of your choice into this kind.
    case reforge(FaceKind, title: String)
    /// Reroll every face the gods have not claimed on one die of your choice.
    case reforgeDie(title: String)
    /// Lay a god's named gift on one face — deepening the same gift on a face
    /// that already carries it, or (rarely) replacing whatever it carries.
    case gift(GiftDef, replace: Bool, title: String)
    /// Bind a second god onto a face that is unclaimed or marked by the first.
    case rite(primary: Deity, secondary: Deity, title: String)
    /// Raise one chosen face's crit chance by this much.
    case imbue(Double, title: String)
    /// You are at the dice cap — pick which die this one replaces.
    case swapDie(Die)
    /// You already carry an item — confirm the swap.
    case swapItem(ItemDef)
}

/// Run-level state: class, permanent loadout, gold, the twelve hours of the
/// night, the landings between them, and the upgrade flows that hang off them.
@Observable
final class GameManager {
    enum Screen: Equatable {
        case title
        case chart
        case battle
        case reward
        case shop
        case event
        case rest
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
    /// Permanent turn-capacity gains taken this run, from Breath of Ra cards.
    private(set) var staminaBonus = 0
    private(set) var totalDamage = 0
    private(set) var totalCombos = 0
    private(set) var totalCrits = 0

    // MARK: The voyage
    private(set) var voyage = Voyage.generate()
    /// Stages the barque has already cleared.
    private(set) var clearedNodeIDs: Set<UUID> = []
    /// The last node cleared; its connections are the open channels.
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
    private(set) var restUsed = false
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

    /// The turn ceiling as it stands: the class maximum plus every Breath of
    /// Ra taken this run, capped two points above the class.
    var effectiveMaxStamina: Int {
        min((heroClass?.maxStamina ?? 3) + GameData.maxStaminaGrants,
            (heroClass?.maxStamina ?? 3) + staminaBonus)
    }

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

    /// Channels open from the last cleared stage — or, at the start, the river mouth.
    var availableNodes: [VoyageNode] {
        guard let last = lastClearedNode else {
            return voyage.nodes(inStage: 0)
        }
        return last.connections.compactMap { voyage.node($0) }
    }

    func isNodeAvailable(_ node: VoyageNode) -> Bool {
        availableNodes.contains { $0.id == node.id }
    }

    /// How many faces of each god you carry, across every die.
    var devotion: [Deity: Int] { Devotion.counts(loadout) }

    /// Gods you follow, strongest first.
    var followedDeities: [(deity: Deity, count: Int)] {
        devotion.map { (deity: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.deity.rawValue < $1.deity.rawValue : $0.count > $1.count }
    }

    /// Where the finished run placed, if it made the table.
    var latestRank: Int? {
        guard let latestRecordID,
              let index = leaderboard.firstIndex(where: { $0.id == latestRecordID }) else { return nil }
        return index + 1
    }

    // MARK: - Flow

    func startRun(with hero: HeroClass) {
        heroClass = hero
        loadout = hero.startingLoadout
        maxHP = hero.maxHP
        currentHP = hero.maxHP
        gold = 40
        critBonus = 0
        staminaBonus = 0
        totalDamage = 0
        totalCombos = 0
        totalCrits = 0
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
        Haptics.success()
        // The barque casts off straight into the mouth of the river — the chart
        // opens once that first guardian is down.
        if let entry = voyage.entryNode {
            enter(entry)
        } else {
            withAnimation { screen = .chart }
        }
    }

    /// Sail into a stage of the river and take whatever waits there.
    func enter(_ node: VoyageNode) {
        guard isNodeAvailable(node) else { return }
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
        case .mooring:
            restUsed = false
            withAnimation { screen = .rest }
        case .shrine:
            enterShrine()
        }
    }

    /// A god holds court on the bank: a wider spread of their favours, plus a
    /// rare rite that binds a second god into one face.
    private func enterShrine() {
        let deity = Deity.allCases.randomElement() ?? .ra
        visitingDeity = deity
        isShrine = true
        var offers = makeBlessingOffers(deity: deity, count: 2, progress: progress)
        if Int.random(in: 0..<100) < 35,
           let partner = Deity.allCases.filter({ $0 != deity }).randomElement() {
            offers.append(makeRiteOffer(primary: deity, partner: partner))
        } else {
            offers.append(makeGiftOffer(GiftContent.gifts(deity).randomElement() ?? GiftContent.all[0]))
        }
        // Rarely, a shrine offers the knife as well as the gift: burn whatever
        // a face carries and lay a fresh gift down, losing all its depth.
        // Rarely a shrine offers the knife as well as the gift: burn whatever
        // a face carries and lay a fresh gift down, losing all its depth.
        if carriesAnyGift, Int.random(in: 0..<100) < 12,
           let carried = followedDeities.first?.deity,
           let fresh = GiftContent.gifts(deity).randomElement() {
            offers.append(makeGiftOffer(fresh, replace: true, replacingDeity: carried))
        }
        // Occasionally a shrine offers the Breath of Ra while the run has
        // room for one.
        if staminaBonus < GameData.maxStaminaGrants, Int.random(in: 0..<100) < 15 {
            offers.append(makeBreathOffer(priced: false))
        }
        rewardOffers = offers
        statusMessage = deity.greeting
        withAnimation { screen = .reward }
    }

    /// True when any face in the loadout carries a god's gift.
    private var carriesAnyGift: Bool {
        loadout?.allDice.contains { die in die.faces.contains { $0.mark != nil } } ?? false
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
                // never fights back, and spoils that arm the relic slot.
                enemies = [EnemyContent.trainingDummy]
            } else {
                enemies = makePack(gate: node.gate, allowPack: true)
            }
        }
        battle = BattleEngine(
            enemies: enemies,
            dice: loadout.allDice,
            classID: hero.id,
            maxHP: maxHP,
            startHP: currentHP,
            maxStamina: effectiveMaxStamina,
            hour: node.hour,
            critBonus: critBonus,
            devotion: devotion
        )
        withAnimation { screen = .battle }
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
            withAnimation { screen = .gameOver(won: false) }
            return
        }

        // Apep falls and the sun comes up.
        if activeNode?.isBoss == true && currentHour >= Voyage.totalHours {
            self.battle = nil
            recordRun(sawDawn: true)
            withAnimation { screen = .gameOver(won: true) }
            return
        }

        // Roughly twice as many stages as the old voyage, so the purse is tuned down.
        // Packs pay a little better than a single foe, but not per-member full.
        let baseGold = battle.enemies.reduce(0) { $0 + $1.def.goldReward }
        let earned = max(6, Int(Double(GameData.goldReward(base: baseGold, progress: progress)) * 0.6))
        gold += earned
        self.battle = nil

        // The practice bout is not a god's audience: its spoils are a choice
        // of relics to arm the empty item slot. The gods start meeting you
        // from the second fight onward.
        if isOpeningEncounter {
            rewardOffers = RelicContent.relics.shuffled().prefix(3).map(makeRelicOffer)
            statusMessage = "+\(earned) gold · \(currentHP)/\(maxHP) health"
            withAnimation { screen = .reward }
            return
        }

        // A god comes to the water's edge after every fight.
        let deity = Deity.allCases.randomElement() ?? .ra
        visitingDeity = deity
        isShrine = false
        let kind = activeNode?.kind
        // Serpent-lords always give up a relic die; the hour's herald sometimes
        // does. Packs of the river teach you its name a little more often. It
        // takes one of the three slots rather than adding a fourth.
        let packRelicOdds = battle.enemies.count >= 3 ? 16 : (battle.enemies.count == 2 ? 10 : 0)
        let dropsRelic = kind == .boss
            || (kind == .herald && Int.random(in: 0..<100) < 38)
            || (kind == .battle && Int.random(in: 0..<100) < packRelicOdds)
        let relic = dropsRelic ? makeRelicOffer(progress: progress, priced: false) : nil
        var spoils = makeBlessingOffers(deity: deity, count: relic == nil ? 3 : 2, progress: progress)
        if let relic { spoils.append(relic) }
        // Rarely the river breathes: a card that permanently widens the bar,
        // at the cost of the blessing beside it.
        if staminaBonus < GameData.maxStaminaGrants, Int.random(in: 0..<100) < 20 {
            spoils.append(makeBreathOffer(priced: false))
        }
        rewardOffers = spoils
        statusMessage = "+\(earned) gold · \(currentHP)/\(maxHP) health"
        withAnimation { screen = .reward }
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
    }

    func leaveEncounter() {
        completeEncounter()
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
        switch offer.kind {
        case .die(let die):
            grant(die: die.instantiated())
        case .reforge(let face):
            pendingSelection = .reforge(face, title: offer.name)
        case .gift(let gift, let replace):
            pendingSelection = .gift(gift, replace: replace, title: gift.name)
        case .rite(let primary, let secondary):
            pendingSelection = .rite(primary: primary, secondary: secondary,
                                     title: "Rite of \(primary.name) & \(secondary.name)")
        case .imbue(let amount):
            pendingSelection = .imbue(amount, title: offer.name)
        case .item(let item):
            grant(item: item)
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
        case .relic(let relic):
            grantRelic(relic)
        case .breath(let amount):
            staminaBonus = min(GameData.maxStaminaGrants, staminaBonus + amount)
            statusMessage = "+\(amount) max stamina — the bar grows."
        case .reforgeDie:
            pendingSelection = .reforgeDie(title: offer.name)
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

    private func grant(item: ItemDef) {
        guard var loadout else { return }
        if loadout.item == nil {
            loadout.item = item.makePiece()
            self.loadout = loadout
            statusMessage = "\(item.name) equipped."
        } else {
            pendingSelection = .swapItem(item)
        }
    }

    /// A relic fills the item slot with its three dice, replacing whatever is
    /// carried there. The first relic of a run always finds an empty slot.
    private func grantRelic(_ relic: RelicDef) {
        guard var loadout else { return }
        loadout.item = relic.makePiece()
        self.loadout = loadout
        statusMessage = "\(relic.name) equipped — its three relic dice join the pool."
    }

    // MARK: - Resolving pending selections

    func applyReforge(dieID: UUID, faceID: UUID, to kind: FaceKind) {
        guard var loadout else { return }
        loadout.mutate(dieID: dieID) { die in
            if let index = die.faces.firstIndex(where: { $0.id == faceID }) {
                die.faces[index] = die.faces[index].reforged(to: kind)
            }
        }
        self.loadout = loadout
        finishSelection("Face reforged into \(kind.label).")
    }

    /// The Ferryman's deep whetstone: every unmarked face on the chosen die is
    /// rolled anew from the class's pool at the die's rarity. Faces the gods
    /// have claimed keep their gifts.
    func applyDieReforge(dieID: UUID) {
        guard var loadout, let die = loadout.die(id: dieID) else { return }
        guard let pick = GameData.diceOffers(classID, die.rarity).randomElement()
                ?? GameData.diceOffers(classID, .common).randomElement() else { return }
        let fresh = pick.die.instantiated().faces
        var index = 0
        loadout.mutate(dieID: dieID) { target in
            target.faces = target.faces.map { face in
                guard face.mark == nil, index < fresh.count else { return face }
                defer { index += 1 }
                return fresh[index]
            }
        }
        self.loadout = loadout
        finishSelection("\(die.name) is rolled anew — every unclaimed face redrawn at \(die.rarity.label) tier.")
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

    /// A god lays a named gift on a face: fresh on an unclaimed face, deeper
    /// on a face that already carries the same gift, or (rare replace offers)
    /// burned down and laid anew on a face promised to another god.
    func applyGift(dieID: UUID, faceID: UUID, gift: GiftDef, replace: Bool) {
        guard var loadout else { return }
        var line = ""
        loadout.mutate(dieID: dieID) { die in
            guard let index = die.faces.firstIndex(where: { $0.id == faceID }) else { return }
            let face = die.faces[index]
            if let existing = face.mark, existing.deity == gift.deity, existing.giftID == gift.id {
                guard existing.depth.next != nil else { return }
                let wasFinal = existing.isFinalForm
                die.faces[index] = face.deepenedMark()
                if !wasFinal, die.faces[index].mark?.depth == .finalForm {
                    line = "\(face.kind.label) becomes \(gift.finalFormName) — \(gift.deity.name)'s final form."
                } else {
                    line = "\(gift.name) deepens on \(face.kind.label)."
                }
            } else if face.mark == nil {
                die.faces[index] = face.marked(by: gift)
                let summary = gift.touched.summary
                line = summary.isEmpty
                    ? "\(gift.deity.name) lays \(gift.name) on \(face.kind.label)."
                    : "\(gift.name) laid on \(face.kind.label) — \(summary)."
            } else if replace {
                die.faces[index] = face.marked(by: gift)
                line = "The old claim burns off \(face.kind.label); \(gift.name) is laid in its place, at its first depth."
            }
        }
        self.loadout = loadout
        let count = devotion[gift.deity] ?? 0
        let tier = Devotion.tier(count)
        if tier > 0, let passive = gift.deity.passives.last(where: { count >= $0.threshold }) {
            line += " · \(gift.deity.name) \(count) — \(passive.text)"
        } else if !line.isEmpty {
            line += " · \(gift.deity.name) \(count)"
        }
        finishSelection(line.isEmpty ? "That face cannot take this gift." : line)
    }

    /// A dual-god rite: bind the second god into a face already carrying the
    /// first. A bound face counts for both gods, feeds both gods' chains, and
    /// fires their named duo at full strength every play.
    func applyRite(dieID: UUID, faceID: UUID, primary: Deity, secondary: Deity) {
        guard var loadout else { return }
        var line = ""
        loadout.mutate(dieID: dieID) { die in
            guard let index = die.faces.firstIndex(where: { $0.id == faceID }) else { return }
            let face = die.faces[index]
            if let mark = face.mark, mark.deity == primary, mark.rite == nil {
                die.faces[index] = face.bound(to: secondary)
                let duo = DuoContent.duo(primary, secondary)
                line = "\(secondary.name) settles beside \(primary.name) on \(face.kind.label)."
                if let duo { line += " Their \(duo.name) fires every play." }
            }
        }
        self.loadout = loadout
        finishSelection(line.isEmpty ? "A rite needs a face that already carries the first god." : line)
    }

    func applySwap(replacing oldDieID: UUID, with newDie: Die) {
        guard var loadout else { return }
        loadout.remove(dieID: oldDieID)
        _ = loadout.add(newDie)
        self.loadout = loadout
        finishSelection("\(newDie.name) takes its place.")
    }

    func applyItemSwap(to item: ItemDef) {
        guard var loadout else { return }
        loadout.item = item.makePiece()
        self.loadout = loadout
        finishSelection("\(item.name) equipped.")
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

    // MARK: - Mooring

    func rest(heal: Bool) {
        guard !restUsed else { return }
        restUsed = true
        if heal {
            let amount = max(20, Int(Double(maxHP) * 0.35))
            currentHP = min(maxHP, currentHP + amount)
            statusMessage = "+\(amount) health"
            Haptics.success()
            leaveEncounter()
        } else {
            let rarity = Rarity.roll(progress: progress)
            let pick = GameData.faceOffers(classID, rarity).randomElement()
            returnToChartAfterSelection = true
            pendingSelection = .reforge(pick?.face ?? .heal, title: "Whetstone on the Deck")
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
        case .item:
            if let pick = SharedContent.items(upTo: rarity).randomElement() {
                grant(item: pick)
                lines.append("Found \(pick.name)")
            }
        case .giftOffer:
            // The old relic overwrites are gone; omens now hand out a named
            // god's gift for free.
            if let gift = GiftContent.all.randomElement() {
                pendingSelection = .gift(gift, replace: false, title: event.title)
                lines.append("\(gift.deity.name) stirs — \(gift.name)")
            }
        case .ritePair:
            let gods = Array(Deity.allCases.shuffled())
            pendingSelection = .rite(primary: gods[0], secondary: gods[1], title: event.title)
            lines.append("\(gods[0].name) and \(gods[1].name) listen")
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
        // The Ferryman does not deal in whole dice — those are relics.
        let roll = Int.random(in: 0..<100)
        let category: Int
        switch roll {
        case 0..<30: category = 1   // face reforge
        case 30..<58: category = 2  // crit imbue
        case 58..<78: category = 3  // item
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
        case 3:
            guard let item = SharedContent.items(upTo: rarity).randomElement() else { return nil }
            return Offer(
                name: item.name,
                detail: item.blurb,
                symbol: item.symbol,
                rarity: item.rarity,
                comboHint: "Item combos — shared by every class",
                price: priced ? GameData.price(base: 45, rarity: item.rarity) : 0,
                kind: .item(item)
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

    /// An altar of named gifts. Only the god standing there gives — every card
    /// is drawn from their own twelve, never another god's, so a visit is that
    /// god's offer to make. The only way a second god reaches your dice is a
    /// duo rite. Cards are spread across the three roles where possible, so an
    /// altar rarely offers three attack gifts in a row.
    func makeBlessingOffers(deity: Deity, count: Int, progress: Double) -> [Offer] {
        let wanted = max(1, count)
        let byRole = Dictionary(grouping: GiftContent.gifts(deity), by: \.role)
        var buckets = MarkRole.allCases.shuffled().compactMap { byRole[$0]?.shuffled() }
        var gifts: [GiftDef] = []
        // Take one from each role in turn, so the spread reads as a choice of
        // what to strengthen rather than a choice of three near-identical cards.
        while gifts.count < wanted, buckets.contains(where: { !$0.isEmpty }) {
            for index in buckets.indices where gifts.count < wanted {
                guard !buckets[index].isEmpty else { continue }
                gifts.append(buckets[index].removeFirst())
            }
        }
        return gifts.map { makeGiftOffer($0, rarity: Rarity.roll(progress: progress)) }
    }

    /// One named-gift card. rarity is the card's material — the gift itself
    /// is what it is, and deepens the same way wherever it is offered.
    private func makeGiftOffer(_ gift: GiftDef, rarity: Rarity = .uncommon, replace: Bool = false, replacingDeity: Deity? = nil) -> Offer {
        let eligible = eligibleFaceCount(for: gift, replace: replace)
        let deepening = loadout?.allDice.contains { die in
            die.faces.contains { $0.mark?.giftID == gift.id && $0.mark?.depth.next != nil }
        } ?? false

        var detail: String
        if replace {
            detail = "Burns off \(replacingDeity?.name ?? "the old claim")'s gift and lays \(gift.name) in its place — at its first depth, all prior depth lost. "
        } else if deepening {
            detail = "Deepens \(gift.name) where you carry it. "
        } else {
            detail = "\(gift.deity.name)'s gift for your \(gift.role.label.lowercased()): "
        }
        detail += gift.touched.summary + "."
        if eligible == 0 && !replace {
            detail += " No face of yours can take it right now."
        }

        return Offer(
            name: gift.name,
            detail: detail,
            symbol: gift.symbol,
            rarity: rarity,
            comboHint: giftHint(gift),
            price: 0,
            kind: .gift(gift, replace: replace),
            deity: gift.deity
        )
    }

    /// How many of your faces could receive this gift: unclaimed faces, faces
    /// deepening the same gift, or — for replace cards — any gifted face.
    private func eligibleFaceCount(for gift: GiftDef, replace: Bool) -> Int {
        loadout?.allDice.reduce(0) { total, die in
            total + die.faces.filter { face in
                if let mark = face.mark {
                    if replace { return true }
                    return mark.deity == gift.deity && mark.giftID == gift.id && mark.depth.next != nil
                }
                return true
            }.count
        } ?? 0
    }

    /// First divine combo the gift feeds, for the card's link chip.
    private func giftHint(_ gift: GiftDef) -> String {
        let pool = DivineContent.combos(for: classID)
        let specific = pool.first { combo in
            combo.required.contains { pattern in
                if case .gift(let id) = pattern { return id == gift.id }
                return false
            }
        }
        if let specific { return specific.name }
        let byDeity = pool.first { combo in
            combo.required.contains { pattern in
                if case .deity(let owner) = pattern { return owner == gift.deity }
                return false
            }
        }
        return byDeity?.name ?? "\(gift.deity.name)'s chains"
    }

    /// The dual-god rite: a rare find that binds two gods into one face.
    private func makeRiteOffer(primary: Deity, partner: Deity) -> Offer {
        Offer(
            name: "Rite of \(primary.name) & \(partner.name)",
            detail: "Two gods, one face. Choose a face that is unclaimed or already marked by \(primary.name); \(partner.name) settles in beside them. The only way two gods ever share a face.",
            symbol: "square.on.square",
            rarity: .rare,
            comboHint: "Counts for both gods",
            price: 0,
            kind: .rite(primary, partner),
            deity: primary
        )
    }

    /// One relic card for the opening spoils: three dice for the item slot.
    private func makeRelicOffer(_ relic: RelicDef) -> Offer {
        Offer(
            name: relic.name,
            detail: "\(relic.blurb) Equips three relic dice into your item slot — the pool grows from seven to ten.",
            symbol: relic.symbol,
            rarity: relic.rarity,
            comboHint: "Item combos — shared by every class",
            price: 0,
            kind: .relic(relic)
        )
    }

    /// The Breath of Ra: a rare card that permanently raises the turn bar.
    private func makeBreathOffer(priced: Bool) -> Offer {
        let gained = min(1, GameData.maxStaminaGrants - staminaBonus)
        return Offer(
            name: "Breath of Ra",
            detail: "Ra's own breath, drawn deep. Permanently raise your turn capacity by \(gained) — the bar you spend from grows by a point, this turn and every turn after.",
            symbol: "wind.circle.fill",
            rarity: .rare,
            comboHint: "More stamina per turn — more faces played",
            price: priced ? GameData.price(base: 110, rarity: .rare) : 0,
            kind: .breath(gained)
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

    /// Whole dice are relics — serpent-lord spoils and the Ferryman's centrepiece.
    private func makeRelicOffer(progress: Double, priced: Bool) -> Offer? {
        let rarity = max(Rarity.roll(progress: progress), .rare)
        guard let pick = GameData.diceOffers(classID, rarity).randomElement() else { return nil }
        let die = pick.die
        return Offer(
            name: die.name,
            detail: "A relic \(die.slot.label.lowercased()) die — a whole new die, not a face. \(faceSummary(die))",
            symbol: die.slot.symbol,
            rarity: rarity,
            comboHint: pick.hint,
            price: priced ? GameData.price(base: 130, rarity: rarity) : 0,
            kind: .die(die)
        )
    }

    private func makeShopStock() -> [Offer] {
        var stock = makeOffers(count: 5, progress: progress, priced: true)
        // Roughly one crossing in four, the Ferryman has a relic under the bench.
        if Int.random(in: 0..<100) < 26, let relic = makeRelicOffer(progress: progress, priced: true) {
            stock.insert(relic, at: 0)
        }
        // Roughly one crossing in three, the deep whetstone is out: a whole
        // die's unclaimed faces rolled anew.
        if Int.random(in: 0..<100) < 35 {
            stock.insert(makeReforgeDieOffer(), at: 0)
        }
        // And, while the run has room for one, a Breath of Ra at a steep price.
        if staminaBonus < GameData.maxStaminaGrants, Int.random(in: 0..<100) < 30 {
            stock.insert(makeBreathOffer(priced: true), at: 0)
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
