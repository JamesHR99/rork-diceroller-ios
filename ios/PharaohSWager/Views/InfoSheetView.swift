import SwiftUI

/// The codex: three tabs — your loadout, your class's combos, and the rules
/// for stamina, crits and statuses.
struct InfoSheetView: View {
    let loadout: Loadout
    let classID: String
    let critBonus: Double
    /// Turn ceiling as it stands — the class maximum plus any Breath of Ra.
    /// Dice this turn's draw put on the table; empty outside battle.
    let drawnDieIDs: Set<UUID>
    /// True once this run has met a god's Trial — the codex then names all six.
    let hasMetTrial: Bool
    /// The god powers equipped right now, so the catalogue can mark them.
    var boons: [EquippedBoon] = []

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

    /// Every chain the player has ever landed. Read once when the codex opens
    /// rather than per row, so scrolling never touches storage.
    private var knownCombos: Set<String> { ComboLore.known() }

    /// Every chain this class could ever find, for the found-count heading.
    private var allCombos: [ComboDef] {
        SameFaceCatalog.actions(for: classID)
    }

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
                PharaohSWagerSymbol(art: PharaohSWagerArt.classSigil(classID), fallback: hero.symbol,
                           size: 30, tint: hero.accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("CODEX OF THE NIGHT")
                        .font(.fantasy(17, weight: .black))
                        .foregroundStyle(Theme.parchment)
                        .kerning(2)
                    Text(hero.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                PharaohSWagerIcon(name: PharaohSWagerArt.utilityClose, size: 24)
                    .frame(width: 44, height: 44)
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
                        Image(systemName: entry.symbol).font(.system(size: 12.5, weight: .bold))
                        Text(entry.label).font(.system(size: 13.5, weight: .black))
                    }
                    .foregroundStyle(tab == entry ? Theme.parchment : Theme.parchmentDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        PharaohSWagerImage(name: tab == entry ? PharaohSWagerArt.tabSelected : PharaohSWagerArt.tabUnselected,
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
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(Theme.gold)
            .kerning(1.5)
    }

    // MARK: - Loadout tab

    private var loadoutTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("YOUR GEAR — WEAPON AND ARMOUR ARE PERMANENT")

            Text("You own \(GameData.ownedDiceTotal) dice and \(GameData.diceDrawCount) of them fill your slots each round, drawn without replacement. The dice left in the bag are marked below, so the randomness is always readable; a face you hold is the only one guaranteed to come back.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(loadout.pieces) { piece in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        PharaohSWagerSymbol(art: piece.slot.artName, fallback: piece.symbol,
                                   size: 26, tint: hero.accent)
                            .frame(width: 36, height: 36)
                            .background(Theme.bg, in: .rect(cornerRadius: 8))
                        Text(piece.name)
                            .font(.fantasy(16, weight: .bold))
                            .foregroundStyle(Theme.parchment)
                        Text("\(piece.slot.label) · \(piece.dice.count) \(piece.dice.count == 1 ? "die" : "dice")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.parchmentDim)
                        Spacer()
                    }

                    ForEach(piece.dice) { die in
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(die.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.parchment)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(die.rarity.label.uppercased())
                                    .font(.system(size: 9.5, weight: .black))
                                    .kerning(0.6)
                                    .foregroundStyle(die.rarity.tint)
                            }
                            .frame(width: 132, alignment: .leading)

                            DieStripView(die: die, tileSize: 30, showCrit: true, critBonus: critBonus)

                            // Which dice this round put on the table, and
                            // which two are still waiting in the bag.
                            if drawnDieIDs.contains(die.id) {
                                Text("DRAWN")
                                    .font(.system(size: 9.5, weight: .black))
                                    .kerning(0.8)
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Theme.gold.opacity(0.14), in: .capsule)
                            } else if !drawnDieIDs.isEmpty {
                                Text("IN THE BAG")
                                    .font(.system(size: 9.5, weight: .black))
                                    .kerning(0.8)
                                    .foregroundStyle(Theme.parchmentDim)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Theme.bg.opacity(0.6), in: .capsule)
                            }

