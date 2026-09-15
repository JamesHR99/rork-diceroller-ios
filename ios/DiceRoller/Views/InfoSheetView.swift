import SwiftUI

/// The codex: three tabs — your loadout, your class's combos, and the rules
/// for stamina, crits and statuses.
struct InfoSheetView: View {
    let loadout: Loadout
    let classID: String
    let critBonus: Double
    /// Turn ceiling as it stands — the class maximum plus any Breath of Ra.
    let maxStamina: Int
    /// Dice this turn's draw put on the table; empty outside battle.
    let drawnDieIDs: Set<UUID>
    /// True once this run has met a god's Trial — the codex then names all six.
    let hasMetTrial: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .loadout

    enum Tab: String, CaseIterable, Identifiable {
        case loadout
        case combos
        case pantheon
        case rules

        var id: String { rawValue }

        var label: String {
            switch self {
            case .loadout: "Loadout"
            case .combos: "Combos"
            case .pantheon: "Gods"
            case .rules: "Rules"
            }
        }

        var symbol: String {
            switch self {
            case .loadout: "dice.fill"
            case .combos: "link"
            case .pantheon: "sun.max.fill"
            case .rules: "book.closed.fill"
            }
        }
    }

    private var hero: HeroClass { GameData.heroClass(id: classID) }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch tab {
                    case .loadout: loadoutTab
                    case .combos: combosTab
                    case .pantheon: pantheonTab
                    case .rules: rulesTab
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .background(Theme.bg)
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                DuatSymbol(art: DuatArt.classSigil(classID), fallback: hero.symbol,
                           size: 22, tint: hero.accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("CODEX OF THE NIGHT")
                        .font(.fantasy(17, weight: .black))
                        .foregroundStyle(Theme.parchment)
                        .kerning(2)
                    Text("\(hero.name) · \(loadout.diceCount)/\(Loadout.maxDice) dice")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                DuatIcon(name: DuatArt.utilityClose, size: 24)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases) { entry in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tab = entry }
                    Haptics.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: entry.symbol).font(.system(size: 10.5, weight: .bold))
                        Text(entry.label).font(.system(size: 11.5, weight: .black))
                    }
                    .foregroundStyle(tab == entry ? Theme.parchment : Theme.parchmentDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        DuatImage(name: tab == entry ? DuatArt.tabSelected : DuatArt.tabUnselected,
                                  fit: .stretch)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .modifier(TintWash(tint: tab == entry ? hero.accent : nil))
                            .opacity(tab == entry ? 1 : 0.6)
                    }
                    .clipShape(.capsule)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(Theme.gold)
            .kerning(1.5)
    }

    // MARK: - Loadout tab

    private var loadoutTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("YOUR GEAR — WEAPON AND ARMOUR ARE PERMANENT")

            Text("Only \(GameData.diceDrawCount) of these dice come out each turn — drawn fresh at random from everything you carry. The rest wait in the bag; a face you hold with a freeze is the only one guaranteed to return.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(loadout.pieces) { piece in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        DuatSymbol(art: piece.slot.artName, fallback: piece.symbol,
                                   size: 20, tint: hero.accent)
                            .frame(width: 28, height: 28)
                            .background(Theme.bg, in: .rect(cornerRadius: 7))
                        Text(piece.name)
                            .font(.fantasy(16, weight: .bold))
                            .foregroundStyle(Theme.parchment)
                        Text("\(piece.slot.label) · \(piece.dice.count) \(piece.dice.count == 1 ? "die" : "dice")")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.parchmentDim)
                        Spacer()
                    }

                    ForEach(piece.dice) { die in
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(die.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.parchment)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(die.rarity.label.uppercased())
                                    .font(.system(size: 7.5, weight: .black))
                                    .kerning(0.6)
                                    .foregroundStyle(die.rarity.tint)
                            }
                            .frame(width: 112, alignment: .leading)

                            DieStripView(die: die, tileSize: 26, showCrit: true, critBonus: critBonus)

                            if drawnDieIDs.contains(die.id) {
                                Text("DRAWN")
                                    .font(.system(size: 7.5, weight: .black))
                                    .kerning(0.8)
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Theme.gold.opacity(0.14), in: .capsule)
                            }

                            Spacer(minLength: 0)
                        }
                    }

                    faceLegend(for: piece)
                }
                .padding(12)
                .background(Theme.bgCard, in: .rect(cornerRadius: 14))
            }

            if loadout.item == nil {
                HStack(spacing: 8) {
                    DuatIcon(name: DuatArt.slotItem, size: 20).opacity(0.5)
                    Text("Item slot empty — the river gives up a relic after the practice bout. Relics bring three dice, items two.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.parchmentDim)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bgCard.opacity(0.6), in: .rect(cornerRadius: 14))
            }
        }
    }

    private func faceLegend(for piece: GearPiece) -> some View {
        let faces = uniqueFaces(in: piece)
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(faces, id: \.self) { face in
                HStack(spacing: 5) {
                    DuatSymbol(art: face.artName, fallback: face.symbol, size: 13, tint: face.tint)
                        .frame(width: 14)
                    Text("\(face.label) — \(face.soloEffect)")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
        }
        .padding(.leading, 4)
    }

    private func uniqueFaces(in piece: GearPiece) -> [FaceKind] {
        var seen: [FaceKind] = []
        for die in piece.dice {
            for face in die.faces where !seen.contains(face.kind) {
                seen.append(face.kind)
            }
        }
        return seen
    }

    // MARK: - Combos tab

    private var combosTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            comboGroup(
                title: "\(hero.weaponName.uppercased()) — WEAPON COMBOS",
                combos: GameData.classCombos(classID).filter { $0.source == .weapon }
            )
            comboGroup(
                title: "\(hero.armorName.uppercased()) — ARMOUR COMBOS",
                combos: GameData.classCombos(classID).filter { $0.source == .armor }
            )
            comboGroup(
                title: "ITEM COMBOS — SHARED BY EVERY CLASS",
                combos: SharedContent.combos
            )

            if classID == "warrior" {
                VStack(alignment: .leading, spacing: 4) {
                    sectionTitle("MOMENTUM — WARRIOR PASSIVE")
                    Text("Every attack you have already thrown this turn adds +5 damage to the next one. Long swing chains snowball.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.parchmentDim)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bgCard, in: .rect(cornerRadius: 14))
            }
        }
    }

    private func comboGroup(title: String, combos: [ComboDef]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title)

            VStack(spacing: 5) {
                ForEach(combos) { combo in
                    HStack(alignment: .top, spacing: 10) {
                        ComboRecipeView(combo: combo, tileSize: 21)
                            .frame(width: 108, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(combo.name)
                                    .font(.fantasy(13, weight: .bold))
                                    .foregroundStyle(combo.tint)
                                Text("\(combo.staminaCost) stam")
                                    .font(.system(size: 8.5, weight: .black))
                                    .foregroundStyle(Theme.parchmentDim)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(Theme.bg, in: .capsule)
                                if combo.damage > 0 {
                                    Text("crit → \(GameData.scaleUp(combo.damage, by: GameData.comboCritMultiplier)) dmg")
                                        .font(.system(size: 8.5, weight: .black).monospacedDigit())
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                            Text(combo.effectSummary.prefix(1).uppercased() + combo.effectSummary.dropFirst())
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(combo.flavor)
                                .font(.paper(10))
                                .italic()
                                .foregroundStyle(Theme.parchmentDim.opacity(0.65))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.bgCard, in: .rect(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Pantheon tab

    private var pantheonTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("THE PANTHEON — ONE GOD PER DIE, ANSWERING WHAT YOU PLAY")

            Text("A god claims a whole die and never touches its faces — the claim simply means their blessing answers every face that die plays, read by what the face is. Attacks get the attack answer, Block faces the block answer, Evade faces the evade answer, everything else the support answer — once each per action, chains included. A blessed die is the entry ticket to that god's four upgrades; two upgrades unlock their capstone. One capstone and one pairing per run.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Deity.allCases) { deity in
                deityCard(deity)
            }

            sectionTitle("FIFTEEN PAIRINGS — TWO GODS STANDING TOGETHER")
            Text("Once you carry one upgrade from each of two gods, their pairing opens: a named effect that fires at most once per turn while both gods stay equipped. One pairing per run.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(PairingContent.pairings) { pairing in
                pairingRow(pairing)
            }
        }
    }

    private func pairingRow(_ pairing: PairingDef) -> some View {
        HStack(alignment: .top, spacing: 9) {
            HStack(spacing: 4) {
                DuatSymbol(art: pairing.first.artName, fallback: pairing.first.symbol,
                           size: 18, tint: pairing.first.tint)
                Text("&")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Theme.parchmentDim)
                DuatSymbol(art: pairing.second.artName, fallback: pairing.second.symbol,
                           size: 18, tint: pairing.second.tint)
            }
            .frame(width: 66, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(pairing.name)
                    .font(.fantasy(12.5, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                Text(pairing.detail)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 9))
    }

    private func deityCard(_ deity: Deity) -> some View {
        let claimedDice = loadout.allDice.filter { $0.patron == deity }.count
        let capstone = GodKit.capstone(for: deity)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                PortraitMedallionView(art: CharacterArt.god(deity),
                                      fallbackSymbol: deity.symbol,
                                      tint: deity.tint,
                                      diameter: 40,
                                      glow: false)

                VStack(alignment: .leading, spacing: 1) {
                    Text(deity.name)
                        .font(.fantasy(17, weight: .black))
                        .foregroundStyle(Theme.parchment)
                    Text(deity.domain.uppercased())
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(1.4)
                        .foregroundStyle(deity.tint)
                }

                Spacer()

                Text(claimedDice == 0 ? "NO CLAIM" : "\(claimedDice) DICE")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(claimedDice > 0 ? deity.tint : Theme.parchmentDim)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(claimedDice > 0 ? deity.tint.opacity(0.14) : Theme.bg, in: .capsule)
            }

            Text(deity.pitch)
                .font(.system(size: 9.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)

            // The blessing — what their answer does to each kind of face.
            VStack(alignment: .leading, spacing: 3) {
                Text("BLESSING — ONCE PER ROLE PER ACTION")
                    .font(.system(size: 7, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(deity.tint)
                ForEach(BlessingRole.allCases, id: \.self) { role in
                    HStack(alignment: .top, spacing: 5) {
                        Text(GodKit.blessingLabel(for: role))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.parchmentDim)
                            .frame(width: 92, alignment: .leading)
                        Text(GodKit.blessing(for: deity, role: role).summary)
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.parchment)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 9))

            // The upgrade path — four rungs, then the capstone.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(GodKit.upgrades(for: deity)) { upgrade in
                    HStack(alignment: .top, spacing: 5) {
                        DuatSymbol(art: deity.artName, fallback: upgrade.symbol,
                                   size: 13, tint: deity.tint)
                            .frame(width: 13)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(upgrade.name)
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(Theme.parchment)
                            Text(upgrade.detail)
                                .font(.system(size: 8.5))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if let capstone {
                    HStack(alignment: .top, spacing: 5) {
                        DuatSymbol(art: DuatArt.Status.champion, fallback: capstone.symbol,
                                   size: 13, tint: Theme.gold)
                            .frame(width: 13)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(capstone.name) — CAPSTONE")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundStyle(Theme.gold)
                            Text(capstone.detail)
                                .font(.system(size: 8.5))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 3)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 9))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(claimedDice > 0 ? deity.tint.opacity(0.45) : .clear, lineWidth: 1)
        )
    }

    // MARK: - Rules tab

    private var rulesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ruleCard(
                icon: "link", tint: Theme.ember, title: "CHAINS ARE THE FIGHT",
                lines: [
                    "A face played on its own is worth about \(Int(GameData.soloAttackScale * 100))% of its printed value. One arrow will not win you anything.",
                    "A recipe asks for ingredients and quantities, never a tap order — any arrangement of the faces fuses into one step. Three Swift Slashes make the same chain whichever tap they arrived from.",
                    "Recipes print their own value — chains no longer multiply by length. What lifts a chain is its critical dice: each one adds +\(Int(GameData.critComboWeight * 100))% to the whole step.",
                    "Fused combos cost less than their faces played apart: 3 faces cost 2, 4 cost 3, 5 cost 4. A chain of three or more banks a single stamina point for next turn.",
                    "Each die wears a coloured letter for every chain it could feed. Tap a letter to fuse that chain; tap it again once it turns gold to break it apart.",
                    "A chain only claims the dice its recipe asks for — anything left over still plays as its own step in the same turn.",
                ]
            )

            ruleCard(
                icon: "dice.fill", tint: Theme.steelBlue, title: "THE DRAW",
                lines: [
                    "You carry up to ten dice — three in the weapon, two in the armour, and the rest won from relics — but only \(GameData.diceDrawCount) hit the table each turn.",
                    "The six are drawn fresh at random every turn, so the same collection produces a different hand each time.",
                    "No mix is guaranteed: a draw can come up all weapon and leave you nothing defensive. That is what freezes are for.",
                    "Dice whose faces you hold are left in the bag — the held face rides along as its own reel instead.",
                    "The loadout tab marks which dice this turn's draw put on the table.",
                    "A weak die dilutes every draw — the Ferryman's Whetstone Ritual rolls a die's faces anew instead of throwing it away.",
                ]
            )

            ruleCard(
                icon: "bolt.fill", tint: Theme.gold, title: "STAMINA",
                lines: [
                    "\(hero.name) starts each battle with \(maxStamina) stamina. Rolling is free — placing a die in the plan costs 1.",
                    "The bar never refills: whatever you don't spend carries over, and each new turn recovers just +\(GameData.staminaRecoveryPerTurn), never past \(maxStamina).",
                    "Chains pay almost nothing back: a pair banks nothing at all, and a chain of three faces or more hands you a single point for the next turn only.",
                    "To go above \(maxStamina) you have to earn it — Focus and Energize faces, and the gods' blessings. That overcharge lasts one turn, then expires if left unspent.",
                    "Rarely the river offers the Breath of Ra: a card that permanently raises the ceiling by one, up to two points above your class maximum. At four you can run two three-face chains in a turn.",
                    "Fused combos cost less than their faces played apart: 3 faces cost 2, 4 cost 3, 5 cost 4. The savings land the moment the fusion forms.",
                ]
            )

            ruleCard(
                icon: "snowflake", tint: Theme.frost, title: "FREEZING DICE",
                lines: [
                    "Freezing is free: two holds a turn from the very first fight, three from the Fire Gate onward.",
                    "Hit the FREEZE button on the right of the tray, then tap a die to hold its face.",
                    "A held face keeps exactly as it landed, crit and all — and the die it came from still rolls again next turn. A freeze hands you an extra face, it never benches a die.",
                    "The die behind a held face sits out the next draw, so the held face never arrives beside a fresh roll of its own die — the hold is the only way to guarantee a face comes back.",
                    "Held faces sit at the front of the tray as their own reel, so they are always where you left them.",
                    "The universal hold bonus is gone — gods reward holds instead. Ra and Horus pay out when an action carries a held face of theirs; Horus even hands stamina back for the first one each turn.",
                    "The hold lasts one turn: play it, freeze it again to keep it longer, or leave it and it is gone.",
                ]
            )

            ruleCard(
                icon: "sparkles", tint: Theme.ember, title: "CRITICAL HITS",
                lines: [
                    "Crits are decided the moment a die lands: the die picks a face, then that face's own crit chance decides if it landed critical.",
                    "A critical die keeps its face name and wears a gold CRIT badge — you always see exactly what you rolled.",
                    "Base chances are small — most faces sit near 5%, signature faces a touch higher. Imbues raise a single face permanently, up to \(Int(DieFace.critCap * 100))%.",
                    "A critical face played alone is worth ×\(String(format: "%.1f", GameData.faceCritMultiplier)) — but a crit is worth far more fed into a chain.",
                    critBonus > 0 ? "Your charms add +\(Int(critBonus * 100))% crit to every face." : "Imbued faces are marked with a gold notch on the die.",
                ]
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    DuatImage(name: DuatArt.chainConnector, width: 16, fit: .fit)
                        .colorMultiply(Theme.gold)
                    Text("COMBO CRITS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .kerning(1.5)
                }
                Text("Every critical face fed into a chain adds +\(Int(GameData.critComboWeight * 100))% to that chain's whole output — no crit is ever wasted in a combo. On top of that it buys a chance the chain itself crits, which multiplies everything by ×\(String(format: "%.1f", GameData.comboCritMultiplier)).")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 3) {
                    critRow("No critical dice", "0%")
                    critRow("One critical die", "35%")
                    critRow("Two critical dice", "70%")
                    critRow("Every die critical", "100% — guaranteed")
                }
                .padding(.top, 2)

                Text("Perfect Shot and Vanishing Strike always crit, whatever fed them. The play bar shows each step's crit odds and its critical damage before you commit.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgCard, in: .rect(cornerRadius: 14))

            ruleCard(
                icon: "sun.max.fill", tint: Theme.sunGold, title: "THE GODS",
                lines: [
                    "A god claims a whole die, never a face. Their blessing reads whatever that die plays: attacks get the attack answer, Block faces the block answer, Evade faces the evade answer, everything else the support answer.",
                    "Each answer fires once per action, chains included — a long chain does not multiply a god's patience.",
                    "A blessed die is the ticket to that god's four upgrades. Two upgrades unlock their capstone — one capstone per run.",
                    "Carry an upgrade from each of two gods and their named pairing opens — fifteen in all, firing at most once per turn while both gods stay equipped. One pairing per run.",
                    "Shrines on the bank are where the gods reliably hold court. After a fight they visit only sometimes — most spoils are the river's own.",
                    "Replacing a patron is always an explicit choice, never accidental. Upgrades tied to a god you no longer carry go quiet rather than disappearing.",
                ]
            )

            ruleCard(
                icon: "person.2.fill", tint: Theme.blood, title: "ENEMY PACKS",
                lines: [
                    "Some fights put more than one foe on the deck — mostly pairs, occasionally three, all from the same stretch of the river.",
                    "Committing against a pack opens the targeting step: every attack in your plan is listed, and you send each one at a foe with a tap — or let them all land on the first living foe.",
                    "Each blow carries its own god triggers and statuses to wherever you send it, and a fallen target's attack slides to the nearest living foe.",
                    "Every living foe shows its own intent, health and statuses — and on their turn they act one after another.",
                    "Pack members arrive with about half their usual health, and the purse and relic odds grow a little with the pack's size.",
                    "Serpent-lords always come alone — the river is only so wide.",
                ]
            )

            // MARK: Ptah's Chisels

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    DuatIcon(name: DuatArt.upgradeHammer, size: 16)
                    Text("CHISELS OF PTAH")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.ptahCopper)
                        .kerning(1.5)
                }
                Text("Ptah the craftsman rarely turns up in the spoils. His Chisel reshapes your whole weapon — never a single die — and your gods and their blessings are untouched. Two different Chisels a run, both active together. The optional ones arm per action from a small copper badge on the recipe's own chip; tapping it folds their cost and outcome into the forecast before you commit.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(ChiselCatalog.chisels(for: classID)) { chisel in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            DuatSymbol(art: chisel.artName, fallback: chisel.symbol,
                                       size: 15, tint: Theme.ptahCopper)
                            Text(chisel.name)
                                .font(.fantasy(12, weight: .bold))
                                .foregroundStyle(Theme.parchment)
                            Text(chisel.isOptional ? "OPTIONAL" : "PASSIVE")
                                .font(.system(size: 7, weight: .black))
                                .kerning(0.8)
                                .foregroundStyle(Theme.ptahCopper)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Theme.ptahCopper.opacity(0.14), in: .capsule)
                        }
                        Text(chisel.detail)
                            .font(.system(size: 9.5))
                            .foregroundStyle(Theme.parchmentDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("e.g. \(chisel.example)")
                            .font(.paper(9.5))
                            .italic()
                            .foregroundStyle(Theme.parchmentDim.opacity(0.7))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 9))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgCard, in: .rect(cornerRadius: 14))

            // MARK: Divine Trials

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    DuatIcon(name: DuatArt.Status.champion, size: 16)
                    Text("DIVINE TRIALS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .kerning(1.5)
                }
                Text("Any ordinary fight can quietly be a god's Trial: a champion carrying that god's power, ringed in its colour for the whole fight. The encounter itself is ordinary — the god lends a mechanic, never health or damage. Declining costs nothing; at most one Trial per run, never before your relic is armed and a blessing carried, and never on a herald, a serpent-lord or the water before one. Win, and the god offers a choice of three of its own boons.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                if hasMetTrial {
                    ForEach(DivineTrial.all) { trial in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                DuatSymbol(art: trial.deity.artName, fallback: trial.deity.symbol,
                                           size: 15, tint: trial.deity.tint)
                                Text(trial.name)
                                    .font(.fantasy(12, weight: .bold))
                                    .foregroundStyle(Theme.parchment)
                            }
                            Text(trial.power)
                                .font(.system(size: 9.5))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 9))
                    }
                } else {
                    Text("You have not yet met a Trial. When one rises, its god names the exact terms before the first blow — and all six possibilities are written here.")
                        .font(.system(size: 9.5))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgCard, in: .rect(cornerRadius: 14))

            ruleCard(
                icon: "shield.fill", tint: Theme.bronze, title: "ARMOUR",
                lines: [
                    "Armoured foes wear a bronze plate above their health. Your hits chip the plate first; only when it shatters can their health be touched.",
                    "Pierce punches through armour exactly as it does block.",
                    "Poison, burn and bleed seep under the plate and tick health directly — DoT builds are the anti-armour answer.",
                    "Their block still sits in front of the plate, so you must chew through guard, then armour, then health.",
                    "Armour never regenerates — once broken, it is broken. But breaking it is a real investment, so armoured brutes trade burst damage for staying power.",
                ]
            )

            ruleCard(
                icon: "drop.triangle.fill", tint: Theme.venom, title: "STATUS EFFECTS",
                lines: [
                    "Bleed, Poison and Burn tick on the enemy at the start of their turn. Burn caps at 12 a tick; bleed refreshes to the stronger value rather than stacking.",
                    "Statuses seep under armour and land on health directly — so does Anubis's stored judgement when it detonates.",
                    "Stagger weakens the enemy's very next attack by its percentage, then wears off.",
                    "Mark multiplies your next hit on that enemy.",
                    "Pierce ignores part of the enemy's block and armour. Your own shield soaks damage before health and stays until something breaks it.",
                    "Evade is a chance to slip a hit entirely, rolled fresh for every blow — chances add up to a ceiling, and it clears after the enemy turn.",
                ]
            )

            ruleCard(
                icon: "arrow.left.arrow.right", tint: Theme.steelBlue, title: "RECIPES, NOT ORDERS",
                lines: [
                    "The plan resolves left to right, in the order you place the dice — but recipes themselves ask for ingredients, never order.",
                    "Any arrangement of the right faces fuses into one combo step; competing recipes are settled by size and specificity, biggest first.",
                    "Tap a recipe in the panel to fuse it by hand, or tap it again to dissolve it back into solo faces.",
                    "Tap a step to take its dice back and reclaim the stamina.",
                ]
            )
        }
    }

    private func critRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.gold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Theme.bg.opacity(0.6), in: .rect(cornerRadius: 7))
    }

    private func ruleCard(icon: String, tint: Color, title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(tint)
                    .kerning(1.5)
            }
            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
    }
}
