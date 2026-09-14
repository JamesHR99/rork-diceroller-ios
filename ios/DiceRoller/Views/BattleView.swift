import SwiftUI

/// The deck of the barque and the water around it: you on the left, the thing
/// that came out of the river on the right, the dice tray centre stage while
/// you plan, and the ordered turn plan below.
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

    private var gate: Gate { game.gate }

    var body: some View {
        ZStack {
            arenaBackground

            VStack(spacing: 5) {
                topStrip

                ZStack {
                    VStack(spacing: 0) {
                        // A hidden copy holds the row's height so the fighters
                        // never shift — the readable one is drawn over the tray.
                        HStack {
                            Spacer(minLength: 0)
                            intentRow
                            Spacer(minLength: 0)
                        }
                        .hidden()

                        Spacer(minLength: 0)

                        // The fighters stand low on the deck so the water and
                        // the hull read behind them. Packs fill the right side.
                        HStack(alignment: .bottom, spacing: 8) {
                            FighterView(
                                engine: engine,
                                side: .player,
                                heroSymbol: game.heroClass?.fighterSymbol ?? "figure.stand",
                                heroName: game.heroClass?.name ?? "Hero",
                                accent: game.heroClass?.accent ?? Theme.gold,
                                heroClassID: game.classID
                            )

                            Spacer(minLength: 0)

                            enemyGroup
                        }
                        .padding(.horizontal, 6)
                    }

                    // The tray owns the middle of the arena while you plan —
                    // the fight dims behind it — then clears away entirely so
                    // the blows have the whole deck. It also steps aside while
                    // attacks are being allocated, leaving the foes tappable.
                    if engine.phase == .player, !engine.isAllocating {
                        Theme.bg.opacity(0.45)
                            .allowsHitTesting(false)
                            .transition(.opacity)

                        DiceTrayView(engine: engine)
                            .padding(.horizontal, 8)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }

                    // What is about to hit you stays readable while you roll
                    // and plan — it sits over the tray, never behind it.
                    VStack(spacing: 0) {
                        HStack {
                            Spacer(minLength: 0)
                            intentRow
                            Spacer(minLength: 0)
                        }
                        Spacer(minLength: 0)
                    }
                    .allowsHitTesting(false)
                    .zIndex(3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.42, dampingFraction: 0.85), value: engine.phase)

                PlayBarView(engine: engine)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }
            .modifier(ShakeEffect(animatableData: engine.shakeTrigger))

            // A landing chain takes the whole deck: shockwave, embers, wash
            // and a banner naming what just happened.
            if let flash = engine.comboFlash {
                ComboFlashView(flash: flash)
                    .id(flash.id)
                    .zIndex(4)
                    .transition(.opacity)
            }

            if let announcement = engine.stageAnnouncement {
                stageBanner(announcement)
            }

            if arrivalShown {
                arrivalCard
                    .zIndex(5)
            }

            if engine.phase == .won || engine.phase == .lost {
                battleEndOverlay
            }

            // The targeting step: with several foes standing, committing lists
            // every attack so each can be sent at a chosen foe.
            if engine.isAllocating {
                AllocationOverlayView(engine: engine)
                    .zIndex(6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: engine.isAllocating)
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus,
                              maxStamina: game.effectiveMaxStamina,
                              drawnDieIDs: game.battle?.drawnDieIDs ?? [])
            }
        }
    }

    /// The barque hull sits under the fighters — you are fighting on the deck.
    private var arenaBackground: some View {
        ZStack {
            RadialGradient(
                colors: [gate.discColor.opacity(0.14 * game.discGlow), .clear],
                center: .center,
                startRadius: 60,
                endRadius: 480
            )

            VStack {
                Spacer()
                BarqueView(gate: gate, width: 620, discGlow: game.discGlow)
                    .opacity(0.55)
                    .offset(y: 96)
            }

            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.85)],
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
    private var enemyGroup: some View {
        let foes = engine.enemies
        let scale: CGFloat = foes.count >= 3 ? 0.72 : (foes.count == 2 ? 0.84 : 1)
        return HStack(alignment: .bottom, spacing: foes.count > 1 ? 2 : 0) {
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
                    onTap: engine.isAllocating ? { engine.assignSelected(to: foe.id) } : nil
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
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(total)")
                        .font(.system(size: 11, weight: .black).monospacedDigit())
                }
                .foregroundStyle(Theme.bg)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.ember, in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                .offset(y: 44)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
    }

    private var topStrip: some View {
        HStack(spacing: 10) {
            Text("TURN \(engine.turnNumber)")
                .font(.system(size: 10, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.gold)
                .kerning(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.bgElevated, in: .capsule)

            Text(engine.lastAction)
                .font(.paper(12.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .animation(.easeInOut(duration: 0.2), value: engine.lastAction)

            Spacer()

            NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)

            Button {
                showInfo = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("CODEX")
                        .font(.system(size: 10, weight: .black))
                        .kerning(1)
                }
                .foregroundStyle(Theme.gold)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Theme.bgElevated, in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.top, 2)
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
            Image(systemName: "eye.fill")
                .font(.system(size: 9))
                .foregroundStyle(Theme.parchmentDim)

            if !compact {
                Text("Intent:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim)
            } else {
                Text(foe.displayName.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
            }

            ForEach(Array(move.faces.enumerated()), id: \.offset) { _, face in
                Image(systemName: face.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(face.tint)
                    .frame(width: 20, height: 20)
                    .background(Theme.bg, in: .rect(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(face.tint.opacity(0.4), lineWidth: 1))
            }

            Text(move.comboName ?? move.name)
                .font(.fantasy(11, weight: .bold))
                .foregroundStyle(move.comboName != nil ? Theme.ember : Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if strike.damage > 0 {
                outcomeBadge("burst.fill", "\(strike.damage)", Theme.blood)
            }
            if strike.heal > 0 {
                outcomeBadge("heart.fill", "+\(strike.heal)", Theme.forest)
            }
            if strike.block > 0 {
                outcomeBadge("shield.fill", "+\(strike.block)", Theme.steel)
            }
            if move.bleedAmount > 0, move.bleedTurns > 0 {
                outcomeBadge("drop.fill", "\(move.bleedAmount)×\(move.bleedTurns)", Theme.blood.opacity(0.85))
            }
            if foe.stagger > 0 {
                outcomeBadge("snowflake", "weakened", Theme.frost)
            }
            if heat > 0 {
                outcomeBadge("thermometer.high", "+\(heat)", Theme.ember)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Theme.bg.opacity(0.85), in: .capsule)
        .overlay(Capsule().strokeBorder(Theme.rule.opacity(0.25), lineWidth: 0.75))
    }

    /// One icon-and-number pair reading what the telegraphed move will do.
    private func outcomeBadge(_ icon: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 8, weight: .bold))
            Text(value).font(.system(size: 10, weight: .black).monospacedDigit())
        }
        .foregroundStyle(tint)
    }

    /// Announces a serpent-lord re-coiling into a new stage.
    private func stageBanner(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text.uppercased())
                .font(.fantasy(15, weight: .black))
                .kerning(2)
                .foregroundStyle(Theme.parchment)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Theme.blood.opacity(0.35), in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.blood, lineWidth: 1.2))
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
        let portraitHeight: CGFloat = solo ? 168 : (count == 2 ? 132 : 106)
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
                            PortraitView(art: CharacterArt.foe(foe.def.id),
                                         fallbackSymbol: foe.def.symbol,
                                         tint: Theme.blood,
                                         height: portraitHeight,
                                         mirrorFallback: true)
                                .shadow(color: Theme.blood.opacity(0.8), radius: 22)
                        }
                    }
                }
                .frame(width: 176)

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

                    HieroglyphBand(tint: Theme.gold, height: 8, opacity: 0.5)
                        .frame(width: 300)

                    Text(foes[0].def.title)
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.6)
                        .foregroundStyle(gate.accent)

                    if anyArmoured {
                        HStack(spacing: 5) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("ARMOURED — BREAK THE PLATE BEFORE THE HEALTH")
                                .font(.system(size: 9, weight: .black))
                                .kerning(1.2)
                        }
                        .foregroundStyle(Theme.bronze)
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
                            .foregroundStyle(Theme.bg)
                            .frame(width: 260, height: 44)
                            .background(
                                LinearGradient(colors: [Theme.gold, Theme.ember],
                                               startPoint: .top, endPoint: .bottom),
                                in: .capsule
                            )
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
            Image(systemName: won ? "sun.max.fill" : "sun.dust.fill")
                .font(.system(size: 46))
                .foregroundStyle(won ? Theme.gold : Theme.blood)
                .shadow(color: (won ? Theme.gold : Theme.blood).opacity(0.7), radius: 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(won ? "THE WAY IS CLEAR" : "THE DISC GOES OUT")
                    .font(.fantasy(30, weight: .black))
                    .foregroundStyle(Theme.parchment)
                    .kerning(3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

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
                        .foregroundStyle(Theme.bg)
                        .frame(width: 220, height: 46)
                        .background(
                            LinearGradient(
                                colors: won ? [Theme.gold, Theme.ember] : [Theme.parchmentDim, Theme.steel],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: .capsule
                        )
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