                            Spacer(minLength: 0)
                        }
                    }

                    faceLegend(for: piece)
                }
                .padding(12)
                .background(Theme.bgCard, in: .rect(cornerRadius: 14))
            }

        }
    }

    private func faceLegend(for piece: GearPiece) -> some View {
        let faces = uniqueFaces(in: piece)
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(faces, id: \.self) { face in
                HStack(spacing: 5) {
                    PharaohSWagerSymbol(art: face.artName, fallback: face.symbol, size: 18, tint: face.tint)
                        .frame(width: 19)
                    Text("\(face.label) — \(face.soloEffect)")
                        .font(.system(size: 11.5))
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
            loreHeading

            comboGroup(
                title: "\(hero.weaponName.uppercased()) — WEAPON COMBOS",
                combos: SameFaceCatalog.actions(for: classID).filter { $0.owner != nil && $0.source == .weapon }
            )
            comboGroup(
                title: "\(hero.armorName.uppercased()) — ARMOUR COMBOS",
                combos: SameFaceCatalog.actions(for: classID).filter { $0.owner != nil && $0.source == .armor }
            )
            comboGroup(
                title: "SHARED FACES",
                combos: SameFaceCatalog.actions(for: classID).filter { $0.owner == nil }
            )

            if classID == "warrior" {
                VStack(alignment: .leading, spacing: 4) {
                    sectionTitle("MOMENTUM — WARRIOR PASSIVE")
                    Text("Every attack you have already thrown this turn adds +5 damage to the next one. Long swing chains snowball.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.parchmentDim)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bgCard, in: .rect(cornerRadius: 14))
            }
        }
    }

    /// What the codex now opens with: a tally of what has been found, and the
    /// rule that replaced the lettered suggestions under the tray.
    private var loreHeading: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                PharaohSWagerIcon(name: PharaohSWagerArt.chainConnector, size: 20)
                Text("WHAT YOU HAVE FOUND")
                    .font(.system(size: 13, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(Theme.gold)
                Spacer(minLength: 0)
                Text("\(ComboLore.knownCount(among: allCombos)) / \(allCombos.count)")
                    .font(.system(size: 13, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.sunGold)
            }
            Text("Dice standing next to each other chain together. Nothing tells you which arrangements mean something — lay them out, commit, and a chain names itself as it lands. Every one you land is written in here for good.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
    }

    private func comboGroup(title: String, combos: [ComboDef]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title)

            VStack(spacing: 5) {
                ForEach(combos) { combo in
                    comboRow(combo, found: knownCombos.contains(combo.id))
                }
            }
        }
    }

    /// One chain in the codex. Landed at least once it reads in full: recipe,
    /// name, cost and what it does. Never landed, it is a sealed row — how
    /// many dice it takes and nothing else, so the codex tells you how much is
    /// left to find without telling you what any of it is.
    private func comboRow(_ combo: ComboDef, found: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ComboRecipeView(combo: combo, tileSize: 26, isRevealed: found)
                .frame(width: 128, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(found ? combo.name : "? ? ?")
                        .font(.fantasy(13, weight: .bold))
                        .kerning(found ? 0 : 3)
                        .foregroundStyle(found ? combo.tint : Theme.parchmentDim.opacity(0.85))

                    if found {
                        Text("\(combo.diceCount) stam")
                            .font(.system(size: 10.5, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Theme.bg, in: .capsule)
                        if combo.damage > 0 {
                            Text("crit → \(GameData.scaleUp(combo.damage, by: GameData.comboCritMultiplier)) dmg")
                                .font(.system(size: 10.5, weight: .black).monospacedDigit())
                                .foregroundStyle(Theme.gold)
                        }
                    } else {
                        Text("\(combo.faceCount) DICE, SIDE BY SIDE")
                            .font(.system(size: 10, weight: .black))
                            .kerning(0.8)
                            .foregroundStyle(Theme.parchmentDim.opacity(0.75))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Theme.bg, in: .capsule)
                    }
                }

                if found {
                    Text(combo.effectSummary.prefix(1).uppercased() + combo.effectSummary.dropFirst())
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.parchmentDim)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(combo.flavor)
                        .font(.paper(10))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim.opacity(0.65))
                        .lineLimit(1)
                } else {
                    Text("Undiscovered — arrange it and see.")
                        .font(.paper(11))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim.opacity(0.55))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 10))
        .opacity(found ? 1 : 0.75)
    }

    // MARK: - Pantheon tab

    private var pantheonTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("YOUR POWERS — THREE ATTACK, TWO DEFENCE, TWO UTILITY, ONE LEGENDARY")

            Text("A power belongs to you, not to a die. Several gods can answer the same action, and nothing needs an entry purchase. Rarity is rolled and shown before you choose it; level climbs inside that rarity, to \(boonMaxLevel). Being offered a power you already carry is a level, never a second copy.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(BoonSlot.allCases.filter { $0 != .legendary }) { slot in
                slotRow(slot)
            }

            sectionTitle("THE CATALOGUE — TEN POWERS PER GOD")
            ForEach(Deity.allCases) { deity in
                catalogueCard(deity)
            }

            sectionTitle("FIFTEEN DUOS — TWO GODS ANSWERING TOGETHER")
            Text("A duo comes as an ordinary card from either of the two gods who made it — there is no separate way to find one. It needs its two source powers equipped and keeps needing them. It never satisfies its own prerequisite, and its values are fixed — duos do not level. Two duos at most, inside the ordinary slots.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(GodCatalog.duos) { duo in
                boonRow(duo, showSources: true)
            }

            sectionTitle("SIX LEGENDARY EVOLUTIONS — ONE PER RUN")
            Text("A legendary requires its source plus another regular boon of that god. It replaces its source in the same slot and retains rarity and level. One evolution per run.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(GodCatalog.legendaries) { legendary in
                boonRow(legendary, showSources: false)
            }
        }
    }

    /// What is sitting in one of the seven slots right now.
    private func slotRow(_ slot: BoonSlot) -> some View {
        let held = boons.filter { $0.def?.slot == slot }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: slot.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(slot.tint)
                Text(slot.label.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(slot.tint)
                Spacer()
                Text("\(held.count)/\(slot.capacity)")
                    .font(.system(size: 11, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchmentDim)
            }

            if held.isEmpty {
                Text("Empty — the gods fill these as the night goes on.")
                    .font(.paper(11.5))
                    .italic()
                    .foregroundStyle(Theme.parchmentDim)
            } else {
                ForEach(held) { owned in
                    HStack(alignment: .top, spacing: 5) {
                        PharaohSWagerSymbol(art: owned.def?.god.artName,
                                   fallback: owned.def?.god.symbol ?? "sparkles",
                                   size: 17, tint: owned.def?.god.tint ?? Theme.gold)
                            .frame(width: 19)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                Text(owned.def?.name ?? "Power")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(Theme.parchment)
                                Text("\(owned.rarity.label.uppercased()) · LV \(owned.level)")
                                    .font(.system(size: 8.5, weight: .black))
                                    .foregroundStyle(owned.rarity.tint)
                            }
                            Text(owned.text)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 10))
    }

    /// One god's ten regular powers, marked where you already carry them.
    private func catalogueCard(_ deity: Deity) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                PortraitMedallionView(art: CharacterArt.god(deity),
                                      fallbackSymbol: deity.symbol,
                                      tint: deity.tint,
                                      diameter: 44,
                                      glow: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(deity.name)
                        .font(.fantasy(17, weight: .black))
                        .foregroundStyle(Theme.parchment)
                    Text(deity.domain.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.3)
                        .foregroundStyle(deity.tint)
                }
                Spacer()
            }

            Text(deity.pitch)
                .font(.system(size: 11.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)

            ForEach(GodCatalog.regulars(of: deity)) { def in
                boonRow(def, showSources: false)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
    }

    /// One catalogue entry: its slot, its complete text at Common level 1, and
    /// a mark when it is the copy you actually carry.
    private func boonRow(_ def: GodBoonDef, showSources: Bool) -> some View {
        let owned = boons.first { $0.defID == def.id }
        return HStack(alignment: .top, spacing: 7) {
            Text(def.slot.label.prefix(3).uppercased())
                .font(.system(size: 8.5, weight: .black))
                .kerning(0.6)
                .foregroundStyle(def.slot.tint)
                .frame(width: 30, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(def.name)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(owned != nil ? Theme.gold : Theme.parchment)
                    if let owned {
                        Text("CARRIED · \(owned.rarity.label.uppercased()) LV \(owned.level)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.gold)
                    } else if def.isFixed {
                        Text("FIXED")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                }

                Text(owned?.text ?? def.text(rarity: .common, level: 1))
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                if showSources, !def.sources.isEmpty {
                    Text("Needs " + def.sources.map(\.label).joined(separator: " + "))
                        .font(.system(size: 9.5, weight: .black))
                        .foregroundStyle(def.god.tint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(owned != nil ? Theme.gold.opacity(0.08) : Theme.bg.opacity(0.45),
                    in: .rect(cornerRadius: 8))
    }

    private func pairingRow(_ pairing: PairingDef) -> some View {
        HStack(alignment: .top, spacing: 9) {
            HStack(spacing: 4) {
                PharaohSWagerSymbol(art: pairing.first.artName, fallback: pairing.first.symbol,
                           size: 24, tint: pairing.first.tint)
                Text("&")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.parchmentDim)
                PharaohSWagerSymbol(art: pairing.second.artName, fallback: pairing.second.symbol,
                           size: 24, tint: pairing.second.tint)
            }
            .frame(width: 82, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(pairing.name)
                    .font(.fantasy(12.5, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                Text(pairing.detail)
                    .font(.system(size: 11))
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
                                      diameter: 52,
                                      glow: false)

                VStack(alignment: .leading, spacing: 1) {
                    Text(deity.name)
                        .font(.fantasy(17, weight: .black))
                        .foregroundStyle(Theme.parchment)
                    Text(deity.domain.uppercased())
                        .font(.system(size: 10.5, weight: .black))
                        .kerning(1.4)
                        .foregroundStyle(deity.tint)
                }

                Spacer()

                Text(claimedDice == 0 ? "NO CLAIM" : "\(claimedDice) DICE")
                    .font(.system(size: 10.5, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(claimedDice > 0 ? deity.tint : Theme.parchmentDim)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(claimedDice > 0 ? deity.tint.opacity(0.14) : Theme.bg, in: .capsule)
            }

            Text(deity.pitch)
                .font(.system(size: 11.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)

            // The blessing — what their answer does to each kind of face.
            VStack(alignment: .leading, spacing: 3) {
                Text("BLESSING — ONCE PER ROLE PER ACTION")
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(deity.tint)
                ForEach(BlessingRole.allCases, id: \.self) { role in
                    HStack(alignment: .top, spacing: 5) {
                        Text(GodKit.blessingLabel(for: role))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.parchmentDim)
                            .frame(width: 108, alignment: .leading)
                        Text(GodKit.blessing(for: deity, role: role).summary)
                            .font(.system(size: 11))
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
                        PharaohSWagerSymbol(art: deity.artName, fallback: upgrade.symbol,
                                   size: 18, tint: deity.tint)
                            .frame(width: 19)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(upgrade.name)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(Theme.parchment)
                            Text(upgrade.detail)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Theme.parchmentDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if let capstone {
                    HStack(alignment: .top, spacing: 5) {
                        PharaohSWagerSymbol(art: PharaohSWagerArt.Status.champion, fallback: capstone.symbol,
                                   size: 18, tint: Theme.gold)
                            .frame(width: 19)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(capstone.name) — CAPSTONE")
                                .font(.system(size: 11.5, weight: .black))
                                .foregroundStyle(Theme.gold)
                            Text(capstone.detail)
                                .font(.system(size: 10.5))
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
                icon: "link", tint: Theme.ember, title: "COMBOS AND SINGLES",
                lines: [
                    "Every die can be used once. Combine 1–6 identical faces; Arrow I and Arrow II are separate.",
                    "Adjacent matching faces combine immediately. Different faces split the run. Drag dice to reorder; minus returns the last die.",
                    "Keep spare dice useful: Twin Shot and a separate Block give you damage and defence in the same round.",
                    "Native crit multiplier: 1 + 0.5 × critical dice / group size. No second critical roll.",
                    "New recipes are recorded in your codex when discovered."
                ]
            )
            ruleCard(
                icon: "dice.fill", tint: Theme.gold, title: "SIX DICE · EARN YOUR REROLLS",
                lines: [
                    "Draw six of your eight dice every round: five weapon and three armour dice in the collection.",
                    "There is no player stamina. Use all six dice or commit early.",
                    "Start each encounter with zero rerolls. Each unused die at commitment earns half a charge, up to two stored rerolls. Half-charges carry between rounds and reset after the encounter. Tap Reroll, then an unplayed die to spend one full charge immediately.",
                    "The other results become Kept during a reroll, including their crits. God powers can reward these results.",
                    "No results carry between rounds. The next round draws six fresh dice.",
                    "Siege Draw and Echoing Staff reserve one reroll while armed. Disarming releases it; committing spends it. Boon rewards refill the same two-charge pool."
                ]
            )
            ruleCard(
                icon: "shield.fill", tint: Theme.frost, title: "PREPARE YOUR DEFENCE",
                lines: [
                    "Block resolves at its place in the action order. Shield persists throughout the battle until consumed.",
                    "Evade grants guaranteed Dodges when it resolves, protecting later strikes. Choose an announced strike or Next strike.",
                    "Evade cancels one hit of a multi-hit attack, never the entire move. Unused dodges expire at round end.",
                    "Focus and Channel prime the next separate Attack, through the end of next round. The strongest prime wins.",
                    "All actions share the alternating queue. Attacks of 4–6 dice wind up for one player event before release."
                ]
            )

            ruleCard(
                icon: "sparkles", tint: Theme.ember, title: "CRITICAL HITS",
                lines: [
                    "Crits are decided the moment a die lands: the die picks a face, then that face's own crit chance decides if it landed critical.",
                    "A critical die keeps its face name and wears a gold CRIT badge — you always see exactly what you rolled.",
                    "Every face starts with a 10% critical chance. Imbues raise a single face permanently, up to \(Int(DieFace.critCap * 100))%.",
                    "A critical face played alone is worth ×\(String(format: "%.1f", GameData.faceCritMultiplier)) — a group scales with the proportion of its critical dice.",
                    critBonus > 0 ? "Your charms add +\(Int(critBonus * 100))% crit to every face." : "Imbued faces are marked with a gold notch on the die.",
                ]
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    PharaohSWagerImage(name: PharaohSWagerArt.chainConnector, width: 16, fit: .fit)
                        .colorMultiply(Theme.gold)
                    Text("COMBO CRITS")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .kerning(1.5)
                }
                Text("Critical quality scales native output: 1 + 0.5 × critical dice / total dice. Status riders, Dodge charges and gods do not multiply.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 3) {
                    critRow("No critical dice", "×1.00")
                    critRow("1 of 2 critical", "×1.25")
                    critRow("1 of 3 critical", "×1.1667")
                    critRow("Every die critical", "×1.50")
                }
                .padding(.top, 2)

                Text("Perfect Shot and Vanishing Strike have authored native values. Critical ingredients improve them predictably, like every other action.")
                    .font(.system(size: 12))
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
                    "Committing against a pack hands the screen to the fight and asks you to aim: each attack in turn is named at the foot of the stage, and you send it by tapping the creature it should strike. One tap per blow, on the thing you want it to hit.",
                    "Every creature you may send it at breathes under a copper ring, and the damage already pointed at each one builds up beside it. Nothing has resolved yet — you can go back to the plan until the last blow is aimed.",
                    "Each blow carries its own god triggers and statuses to wherever you send it, and a fallen target's attack slides to the nearest living foe.",
                    "Every living foe shows its whole round before you commit — health, guard, statuses and each action in order. A creature that goes under leaves the deck, so what you are looking at is only ever the fight you still have on your hands.",
                    "Pack members arrive with about half their usual health, and the purse grows a little with the pack's size.",
                    "Serpent-lords always come alone — the river is only so wide.",
                ]
            )

            // MARK: Ptah's Chisels

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.upgradeHammer, size: 22)
                    Text("CHISELS OF PTAH")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.ptahCopper)
                        .kerning(1.5)
                }
                Text("Ptah the craftsman rarely turns up in the spoils. His Chisel reshapes your whole weapon — never a single die — and your gods and their blessings are untouched. Two different Chisels a run, both active together. The optional ones are worked from the copper marks beside the turn count: tap a mark to pick that Chisel up, tap a chain in your plan to spend it there, and tap the mark again to put it down.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(ChiselCatalog.chisels(for: classID)) { chisel in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            PharaohSWagerSymbol(art: chisel.artName, fallback: chisel.symbol,
                                       size: 15, tint: Theme.ptahCopper)
                            Text(chisel.name)
                                .font(.fantasy(12, weight: .bold))
                                .foregroundStyle(Theme.parchment)
                            Text(chisel.isOptional ? "OPTIONAL" : "PASSIVE")
                                .font(.system(size: 9, weight: .black))
                                .kerning(0.8)
                                .foregroundStyle(Theme.ptahCopper)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Theme.ptahCopper.opacity(0.14), in: .capsule)
                        }
                        Text(chisel.detail)
                            .font(.system(size: 11.5))
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
                    PharaohSWagerIcon(name: PharaohSWagerArt.Status.champion, size: 22)
                    Text("DIVINE TRIALS")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.gold)
                        .kerning(1.5)
                }
                Text("Any ordinary fight can quietly be a god's Trial: a champion carrying that god's power, ringed in its colour for the whole fight. The encounter itself is ordinary — the god lends a mechanic, never health or damage. Declining costs nothing; at most one Trial per run, never before a blessing is carried, and never on a herald, a serpent-lord or the water before one. Win, and the god offers a choice of three of its own boons.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                if hasMetTrial {
                    ForEach(DivineTrial.all) { trial in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                PharaohSWagerSymbol(art: trial.deity.artName, fallback: trial.deity.symbol,
                                           size: 15, tint: trial.deity.tint)
                                Text(trial.name)
                                    .font(.fantasy(12, weight: .bold))
                                    .foregroundStyle(Theme.parchment)
                            }
                            Text(trial.power)
                                .font(.system(size: 11.5))
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
                        .font(.system(size: 11.5))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgCard, in: .rect(cornerRadius: 14))

            ruleCard(
                icon: "shield.fill", tint: Theme.bronze, title: "ENEMY GUARD",
                lines: [
                    "A foe keeps one guard pool on a bronze channel over its health — plate it was born wearing and block it raises mid-fight are the same resource, so there is only ever one layer to chew through.",
                    "Your hits chip the guard first; only when it is gone can health be touched. What survives your turn stands until something breaks it, Your own guard also persists until consumed.",
                    "Pierce ignores part of the guard, measured against the deepest it has ever stood.",
                    "Poison, burn and bleed seep under it and tick health directly — damage over time is the answer to a heavy guard.",
                    "Guard never regenerates on its own, so breaking a plated brute is a real investment: they trade burst damage for staying power.",
                ]
            )

            actionOrderCard

            statusGlossary

            ruleCard(
                icon: "arrow.left.arrow.right", tint: Theme.steelBlue, title: "ARRANGEMENT IS EVERYTHING",
                lines: [
                    "The plan resolves left to right, in the order you place the dice — and that same order is what decides which chains form at all.",
                    "Only neighbours chain. Dropping a die between two others can weld a chain together, or break one you already had.",
                    "Inside a run of neighbours the order does not matter, so a chain is never a memory test about which die you tapped first.",
                    "Where two chains could both claim the same dice, the longer and more specific one takes them.",
                    "The plan only ever shows the order you will play, never what it adds up to — a chain names itself when it lands.",
                    "Tap a die in the plan to take it back and use it elsewhere.",
                ]
            )
        }
    }

    private var actionOrderCard: some View {
        ruleCard(icon: "arrow.left.arrow.right", tint: Theme.frost, title: "ACTION ORDER", lines: [
            "Every support action takes a turn-order event. Attacks using four to six dice wind up, then release on a second event. Enemy actions alternate between yours.",
            "Each enemy gets only its announced actions. Playing more singles never gives it extra attacks.",
            "When one side runs out, the remaining announced actions finish. Defeated enemies lose their pending actions.",
            "Glacier and other delay effects move a pending enemy action behind your next action. They never delete attacks.",
            "Open TURN ORDER to inspect the sequence before committing."
        ])
    }

    // MARK: - Status glossary

    /// Every status defined properly, once: its mark, what it does, when it
    /// fires, whether it stacks, whether guard stops it, and its ceiling.
    /// The fight's tap-a-badge bubbles read from the same definitions, so a
    /// status can never be explained two different ways.
    private var statusGlossary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "drop.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.venom)
                Text("EVERY STATUS, DEFINED")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.venom)
                    .kerning(1.5)
            }

            Text("Tap any badge under a fighter mid-fight and this same reading opens beside it, with your live numbers.")
                .font(.system(size: 11.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            ForEach(StatusKind.allCases) { status in
                statusEntry(status)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
    }

    private func statusEntry(_ status: StatusKind) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                PharaohSWagerSymbol(art: status.art, fallback: status.fallbackSymbol,
                           size: 17, tint: status.tint)
                    .frame(width: 24, height: 24)
                    .background(status.tint.opacity(0.15), in: .rect(cornerRadius: 6))

                Text(status.name.uppercased())
                    .font(.system(size: 12.5, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(status.tint)

                // The god who owns this status, named right beside it.
                if let patron = status.patron {
                    HStack(spacing: 3) {
                        PharaohSWagerSymbol(art: patron.artName, fallback: patron.symbol,
                                   size: 11, tint: patron.tint)
                        Text(patron.name.uppercased())
                            .font(.system(size: 8.5, weight: .black))
                            .kerning(0.5)
                            .foregroundStyle(patron.tint)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(patron.tint.opacity(0.14), in: .capsule)
                }

                Spacer(minLength: 0)

                if status.bypassesGuard {
                    Text("PAST GUARD")
                        .font(.system(size: 8, weight: .black))
                        .kerning(0.5)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Theme.blood, in: .capsule)
                }
            }

            // Written from the wearer's point of view, as in the fight.
            Text(status.summary(onSelf: true))
                .font(.system(size: 12))
                .foregroundStyle(Theme.parchment.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text(status.codexLine)
                .font(.system(size: 11))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            Text(status.stacking)
                .font(.system(size: 11))
                .italic()
                .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 9))
    }

    private func critRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .black).monospacedDigit())
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(tint)
                    .kerning(1.5)
            }
            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
    }
}


