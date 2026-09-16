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
    @State private var showInfo = false
    @State private var arrivalShown = true
    /// How tall the deck actually draws once its dice and plan are laid out.
    /// Measured rather than guessed, so a screen it still cannot fit on takes
    /// the whole shelf down to size instead of letting FIGHT hang off the edge.
    @State private var deckNaturalHeight: CGFloat = 0
    /// Where the run's heading and the health rail actually end. The deck is
    /// hung off this rather than off the bottom of the screen, so it rises to
    /// meet the health bars instead of leaving a band of empty river between
    /// them and pushing its own last row off the bottom edge.
    @State private var headerHeight: CGFloat = 0

    private var gate: Gate { game.gate }

    /// The dice deck rides up over the arena while you are planning, and slides
    /// away the moment you commit — that is what hands the whole screen back to
    /// the fighters and the hull they are standing on.
    private var deckUp: Bool {
        engine.phase == .player && !engine.isAllocating
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
                            tickerRail
                                .padding(.horizontal, 12)
                                .padding(.top, 2)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // The hour strip sits between the health bars and the
                        // dice: your plan and every foe's blow on one line, in
                        // the order they resolve. This is where intent is read
                        // now — a blow you cannot place in time is not
                        // information you can use. It stays up through
                        // resolution so the round plays out along the same
                        // line you planned it on.
                        if engine.isFightLive {
                            TimelineStripView(engine: engine, height: 58)
                                .padding(.horizontal, 12)
                                .padding(.top, 3)
                                .transition(.opacity)
                        }
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
                        .blur(radius: deckUp ? 3 : 0)
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
                ProjectileLayerView(shots: engine.shots, anchors: anchors)
                    .zIndex(3)
            }
            .animation(.spring(response: 0.52, dampingFraction: 0.86), value: deckUp)
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
            // The targeting step: with several foes standing, committing lists
            // every attack so each can be sent at a chosen foe.
            if engine.isAllocating {
                AllocationOverlayView(engine: engine)
                    .zIndex(6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: engine.isAllocating)
        .animation(.easeInOut(duration: 0.3), value: engine.trialPromptVisible)
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus,
                              maxStamina: game.effectiveMaxStamina,
                              drawnDieIDs: game.battle?.drawnDieIDs ?? [],
                              hasMetTrial: game.trialUsed,
                              boons: game.equippedBoons)
            }
        }
    }

    // MARK: - Dice deck

    /// The roll tray and the turn plan, welded into one sheet that slides up
    /// from the bottom of the screen. Tapping FIGHT drops it out of frame and
    /// the fight plays out on the stage behind it.
    /// The deck is cut to the screen it has to fit on. `reel` is the tallest a
    /// die may run and `body` the height of the plan cards; both shrink
    /// together on a short landscape iPhone so the turn plan and the FIGHT slab
    /// The room the deck actually has: everything under the run's heading and
    /// the health rail, less a margin so the FIGHT slab never rides the bottom
    /// edge. Measured off the heading itself, so the deck rises to meet the
    /// health bars instead of leaving a band of open river between them.
    private func deckBox(_ size: CGSize) -> CGFloat {
        let header = headerHeight > 0 ? headerHeight : 108
        return max(size.height - header - 8, 170)
    }

    /// How tall a die and a plan card may run on this screen. Both are cut
    /// from the room left after the deck's own chrome — the tray heading, the
    /// channel lips, the plan header and every padding in between — so the
    /// dice and the turn plan give up height together and the stamina rail and
    /// the FIGHT slab are never the parts that fall off the bottom.
    private func deckSizing(_ box: CGFloat) -> (reel: CGFloat, body: CGFloat) {
        let chrome: CGFloat = 100
        let free = max(box - chrome, 130)
        // The dice and the plan are grown until they very nearly fill the room
        // under the health rail. Leaving them short is what opened the band of
        // empty river between the rail and the deck — that space belongs to the
        // dice, so it is spent on them instead of left blank.
        return (
            reel: min(132, max(70, free * 0.54)),
            body: min(110, max(60, free * 0.44))
        )
    }

    private func diceDeck(size: CGSize) -> some View {
        let box = deckBox(size)
        let sizing = deckSizing(box)
        // The deck is drawn at full size, measured, and then taken down as one
        // piece if it does not fit the screen it landed on. Nothing is guessed:
        // whatever the dice, the turn plan, the stamina rail and the FIGHT slab
        // actually need is what gets scaled, so they are always whole and
        // always inside the screen.
        let fit: CGFloat = deckNaturalHeight > box ? box / deckNaturalHeight : 1
        return VStack(spacing: 6) {
            DiceTrayView(
                engine: engine,
                maxReelHeight: sizing.reel,
                maxRowWidth: size.width - 44
            )
            .padding(.horizontal, 8)

            PlayBarView(engine: engine, bodyHeight: sizing.body)
                .padding(.horizontal, 10)
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        // Held at its ideal height while it is measured, so the reading cannot
        // chase the constraint it is used to set.
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            deckNaturalHeight = height
        }
        .scaleEffect(fit, anchor: .bottom)
        .frame(height: deckNaturalHeight > 0 ? min(deckNaturalHeight, box) : nil, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .background {
            // The deck's own ground: a lip of carved stone that reads as a
            // shelf sliding over the deck boards rather than a floating card.
            DeckShelfBackground(armed: engine.freezeArmed)
                .ignoresSafeArea(edges: .bottom)
        }
        .offset(y: deckUp ? 0 : size.height)
        .allowsHitTesting(deckUp)
    }

    // MARK: - Ticker rail

    /// The slim read carried while the deck is up: you on the left, everything
    /// that rose out of the river on the right, each with its health and the
    /// blow it is winding up.
    private var tickerRail: some View {
        let foes = engine.enemies
        let compact = foes.count > 1
        return HStack(alignment: .top, spacing: 8) {
            FighterView(
                engine: engine,
                side: .player,
                heroSymbol: game.heroClass?.fighterSymbol ?? "figure.stand",
                heroName: game.heroClass?.name ?? "Hero",
                accent: game.heroClass?.accent ?? Theme.gold,
                heroClassID: game.classID,
                layout: .ticker,
                tickerCompact: compact
            )

            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: 6) {
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
                        tickerCompact: compact
                    )
                    .opacity(foe.isAlive ? 1 : 0.4)
                }
            }
        }
    }

    // MARK: - Stage

    /// How tall an ordinary fighter stands, measured off the room the arena
    /// has actually been given rather than the whole screen. The name, the
    /// bars and the status row all have to fit above the figure, and a
    /// serpent-lord is drawn taller again, so the tallest fighter on the deck
    /// sets the measure for everyone.
    private func fighterHeight(_ room: CGFloat) -> CGFloat {
        let chrome: CGFloat = 96
        let tallest: CGFloat = engine.enemies.contains { $0.def.isBoss } ? 1.16 : 1
        let free = room - chrome
        return min(232, max(112, free / (1.06 * tallest)))
    }

    /// The fight itself, uncovered once the deck goes down: full-size figures
    /// standing on the hull with the water behind them.
    private func battleStage(size: CGSize) -> some View {
        VStack(spacing: 0) {

            // The figures are cut to the room actually left under the heading
            // and stood in the middle of it, so they hold the centre of the
            // screen instead of sinking through the bottom edge.
            GeometryReader { stage in
                let room = stage.size.height
                HStack(alignment: .bottom, spacing: 8) {
                    FighterView(
                        engine: engine,
                        side: .player,
                        heroSymbol: game.heroClass?.fighterSymbol ?? "figure.stand",
                        heroName: game.heroClass?.name ?? "Hero",
                        accent: game.heroClass?.accent ?? Theme.gold,
                        heroClassID: game.classID,
                        stageHeight: fighterHeight(room)
                    )

                    Spacer(minLength: 0)

                    enemyGroup(room: room)
                }
                .padding(.horizontal, 10)
                .frame(width: stage.size.width, height: room, alignment: .center)
            }
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

            VStack {
                Spacer()
                BarqueView(gate: gate, width: size.width * 0.92, discGlow: game.discGlow)
                    .opacity(deckUp ? 0.3 : 0.72)
                    .offset(y: deckUp ? 130 : 116)
            }

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
    private func enemyGroup(room: CGFloat) -> some View {
        let foes = engine.enemies
        let scale: CGFloat = foes.count >= 3 ? 0.66 : (foes.count == 2 ? 0.8 : 1)
        return HStack(alignment: .bottom, spacing: foes.count > 1 ? 0 : 0) {
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
                    onTap: engine.isAllocating ? { engine.assignSelected(to: foe.id) } : nil,
                    stageHeight: fighterHeight(room)
                )
                .overlay(alignment: .bottom) { allocationTotal(for: foe) }
            }
        }
    }

    /// The running damage total pointed at a foe while attacks are being
    /// allocated — it builds up beside each fighter as blows are assigned.
    @ViewBuilder
    private func allocationTotal(for foe: EnemyState) -> some View {
        if engine.isAllocating {
            let total = engine.allocatedDamage(for: foe.id)
            if total > 0 {
                HStack(spacing: 4) {
                    DuatSymbol(art: DuatArt.Status.piercing, fallback: "bolt.fill",
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
                    .font(.system(size: 15, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Theme.bgElevated, in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1))

            // Chisels of Ptah: small copper marks beside the turn.
            if !engine.chisels.isEmpty {
                HStack(spacing: 3) {
                    ForEach(engine.chisels.sorted(), id: \.self) { id in
                        DuatSymbol(art: DuatArt.chisel(id),
                                   fallback: ChiselCatalog.def(id)?.symbol ?? "hammer.fill",
                                   size: 18,
                                   tint: Theme.ptahCopper)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.bgElevated, in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.ptahCopper.opacity(0.4), lineWidth: 1))
            }

            Text(engine.lastAction)
                .font(.paper(14))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .animation(.easeInOut(duration: 0.2), value: engine.lastAction)

            Spacer(minLength: 4)

            NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared)

            Button {
                showInfo = true
                Haptics.light()
            } label: {
                HStack(spacing: 5) {
                    DuatIcon(name: DuatArt.utilityCodex, size: 19)
                    Text("CODEX")
                        .font(.fantasy(13, weight: .black))
                        .kerning(1)
                        .foregroundStyle(Theme.parchment)
                }
                .frame(width: 106, height: 38)
                .background {
                    DuatImage(name: DuatArt.button(.secondary, .normal), fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(.rect(cornerRadius: 11))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.top, 3)
    }

    /// One intent capsule per living foe — in packs you read the whole ambush
    /// at once; solo it is the same single capsule as always.
    private var intentRow: some View {
        HStack(spacing: 6) {
            ForEach(engine.livingFoes) { foe in
                intentChip(foe: foe, compact: engine.isPack)
            }
        }
    }

    private func intentChip(foe: EnemyState, compact: Bool) -> some View {
        let heat = engine.heatDamage(for: foe)
        // The real numbers, hour depth and heat included — what you read here
        // is exactly what the blow will do.
        let strike = engine.projectedStrike(for: foe)
        let move = foe.intent
        return HStack(spacing: 6) {
            DuatIcon(name: DuatArt.Status.marked, size: 15)
                .opacity(0.8)

            if !compact {
                Text("Intent:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim)
            } else {
                Text(foe.displayName.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
            }

            ForEach(Array(move.faces.enumerated()), id: \.offset) { _, face in
                DuatSymbol(art: face.artName, fallback: face.symbol, size: 19, tint: face.tint)
                    .frame(width: 23, height: 23)
                    .background(Theme.bg.opacity(0.7), in: .rect(cornerRadius: 5))
            }

            Text(move.comboName ?? move.name)
                .font(.fantasy(12.5, weight: .bold))
                .foregroundStyle(move.comboName != nil ? Theme.ember : Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if strike.damage > 0 {
                outcomeBadge(DuatArt.Status.piercing, "burst.fill", "\(strike.damage)", Theme.blood)
            }
            if strike.heal > 0 {
                outcomeBadge(DuatArt.Status.health, "heart.fill", "+\(strike.heal)", Theme.forest)
            }
            if strike.block > 0 {
                outcomeBadge(DuatArt.Status.shield, "shield.fill", "+\(strike.block)", Theme.steel)
            }
            if move.bleedAmount > 0, move.bleedTurns > 0 {
                outcomeBadge(DuatArt.Status.bleed, "drop.fill",
                             "\(move.bleedAmount)×\(move.bleedTurns)", Theme.blood.opacity(0.85))
            }
            if foe.stagger > 0 {
                outcomeBadge(DuatArt.Status.frost, "snowflake", "weakened", Theme.frost)
            }
            if heat > 0 {
                outcomeBadge(DuatArt.Status.burn, "thermometer.high", "+\(heat)", Theme.ember)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 6)
        .background {
            // The painted intent plate: what is about to hit you, on a slab.
            DuatImage(name: DuatArt.enemyIntent, fit: .stretch)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }

    /// One icon-and-number pair reading what the telegraphed move will do.
    private func outcomeBadge(_ art: String, _ fallback: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 2) {
            DuatSymbol(art: art, fallback: fallback, size: 14, tint: tint)
            Text(value)
                .font(.system(size: 11.5, weight: .black).monospacedDigit())
                .foregroundStyle(tint)
        }
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
                    DuatImage(name: DuatArt.banner, fit: .stretch)
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
                            DuatIcon(name: DuatArt.Status.armour, size: 13)
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
                                DuatImage(name: DuatArt.button(.primary, .normal), fit: .stretch)
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
            DuatImage(name: won ? "duat_environment_sun_bright" : "duat_environment_sun_extinguished",
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
                        DuatImage(name: won ? DuatArt.bannerVictory : DuatArt.bannerDefeat, fit: .stretch)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            DuatImage(name: DuatArt.button(won ? .primary : .secondary, .normal),
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
