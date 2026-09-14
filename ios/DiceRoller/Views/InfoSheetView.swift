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

    private var devotion: [Deity: Int] { Devotion.counts(loadout) }

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
                Image(systemName: hero.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(hero.accent)
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
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.parchmentDim)
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
                    .foregroundStyle(tab == entry ? Theme.bg : Theme.parchmentDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(
                        tab == entry ? AnyShapeStyle(hero.accent) : AnyShapeStyle(Theme.bgCard),
                        in: .capsule
                    )
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
                        Image(systemName: piece.symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(hero.accent)
                            .frame(width: 26, height: 26)
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
                    Image(systemName: "bag")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.parchmentDim)
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
                    Image(systemName: face.symbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(face.tint)
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
            sectionTitle("THE PANTHEON — GODS MARK THE FACES YOU ALREADY OWN")

            Text("Gods rise out of the water after every fight and hold court at the shrines on the bank. A god never takes a face away: their named gift is laid on top of a face you already own — the face keeps its name, its numbers and every chain it feeds, and the gift's answer rides on top. Each god carries twelve gifts, four per kind of face, and a gift deepens three times on the same face, ending in a named final form. One face belongs to one god; only a rare dual-god rite binds two gods into one face — and a bound face fires their duo at full strength every play.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Deity.allCases) { deity in
                deityCard(deity)
            }

            comboGroup(
                title: "CROSS-GOD FUSIONS — ANY CLASS",
                combos: DivineContent.fusions
            )

            sectionTitle("DUO GODS — FIFTEEN NAMED PAIRS")
            Text("Chain two different gods' gifted faces into one chain and their duo fires as a bonus rider — a taste. Bind the pair into one face with a rare rite and it fires at full strength every play.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(DuoContent.all) { duo in
                duoRow(duo)
            }
        }
    }

    private func duoRow(_ duo: DuoDef) -> some View {
        HStack(alignment: .top, spacing: 9) {
            HStack(spacing: 4) {
                Image(systemName: duo.first.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(duo.first.tint)
                Text("&")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Theme.parchmentDim)
                Image(systemName: duo.second.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(duo.second.tint)
            }
            .frame(width: 96, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(duo.name)
                    .font(.fantasy(12.5, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                Text("Chained — \(duo.chained.summary).")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Bound by rite — \(duo.bound.summary).")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.gold.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Text(duo.flavor)
                    .font(.system(size: 8.5).italic())
                    .foregroundStyle(Theme.parchmentDim.opacity(0.7))
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
        let count = devotion[deity] ?? 0
        let classCombos = DivineContent.classCombos(classID).filter { $0.deity == deity }
        let ladder = DivineContent.ladder(for: deity)
        let signature = DivineContent.signatures.filter { $0.deity == deity }

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

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < count ? deity.tint : Theme.bg)
                            .frame(width: 7, height: 7)
                    }
                    Text("\(count)")
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                        .foregroundStyle(count > 0 ? deity.tint : Theme.parchmentDim)
                }
            }

            // Their twelve gifts — four per kind of face, touched → final form.
            VStack(alignment: .leading, spacing: 6) {
                ForEach(MarkRole.allCases, id: \.self) { role in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.label.uppercased())
                            .font(.system(size: 7, weight: .black))
                            .kerning(0.5)
                            .foregroundStyle(deity.tint)
                        ForEach(GiftContent.gifts(deity, role)) { gift in
                            HStack(alignment: .top, spacing: 5) {
                                Image(systemName: gift.symbol)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(deity.tint)
                                    .frame(width: 13)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(gift.name) — \(gift.touched.summary)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Theme.parchment)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Final form: \(gift.finalFormName) — \(gift.finalForm.summary)")
                                        .font(.system(size: 8.5))
                                        .foregroundStyle(deity.tint.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }

            // Devotion track.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(deity.passives, id: \.threshold) { passive in
                    HStack(spacing: 5) {
                        Image(systemName: count >= passive.threshold ? "checkmark.seal.fill" : "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(count >= passive.threshold ? deity.tint : Theme.parchmentDim.opacity(0.5))
                        Text("\(passive.threshold) devotion — \(passive.text)")
                            .font(.system(size: 9))
                            .foregroundStyle(count >= passive.threshold ? Theme.parchment : Theme.parchmentDim.opacity(0.7))
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 9))

            if !classCombos.isEmpty || !ladder.isEmpty || !signature.isEmpty {
                VStack(spacing: 4) {
                    ForEach(ladder + classCombos + signature) { combo in
                        divineComboRow(combo, deity: deity, count: count)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(count >= Devotion.passiveTier ? deity.tint.opacity(0.45) : .clear, lineWidth: 1)
        )
    }

    private func divineComboRow(_ combo: ComboDef, deity: Deity, count: Int) -> some View {
        let locked = combo.devotionRequired > count
        let reachable = GameData.isReachable(combo, loadout: loadout)
        return HStack(alignment: .top, spacing: 9) {
            ComboRecipeView(combo: combo, tileSize: 19)
                .frame(width: 96, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(combo.name)
                        .font(.fantasy(12.5, weight: .bold))
                        .foregroundStyle(locked ? Theme.parchmentDim : deity.tint)
                    if locked {
                        Text("DEVOTION \(combo.devotionRequired)")
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(Theme.bg, in: .capsule)
                    } else if reachable {
                        Text("READY")
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundStyle(Theme.bg)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(deity.tint, in: .capsule)
                    }
                    Text("\(combo.staminaCost) stam")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Theme.parchmentDim)
                }
                Text(combo.effectSummary)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 9))
        .opacity(locked ? 0.6 : 1)
    }

    // MARK: - Rules tab

    private var rulesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ruleCard(
                icon: "link", tint: Theme.ember, title: "CHAINS ARE THE FIGHT",
                lines: [
                    "A face played on its own is chip damage — worth about \(Int(GameData.soloAttackScale * 100))% of its printed value. One arrow will not win you anything.",
                    "Fuse faces side by side into a recipe and the whole chain multiplies: two faces pay as printed, three ×\(String(format: "%.1f", GameData.comboLengthScale(faces: 3))), four ×\(String(format: "%.1f", GameData.comboLengthScale(faces: 4))), five ×\(String(format: "%.1f", GameData.comboLengthScale(faces: 5))).",
                    "Damage, block, healing, poison, bleed and burn all ride the same curve — a long defensive chain is worth building too.",
                    "Order matters: the faces must sit side by side in the plan, in the recipe's exact order.",
                    "The longest recipe always wins, so a four-face chain beats the two-face combo hiding inside it.",
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
                    "A weak die dilutes every draw — the Ferryman's Whetstone Ritual rolls a die's unclaimed faces anew instead of throwing it away.",
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
                    "A held face played into a combo adds +\(Int(GameData.frozenFuelCritBonus * 100))% to that chain's crit roll — spend the freeze setting up the big chain.",
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
                    Image(systemName: "link")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.gold)
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

                Text("Perfect Shot and Vanishing Strike always crit, whatever fed them. The play bar shows each step's crit odds and its critical damage before you commit. A face carried over from a freeze glints with frost and adds +\(Int(GameData.frozenFuelCritBonus * 100))% to the chain's crit odds.")
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
                    "A god never takes a face away. Their named gift is laid on top of a face you already own — the face keeps its name, its numbers and every chain it fed. A fire arrow is still an arrow.",
                    "Each god carries twelve gifts — four for attacks, four for guards, four for mends and support — and they pull in different directions. Following Ra twice does not mean the same run twice.",
                    "A gift deepens where it lands: touched, deepened, then a named final form. Once a face carries a gift it carries that gift. Replacing one is possible only through a rare shrine offer — and it costs all the depth.",
                    "When a chain fires, every gifted face in it speaks in turn on top of the chain's own effect — gently scaled, each announced on its own. Two different gods in one chain fire their named duo; three or more trigger the pantheon flourish and every rider lands harder.",
                    "Every pair of gods has a named duo — fifteen in all. Chain two gods for a taste; a rare rite binds the pair into one face and fires the duo at full strength every play.",
                    "Devotion counts one per gifted face, more the deeper it runs. Two devotion opens a god's first own chain, three their second, five their signature — and a god's chain hits harder the more devotion stands behind it when it fires.",
                ]
            )

            ruleCard(
                icon: "person.2.fill", tint: Theme.blood, title: "ENEMY PACKS",
                lines: [
                    "Some fights put more than one foe on the deck — mostly pairs, occasionally three, all from the same stretch of the river.",
                    "Tap a foe to aim at it. Your aim sticks until you tap another, and slides to the nearest living foe if your target falls mid-turn.",
                    "Every living foe shows its own intent, health and statuses — and on their turn they act one after another.",
                    "Pack members arrive with about half their usual health, and the purse and relic odds grow a little with the pack's size.",
                    "Serpent-lords always come alone — the river is only so wide.",
                ]
            )

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
                    "Bleed, Poison and Burn tick on the enemy at the start of their turn and stack duration.",
                    "Statuses seep under armour and land on health directly.",
                    "Stagger weakens the enemy's very next attack by its percentage, then wears off.",
                    "Mark multiplies your next hit on that enemy.",
                    "Pierce ignores part of the enemy's block and armour. Block soaks damage and clears each turn unless a Brace carries it.",
                    "Evade cancels one incoming hit outright — and every evade you get comes from a face you played or a gift you carry. Nobody slips a blow by luck alone.",
                ]
            )

            ruleCard(
                icon: "arrow.left.arrow.right", tint: Theme.steelBlue, title: "ORDER MATTERS",
                lines: [
                    "The plan resolves strictly left to right, in the order you place the dice.",
                    "Adjacent faces matching one of your recipes fuse into a single combo step.",
                    "Mis-ordered chains simply play as separate faces — Rising Guillotine and Cleaving Follow-Through use the same two faces in opposite order.",
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
