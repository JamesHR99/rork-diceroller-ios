import SwiftUI

/// An animated fighter, in one of two layouts.
///
/// `.stage` is the full figure standing on the deck of the barque: sprite,
/// name, health, statuses and pose-driven motion. It is what you watch once
/// the dice deck has slid away and the fight has the whole screen.
///
/// `.ticker` is the slim read used while you are still planning the turn and
/// the deck is up: a portrait, a name, the health channel, and — for a foe —
/// the blow it is winding up. No animation, no floaters: the fight is paused
/// on the other side of the deck, so it only has to be legible.
struct FighterView: View {
    enum Side {
        case player
        case enemy
    }

    enum Layout {
        /// The fighter standing on the deck, full height.
        case stage
        /// The slim HUD read carried over the dice deck.
        case ticker
    }

    let engine: BattleEngine
    let side: Side
    let heroSymbol: String
    let heroName: String
    let accent: Color
    /// Which demigod is standing here — picks the hero's drawn frame set and
    /// the weapon signature its strikes are timed to.
    var heroClassID: String = ""
    /// The foe this panel shows — always set on the enemy side.
    var foe: EnemyState? = nil
    /// Packs squeeze down so two or three foes fit on the deck.
    var packScale: CGFloat = 1
    /// True while this foe wears the gold ring — the blow in flight was sent
    /// here.
    var isTargeted: Bool = false
    /// True while the stage is waiting for you to send a blow, and this
    /// creature is a legal place to send it.
    var isAimable: Bool = false
    var onTap: (() -> Void)? = nil
    var layout: Layout = .stage
    /// Tickers squeeze further still when a whole pack has to fit the rail.
    var tickerCompact: Bool = false
    /// How tall an ordinary fighter stands on the stage, measured by the arena
    /// from the room it actually has.
    var stageHeight: CGFloat = 164
    /// The width this card has been given. The arena and the rail measure the
    /// screen and hand a share down, so three foes fit an iPhone instead of
    /// the third one walking off the right-hand edge.
    var cardWidth: CGFloat? = nil

    @State private var aimPulse = false

    var body: some View {
        Group {
            switch layout {
            case .stage: stageBody
            case .ticker: tickerBody
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                aimPulse = true
            }
        }
    }

    // MARK: - Stage

    private var stageBody: some View {
        VStack(spacing: 4) {
            nameRow
            if side == .enemy, let foe, foe.armour + foe.shield > 0 {
                armourBar(foe, width: barWidth)
            }
            // The guard sits directly over health, the way armour does on a
            // foe: a steel channel you can read the depth of at a glance,
            // rather than a small number lost in the status row.
            if shieldValue > 0 {
                shieldBar(width: barWidth, height: 13)
            }
            healthBar
            sprite
                .overlay(alignment: .bottom) {
                    badgeRow
                        .offset(y: 7)
                }
                .padding(.bottom, 7)
        }
        .frame(width: stageWidth)
        .overlay(alignment: .top) { floaters }
        .overlay { aimRing }
        .overlay { aimInvite }
        .overlay { championRing }
        .overlay { verdictRing }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    /// While a blow is waiting to be aimed, every creature it could be sent at
    /// breathes under a copper ring — so where you may tap is never a guess.
    @ViewBuilder
    private var aimInvite: some View {
        if side == .enemy, isAimable, let foe, foe.isAlive {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.gold.opacity(aimPulse ? 0.95 : 0.4),
                              lineWidth: aimPulse ? 2.4 : 1.4)
                .shadow(color: Theme.gold.opacity(aimPulse ? 0.6 : 0.2), radius: 12)
                .overlay(alignment: .top) {
                    Text("TAP TO STRIKE")
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(1.6)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(Theme.gold, in: .capsule)
                        .offset(y: -8)
                }
                .allowsHitTesting(false)
        }
    }

    /// Stage cards keep their width in step with the pack, so three foes still
    /// fit the deck without overlapping the demigod. The arena measures the
    /// screen and hands the share down; the figure itself is free to draw
    /// wider than its card, which is what makes a pack read as a crowd.
    private var stageWidth: CGFloat {
        cardWidth ?? (side == .enemy ? 248 * max(packScale, 0.7) : 248)
    }

    /// The bars are cut to the card rather than drawn at a fixed 210, so a
    /// packed deck keeps every health channel on screen.
    private var barWidth: CGFloat {
        max(74, stageWidth - 38)
    }

    // MARK: - Ticker

