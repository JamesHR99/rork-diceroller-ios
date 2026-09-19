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
    @State private var arrivalShown = true
    /// Where the run's heading and the health rail actually end. The deck is
    /// hung off this rather than off the bottom of the screen, so it rises to
    /// meet the health bars instead of leaving a band of empty river between
    /// them and pushing its own last row off the bottom edge.
    @State private var headerHeight: CGFloat = 0

    private var gate: Gate { game.gate }

    /// The dice deck rides up over the arena while you are planning, and slides
    /// away the moment you commit — that is what hands the whole screen back to
    /// the fighters and the hull they are standing on. Aiming happens on the
    /// uncovered stage, so the deck is down for that too.
    private var deckUp: Bool {
        engine.phase == .player
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        topStrip

                        // While the deck is up, the fighters are read off the
                        // slim rail; once it drops, the stage below is
                        // uncovered and the full-size figures are what you
                        // watch.
                        if deckUp {
                            tickerRail(width: max(0, size.width - 24))
                                .padding(.horizontal, 12)
                                .padding(.top, 2)
                                .transition(.move(edge: .top).combined(with: .opacity))

                            enemyOrderStrip
                                .padding(.horizontal, 14)
                                .padding(.top, 3)
                        }

                        // Enemy actions have one shared strip above the reels;
                        // the health cards stay compact and the whole pack's
                        // order can be read from left to right.
                    }
                    // The deck is measured against what this strip leaves
                    // behind, so it can sit directly under the health bars.
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        headerHeight = height
                    }

                    battleStage(size: size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(deckUp ? 0.22 : 1)
                        .scaleEffect(deckUp ? 0.94 : 1, anchor: .top)
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
        .overlay {
            // A landing chain takes the whole deck: shockwave, embers, wash
            // and a banner naming what just happened.
            if let flash = engine.comboFlash {
                ComboFlashView(flash: flash)
                    .id(flash.id)
                    .zIndex(4)
                    .transition(.opacity)
            }
        }
        .overlay {
            // Before an action lands it is named and held still: who is
            // acting, what they are doing, what it is worth and every god
            // power riding it, all at the same time.
            if let card = engine.spotlight {
                ActionSpotlightView(card: card)
                    .id(card.id)
                    .zIndex(5)
                    .transition(.opacity)
            }
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

    private func diceDeck(size: CGSize) -> some View {
        let metrics = BattleDeckMetrics(screenHeight: size.height,
                                        headerHeight: headerHeight > 0 ? headerHeight : 120)
        return ScrollView(.vertical) {
            VStack(spacing: 6) {
                DiceTrayView(engine: engine, maxReelHeight: metrics.reelHeight,
                             maxRowWidth: max(0, size.width - 44), compact: metrics.isCompact)
                    .padding(.horizontal, 8)
                PlayBarView(engine: engine, bodyHeight: metrics.planHeight)
                    .padding(.horizontal, 10)
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .frame(height: metrics.height)
        .background {
            DeckShelfBackground(armed: engine.selectingReroll)
                .ignoresSafeArea(edges: .bottom)
        }
        .offset(y: deckUp ? 0 : size.height)
        .opacity(deckUp ? 1 : 0)
        .allowsHitTesting(deckUp)
        .accessibilityHidden(!deckUp)
    }

    /// The slim read carried while the deck is up: you on the left, everything
    /// that rose out of the river on the right, each with its health and the
    /// blow it is winding up.
    private func tickerRail(width: CGFloat) -> some View {
        let foes = engine.stagedFoes
        let compact = foes.count > 1
        let spacing: CGFloat = foes.count > 2 ? 4 : 6
        let natural: CGFloat = compact ? 212 : 268
        // You take a smaller share of a crowded rail so all health channels
        // and portraits remain visible at once.
        let playerShare: CGFloat = foes.count >= 3 ? 0.3 : (foes.count == 2 ? 0.34 : 0.42)
        let playerWidth = min(natural, max(120, width * playerShare))
        let foeRoom = width - playerWidth - spacing * CGFloat(foes.count + 1)
        let foeWidth = min(natural, max(96, foeRoom / CGFloat(max(foes.count, 1))))

        return HStack(alignment: .top, spacing: spacing) {
            FighterView(
                engine: engine,
                side: .player,
                heroSymbol: game.heroClass?.fighterSymbol ?? "figure.stand",
                heroName: game.heroClass?.name ?? "Hero",
                accent: game.heroClass?.accent ?? Theme.gold,
                heroClassID: game.classID,
                layout: .ticker,
                tickerCompact: compact,
                cardWidth: playerWidth
            )

            Spacer(minLength: 0)

            ForEach(foes) { foe in
                FighterView(
                    engine: engine,
                    side: .enemy,
                    heroSymbol: "",
                    heroName: "",
                    accent: Theme.blood,
                    foe: foe,
                    isTargeted: engine.isTargeted(foeID: foe.id),
                    layout: .ticker,
                    tickerCompact: compact,
                    cardWidth: foeWidth
                )
                .opacity(foe.isAlive ? 1 : 0.4)
            }
        }
        .frame(width: width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// One shared enemy queue above the reels. Health cards stay focused on
    /// health, while this strip shows exactly which creature acts next when a
    /// pack has several announced moves.
    private var enemyOrderStrip: some View {
        let actions = engine.timeline.filter { !$0.isPlayer }
        return HStack(spacing: 6) {
            Text("ENEMY ORDER")
                .font(.system(size: 8.5, weight: .black))
                .kerning(0.8)
                .foregroundStyle(Theme.blood)
                .fixedSize()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        HStack(spacing: 4) {
                            Text("\(index + 1)")
                                .font(.system(size: 8, weight: .black).monospacedDigit())
                                .foregroundStyle(Theme.bg)
                                .frame(width: 15, height: 15)
                                .background(Theme.blood, in: .circle)
                            Text(action.title)
                                .font(.fantasy(9.5, weight: .bold))
                                .foregroundStyle(Theme.parchment)
                            Text(action.detail.uppercased())
                                .font(.system(size: 7.5, weight: .black).monospacedDigit())
                                .foregroundStyle(Theme.parchmentDim)
                        }
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .frame(height: 24)
                        .background(Theme.bgCard.opacity(0.82), in: .capsule)
                        .overlay(Capsule().strokeBorder(Theme.blood.opacity(0.4), lineWidth: 1))

                        if index < actions.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(Theme.blood.opacity(0.75))
                        }
                    }
                }
            }
        }
        .frame(height: 28)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Enemy action order")
    }

    // MARK: - Stage

    /// How tall an ordinary fighter stands, measured off the room the arena
    /// has actually been given rather than the whole screen. The name, the
    /// bars and the status row all have to fit above the figure, and a
    /// serpent-lord is drawn taller again, so the tallest fighter on the deck
    /// sets the measure for everyone.
    private func fighterHeight(_ room: CGFloat) -> CGFloat {
        let chrome: CGFloat = 96
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
            let boatWidth = min(stage.size.width * 0.99, 920)
            // The usable fighting deck is inset from the prow and stern and
            // sits lower than the ornamental rail. The old lift put feet on
            // the rail itself; this value follows the broad central planks.
            let deckInset = min(56, max(18, boatWidth * 0.075))
            let combatWidth = max(280, stage.size.width - deckInset * 2)
            let deckLift = min(62, max(28, boatWidth / 11.2))
            let fighterRoom = max(150, room - deckLift)
            // A crowd takes more of the deck than a single guardian, but the
            // demigod always keeps a readable share of it.
            let playerWidth = max(112, combatWidth * (foeCount >= 3 ? 0.25 : 0.35))
            let foeWidth = max(92, combatWidth - 20 - playerWidth)

            ZStack(alignment: .bottom) {
                BattleBarqueView(gate: gate, width: boatWidth, discGlow: game.discGlow)
                    .opacity(deckUp ? 0.3 : 0.96)

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
                    stageHeight: fighterHeight(room),
                    cardWidth: foes.count > 1 ? cardWidth : nil
                )
                .overlay(alignment: .bottom) { allocationTotal(for: foe) }
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: foes.count)
    }

    /// The blow waiting to be sent, named on a slab at the foot of the stage.
    /// Aiming is its own moment now: the deck is down, the fighters are
    /// full-size, and each attack asks which creature it should strike.
    private func aimPrompt(_ aim: AimRequest) -> some View {
        VStack(spacing: 8) {
            Text("AIM THIS BLOW")
                .font(.system(size: 9, weight: .black))
                .kerning(2.6)
                .foregroundStyle(Theme.gold)

            HStack(spacing: 8) {
                ForEach(Array(aim.faces.prefix(5).enumerated()), id: \.offset) { _, face in
                    PharaohSWagerSymbol(art: face.artName, fallback: face.symbol,
                               size: 22, tint: face.tint)
                        .frame(width: 27, height: 25)
                        .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 7))
                }

                Text(aim.title.uppercased())
                    .font(.fantasy(19, weight: .black))
                    .kerning(1)
                    .foregroundStyle(aim.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Text(aim.detail)
                    .font(.system(size: 12.5, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.ember)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Theme.bg.opacity(0.6), in: .capsule)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            HStack(spacing: 10) {
                Text("TAP THE CREATURE IT SHOULD STRIKE")
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
                    Text("BACK TO PLAN")
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
                .strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1.4)
        )
        .shadow(color: .black.opacity(0.7), radius: 16, y: 6)
        .padding(.bottom, 18)
        .padding(.horizontal, 14)
    }

    /// The running damage total pointed at a foe while attacks are being
    /// allocated — it builds up beside each fighter as blows are assigned.
    @ViewBuilder
    private func allocationTotal(for foe: EnemyState) -> some View {
        if engine.isAiming {
            let total = engine.allocatedDamage(for: foe.id)
            if total > 0 {
                HStack(spacing: 4) {
                    PharaohSWagerSymbol(art: PharaohSWagerArt.Status.piercing, fallback: "bolt.fill",
                               size: 13, tint: Theme.bg)
                    Text("\(total)")
                        .font(.system(size: 13, weight: .black).monospacedDigit())
                }
                .foregroundStyle(Theme.bg)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.ember, in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                .offset(y: 48)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
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
                Text(won ? "THE WAY IS CLEAR" : "THE DISC GOES OUT")
                    .font(.fantasy(28, weight: .black))
                    .foregroundStyle(Theme.parchment)
                    .kerning(3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background {
                        TurnOrderPlaque(accent: won ? Theme.gold : Theme.blood)
                    }

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

