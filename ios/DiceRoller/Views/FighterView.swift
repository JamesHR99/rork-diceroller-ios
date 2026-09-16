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
    /// True while this foe wears the gold ring — the attack being allocated
    /// points here, or the blow in flight was sent here.
    var isTargeted: Bool = false
    var onTap: (() -> Void)? = nil
    var layout: Layout = .stage
    /// Tickers squeeze further still when a whole pack has to fit the rail.
    var tickerCompact: Bool = false
    /// How tall an ordinary fighter stands on the stage, measured by the arena
    /// from the room it actually has.
    var stageHeight: CGFloat = 164

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
            if side == .enemy, let foe, foe.armourMax > 0 {
                armourBar(foe)
            }
            healthBar
            sprite
            badgeRow
        }
        .frame(width: stageWidth)
        .overlay(alignment: .top) { floaters }
        .overlay { aimRing }
        .overlay { championRing }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    /// Stage cards keep their width in step with the pack, so three foes still
    /// fit the deck without overlapping the demigod.
    private var stageWidth: CGFloat {
        side == .enemy ? 248 * max(packScale, 0.7) : 248
    }

    // MARK: - Ticker

    /// The compact read: the fighter's face, name, health, and — for a foe —
    /// the blow they are winding up, all on one painted slab.
    private var tickerBody: some View {
        HStack(spacing: 9) {
            if side == .player { tickerPortrait }

            VStack(alignment: side == .player ? .leading : .trailing, spacing: 3) {
                HStack(spacing: 5) {
                    Text(side == .player ? heroName : (foe?.displayName ?? ""))
                        .font(.fantasy(tickerCompact ? 13 : 15, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    badgeRow
                }

                if side == .enemy, let foe, foe.armourMax > 0 {
                    armourBar(foe, width: tickerWidth - 62)
                }

                healthBar(width: tickerWidth - 62, height: 15)

                if side == .enemy, let foe {
                    intentLine(foe)
                }
            }
            .frame(maxWidth: .infinity, alignment: side == .player ? .leading : .trailing)

            if side == .enemy { tickerPortrait }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(width: tickerWidth)
        .papyrusPanel(tint: Theme.bgElevated, cornerRadius: 13, strength: 0.5, shade: 0.46)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder((side == .player ? accent : Theme.blood).opacity(0.35), lineWidth: 1)
        )
    }

    private var tickerWidth: CGFloat { tickerCompact ? 212 : 268 }

    private var tickerPortrait: some View {
        PortraitMedallionView(
            art: frames.art(.idle),
            fallbackSymbol: side == .player ? heroSymbol : (foe?.def.symbol ?? "questionmark"),
            tint: side == .player ? accent : Theme.blood,
            diameter: tickerCompact ? 44 : 52,
            glow: false
        )
    }

    /// What this foe will throw when the deck goes down, under its health.
    private func intentLine(_ foe: EnemyState) -> some View {
        let strike = engine.projectedStrike(for: foe)
        let move = foe.intent
        return HStack(spacing: 4) {
            ForEach(Array(move.faces.prefix(3).enumerated()), id: \.offset) { _, face in
                DuatSymbol(art: face.artName, fallback: face.symbol, size: 15, tint: face.tint)
                    .frame(width: 18, height: 18)
            }

            Text(move.comboName ?? move.name)
                .font(.fantasy(11, weight: .bold))
                .foregroundStyle(move.comboName != nil ? Theme.ember : Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if strike.damage > 0 {
                HStack(spacing: 2) {
                    DuatSymbol(art: DuatArt.Status.piercing, fallback: "burst.fill",
                               size: 12, tint: Theme.blood)
                    Text("\(strike.damage)")
                        .font(.system(size: 11, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.blood)
                }
            }
            if strike.block > 0 {
                HStack(spacing: 2) {
                    DuatSymbol(art: DuatArt.Status.shield, fallback: "shield.fill",
                               size: 11, tint: Theme.steel)
                    Text("\(strike.block)")
                        .font(.system(size: 10.5, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.steel)
                }
            }
        }
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
                DuatImage(name: DuatArt.targetRing, width: 186, fit: .fit)
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
                foeSheetID: foeSheetID
            )
            .shadow(color: auraColor.opacity(pose == .idle ? 0.4 : 0.95), radius: pose == .idle ? 14 : 30)
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
                    DuatSymbol(art: god.artName, fallback: god.symbol, size: 42, tint: god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: 16)
                }
            }
            .offset(x: 48 * facing, y: -18)
            .transition(.scale(scale: 2.3).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    private var nameRow: some View {
        Text(side == .player ? heroName : (foe?.displayName ?? ""))
            .font(.fantasy(17, weight: .bold))
            .kerning(0.6)
            .foregroundStyle(Theme.parchment)
            .shadow(color: .black.opacity(0.8), radius: 3, y: 1)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
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
        healthBar(width: 210, height: 19)
    }

    private func healthBar(width: CGFloat, height: CGFloat) -> some View {
        DuatBar(
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
                .allowsHitTesting(false)
        }
    }

    /// The bronze plate worn over health. Direct hits chip it away first;
    /// cracks open as it thins, and once it is gone the health is bare.
    private func armourBar(_ foe: EnemyState, width: CGFloat = 176) -> some View {
        let fraction = foe.armourMax > 0
            ? CGFloat(foe.armour) / CGFloat(foe.armourMax)
            : 0
        return DuatBar(
            kind: .armour,
            fraction: Double(fraction),
            width: width,
            height: 13
        )
        .overlay(alignment: .trailing) {
            HStack(spacing: 2) {
                DuatIcon(name: DuatArt.Status.armour, size: 12)
                Text("\(foe.armour)")
                    .font(.system(size: 10, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.bronze)
            }
            .offset(x: 28)
        }
    }

    /// Everything riding this fighter right now, each on its painted mark.
    private var badgeRow: some View {
        HStack(spacing: 4) {
            if side == .player {
                if engine.playerShield > 0 {
                    badge(DuatArt.Status.shield, "shield.fill", "\(engine.playerShield)", Theme.steel)
                }
                if engine.evadeChance > 0 {
                    badge(DuatArt.Status.evade, "wind", "\(Int(engine.evadeChance * 100))%", Theme.steel)
                }
                if engine.regenTurns > 0 {
                    badge(DuatArt.Status.regeneration, "leaf.fill",
                          "\(engine.regenAmount)×\(engine.regenTurns)", Theme.forest)
                }
                if engine.playerBleedTurns > 0 {
                    badge(DuatArt.Status.bleed, "drop.fill",
                          "\(engine.playerBleedAmount)×\(engine.playerBleedTurns)", Theme.blood)
                }
                if engine.playerBurnTurns > 0 {
                    badge(DuatArt.Status.burn, "flame.fill",
                          "\(engine.playerBurnAmount)×\(engine.playerBurnTurns)", Theme.ember)
                }
                if engine.playerJudgementPending {
                    badge(DuatArt.Status.judgement, "scalemass.fill",
                          "\(engine.playerJudgementAmount)", Deity.anubis.tint)
                }
            } else if let foe {
                if foe.isTrialChampion, engine.trialAccepted {
                    badge(DuatArt.Status.champion, "crown.fill", "CHAMPION",
                          engine.trial?.deity.tint ?? Theme.gold)
                }
                if foe.evadeCharges > 0 {
                    badge(DuatArt.Status.evade, "wind", "EVADE", Deity.bastet.tint)
                }
                if foe.armourMax > 0 && foe.armour > 0 {
                    badge(DuatArt.Status.armour, "shield.fill", "\(foe.armour)", Theme.bronze)
                }
                if foe.block > 0 {
                    badge(DuatArt.Status.shield, "shield.lefthalf.filled", "\(foe.block)", Theme.steel)
                }
                if foe.judgementPending {
                    badge(DuatArt.Status.judgement, "scalemass.fill",
                          "\(foe.judgementAmount)", Deity.anubis.tint)
                }
                if foe.bleedTurns > 0 {
                    badge(DuatArt.Status.bleed, "drop.fill",
                          "\(foe.bleedAmount)×\(foe.bleedTurns)", Theme.blood)
                }
                if foe.poisonTurns > 0 {
                    badge(DuatArt.Status.poison, "drop.triangle.fill",
                          "\(foe.poisonAmount)×\(foe.poisonTurns)", Theme.venom)
                }
                if foe.burnTurns > 0 {
                    badge(DuatArt.Status.burn, "flame.fill",
                          "\(foe.burnAmount)×\(foe.burnTurns)", Theme.ember)
                }
                if foe.stagger > 0 {
                    badge(DuatArt.Status.frost, "snowflake", "\(Int(foe.stagger * 100))%", Theme.frost)
                }
                if foe.mark > 1 {
                    badge(DuatArt.Status.marked, "scope", "MARK", Theme.venom)
                }
            }
        }
        .frame(height: layout == .ticker ? 16 : 21)
        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                   value: engine.playerShield + Int(engine.evadeChance * 100) + (foe?.block ?? 0) + (foe?.armour ?? 0))
    }

    private func badge(_ art: String, _ fallback: String, _ text: String, _ tint: Color) -> some View {
        let scale: CGFloat = layout == .ticker ? 0.85 : 1
        return HStack(spacing: 2.5) {
            DuatSymbol(art: art, fallback: fallback, size: 14 * scale, tint: tint)
            Text(text)
                .font(.system(size: 11 * scale, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 6 * scale)
        .padding(.vertical, 3 * scale)
        .background(tint.opacity(0.16), in: .capsule)
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.8))
    }
}