    /// The compact read: the fighter's face, name, health, and — for a foe —
    /// the blow they are winding up, all on one painted slab.
    private var tickerBody: some View {
        HStack(spacing: 9) {
            if side == .player && showsTickerPortrait { tickerPortrait }

            VStack(alignment: side == .player ? .leading : .trailing, spacing: 3) {
                HStack(spacing: 5) {
                    Text(side == .player ? heroName : (foe?.displayName ?? ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    badgeRow
                }

                if side == .enemy, let foe, foe.armour + foe.shield > 0 {
                    armourBar(foe, width: tickerBarWidth)
                }

                if shieldValue > 0 {
                    shieldBar(width: tickerBarWidth, height: 11)
                }

                healthBar(width: tickerBarWidth, height: 23)
            }
            .frame(maxWidth: .infinity, alignment: side == .player ? .leading : .trailing)

            if side == .enemy && showsTickerPortrait { tickerPortrait }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .frame(width: tickerWidth)
        .papyrusPanel(tint: Theme.bgElevated, cornerRadius: 13, strength: 0.5, shade: 0.46)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder((side == .player ? accent : Theme.blood).opacity(0.35), lineWidth: 1)
        )
    }

    private var tickerWidth: CGFloat { cardWidth ?? (tickerCompact ? 212 : 268) }

    private var tickerPortrait: some View {
        PortraitMedallionView(
            art: frames.art(.idle),
            fallbackSymbol: side == .player ? heroSymbol : (foe?.def.symbol ?? "questionmark"),
            tint: side == .player ? accent : Theme.blood,
            diameter: tickerCompact ? 44 : 52,
            glow: false
        )
    }

    private var showsTickerPortrait: Bool { tickerWidth >= 190 }
    private var tickerBarWidth: CGFloat {
        max(0, tickerWidth - 18 - (showsTickerPortrait ? (tickerCompact ? 53 : 61) : 0))
    }

    // MARK: - Overlays

    private var floaters: some View {
        Group {
            if side == .player {
                FloaterStackView(floaters: engine.floaters.filter { !$0.onEnemy })
            } else if let foe {
                FloaterStackView(floaters: engine.floaters.filter { $0.foeID == foe.id })
            }
        }
        .offset(y: 6)
        .allowsHitTesting(false)
    }

    /// The painted target ring worn by the foe an attack is being sent at —
    /// during allocation, and again as each blow lands. It sits under the
    /// fighter's feet like a mark drawn on the deck.
    @ViewBuilder
    private var aimRing: some View {
        if side == .enemy, isTargeted, let foe, foe.isAlive {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                PharaohSWagerImage(name: PharaohSWagerArt.targetRing, width: 186, fit: .fit)
                    .colorMultiply(Theme.gold)
                    .opacity(aimPulse ? 0.65 : 1)
                    .shadow(color: Theme.gold.opacity(0.8), radius: 12)
                    .offset(y: 20)
            }
            .overlay(alignment: .top) {
                Text("TARGET")
                    .font(.system(size: 9, weight: .black))
                    .kerning(2)
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Theme.gold, in: .capsule)
                    .offset(y: 2)
            }
            .allowsHitTesting(false)
        }
    }

    /// The scales tipping on this creature. A verdict ignores guard and armour
    /// entirely, so it gets its own unmistakable spectacle rather than an
    /// ordinary damage number: jackal-dark rings thrown off the figure, a pair
    /// of scales rising through them, and the amount struck across the middle.
    @ViewBuilder
    private var verdictRing: some View {
        if side == .enemy, let foe, let burst = engine.verdictBurst, burst.foeID == foe.id {
            VerdictBurstView(burst: burst)
                .id(burst.id)
                .allowsHitTesting(false)
        }
    }

    /// A trial champion wears the attending god's halo for the whole fight —
    /// their sigil burning quietly behind the figure.
    @ViewBuilder
    private var championRing: some View {
        if side == .enemy, let foe, foe.isTrialChampion, engine.trialAccepted,
           let trial = engine.trial, foe.isAlive {
            HaloedSigilView(deity: trial.deity, diameter: 110, breathes: true)
                .opacity(0.5)
                .offset(y: -18)
                .allowsHitTesting(false)
        }
    }

    /// Serpent-lords loom over the deck; ordinary guardians stand your height,
    /// and pack members squeeze down a touch further so everyone fits.
    private var sizeScale: CGFloat {
        guard side == .enemy else { return 1 }
        let bossScale = foe?.def.isBoss == true ? 1.16 : 1
        return bossScale * packScale
    }

    /// The fight owns the whole screen now that the dice have their own deck,
    /// so the figures are drawn much larger than they were when the tray sat
    /// on top of them. The arena measures the room it actually has and hands
    /// down `stageHeight`, so the fighters fill a tall screen without their
    /// feet running off a short one. A serpent-lord's extra height rides on
    /// `sizeScale`, so it is only ever counted once.
    private var portraitHeight: CGFloat {
        stageHeight * sizeScale
    }

