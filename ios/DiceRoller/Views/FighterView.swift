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

    /// The gold ring with its TARGET tag, worn by the foe an attack is being
    /// sent at — during allocation, and again as each blow lands.
    @ViewBuilder
    private var aimRing: some View {
        if side == .enemy, isTargeted, let foe, foe.isAlive {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.gold.opacity(aimPulse ? 0.45 : 1), lineWidth: 2.2)
                .shadow(color: Theme.gold.opacity(0.8), radius: 12)
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

    /// A trial champion wears the attending god's colour for the whole fight —
    /// a thin, persistent ring beneath the gold target ring.
    @ViewBuilder
    private var championRing: some View {
        if side == .enemy, let foe, foe.isTrialChampion, engine.trialAccepted,
           let trial = engine.trial, foe.isAlive {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(trial.deity.tint.opacity(0.8), lineWidth: 1.6)
                .padding(.horizontal, -3)
                .padding(.vertical, -3)
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
                    Image(systemName: god.symbol)
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: 14)
                }
            }
            .offset(x: 38 * facing, y: -14)
            .transition(.scale(scale: 2.3).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(side == .player ? heroName : (foe?.displayName ?? ""))
                .font(.fantasy(15, weight: .bold))
                .foregroundStyle(Theme.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text("\(currentHP)/\(maxHP)")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .foregroundStyle(Theme.parchmentDim)
        }
    }

    private var currentHP: Int { side == .player ? engine.playerHP : (foe?.hp ?? 0) }
    private var maxHP: Int {
        side == .player ? engine.playerMaxHP : max(foe?.def.maxHP ?? 1, 1)
    }

    private var healthBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.bg)
                Capsule()
                    .fill(LinearGradient(
                        colors: side == .player ? [Theme.forest, accent] : [Theme.blood, Theme.ember],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: proxy.size.width * CGFloat(currentHP) / CGFloat(max(maxHP, 1)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentHP)
            }
        }
        .frame(width: 152, height: 9)
    }

    /// The bronze plate worn over health. Direct hits chip it away first;
    /// cracks open as it thins, and once it is gone the health is bare.
    private func armourBar(_ foe: EnemyState) -> some View {
        GeometryReader { proxy in
            let fraction = foe.armourMax > 0
                ? CGFloat(foe.armour) / CGFloat(foe.armourMax)
                : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.bg)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.bronze, Theme.goldDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: proxy.size.width * fraction)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: foe.armour)
                if fraction <= 0.67 {
                    crackMark.offset(x: proxy.size.width * 0.67)
                }
                if fraction <= 0.34 {
                    crackMark.offset(x: proxy.size.width * 0.34)
                }
            }
        }
        .frame(width: 152, height: 7)
        .overlay(alignment: .trailing) {
            HStack(spacing: 1) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 6.5, weight: .bold))
                Text("\(foe.armour)")
                    .font(.system(size: 8, weight: .black).monospacedDigit())
            }
            .foregroundStyle(Theme.bronze)
            .offset(x: 26)
        }
    }

    private var crackMark: some View {
        Rectangle()
            .fill(Color.black.opacity(0.6))
            .frame(width: 1.4, height: 9)
    }

    private var badgeRow: some View {
        HStack(spacing: 3) {
            if side == .player {
                if engine.playerShield > 0 { badge(icon: "shield.fill", text: "\(engine.playerShield)", tint: Theme.steel) }
                if engine.evadeChance > 0 { badge(icon: "wind", text: "\(Int(engine.evadeChance * 100))%", tint: Theme.steel) }
                if engine.regenTurns > 0 { badge(icon: "leaf.fill", text: "\(engine.regenAmount)×\(engine.regenTurns)", tint: Theme.forest) }
                if engine.playerBleedTurns > 0 { badge(icon: "drop.fill", text: "\(engine.playerBleedAmount)×\(engine.playerBleedTurns)", tint: Theme.blood) }
                if engine.playerBurnTurns > 0 { badge(icon: "flame.fill", text: "\(engine.playerBurnAmount)×\(engine.playerBurnTurns)", tint: Theme.ember) }
                if engine.playerJudgementPending { badge(icon: "scalemass.fill", text: "\(engine.playerJudgementAmount)", tint: Deity.anubis.tint) }
            } else if let foe {
                if foe.isTrialChampion, engine.trialAccepted {
                    badge(icon: "crown.fill", text: "CHAMPION", tint: engine.trial?.deity.tint ?? Theme.gold)
                }
                if foe.evadeCharges > 0 { badge(icon: "wind", text: "EVADE", tint: Deity.bastet.tint) }
                if foe.armourMax > 0 && foe.armour > 0 {
                    badge(icon: "shield.fill", text: "\(foe.armour)", tint: Theme.bronze)
                }
                if foe.block > 0 { badge(icon: "shield.lefthalf.filled", text: "\(foe.block)", tint: Theme.steel) }
                if foe.judgementPending { badge(icon: "scalemass.fill", text: "\(foe.judgementAmount)", tint: Deity.anubis.tint) }
                if foe.bleedTurns > 0 { badge(icon: "drop.fill", text: "\(foe.bleedAmount)×\(foe.bleedTurns)", tint: Theme.blood) }
                if foe.poisonTurns > 0 { badge(icon: "drop.triangle.fill", text: "\(foe.poisonAmount)×\(foe.poisonTurns)", tint: Theme.venom) }
                if foe.burnTurns > 0 { badge(icon: "flame.fill", text: "\(foe.burnAmount)×\(foe.burnTurns)", tint: Theme.ember) }
                if foe.stagger > 0 { badge(icon: "snowflake", text: "\(Int(foe.stagger * 100))%", tint: Theme.frost) }
                if foe.mark > 1 { badge(icon: "scope", text: "MARK", tint: Theme.venom) }
            }
        }
        .frame(height: 18)
        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                   value: engine.playerShield + Int(engine.evadeChance * 100) + (foe?.block ?? 0) + (foe?.armour ?? 0))
    }

    private func badge(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 7.5, weight: .bold))
            Text(text).font(.system(size: 9, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(tint.opacity(0.15), in: .capsule)
    }
}
