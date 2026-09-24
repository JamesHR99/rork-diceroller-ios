import SwiftUI

/// The deck of the barque and the water around it: you on the left, the thing
/// that came out of the river on the right, and the dice deck sliding up over
/// the whole lower half while you plan the turn.
struct BattleView: View {
    @Environment(GameManager.self) private var game

    var body: some View {
        if let engine = game.battle {
            BattleContentView(engine: engine)
        } else {
            Color.clear
        }
    }
}

private struct BattleContentView: View {
    let engine: BattleEngine
    @Environment(GameManager.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showInfo = false
    @State private var showBoons = false
    @State private var arrivalShown = true

    private var gate: Gate { game.gate }

    /// Keep the combat hand on-screen throughout the round. Resolution and
    /// enemy animations play above it instead of making the whole interface
    /// disappear and reappear between actions.
    private var deckUp: Bool {
        switch engine.phase {
        case .won, .lost:
            return false
        default:
            return true
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topStrip

                    // The battlefield always receives the full remaining
                    // screen. The combat console is a true overlay on the
                    // barque, so showing the dice never pushes the boat or the
                    // fighters upward.
                    battleStage(size: size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .modifier(ShakeEffect(animatableData: engine.shakeTrigger))

                diceDeck(size: size)
            }
            // The river is painted behind the arena rather than stacked inside
            // it. As a background it cannot drive the layout — held as a child
            // it ignored the safe area and dragged the whole stack down past
            // the bottom of the screen, taking the stamina rail and the FIGHT
            // slab with it.
            .background { arenaBackground(size: size) }
            // Arrows, thrown knives, cast runes and lobbed bombs cross the air
            // above the deck, launched from the frames the fighters reported.
            .overlayPreferenceValue(FighterAnchorKey.self) { anchors in
                ZStack {
                    ProjectileLayerView(shots: engine.shots, anchors: anchors)
                    // Every blow leaves its own mark on the body it struck:
                    // gashes, punctures, impact stars, scorches and lattices.
                    ImpactLayerView(marks: engine.impacts, anchors: anchors)
                }
                .zIndex(3)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9), value: deckUp)
        }
        .overlay(alignment: .bottom) {
            // Aiming happens after you commit: the deck is down, the stage is
            // uncovered, and each blow asks which creature it should strike.
            if engine.isAiming, let aim = engine.activeAim {
                aimPrompt(aim)
                    .zIndex(6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: engine.activeAim?.id)
        .overlay {
            if let announcement = engine.stageAnnouncement {
                stageBanner(announcement)
            }
        }
        .overlay {
            if arrivalShown {
                arrivalCard.zIndex(5)
            }
        }
        .overlay {
            if engine.phase == .won || engine.phase == .lost {
                battleEndOverlay
            }
        }
        .overlay {
            // A god's Trial: the sigil rises before the fight truly opens.
            if engine.trialPromptVisible {
                TrialPromptView(engine: engine)
                    .zIndex(7)
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: engine.trialPromptVisible)
        .overlay {
            // The engine already totals every resolving action into a spotlight.
            // Keep it in the middle of the arena so damage, combo names and
            // statuses are readable while the fighters and dice remain visible.
            if let spotlight = engine.spotlight {
                ActionSpotlightView(card: spotlight)
                    .padding(.horizontal, 90)
                    .zIndex(8)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.spotlight?.id)
        .task {
            // The opening hand should behave like every later turn: it rolls
            // itself as soon as battle appears. The guard inside rollAll keeps
            // this safe if SwiftUI re-runs the task after the hand has settled.
            engine.rollAll(reduceMotion: reduceMotion)
        }
        .onChange(of: engine.turnNumber) { _, _ in
            // Every fresh player turn auto-rolls after the engine has drawn its
            // new six-die hand. Keeping this trigger in the live battle view
            // avoids coupling deterministic engine tests to presentation timing.
            engine.rollAll(reduceMotion: reduceMotion)
        }
        .sheet(isPresented: $showBoons) {
            VStack(spacing: 12) {
                HStack {
                    Text("GOD BOONS").font(.fantasy(26, weight: .black)).foregroundStyle(Theme.gold)
                    Spacer()
                    Button("DONE") { showBoons = false }
                        .font(.fantasy(14, weight: .bold)).foregroundStyle(Theme.parchment)
                        .buttonStyle(PaintedButtonStyle(tone: .secondary))
                        .frame(width: 110)
                }
                GoldRule(height: 6)
                ScrollView {
                    VStack(spacing: 12) {
                        if game.equippedBoons.isEmpty {
                            Text("No god boons equipped yet. Earn blessings during your voyage.")
                                .foregroundStyle(Theme.parchment).padding(24)
                        }
                        ForEach(game.equippedBoons) { boon in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    PharaohSWagerSymbol(art: boon.def?.god.artName,
                                        fallback: boon.def?.god.symbol ?? "sparkles", size: 30,
                                        tint: boon.def?.god.tint ?? Theme.gold)
                                    Text(boon.def?.name ?? boon.defID)
                                        .font(.fantasy(20, weight: .bold)).foregroundStyle(Theme.gold)
                                    Spacer()
                                    Text("\(boon.rarity.label) · Level \(boon.level)")
                                        .font(.system(size: 12, weight: .bold)).foregroundStyle(boon.rarity.tint)
                                }
                                Text(boon.text).font(.system(size: 15)).foregroundStyle(Theme.parchment)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background { TurnOrderPlaque(accent: boon.def?.god.tint ?? Theme.gold) }
                        }
                    }
                    .padding(4)
                }
            }
            .padding(20)
            .background { PapyrusSurface(ground: .panel, tint: Theme.bg, strength: 0.75, shade: 0.3).ignoresSafeArea() }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus,
                              drawnDieIDs: game.battle?.drawnDieIDs ?? [],
                              hasMetTrial: game.trialUsed,
                              boons: game.equippedBoons)
            }
        }
    }

    // MARK: - Dice deck

    private func actionTrayHeight(for size: CGSize) -> CGFloat {
        // The controls now float over the barque rather than reserving layout
        // space. On phones that lets the hand become a larger two-tier console:
        // dice/roll above, Resolve + Reroll + Play below.
        if size.width < 600 {
            return min(142, max(122, size.height * 0.18))
        }
        return min(126, max(108, size.height * 0.16))
    }

    @ViewBuilder
    private func diceDeck(size: CGSize) -> some View {
        let trayHeight = actionTrayHeight(for: size)
        let phone = size.width < 600
        let wideResolveWidth: CGFloat = 86
        let wideControlsWidth: CGFloat = 222
        let wideOuterPadding: CGFloat = 14
        let wideSpacing: CGFloat = 12
        let wideDiceWidth = max(
            300,
            size.width - wideResolveWidth - wideControlsWidth
                - (wideOuterPadding * 2) - (wideSpacing * 2)
        )

        Group {
            if phone {
                VStack(spacing: 4) {
                    // Give the six-die hand almost the whole phone width. With
                    // no manual roll control, every lane is now a physical die.
                    DiceTrayView(
                        engine: engine,
                        maxReelHeight: 66,
                        maxRowWidth: max(300, size.width - 12),
                        compact: true
                    )
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        ResolveMedallionView(engine: engine, diameter: 38)

                        Spacer(minLength: 6)

                        PlayBarView(engine: engine, bodyHeight: 72)
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.top, 5)
                .padding(.bottom, 7)
            } else {
                HStack(spacing: wideSpacing) {
                    ResolveMedallionView(engine: engine, diameter: wideResolveWidth)
                        .frame(width: wideResolveWidth)

                    DiceTrayView(
                        engine: engine,
                        maxReelHeight: 94,
                        maxRowWidth: wideDiceWidth,
                        compact: true
                    )
                    .frame(maxWidth: wideDiceWidth)

                    PlayBarView(engine: engine, bodyHeight: 112)
                        .frame(width: wideControlsWidth)
                }
                .padding(.horizontal, wideOuterPadding)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: trayHeight, alignment: .bottom)
        .disabled(!engine.rerollChargeFlights.isEmpty)
        .overlayPreferenceValue(RerollChargeAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if !engine.rerollChargeFlights.isEmpty, let target = anchors["reroll"] {
                    RerollChargeFlight(
                        sources: engine.rerollChargeFlights.compactMap { anchors[$0.uuidString].map { proxy[$0] } },
                        destination: proxy[target]
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .background {
            DeckShelfBackground(armed: engine.selectingReroll)
                .ignoresSafeArea(edges: .bottom)
        }
        .offset(y: deckUp ? 0 : trayHeight + 28)
        .opacity(deckUp ? 1 : 0)
        .allowsHitTesting(deckUp)
        .accessibilityHidden(!deckUp)
    }

    // MARK: - Stage

    /// How tall an ordinary fighter stands, measured off the room the arena
    /// has actually been given rather than the whole screen. The name, the
    /// bars and the status row all have to fit above the figure, and a
    /// serpent-lord is drawn taller again, so the tallest fighter on the deck
    /// sets the measure for everyone.
    private func fighterHeight(_ room: CGFloat, hasIntent: Bool = false) -> CGFloat {
        let chrome: CGFloat = hasIntent ? 120 : 96
        let tallest: CGFloat = engine.stagedFoes.contains { $0.def.isBoss } ? 1.16 : 1
        let free = room - chrome
        return min(232, max(112, free / (1.06 * tallest)))
    }

    /// The fight itself, uncovered once the deck goes down: full-size figures
    /// standing on the hull with the water behind them.
    private func battleStage(size: CGSize) -> some View {
        GeometryReader { stage in
            let room = stage.size.height
            let foeCount = engine.stagedFoes.count
            let boatWidth = stage.size.width + 100
            // The usable fighting deck is inset from the prow and stern and
            // sits lower than the ornamental rail. The old lift put feet on
            // the rail itself; this value follows the broad central planks.
            let deckInset: CGFloat = 24
            let combatWidth = max(280, stage.size.width - deckInset * 2)
            // Landscape iPhones are wider than 600pt, so width alone cannot
            // identify the compact screen shown in play. Use the short side to
            // reserve the full dice-console depth and keep both fighters above it.
            let isCompactPhone = min(size.width, size.height) < 500
            let trayClearance: CGFloat = isCompactPhone ? 78 : 26
            let deckLift: CGFloat = isCompactPhone
                ? min(138, max(112, boatWidth * 0.065 + trayClearance))
                : min(98, max(62, boatWidth * 0.065 + trayClearance))
            let fighterRoom = max(150, room - deckLift)
            // A crowd takes more of the deck than a single guardian, but the
            // demigod always keeps a readable share of it.
            let playerWidth = max(112, combatWidth * (foeCount >= 3 ? 0.25 : 0.35))
            let foeWidth = max(92, combatWidth - 20 - playerWidth)

            ZStack(alignment: .bottom) {
                BattleBarqueView(gate: gate, width: boatWidth, discGlow: game.discGlow)
                    .opacity(0.96)

                HStack(alignment: .bottom, spacing: 8) {
                    FighterView(
                        engine: engine,
                        side: .player,
                        heroSymbol: game.heroClass?.fighterSymbol ?? "figure.stand",
                        heroName: game.heroClass?.name ?? "Hero",
                        accent: game.heroClass?.accent ?? Theme.gold,
                        heroClassID: game.classID,
                        stageHeight: fighterHeight(fighterRoom),
                        cardWidth: foeCount > 1 ? playerWidth : nil
                    )

                    Spacer(minLength: 0)

                    enemyGroup(room: fighterRoom, width: foeWidth)
                }
                .padding(.horizontal, deckInset)
                .padding(.bottom, deckLift)
                .frame(width: stage.size.width, height: room, alignment: .bottom)
            }
            .frame(width: stage.size.width, height: room)
        }
    }

    /// The barque hull sits under the fighters — you are fighting on the deck.
    /// The river draws no hull of its own while the arena is up, so there is
    /// only ever one boat on screen.
    private func arenaBackground(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [gate.discColor.opacity(0.16 * game.discGlow), .clear],
                center: .center,
                startRadius: 60,
                endRadius: 480
            )

            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// The foes stand together on the right of the deck — one, or packed up
    /// two or three wide when the river sends company. While attacks are being
    /// allocated they are tapped to receive the selected blow; otherwise they
    /// stand quiet — no aiming happens during planning.
    private func enemyGroup(room: CGFloat, width: CGFloat) -> some View {
        let foes = engine.stagedFoes
        let scale: CGFloat = foes.count >= 3 ? 0.66 : (foes.count == 2 ? 0.8 : 1)
        // The pack is cut to the room the deck actually has. Three cards at a
        // fixed width overran an iPhone and pushed the last foe off-screen, so
        // the share is measured and the figures squeeze to fit it.
        let cardWidth = max(92, width / CGFloat(max(foes.count, 1)))
        return HStack(alignment: .bottom, spacing: 0) {
            ForEach(foes) { foe in
                FighterView(
                    engine: engine,
                    side: .enemy,
                    heroSymbol: "",
                    heroName: "",
                    accent: Theme.blood,
                    foe: foe,
                    packScale: scale,
                    isTargeted: engine.isTargeted(foeID: foe.id),
                    isAimable: engine.isAiming && foe.isAlive,
                    onTap: engine.isAiming ? { engine.aim(at: foe.id) } : nil,
                    stageHeight: fighterHeight(room, hasIntent: true),
                    cardWidth: foes.count > 1 ? cardWidth : nil
                )
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: foes.count)
    }

    /// Multi-enemy fights still need a targeting moment, but this pass keeps it
    /// deliberately free of combo names, damage previews and effect text.
    private func aimPrompt(_ aim: AimRequest) -> some View {
        VStack(spacing: 8) {
            Text("CHOOSE A TARGET")
                .font(.fantasy(18, weight: .black))
                .kerning(1.8)
                .foregroundStyle(Theme.gold)

            if !aim.faces.isEmpty {
                HStack(spacing: 5) {
                    ForEach(Array(aim.faces.prefix(5).enumerated()), id: \.offset) { _, face in
                        PharaohSWagerSymbol(
                            art: face.artName,
                            fallback: face.symbol,
                            size: 22,
                            tint: face.tint
                        )
                        .frame(width: 28, height: 26)
                        .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 7))
                    }
                }
            }

            HStack(spacing: 10) {
                Text("TAP AN ENEMY")
                    .font(.system(size: 9.5, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(Theme.parchmentDim)

                if engine.aimQueue.count > 1 {
                    Text("\(engine.aimQueue.count) LEFT")
                        .font(.system(size: 9, weight: .black))
                        .kerning(1)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Theme.gold, in: .capsule)
                }

                Button {
                    engine.cancelAiming()
                } label: {
                    Text("BACK")
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(Theme.parchment)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Theme.bgElevated, in: .capsule)
                        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bgElevated, strength: 0.55, shade: 0.44)
                .clipShape(.rect(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1.2)
        )
        .goldCorners(size: 18, inset: 4, opacity: 0.6)
        .shadow(color: .black.opacity(0.7), radius: 16, y: 6)
        .padding(.bottom, 18)
        .padding(.horizontal, 14)
    }

    // MARK: - Top strip

    /// The run's heading: the turn count, the chisels riding this run, the
    /// night dial and the codex. Everything here got a size up now that the
    /// dice have their own deck and the top of the screen is free.
    private var topStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Text("TURN")
                    .font(.system(size: 9, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.parchmentDim)
                Text("\(engine.turnNumber)")
                    .accessibilityLabel("Round \(engine.turnNumber). \(engine.pressureSummary)")
                    .help(engine.pressureSummary)
                    .font(.system(size: 15, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Theme.bgElevated, in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1))

            boonStrip

            // Chisels of Ptah: the copper marks beside the turn. The optional
            // ones are controls — tap a mark to pick the Chisel up, then tap
            // the chain in your plan you want it to ride. Tap it again to put
            // it back down.
            if !engine.chisels.isEmpty {
                HStack(spacing: 3) {
                    ForEach(engine.chisels.sorted(), id: \.self) { id in
                        chiselMark(id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.bgElevated, in: .capsule)
                .overlay(Capsule().strokeBorder(
                    Theme.ptahCopper.opacity(engine.armingChisel != nil ? 0.9 : 0.4),
                    lineWidth: engine.armingChisel != nil ? 1.6 : 1
                ))
            }

            // No running narration here: the damage numbers, the action
            // spotlight and the floating text already say what just happened.
            Spacer(minLength: 4)

            NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)

            Button {
                showInfo = true
                Haptics.light()
            } label: {
                HStack(spacing: 5) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.utilityCodex, size: 19)
                    Text("CODEX")
                        .font(.fantasy(13, weight: .black))
                        .kerning(1)
                        .foregroundStyle(Theme.parchment)
                }
                .paintedContentInsets()
                .frame(width: 84, height: 44)
                .background {
                    PharaohSWagerImage(name: PharaohSWagerArt.button(.secondary, .normal), fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(.rect(cornerRadius: 11))
            }
            .buttonStyle(PressableButtonStyle())

            PauseButton()
        }
        .padding(.horizontal, 14)
        .padding(.top, 3)
    }

    /// God boons stay visible as icons during combat instead of hiding behind
    /// a count. Tapping the strip still opens the existing detailed sheet.
    private var boonStrip: some View {
        Button {
            showBoons = true
            Haptics.light()
        } label: {
            HStack(spacing: 4) {
                if game.equippedBoons.isEmpty {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.parchmentDim)
                    Text("NO BOONS")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Theme.parchmentDim)
                } else {
                    ForEach(game.equippedBoons) { boon in
                        let god = boon.def?.god
                        PharaohSWagerSymbol(
                            art: god?.artName,
                            fallback: god?.symbol ?? "sparkles",
                            size: 18,
                            tint: god?.tint ?? Theme.gold
                        )
                        .frame(width: 28, height: 28)
                        .background(Theme.bg.opacity(0.72), in: .rect(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder((god?.tint ?? Theme.gold).opacity(0.5), lineWidth: 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if boon.level > 1 {
                                Text("\(boon.level)")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(Theme.bg)
                                    .frame(width: 12, height: 12)
                                    .background(Theme.gold, in: .circle)
                                    .offset(x: 3, y: 3)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Theme.bgElevated.opacity(0.92), in: .rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.gold.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier("battle.boons")
        .accessibilityLabel("Equipped god boons, \(game.equippedBoons.count)")
    }

    /// One Chisel's copper mark. An optional Chisel is a button: it lifts the
    /// mark, lights every chain in the plan it could ride, and waits for you
    /// to name one. A passive Chisel just says what it is already doing.
    private func chiselMark(_ id: String) -> some View {
        let optional = engine.isOptionalChiselCarried(id)
        let held = engine.armingChiselID == id
        return Button {
            engine.beginArming(id)
        } label: {
            PharaohSWagerSymbol(art: PharaohSWagerArt.chisel(id),
                       fallback: ChiselCatalog.def(id)?.symbol ?? "hammer.fill",
                       size: 18,
                       tint: held ? Theme.bg : Theme.ptahCopper)
                .frame(width: 26, height: 26)
                .background {
                    if held {
                        Circle().fill(Theme.ptahCopper)
                    } else if optional {
                        Circle().strokeBorder(Theme.ptahCopper.opacity(0.55), lineWidth: 1)
                    }
                }
                .shadow(color: held ? Theme.ptahCopper.opacity(0.8) : .clear, radius: 7)
                .overlay(alignment: .topTrailing) {
                    // A small copper pip marks the Chisels that are yours to
                    // spend, so they read apart from the passive ones.
                    if optional, !held {
                        Circle()
                            .fill(Theme.ptahCopper)
                            .frame(width: 5, height: 5)
                            .offset(x: 1, y: -1)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(engine.phase != .player)
        .accessibilityLabel(ChiselCatalog.def(id)?.name ?? "Chisel")
        .accessibilityHint(optional ? "Tap, then tap a chain to spend it" : "Always active")
    }

    /// Announces a serpent-lord re-coiling into a new stage, on the painted
    /// banner with the name burning over it.
    private func stageBanner(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text.uppercased())
                .font(.fantasy(15, weight: .black))
                .kerning(2)
                .foregroundStyle(Theme.parchment)
                .padding(.horizontal, 44)
                .padding(.vertical, 14)
                .background {
                    PharaohSWagerImage(name: PharaohSWagerArt.banner, fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .colorMultiply(Theme.blood)
                }
                .shadow(color: Theme.blood.opacity(0.7), radius: 18)
            Spacer()
        }
        .allowsHitTesting(false)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: text)
    }

    /// The card that names whatever just came out of the water — one foe, or
    /// the whole pack with an armour warning when plates are in play.
    private var arrivalCard: some View {
        let foes = engine.enemies
        let count = foes.count
        let solo = count == 1
        let portraitHeight: CGFloat = solo ? 178 : (count == 2 ? 140 : 112)
        let headline = foes.first?.def.isBoss == true
            ? "THE GATE IS BARRED"
            : count == 2 ? "TWO RISE"
            : count == 3 ? "THREE RISE"
            : "SOMETHING RISES"
        let names = foes.map { $0.def.name }.joined(separator: " + ")
        let anyArmoured = foes.contains { $0.def.armour > 0 }
        return ZStack {
            Theme.bg.opacity(0.82).ignoresSafeArea()

            HStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Theme.blood.opacity(0.4), .clear],
                                             center: .center, startRadius: 2, endRadius: 70))
                        .frame(width: 150, height: 150)
                    HStack(spacing: solo ? 0 : -20) {
                        ForEach(foes) { foe in
                            PortraitView(art: CharacterArt.foe(foe.def.id, stageID: foe.stageID),
                                         fallbackSymbol: foe.def.symbol,
                                         tint: Theme.blood,
                                         height: portraitHeight,
                                         mirrorFallback: true)
                                .shadow(color: Theme.blood.opacity(0.8), radius: 22)
                        }
                    }
                }
                .frame(width: 186)

                VStack(alignment: .leading, spacing: 8) {
                    Text(headline)
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(3)
                        .foregroundStyle(Theme.blood)

                    Text(names.uppercased())
                        .font(.fantasy(solo ? (foes[0].def.isBoss ? 32 : 27) : 20, weight: .black))
                        .kerning(2)
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.parchment, Theme.gold],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)

                    GoldRule(height: 6, opacity: 0.85)
                        .frame(width: 300)

                    Text(foes[0].def.title)
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.6)
                        .foregroundStyle(gate.accent)

                    if anyArmoured {
                        HStack(spacing: 5) {
                            PharaohSWagerIcon(name: PharaohSWagerArt.Status.armour, size: 13)
                            Text("ARMOURED — BREAK THE PLATE BEFORE THE HEALTH")
                                .font(.system(size: 9, weight: .black))
                                .kerning(1.2)
                                .foregroundStyle(Theme.bronze)
                        }
                    }

                    if let blurb = foes.first?.def.blurb, !blurb.isEmpty {
                        Text(blurb)
                            .font(.fantasy(13, weight: .medium))
                            .italic()
                            .foregroundStyle(Theme.parchmentDim)
                            .frame(width: 340, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) { arrivalShown = false }
                        Haptics.medium()
                    } label: {
                        Text(foes[0].def.isBoss ? "Stand Between It and Ra" : "Take Up Your Dice")
                            .font(.fantasy(16, weight: .bold))
                            .foregroundStyle(Theme.parchment)
                            .paintedContentInsets()
                            .frame(width: 260, height: 48)
                            .background {
                                PharaohSWagerImage(name: PharaohSWagerArt.button(.primary, .normal), fit: .stretch)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.top, 4)
                }
            }
            .padding(30)
        }
        .transition(.opacity)
        .onAppear { Haptics.heavy() }
    }

    private var battleEndOverlay: some View {
        let won = engine.phase == .won
        return HStack(spacing: 24) {
            PharaohSWagerImage(name: won ? "duat_environment_sun_bright" : "duat_environment_sun_extinguished",
                      height: 76, fit: .fit)
                .shadow(color: (won ? Theme.gold : Theme.blood).opacity(0.7), radius: 18)

            VStack(alignment: .leading, spacing: 8) {
                VerdictBanner(title: won ? "THE WAY IS CLEAR" : "THE DISC GOES OUT", won: won)

                Text(won
                     ? "\(engine.isPack ? "The pack" : engine.enemyDisplayName) sinks back into the water. \(engine.combosLanded) combos, \(engine.critsLanded) crit dice."
                     : "The barque drifts on without you.")
                    .font(.fantasy(14, weight: .medium))
                    .foregroundStyle(Theme.parchmentDim)

                Button {
                    game.concludeBattle()
                } label: {
                    Text(won ? "Take the Spoils" : "See the Tale")
                        .font(.fantasy(16, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .paintedContentInsets()
                        .frame(width: 220, height: 48)
                        .background {
                            PharaohSWagerImage(name: PharaohSWagerArt.button(won ? .primary : .secondary, .normal),
                                      fit: .stretch)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.opacity(0.88).ignoresSafeArea())
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: engine.phase)
    }
}

/// The ground the dice deck rides on: a slab of dark papyrus with a carved
/// gold lip along its top edge, so the deck reads as a shelf being pushed up
/// over the boards rather than a card floating in the air.
private struct DeckShelfBackground: View {
    let armed: Bool

    var body: some View {
        ZStack(alignment: .top) {
            PapyrusSurface(ground: .panel, tint: Theme.bgElevated, strength: 0.5, shade: 0.5)
                .clipShape(.rect(topLeadingRadius: 26, topTrailingRadius: 26))

            LinearGradient(
                colors: [Theme.bg.opacity(0.0), Theme.bg.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(.rect(topLeadingRadius: 26, topTrailingRadius: 26))

            VStack(spacing: 0) {
                GoldRule(height: 7, opacity: armed ? 0.5 : 0.9)
                    .modifier(TintWash(tint: armed ? Theme.frost : nil))
                HieroglyphBand(tint: armed ? Theme.frost : Theme.gold, height: 9, opacity: 0.24)
                    .padding(.horizontal, 26)
            }
            .padding(.top, 2)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill((armed ? Theme.frost : Theme.gold).opacity(0.5))
                .frame(height: 1.2)
        }
        .shadow(color: .black.opacity(0.7), radius: 24, y: -8)
        .allowsHitTesting(false)
    }
}