    /// Every drawing this fighter owns, resolved once from the catalogue.
    private var frames: FrameSet {
        side == .player
            ? CharacterArt.heroFrames(heroClassID)
            : CharacterArt.foeFrames(foe?.def.id ?? engine.enemy.id, stageID: foe?.stageID)
    }

    /// The painted sheet a creature animates from, when it owns one.
    private var foeSheetID: String? {
        side == .enemy ? foe?.sheetID : nil
    }

    /// Heroes swing their own weapon; everything out of the river fights with
    /// teeth, claws and coils.
    private var weapon: WeaponSignature {
        side == .player ? .forHero(heroClassID) : .natural
    }

    /// The gods riding the blow being thrown right now, if any.
    private var strikeGods: [Deity] {
        side == .player ? engine.strikeGods : []
    }

    // MARK: - Pose

    private var pose: FighterPose {
        side == .player ? engine.playerPose : (foe?.pose ?? .idle)
    }

    private var actionID: Int {
        side == .player ? engine.playerAnimationID : (foe?.animationID ?? 0)
    }

    private var actionPower: Int {
        side == .player ? engine.playerActionPower : (foe?.actionPower ?? 1)
    }

    private var facing: CGFloat { side == .player ? 1 : -1 }

    /// A blessed strike burns in its god's colour instead of plain ember.
    private var auraColor: Color {
        switch pose {
        case .attack: strikeGods.first?.tint ?? Theme.ember
        case .hurt: Theme.blood
        case .block: Theme.steel
        case .heal: Theme.forest
        case .dodge: Theme.steel
        case .victory: Theme.gold
        default: accent.opacity(0.5)
        }
    }

    // MARK: - Pieces

    /// Which fighter this panel is, for the projectile layer to aim at.
    private var anchorID: FighterAnchorID {
        side == .player ? .player : .foe(foe?.id ?? UUID())
    }

