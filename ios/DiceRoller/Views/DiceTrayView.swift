import SwiftUI

/// The roll tray. It takes over the middle of the arena during your turn — one
/// pull rolls every die that isn't frozen, then you tap faces into the plan.
/// Freezing is armed from the play bar. The whole tray clears away once the
/// turn is committed so the fighters have the stage to themselves.
struct DiceTrayView: View {
    let engine: BattleEngine

    @State private var slamKick: CGFloat = 0
    @State private var slamFlare: Double = 0

    private var freezeArmed: Bool { engine.freezeArmed }

    /// Dice grow to fill the arena, shrinking only once the row gets long. A
    /// freeze adds a carried reel on top of the loadout, so the row can run
    /// one wider than the dice cap.
    private var reelWidth: CGFloat {
        switch engine.slots.count {
        case ...6: return 92
        case 7: return 84
        case 8: return 76
        case 9: return 69
        case 10: return 63
        default: return 57
        }
    }

    private var reelHeight: CGFloat { min(126, reelWidth * 1.28) }

    var body: some View {
        VStack(spacing: 10) {
            header

            HStack(spacing: 8) {
                leadingControl

                HStack(spacing: engine.slots.count > 7 ? 5 : 7) {
                    let counts = Dictionary(uniqueKeysWithValues:
                        engine.comboMarkers.map { ($0.key, $0.value.count) })
                    ForEach(engine.slots) { slot in
                        DiceTrayReelView(
                            slot: slot,
                            engine: engine,
                            width: reelWidth,
                            height: reelHeight,
                            chainCounts: counts
                        )
                    }
                }
            }

            comboPanel
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .papyrusPanel(tint: Theme.bgElevated, cornerRadius: 24, strength: 0.5)
        .overlay(alignment: .bottom) {
            HieroglyphBand(tint: freezeArmed ? Theme.frost : Theme.gold, height: 9, opacity: 0.32)
                .padding(.horizontal, 22)
                .padding(.bottom, 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: freezeArmed
                            ? [Theme.frost.opacity(0.8), Theme.frost.opacity(0.2)]
                            : [Theme.gold.opacity(0.55), Theme.lapis.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: freezeArmed ? 2 : 1.4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .inset(by: 4)
                .strokeBorder(Theme.rule.opacity(0.18), lineWidth: 0.75)
        )
        .overlay {
            // Gold bloom washing out of the frame each time a reel lands.
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Theme.gold, lineWidth: 3)
                .blur(radius: 6)
                .opacity(slamFlare * 0.9)
                .allowsHitTesting(false)
        }
        .shadow(color: (freezeArmed ? Theme.frost : Color.black).opacity(freezeArmed ? 0.4 : 0.6),
                radius: 26, y: 10)
        .shadow(color: Theme.gold.opacity(slamFlare * 0.55), radius: 30)
        .fixedSize(horizontal: true, vertical: true)
        .scaleEffect(1 + slamKick)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: freezeArmed)
        .onChange(of: engine.slamPulse) { _, _ in
            let heavy = engine.lastReelLocked
            slamKick = heavy ? 0.03 : 0.016
            slamFlare = heavy ? 1 : 0.55
            withAnimation(.spring(response: 0.34, dampingFraction: 0.45)) { slamKick = 0 }
            withAnimation(.easeOut(duration: heavy ? 0.55 : 0.32)) { slamFlare = 0 }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let faceID = UUID(uuidString: idString) else { return false }
            engine.returnToTray(faceID: faceID)
            return true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(headerTitle)
                .font(.system(size: 10, weight: .black))
                .kerning(1.2)
                .foregroundStyle(freezeArmed ? Theme.frost : Theme.gold)

            // Chisels of Ptah, struck in his copper beside the title.
            if !engine.chisels.isEmpty {
                HStack(spacing: 2) {
                    ForEach(engine.chisels.sorted(), id: \.self) { id in
                        Image(systemName: ChiselCatalog.def(id)?.symbol ?? "hammer.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.ptahCopper)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.bg.opacity(0.7), in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.ptahCopper.opacity(0.4), lineWidth: 1))
            }

            Text(hint)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            if engine.frozenCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(engine.frozenCount) CARRIES OVER · DIE STILL ROLLS")
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundStyle(Theme.frost)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Theme.frost.opacity(0.15), in: .capsule)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if engine.carriedCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(engine.carriedCount) HELD FACE\(engine.carriedCount > 1 ? "S" : "") IN HAND")
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundStyle(Theme.frost.opacity(0.8))
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Theme.frost.opacity(0.1), in: .capsule)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if engine.chainsInHand > 0 && !freezeArmed {
                chainsBadge
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: engine.chainsInHand)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: engine.frozenCount)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: freezeArmed)
    }

    private var headerTitle: String {
        if freezeArmed { return "FREEZE MODE" }
        if engine.canRoll { return "YOUR DICE" }
        if engine.isRolling { return "LOCKING \(engine.lockedReelCount)/\(engine.slots.count)" }
        return "YOUR ROLL"
    }

    /// How many chains are still reachable from where the plan stands. It is
    /// live: lay a die down and the number reads the chains that survive that
    /// choice, never naming a single one of them.
    private var chainsBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "link").font(.system(size: 9, weight: .black))
            Text("\(engine.chainsInHand) CHAIN\(engine.chainsInHand > 1 ? "S" : "") STILL IN REACH")
                .font(.system(size: 9, weight: .black).monospacedDigit())
                .contentTransition(.numericText())
        }
        .foregroundStyle(Theme.parchment.opacity(0.85))
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(Theme.bgCard, in: .capsule)
        .overlay(Capsule().strokeBorder(Theme.rule.opacity(0.35), lineWidth: 1))
        .transition(.scale(scale: 0.7).combined(with: .opacity))
    }

    private var hint: String {
        if freezeArmed {
            let left = engine.freezesRemaining
            return "Hold a face · \(left) freeze\(left == 1 ? "" : "s") left · the die still rolls next turn"
        }

        if engine.canRoll { return "Roll to begin the turn · the order changes every roll" }
        if engine.isRolling { return "The drums wind down, one by one..." }
        if !engine.comboCandidates.isEmpty {
            return "Tap a recipe to fuse it · letters match the marks on your dice"
        }
        return "Chain faces together — alone they barely scratch · FREEZE holds one face"
    }

    // MARK: - Combo panel

    /// Every chain the roll could still make: name, effect, ingredients and
    /// stamina, with a letter that matches the markers under the dice feeding
    /// it. Tap to fuse; tap a planned one to dissolve it back into solos.
    @ViewBuilder
    private var comboPanel: some View {
        if !engine.canRoll && !engine.isRolling && !engine.comboCandidates.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(engine.comboCandidates) { candidate in
                        comboChip(candidate)
                    }
                }
                .padding(.vertical, 1)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func comboChip(_ candidate: ComboCandidate) -> some View {
        let planned = candidate.isForced && candidate.isInPlan
        let partial = candidate.placedCount > 0 && !planned
        return Button {
            engine.toggleCombo(candidate.combo.id)
        } label: {
            HStack(spacing: 5) {
                Text(candidate.letter)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 18, height: 18)
                    .background(candidate.combo.tint, in: .circle)

                VStack(alignment: .leading, spacing: 0) {
                    Text(candidate.combo.name)
                        .font(.system(size: 10.5, weight: .black))
                        .kerning(0.4)
                        .foregroundStyle(planned ? Theme.gold : Theme.parchment)
                        .lineLimit(1)
                    Text(candidate.combo.effectSummary)
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                        .lineLimit(1)
                }

                Text("\(candidate.combo.staminaCost)")
                    .font(.system(size: 10, weight: .black).monospacedDigit())
                    .foregroundStyle(planned ? Theme.gold : Theme.parchmentDim)

                // The Ptah badge: arms this recipe's optional Chisel — tap to
                // see its cost and outcome fold into the forecast, tap again
                // to disarm.
                if let badgeChisel = engine.badgeChisel(for: candidate.combo.id) {
                    let armed = engine.isArmed(badgeChisel, comboID: candidate.combo.id)
                    Button {
                        engine.toggleArmed(badgeChisel, comboID: candidate.combo.id)
                    } label: {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(armed ? Theme.bg : Theme.ptahCopper)
                            .frame(width: 20, height: 20)
                            .background(armed ? Theme.ptahCopper : Theme.bg, in: .circle)
                            .overlay(Circle().strokeBorder(Theme.ptahCopper.opacity(armed ? 1 : 0.6), lineWidth: 1))
                            .shadow(color: armed ? Theme.ptahCopper.opacity(0.6) : .clear, radius: 5)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.bgCard, in: .capsule)
            .overlay(
                Capsule().strokeBorder(
                    planned ? Theme.gold : (partial ? candidate.combo.tint.opacity(0.7) : Theme.rule.opacity(0.35)),
                    lineWidth: planned ? 1.8 : 1
                )
            )
            .opacity(partial ? 0.75 : 1)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Roll control

    @ViewBuilder
    private var leadingControl: some View {
        if engine.canRoll {
            Button {
                engine.rollAll()
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 26, weight: .bold))
                    Text("ROLL")
                        .font(.fantasy(16, weight: .black))
                        .kerning(1.4)
                }
                .foregroundStyle(Theme.bg)
                .frame(width: 96, height: reelHeight)
                .background(
                    LinearGradient(colors: [Theme.gold, Theme.ember], startPoint: .top, endPoint: .bottom),
                    in: .rect(cornerRadius: 16)
                )
                .shadow(color: Theme.ember.opacity(0.55), radius: 12, y: 2)
            }
            .buttonStyle(PressableButtonStyle())
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

/// A single die in the tray: waits, tumbles, settles on a face, then empties
/// once that face has been sent down to the plan — unless it has been frozen,
/// in which case it keeps its face through the enemy's turn.
private struct DiceTrayReelView: View {
    let slot: DieSlot
    let engine: BattleEngine
    let width: CGFloat
    let height: CGFloat
    /// How many chains each die could still feed from where the plan stands —
    /// never which ones.
    let chainCounts: [UUID: Int]

    @State private var spinIndex = 0
    @State private var settled = false
    @State private var critFlash = false
    @State private var frostPulse = false
    /// 2 = drum at full speed, 1 = braking, 0 = about to stop.
    @State private var drumSpeed = 2
    /// Set just before this reel's stop, so it tenses before it lands.
    @State private var imminent = false
    /// Shockwave ring thrown off the moment the reel locks.
    @State private var shock: CGFloat = 0
    /// Spark burst thrown off a critical as it slams home.
    @State private var sparkBurst: Double = 0
    @State private var flash: Double = 0

    private var freezeArmed: Bool { engine.freezeArmed }
    private var isFrozen: Bool { engine.isFrozen(slotID: slot.id) }
    /// A reel holding a face carried over from last turn's freeze.
    private var isHeld: Bool { slot.isCarried }

    private var corner: CGFloat { 15 }
    private var iconSize: CGFloat { width * 0.34 }
    private var labelSize: CGFloat { max(8, width * 0.115) }
    /// A claimed die's face carries its name in bigger type — the god's
    /// blessing is part of the read that decides a turn.
    private func labelSize(for face: RolledFace) -> CGFloat {
        face.patron == nil ? labelSize : max(11, width * 0.16)
    }
    private var tagSize: CGFloat { max(8.5, width * 0.125) }

    /// Smear on the drum, tied to how fast this particular reel is turning —
    /// the lazier late reels are read clearly rather than blurred away.
    private var spinBlur: CGFloat {
        guard drumSpeed > 0 else { return 0 }
        let pace = CGFloat(BattleEngine.drumStepBase / max(engine.drumStep(slotID: slot.id), 0.04))
        return drumSpeed == 2 ? 2.2 * pace : 0.9 * pace
    }

    var body: some View {
        Group {
            switch slot.state {
            case .idle:
                idleReel
            case .rolling:
                spinningReel
            case .rolled(let face):
                if engine.playOrder.contains(face.id) {
                    emptyReel(icon: "arrow.down")
                } else {
                    settledReel(face)
                }
            case .spent:
                emptyReel(icon: "checkmark")
            }
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.playOrder)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: chainCounts)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFrozen)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: freezeArmed)
    }

    private var idleReel: some View {
        VStack(spacing: 4) {
            Image(systemName: "dice")
                .font(.system(size: iconSize * 0.85, weight: .bold))
                .foregroundStyle(Theme.parchmentDim.opacity(0.5))
            reelName
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: corner))
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.parchmentDim.opacity(0.2), style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
        )
    }

    private var spinningReel: some View {
        let faces = slot.die.faces
        let count = max(faces.count, 1)
        let face = faces[spinIndex % count]
        let ghostAbove = faces[(spinIndex + count - 1) % count]
        let ghostBelow = faces[(spinIndex + 1) % count]

        return VStack(spacing: 4) {
            ZStack {
                // Neighbouring faces bleeding past the drum window.
                Image(systemName: ghostAbove.kind.symbol)
                    .font(.system(size: iconSize * 0.78, weight: .bold))
                    .foregroundStyle(ghostAbove.kind.tint.opacity(0.22))
                    .offset(y: -iconSize * 0.92)
                Image(systemName: ghostBelow.kind.symbol)
                    .font(.system(size: iconSize * 0.78, weight: .bold))
                    .foregroundStyle(ghostBelow.kind.tint.opacity(0.22))
                    .offset(y: iconSize * 0.92)

                Image(systemName: face.kind.symbol)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(face.kind.tint.opacity(drumSpeed == 0 ? 1 : 0.85))
                    .id(spinIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
            .frame(height: iconSize * 1.5)
            .blur(radius: spinBlur)
            .clipped()

            reelName
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgCard, in: .rect(cornerRadius: corner))
        .overlay {
            // Curved-glass shading so the reel reads as a spinning drum.
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.gold.opacity(imminent ? 0.95 : 0.45),
                              lineWidth: imminent ? 2.4 : 1.5)
        )
        .clipShape(.rect(cornerRadius: corner))
        .shadow(color: Theme.gold.opacity(imminent ? 0.55 : 0), radius: 12)
        .scaleEffect(imminent ? 1.05 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: imminent)
        .task {
            // Reels keep their identity from turn to turn, so the landing
            // animation has to be re-armed each time the drum starts up —
            // otherwise only the first roll of the fight slams home.
            resetLandingAnimation()
            let base = engine.drumStep(slotID: slot.id)
            let lockAt = Date().addingTimeInterval(engine.lockTime(slotID: slot.id))
            while engine.slots.first(where: { $0.id == slot.id })?.state == .rolling {
                let remaining = lockAt.timeIntervalSinceNow
                // The drum brakes into its stop instead of cutting dead: full
                // speed, then a long haul, then one last lazy turn. The brake
                // stages start earlier and run longer on later reels, so the
                // row settles slower as it empties left to right.
                let windows = engine.brakeWindows(slotID: slot.id)
                let step: Double = remaining < windows.crawl
                    ? base * 4.0
                    : (remaining < windows.haul ? base * 2.0 : base)
                let speed = remaining < windows.crawl ? 0 : (remaining < windows.haul ? 1 : 2)
                if speed != drumSpeed { drumSpeed = speed }
                if remaining < windows.ring && !imminent { imminent = true }
                try? await Task.sleep(for: .seconds(step))
                withAnimation(.linear(duration: step)) { spinIndex += 1 }
            }
        }
    }

    /// Clears every one-shot landing effect so the next lock plays in full.
    private func resetLandingAnimation() {
        withAnimation(.linear(duration: 0)) {
            settled = false
            critFlash = false
        }
        shock = 0
        flash = 0
        sparkBurst = 0
        imminent = false
    }

    // MARK: - Settled die

    private func settledReel(_ face: RolledFace) -> some View {
        Button {
            if freezeArmed {
                engine.toggleFreeze(slotID: slot.id)
            } else {
                engine.placeInPlayBar(faceID: face.id)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: face.matchFace.symbol)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(iconTint(face))
                // The face that actually landed always keeps its name — a crit
                // is announced by the badge and the gold, never by hiding the
                // roll you are trying to read. A Chisel substitution shows the
                // tier the engine will use, in Ptah's copper.
                Text(reelLabel(face))
                    .font(.system(size: labelSize(for: face), weight: .heavy))
                    .kerning(0.2)
                    .foregroundStyle(face.isCrit
                                     ? Theme.gold
                                     : ((face.patron?.tint ?? face.matchFace.tint)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(bottomTag(face))
                    .font(.system(size: tagSize, weight: .black).monospacedDigit())
                    .foregroundStyle(bottomTagTint(face))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bgCard, in: .rect(cornerRadius: corner))
            .overlay { frostLayer }
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(borderTint(face), lineWidth: isFrozen ? 2.4 : (face.isCrit ? 2.4 : 1.6))
            )
            .overlay { armedHalo }
            .overlay(alignment: .bottomLeading) { chainCountBadge(face) }
            .overlay(alignment: .topTrailing) {
                if face.imbueTiers > 0 {
                    Circle().fill(Theme.gold).frame(width: 5, height: 5).padding(5)
                }
            }
            .overlay(alignment: .topLeading) {
                // A patron god's sigil rides the die whose faces they answer.
                if let patron = face.patron {
                    Image(systemName: patron.symbol)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(patron.tint)
                        .frame(width: 16, height: 16)
                        .background(Theme.bg.opacity(0.85), in: .circle)
                        .overlay(Circle().strokeBorder(patron.tint.opacity(0.8), lineWidth: 1))
                        .padding(4)
                }
            }
            .overlay(alignment: .top) { critBadge(face) }
            .overlay(alignment: .bottomTrailing) { nockControls(face) }
            .overlay { slamFlash(face) }
            .overlay { shockRing(face) }
            .overlay { critSparks(face) }
            .shadow(color: glowTint(face).opacity(isFrozen ? 0.7 : (face.isCrit ? 0.8 : 0.35)),
                    radius: (face.isCrit && critFlash) || (isFrozen && frostPulse) ? 14 : 7)
            .scaleEffect(settled ? 1 : (face.isCrit ? 1.9 : 1.72))
            .offset(y: settled ? 0 : -height * 0.34)
            .rotation3DEffect(.degrees(settled ? 0 : (face.isCrit ? 26 : 18)), axis: (x: 1, y: 0, z: 0))
            .blur(radius: settled ? 0 : 5)
            // A die that can no longer feed anything steps back a little so the
            // live ones read clean — no colour, just weight.
            .opacity(isDeadWeight(face) ? 0.6 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .draggable(face.id.uuidString)
        .onAppear {
            // The reel drops the last inch and slams into its detent.
            flash = 1
            withAnimation(.spring(response: face.isCrit ? 0.3 : 0.24, dampingFraction: 0.4)) {
                settled = true
            }
            withAnimation(.easeOut(duration: face.isCrit ? 0.5 : 0.34)) { shock = 1 }
            withAnimation(.easeOut(duration: face.isCrit ? 0.42 : 0.26)) { flash = 0 }
            if face.isCrit {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { critFlash = true }
                withAnimation(.easeOut(duration: 0.72)) { sparkBurst = 1 }
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { frostPulse = true }
        }
    }

    /// How many chains this die could still feed from where the plan stands.
    private func count(_ face: RolledFace) -> Int { chainCounts[face.id] ?? 0 }

    /// A die that nothing left in reach can use.
    private func isDeadWeight(_ face: RolledFace) -> Bool {
        !freezeArmed && !chainCounts.isEmpty && count(face) == 0
    }

    /// The letters carved on a die: every chain the combo panel lists that
    /// this die could feed, coloured to match the list. Tap the panel entry to
    /// fuse the chain; the letters fall away as dice commit elsewhere.
    @ViewBuilder
    private func chainCountBadge(_ face: RolledFace) -> some View {
        let markers = engine.comboMarkers[face.id] ?? []
        if !markers.isEmpty && !freezeArmed {
            HStack(spacing: 1.5) {
                ForEach(Array(markers.prefix(3).enumerated()), id: \.offset) { _, marker in
                    Text(marker.letter)
                        .font(.system(size: max(7.5, width * 0.1), weight: .black))
                        .foregroundStyle(Theme.bg)
                        .frame(width: max(10, width * 0.15), height: max(10, width * 0.15))
                        .background(marker.color, in: .circle)
                        .overlay(Circle().strokeBorder(Theme.bg.opacity(0.6), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 1.5)
            .background(Theme.bg.opacity(0.85), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.rule.opacity(0.45), lineWidth: 1))
            .padding(4)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }

    /// Adjustable Nock: a held arrow may count one tier up or down, once a
    /// turn — tap again on the shifted arrow to set it back true.
    @ViewBuilder
    private func nockControls(_ face: RolledFace) -> some View {
        if engine.nockAvailable(for: face.id) {
            HStack(spacing: 2) {
                nockButton(face.id, up: false)
                nockButton(face.id, up: true)
            }
            .padding(3)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private func nockButton(_ faceID: UUID, up: Bool) -> some View {
        Button {
            engine.nockShift(faceID: faceID, up: up)
        } label: {
            Image(systemName: up ? "chevron.up" : "chevron.down")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Theme.ptahCopper)
                .frame(width: 15, height: 15)
                .background(Theme.bg.opacity(0.88), in: .circle)
                .overlay(Circle().strokeBorder(Theme.ptahCopper.opacity(0.7), lineWidth: 0.8))
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// White-hot bloom on the face at the instant of the lock.
    private func slamFlash(_ face: RolledFace) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(face.isCrit ? Theme.gold : Theme.parchment)
            .opacity(flash * (face.isCrit ? 0.75 : 0.4))
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// Gold badge that says CRIT without stealing the face's name.
    @ViewBuilder
    private func critBadge(_ face: RolledFace) -> some View {
        if face.isCrit && !isFrozen {
            HStack(spacing: 2) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: max(6.5, width * 0.075), weight: .black))
                Text("CRIT")
                    .font(.system(size: max(7, width * 0.085), weight: .black))
                    .kerning(0.6)
            }
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(
                LinearGradient(colors: [Theme.gold, Theme.ember], startPoint: .leading, endPoint: .trailing),
                in: .capsule
            )
            .shadow(color: Theme.gold.opacity(critFlash ? 0.9 : 0.4), radius: critFlash ? 8 : 3)
            .scaleEffect(critFlash ? 1.06 : 0.96)
            .offset(y: -6)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.5).combined(with: .opacity))
        }
    }

    /// Sparks thrown off the detent when a critical lands.
    @ViewBuilder
    private func critSparks(_ face: RolledFace) -> some View {
        if face.isCrit {
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    let angle = Double(index) / 10 * 2 * .pi
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? Theme.gold : Theme.ember)
                        .frame(width: 2.4, height: 9)
                        .offset(y: -height * 0.34)
                        .rotationEffect(.radians(angle))
                        .scaleEffect(0.5 + sparkBurst * 1.1)
                        .opacity((1 - sparkBurst) * 0.95)
                }
            }
            .blur(radius: 0.6)
            .allowsHitTesting(false)
        }
    }

    /// Ring thrown outward by the impact, twice over for a crit.
    private func shockRing(_ face: RolledFace) -> some View {
        let tint = face.isCrit ? Theme.gold : glowTint(face)
        return ZStack {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(tint, lineWidth: 3)
                .scaleEffect(1 + shock * (face.isCrit ? 0.55 : 0.34))
                .opacity((1 - Double(shock)) * (face.isCrit ? 0.95 : 0.6))
            if face.isCrit {
                RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(Theme.ember, lineWidth: 2)
                    .scaleEffect(1 + shock * 0.95)
                    .opacity((1 - Double(shock)) * 0.55)
            }
        }
        .blur(radius: 1.5)
        .allowsHitTesting(false)
    }

    /// Icy sheen drawn over a frozen (or carried-over) die.
    @ViewBuilder
    private var frostLayer: some View {
        if isFrozen || isHeld {
            RoundedRectangle(cornerRadius: corner)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.frost.opacity(isFrozen ? 0.34 : 0.16),
                            Theme.frost.opacity(isFrozen ? 0.10 : 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.frost.opacity(isFrozen ? 0.9 : 0.5))
                        .padding(4)
                }
                .opacity(isFrozen ? (frostPulse ? 1 : 0.75) : 1)
                .allowsHitTesting(false)
        }
    }

    /// While freeze mode is armed, every freezable die wears a breathing icy ring.
    @ViewBuilder
    private var armedHalo: some View {
        if freezeArmed && !isFrozen {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.frost.opacity(frostPulse ? 0.95 : 0.4),
                              style: StrokeStyle(lineWidth: 2.4, dash: [4.5, 4]))
                .shadow(color: Theme.frost.opacity(frostPulse ? 0.6 : 0.2), radius: 8)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Styling helpers

    /// The settled reel's label — the face the engine will actually use,
    /// which is the true face unless a Chisel substituted a tier.
    private func reelLabel(_ face: RolledFace) -> String {
        face.matchFace.shortLabel
    }

    private func iconTint(_ face: RolledFace) -> Color {
        if face.isCrit { return Theme.gold }
        if isFrozen { return Theme.frost }
        if let patron = face.patron { return patron.tint }
        return face.matchFace.tint
    }

    private func borderTint(_ face: RolledFace) -> Color {
        if isFrozen { return Theme.frost }
        if face.effectiveFace != nil { return Theme.ptahCopper }
        if face.isCrit { return Theme.gold }
        if isHeld { return Theme.frost.opacity(0.6) }
        if let patron = face.patron { return patron.tint.opacity(0.85) }
        return face.face.tint.opacity(0.55)
    }

    private func glowTint(_ face: RolledFace) -> Color {
        if isFrozen { return Theme.frost }
        if let patron = face.patron { return patron.tint }
        return face.isCrit ? Theme.gold : face.face.tint
    }

    private func bottomTagTint(_ face: RolledFace) -> Color {
        if isFrozen { return Theme.frost }
        return face.isCrit ? Theme.gold : Theme.parchment.opacity(0.85)
    }

    /// Quick "what will this do" tag under the face icon — read from the
    /// substituted tier when a Chisel has shifted the face.
    private func bottomTag(_ face: RolledFace) -> String {
        if isFrozen { return "HELD NEXT" }
        guard face.isCrit else { return face.matchFace.soloTag }
        let value = GameData.scaleUp(face.matchFace.soloValue, by: GameData.faceCritMultiplier)
        switch face.face.soloKind {
        case .damage: return "\(value) dmg"
        case .block: return "+\(value) shield"
        case .heal: return "+\(value) hp"
        case .poison: return "\(value) psn"
        case .stamina: return "+2 stam"
        case .evade: return face.isCrit ? "+20% evd" : "+15% evd"
        case .focus: return "focus"
        }
    }

    private func emptyReel(icon: String) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .strokeBorder(Theme.parchmentDim.opacity(0.14), style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.3))
            }
    }

    private var reelName: some View {
        Text(slot.isCarried ? "Held · \(slot.die.name)" : slot.die.name)
            .font(.system(size: max(7.5, width * 0.095), weight: .semibold))
            .foregroundStyle(Theme.parchmentDim)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 3)
    }
}
