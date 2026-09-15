import SwiftUI

/// An animated fighter in the arena: sprite, name, health bar, status badges,
/// and pose-driven attack/hurt/block/dodge motion. The player stands on the
/// left; every foe on the right owns one of these, tapped during attack
/// allocation to receive the selected blow.
struct FighterView: View {
    enum Side {
        case player
        case enemy
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

    @State private var aimPulse = false

    var body: some View {
        VStack(spacing: 5) {
            nameRow
            if side == .enemy, let foe, foe.armourMax > 0 {
                armourBar(foe)
            }
            healthBar
            sprite
            badgeRow
        }
        .frame(width: 190)
        .overlay(alignment: .top) { floaters }
        .overlay { aimRing }
        .overlay { championRing }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                aimPulse = true
            }
        }
    }

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
                DuatImage(name: DuatArt.targetRing, width: 150, fit: .fit)
                    .colorMultiply(Theme.gold)
                    .opacity(aimPulse ? 0.65 : 1)
                    .shadow(color: Theme.gold.opacity(0.8), radius: 12)
                    .offset(y: 18)
            }
            .overlay(alignment: .top) {
                Text("TARGET")
                    .font(.system(size: 8, weight: .black))
                    .kerning(2)
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 8)
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
            HaloedSigilView(deity: trial.deity, diameter: 86, breathes: true)
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

    /// Paintings read far better than glyphs, so they are drawn larger.
    private var portraitHeight: CGFloat {
        ((foe?.def.isBoss == true && side == .enemy) ? 132 : 118) * sizeScale
    }

    /// Every drawing this fighter owns, resolved once from the catalogue.
    private var frames: FrameSet {
        side == .player
            ? CharacterArt.heroFrames(heroClassID)
            : CharacterArt.foeFrames(foe?.def.id ?? engine.enemy.id)
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

    private var sprite: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.55))
                .frame(width: 124 * sizeScale, height: 21)
                .offset(y: 64)
                .scaleEffect(x: pose == .dodge ? 0.7 : 1)

            AnimatedFighterSprite(
                frames: frames,
                pose: pose,
                weapon: weapon,
                facing: facing,
                height: portraitHeight,
                accent: accent,
                fallbackSymbol: side == .player ? heroSymbol : (foe?.def.symbol ?? "questionmark"),
                mirrorFallback: side == .enemy
            )
            .shadow(color: auraColor.opacity(pose == .idle ? 0.4 : 0.95), radius: pose == .idle ? 12 : 26)
            .opacity(pose == .defeat ? 0.42 : 1)
            .grayscale(pose == .defeat ? 0.85 : 0)
            .overlay { godSigil }
        }
        .frame(height: 138)
    }

    /// The sigil of whichever god blessed the blow, stamping over the strike
    /// and burning away.
    @ViewBuilder
    private var godSigil: some View {
        if pose == .attack, !strikeGods.isEmpty {
            HStack(spacing: 6) {
                ForEach(strikeGods.prefix(2), id: \.self) { god in
                    DuatSymbol(art: god.artName, fallback: god.symbol, size: 34, tint: god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: 14)
                }
            }
            .offset(x: 38 * facing, y: -14)
            .transition(.scale(scale: 2.3).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    private var nameRow: some View {
        Text(side == .player ? heroName : (foe?.displayName ?? ""))
            .font(.fantasy(15, weight: .bold))
            .foregroundStyle(Theme.parchment)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
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
        DuatBar(
            kind: .health,
            fraction: Double(currentHP) / Double(max(maxHP, 1)),
            width: 160,
            height: 15,
            tint: side == .player ? accent : nil
        )
        .overlay {
            Text("\(currentHP)/\(maxHP)")
                .font(.system(size: 9.5, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.parchment)
                .shadow(color: .black, radius: 2.5)
                .shadow(color: .black.opacity(0.9), radius: 1)
                .contentTransition(.numericText())
                .allowsHitTesting(false)
        }
    }

    /// The bronze plate worn over health. Direct hits chip it away first;
    /// cracks open as it thins, and once it is gone the health is bare.
    private func armourBar(_ foe: EnemyState) -> some View {
        let fraction = foe.armourMax > 0
            ? CGFloat(foe.armour) / CGFloat(foe.armourMax)
            : 0
        return DuatBar(
            kind: .armour,
            fraction: Double(fraction),
            width: 132,
            height: 11
        )
        .overlay(alignment: .trailing) {
            HStack(spacing: 2) {
                DuatIcon(name: DuatArt.Status.armour, size: 10)
                Text("\(foe.armour)")
                    .font(.system(size: 9, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.bronze)
            }
            .offset(x: 26)
        }
    }

    /// Everything riding this fighter right now, each on its painted mark.
    private var badgeRow: some View {
        HStack(spacing: 3) {
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
        .frame(height: 18)
        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                   value: engine.playerShield + Int(engine.evadeChance * 100) + (foe?.block ?? 0) + (foe?.armour ?? 0))
    }

    private func badge(_ art: String, _ fallback: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 2) {
            DuatSymbol(art: art, fallback: fallback, size: 11, tint: tint)
            Text(text)
                .font(.system(size: 9, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(tint.opacity(0.15), in: .capsule)
    }
}