    private var sprite: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.55))
                .frame(width: portraitHeight * 0.82, height: 24)
                .offset(y: portraitHeight * 0.47)
                .scaleEffect(x: pose == .dodge ? 0.7 : 1)
                .blur(radius: 3)

            AnimatedFighterSprite(
                frames: frames,
                pose: pose,
                weapon: weapon,
                facing: facing,
                height: portraitHeight,
                accent: accent,
                fallbackSymbol: side == .player ? heroSymbol : (foe?.def.symbol ?? "questionmark"),
                mirrorFallback: side == .enemy,
                characterID: side == .player ? heroClassID : nil,
                foeSheetID: foeSheetID,
                actionID: actionID,
                actionPower: actionPower,
                choreography: side == .player ? engine.playerChoreography : (foe?.choreography ?? CombatChoreography()),
                enemyID: side == .enemy ? (foe?.def.id ?? engine.enemy.id) : nil,
                allowsPersonality: engine.phase == .player
            )
            .shadow(color: auraColor.opacity(pose == .idle ? 0.2 : 0.65), radius: pose == .idle ? 3 : 7)
            .opacity(pose == .defeat ? 0.42 : 1)
            .grayscale(pose == .defeat ? 0.85 : 0)
            .overlay { godSigil }
            // The figure reports the frame it actually occupies so shots leave
            // the thrower's hands and land on the body they were aimed at.
            .anchorPreference(key: FighterAnchorKey.self, value: .bounds) { [anchorID: $0] }
        }
        .frame(height: portraitHeight * 1.06)
    }

    /// The sigil of whichever god blessed the blow, stamping over the strike
    /// and burning away.
    @ViewBuilder
    private var godSigil: some View {
        if pose == .attack, !strikeGods.isEmpty {
            HStack(spacing: 6) {
                ForEach(strikeGods.prefix(2), id: \.self) { god in
                    PharaohSWagerSymbol(art: god.artName, fallback: god.symbol, size: 42, tint: god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: 16)
                }
            }
            .offset(x: 48 * facing, y: -18)
            .transition(.scale(scale: 2.3).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(side == .player ? heroName : (foe?.displayName ?? ""))
                .font(.fantasy(17, weight: .bold))
                .kerning(0.6)
                .foregroundStyle(Theme.parchment)
                .shadow(color: .black.opacity(0.8), radius: 3, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            actionChip()
        }
    }

    /// This fighter's base agility, beside the name and over the health bar.
    /// Every action adds its size in dice to this number, and the lower total
    /// acts first — so with both sides printed, the order of the round can be
    /// worked out by hand before you commit to anything.
    private func actionChip(scale: CGFloat = 1) -> some View {
        Text(side == .player ? "ROUND \(engine.turnNumber)" : "\(foe?.intents.count ?? 0) ACTIONS")
            .font(.system(size: 8 * scale, weight: .black))
            .foregroundStyle(Theme.frost)
            .padding(.horizontal, 5).padding(.vertical, 3)
            .background(Theme.bg.opacity(0.7), in: .capsule)
    }

    private var currentHP: Int { side == .player ? engine.playerHP : (foe?.hp ?? 0) }
    private var maxHP: Int {
        side == .player ? engine.playerMaxHP : max(foe?.def.maxHP ?? 1, 1)
    }

    /// The painted health channel, its fill revealed from the leading edge.
    /// A hero's runs in their own accent; everything out of the river bleeds.
    /// The numbers ride the bar itself so a foe's remaining health is legible
    /// at a glance even when the fill is nearly gone.
    private var healthBar: some View {
        healthBar(width: barWidth, height: 19)
    }

    private func healthBar(width: CGFloat, height: CGFloat) -> some View {
        PharaohSWagerBar(
            kind: .health,
            fraction: Double(currentHP) / Double(max(maxHP, 1)),
            width: width,
            height: height,
            tint: side == .player ? accent : nil
        )
        .overlay {
            Text("\(currentHP)/\(maxHP)")
                .font(.system(size: height * 0.62, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.parchment)
                .shadow(color: .black, radius: 2.5)
                .shadow(color: .black.opacity(0.9), radius: 1)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 2)
                .allowsHitTesting(false)
        }
    }

    /// The guard standing on this fighter right now. A foe keeps its whole
    /// guard in one pool, drawn on its own bronze channel, so only your own
    /// shield uses the steel one.
    private var shieldValue: Int {
        side == .player ? engine.playerShield : 0
    }

    /// The steel channel worn over health. Shield has no fixed maximum, so the
    /// channel is drawn against a quarter of the fighter's health: a guard that
    /// would eat a serious blow reads as a full bar, and the number is always
    /// printed on it so the exact value is never inferred from the fill.
    private func shieldBar(width: CGFloat, height: CGFloat) -> some View {
        let reference = max(Double(maxHP) * 0.25, 20)
        return PharaohSWagerBar(
            kind: .shield,
            fraction: min(1, Double(shieldValue) / reference),
            width: width,
            height: height
        )
        .overlay {
            HStack(spacing: 2.5) {
                PharaohSWagerSymbol(art: PharaohSWagerArt.Status.shield, fallback: "shield.fill",
                           size: height * 0.85, tint: Theme.parchment)
                Text("\(shieldValue)")
                    .font(.system(size: height * 0.78, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchment)
                    .contentTransition(.numericText())
            }
            .shadow(color: .black, radius: 2)
            .allowsHitTesting(false)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: shieldValue)
    }

    /// The guard worn over health — plate it was born in and block it raised,
    /// one pool on one bronze channel. Direct hits chip it away first; once it
    /// is gone the health is bare. The number rides on the bar the way your
    /// own shield's does, so both sides of the deck read the same way.
    private func armourBar(_ foe: EnemyState, width: CGFloat = 176) -> some View {
        let height: CGFloat = 13
        let guardValue = foe.armour + foe.shield
        let reference = max(foe.armourMax, max(20, foe.def.maxHP / 4))
        let fraction = min(1, CGFloat(guardValue) / CGFloat(reference))
        return PharaohSWagerBar(
            kind: .armour,
            fraction: Double(fraction),
            width: width,
            height: height
        )
        .overlay {
            HStack(spacing: 2.5) {
                PharaohSWagerSymbol(art: PharaohSWagerArt.Status.armour, fallback: "shield.fill",
                           size: height * 0.85, tint: Theme.parchment)
                Text("\(guardValue)")
                    .font(.system(size: height * 0.78, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchment)
                    .contentTransition(.numericText())
            }
            .shadow(color: .black, radius: 2)
            .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: guardValue)
        .accessibilityLabel("Armour and block: \(guardValue). Persists until consumed.")
    }

    /// Everything riding this fighter right now, each on its painted mark, and
    /// each one tappable for a plain explanation of what it is doing.
    /// The guard is no longer among them — it has its own channel over health.
    private var badgeRow: some View {
        HStack(spacing: 4) {
            ForEach(liveStatuses) { status in
                badge(status)
            }
        }
        .frame(height: layout == .ticker ? 16 : 21)
        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                   value: engine.playerShield + engine.dodgeCharges + (foe?.armour ?? 0))
    }

    /// Every status on this fighter right now, with its live numbers. Reading
    /// them into one list means the badges and their bubbles can never drift
    /// apart, and the fight and the codex describe a status the same way.
    private var liveStatuses: [LiveStatus] {
        var list: [LiveStatus] = []
        if side == .player {
            if engine.dodgeCharges > 0 {
                list.append(LiveStatus(kind: .evade, onSelf: true,
                                       total: engine.dodgeCharges, evadeReductions: engine.evadeChargeReductions))
            }
            if engine.regenTurns > 0 {
                list.append(LiveStatus(kind: .regeneration, onSelf: true,
                                       perTick: engine.regenAmount, ticksLeft: engine.regenTurns))
            }
            if engine.playerBleedTurns > 0 {
                list.append(LiveStatus(kind: .bleed, onSelf: true,
                                       perTick: engine.playerBleedAmount,
                                       ticksLeft: engine.playerBleedTurns))
            }
            if engine.playerBurnTurns > 0 {
                list.append(LiveStatus(kind: .burn, onSelf: true,
                                       perTick: engine.playerBurnAmount,
                                       ticksLeft: engine.playerBurnTurns))
            }
            if engine.playerJudgementPending {
                list.append(LiveStatus(kind: .judgement, onSelf: true,
                                       total: engine.playerJudgementAmount))
            }
        } else if let foe {
            if foe.isTrialChampion, engine.trialAccepted {
                list.append(LiveStatus(kind: .champion, onSelf: false))
            }
            if foe.evadeCharges > 0 {
                list.append(LiveStatus(kind: .evade, onSelf: false, total: foe.evadeCharges,
                    evadeReductions: Array(repeating: BattleRules.baseEvadePercent, count: foe.evadeCharges)))
            }
            if foe.judgementPending {
                // The pile shows its weight; nothing counts down any more,
                // because only your own big combo releases it.
                list.append(LiveStatus(kind: .judgement, onSelf: false,
                                       total: foe.judgementAmount))
            }
            // Bleed and poison no longer count rounds: the stack itself is the
            // whole story, so the badge shows one number.
            if foe.bleedAmount > 0 {
                list.append(LiveStatus(kind: .bleed, onSelf: false, perTick: foe.bleedAmount))
            }
            if foe.poisonAmount > 0 {
                list.append(LiveStatus(kind: .poison, onSelf: false, perTick: foe.poisonAmount))
            }
            if foe.burnAmount > 0 {
                list.append(LiveStatus(kind: .burn, onSelf: false, perTick: foe.burnAmount))
            }
            if foe.weaken > 0 {
                list.append(LiveStatus(kind: .weaken, onSelf: false,
                                       percent: Int(foe.weaken * 100)))
            }
            if foe.markBonus > 0 {
                list.append(LiveStatus(kind: .mark, onSelf: false,
                                       percent: Int(foe.markBonus * 100)))
            }
        }
        return list
    }

    /// One status badge. Tapping it opens the bubble pinned beside it; the
    /// champion's crown keeps its word rather than a number.
    private func badge(_ status: LiveStatus) -> some View {
        let scale: CGFloat = layout == .ticker ? 0.85 : 1
        let tint = status.kind == .champion
            ? (engine.trial?.deity.tint ?? Theme.gold)
            : status.kind.tint
        let tooltipID = "fighter.\(side == .player ? "player" : "foe").\(status.id)"
        let isOpen = TooltipCenter.shared.isOpen(tooltipID)
        return Button {
            Haptics.light()
            Audio.shared.play(.uiTap)
            TooltipCenter.shared.toggle(tooltipID)
        } label: {
            HStack(spacing: 2.5) {
                PharaohSWagerSymbol(art: status.kind.art, fallback: status.kind.fallbackSymbol,
                           size: 14 * scale, tint: tint)
                Text(status.badgeText)
                    .font(.system(size: 11 * scale, weight: .bold).monospacedDigit())
                    .foregroundStyle(tint)
            }
            .padding(.horizontal, 6 * scale)
            .padding(.vertical, 3 * scale)
            .background(tint.opacity(isOpen ? 0.3 : 0.16), in: .capsule)
            .overlay(Capsule().strokeBorder(tint.opacity(isOpen ? 0.9 : 0.35),
                                            lineWidth: isOpen ? 1.4 : 0.8))
        }
        .buttonStyle(PressableButtonStyle())
        // The bubble is drawn by the root tooltip layer so it can never be
        // clipped by the fighter's panel, and it clamps itself on screen.
        .tooltipAnchor(id: tooltipID, payload: isOpen ? .status(status) : nil)
    }
}
