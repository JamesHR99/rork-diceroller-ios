import SwiftUI

/// The roll tray. It takes over the middle of the arena during your turn — one
/// pull rolls every die that isn't frozen, then you tap faces into the plan.
/// Freezing is armed from the play bar. The whole tray clears away once the
/// turn is committed so the fighters have the stage to themselves.
struct DiceTrayView: View {
    let engine: BattleEngine
    /// The tallest a reel may run. The deck measures the screen it has to fit
    /// into and hands this down, so a short landscape iPhone keeps the whole
    /// deck — dice and turn plan both — above the bottom edge.
    var maxReelHeight: CGFloat = 138
    /// The widest the whole row may run, measured by the deck. The dice are cut
    /// from this, so the row never pushes the lever or the last die off the
    /// side of the screen.
    var maxRowWidth: CGFloat = 690

    @State private var slamKick: CGFloat = 0
    @State private var slamFlare: Double = 0

    private var freezeArmed: Bool { engine.freezeArmed }

    /// Dice grow to fill the deck, shrinking only once the row gets long — and
    /// never past the width the deck actually has. A freeze adds a carried reel
    /// on top of the loadout, so the row can run one wider than the dice cap;
    /// cutting the reels from the measured width is what keeps the outermost
    /// die on screen when it does.
    private var reelWidth: CGFloat {
        let count = max(engine.slots.count, 1)
        let ideal: CGFloat = count <= 6 ? 100 : (count <= 8 ? 88 : 74)
        // The lever's lane is reserved whether or not ROLL is showing, so the
        // dice keep one size for the whole turn instead of jumping wider the
        // moment the lever is pulled.
        let leverLane: CGFloat = 113
        let bedPadding: CGFloat = 22
        let gaps = reelGap * CGFloat(count - 1)
        let free = maxRowWidth - leverLane - bedPadding - gaps
        return max(46, min(ideal, free / CGFloat(count)))
    }

    private var reelGap: CGFloat { engine.slots.count > 7 ? 6 : 8 }

    private var reelHeight: CGFloat { min(maxReelHeight, reelWidth * 1.3) }

    /// The full combo rail under the tray: every chain spelled out with its
    /// name, effect, cost and Chisel badge. Off by default — the letters
    /// carved under each die carry the same read in a fraction of the height,
    /// and the arena is short. The rail is kept whole so it can be switched
    /// back on by flipping this to true.
    static let showsComboRail = false

    var body: some View {
        VStack(spacing: 9) {
            header

            HStack(spacing: 9) {
                leadingControl

                HStack(spacing: reelGap) {
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
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background { reelBed }
            }

            comboPanel
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
        // The tray takes its height from its content but never more width than
        // the deck gives it — sizing itself horizontally is what used to drag
        // the whole shelf wider than the screen and carry the stamina rail and
        // the FIGHT slab off both edges.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
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

    /// The stone bed the reels are set into: a sunken channel of dark papyrus
    /// with a gilded rim, so the row of dice reads as carved into the deck
    /// rather than a run of floating chips. It flares gold each time a reel
    /// slams into its detent.
    private var reelBed: some View {
        ZStack {
            PapyrusSurface(ground: .panel, tint: Theme.bg, strength: 0.65, shade: 0.5)
                .clipShape(.rect(cornerRadius: 20))

            // The channel's own shading: dark at the lip, open in the middle.
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(.rect(cornerRadius: 20))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: freezeArmed
                            ? [Theme.frost.opacity(0.85), Theme.frost.opacity(0.25)]
                            : [Theme.gold.opacity(0.6), Theme.goldDeep.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: freezeArmed ? 2 : 1.5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 3.5)
                .strokeBorder(Theme.rule.opacity(0.2), lineWidth: 0.75)
        )
        .overlay {
            // Gold bloom washing out of the channel each time a reel lands.
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.gold, lineWidth: 3)
                .blur(radius: 6)
                .opacity(slamFlare * 0.9)
        }
        .overlay(alignment: .top) {
            HieroglyphBand(tint: freezeArmed ? Theme.frost : Theme.gold, height: 8, opacity: 0.22)
                .padding(.horizontal, 20)
                .padding(.top, 2)
        }
        .shadow(color: Theme.gold.opacity(slamFlare * 0.5), radius: 26)
        .shadow(color: .black.opacity(0.55), radius: 14, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: freezeArmed)
        .allowsHitTesting(false)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(headerTitle)
                .font(.fantasy(13, weight: .black))
                .kerning(1.6)
                .foregroundStyle(freezeArmed ? Theme.frost : Theme.gold)

            // Chisels of Ptah, struck in his copper beside the title.
            if !engine.chisels.isEmpty {
                HStack(spacing: 2) {
                    ForEach(engine.chisels.sorted(), id: \.self) { id in
                        DuatSymbol(art: DuatArt.chisel(id),
                                   fallback: ChiselCatalog.def(id)?.symbol ?? "hammer.fill",
                                   size: 13,
                                   tint: Theme.ptahCopper)
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
                    DuatSymbol(art: DuatArt.interactionHeld, fallback: "snowflake",
                               size: 12, tint: Theme.frost)
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
                    DuatSymbol(art: DuatArt.interactionHeld, fallback: "snowflake",
                               size: 12, tint: Theme.frost.opacity(0.8))
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
            DuatImage(name: DuatArt.chainConnector, width: 14, fit: .fit)
                .colorMultiply(Theme.parchment)
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
            let count = engine.comboCandidates.count
            return "Tap a letter under a die to fuse that chain · \(count) in reach"
        }
        return "Chain faces together — alone they barely scratch · FREEZE holds one face"
    }

    // MARK: - Combo panel

    /// Every chain the roll could still make: name, effect, ingredients and
    /// stamina, with a letter that matches the markers under the dice feeding
    /// it. Tap to fuse; tap a planned one to dissolve it back into solos.
    @ViewBuilder
    private var comboPanel: some View {
        if Self.showsComboRail && !engine.canRoll && !engine.isRolling && !engine.comboCandidates.isEmpty {
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
                        DuatSymbol(art: badgeChisel.artName ?? DuatArt.upgradeHammer,
                                   fallback: "hammer.fill",
                                   size: 13,
                                   tint: armed ? Theme.bg : Theme.ptahCopper)
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
            RollLeverButton(height: reelHeight + 18) { engine.rollAll() }
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
    /// The face drawing is the whole point of a die, so it is drawn as large
    /// as the window allows — a small plate scaled up reads grainy, a large
    /// one reads painted.
    private var iconSize: CGFloat { width * 0.40 }
    private var labelSize: CGFloat { max(10, width * 0.135) }
    /// A claimed die's face carries its name in bigger type — the god's
    /// blessing is part of the read that decides a turn.
    private func labelSize(for face: RolledFace) -> CGFloat {
        face.patron == nil ? labelSize : max(12.5, width * 0.175)
    }
    private var tagSize: CGFloat { max(9.5, width * 0.135) }

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
                    emptyReel(spent: false)
                } else {
                    settledReel(face)
                }
            case .spent:
                emptyReel(spent: true)
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
            Spacer(minLength: 0)
            reelName
        }
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { reelGround(opacity: 0.35) }
        .clipShape(.rect(cornerRadius: corner))
        .dieFrame(.empty, opacity: 0.75)
    }

    /// The papyrus face of a die: the same paper the rest of the game is
    /// painted on, sunk behind the open window of the painted frame so a reel
    /// reads as carved bone rather than a flat dark rectangle.
    private func reelGround(opacity: Double) -> some View {
        PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.7, shade: 0.52)
            .opacity(opacity)
            .overlay {
                // A lit top and a shadowed foot so the face has a little relief.
                LinearGradient(
                    colors: [Theme.parchment.opacity(0.09), .clear, Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(.rect(cornerRadius: corner))
            .allowsHitTesting(false)
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
                DuatSymbol(art: ghostAbove.kind.artName, fallback: ghostAbove.kind.symbol,
                           size: iconSize * 0.88, tint: ghostAbove.kind.tint)
                    .opacity(0.22)
                    .offset(y: -iconSize * 0.92)
                DuatSymbol(art: ghostBelow.kind.artName, fallback: ghostBelow.kind.symbol,
                           size: iconSize * 0.88, tint: ghostBelow.kind.tint)
                    .opacity(0.22)
                    .offset(y: iconSize * 0.92)

                DuatSymbol(art: face.kind.artName, fallback: face.kind.symbol,
                           size: iconSize * 1.12, tint: face.kind.tint)
                    .opacity(drumSpeed == 0 ? 1 : 0.85)
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
        .background { reelGround(opacity: 0.75) }
        .overlay {
            // Curved-glass shading so the reel reads as a spinning drum.
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: corner))
        .dieFrame(.rolling, tint: imminent ? Theme.gold : nil)
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
                DuatSymbol(art: face.matchFace.artName,
                           fallback: face.matchFace.symbol,
                           size: iconSize * 1.2,
                           tint: iconTint(face))
                    .modifier(FaceWash(tint: iconTint(face), active: face.isCrit || isFrozen))
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
            .background { reelGround(opacity: 1) }
            .overlay { frostLayer }
            .clipShape(.rect(cornerRadius: corner))
            .dieFrame(settledFrame(face), tint: frameTint(face))
            .overlay { armedHalo }
            .overlay(alignment: .topTrailing) {
                if face.imbueTiers > 0 {
                    DuatIcon(name: DuatArt.interactionImbue, size: 15).padding(3)
                }
            }
            .overlay(alignment: .topLeading) {
                // A patron god's sigil rides the die whose faces they answer.
                if let patron = face.patron {
                    DuatSymbol(art: patron.artName, fallback: patron.symbol,
                               size: 17, tint: patron.tint)
                        .frame(width: 23, height: 23)
                        .background(Theme.bg.opacity(0.85), in: .circle)
                        .overlay(Circle().strokeBorder(patron.tint.opacity(0.8), lineWidth: 1))
                        .padding(3)
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
        // The chain letters ride outside the die's own button so their taps
        // land on them rather than on the die underneath.
        .overlay(alignment: .bottomLeading) { chainCountBadge(face) }
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

    /// Which painted frame a settled reel wears. A held face and a critical
    /// each have their own drawing; everything else is a ready die.
    private func settledFrame(_ face: RolledFace) -> DuatArt.DieFrame {
        if isFrozen || isHeld { return .held }
        if face.isCrit { return .critical }
        return .ready
    }

    /// The colour washed over the painted frame — the state coding the border
    /// used to carry.
    private func frameTint(_ face: RolledFace) -> Color? {
        if isFrozen { return Theme.frost }
        if face.effectiveFace != nil { return Theme.ptahCopper }
        if face.isCrit { return nil }
        if isHeld { return Theme.frost }
        if let patron = face.patron { return patron.tint }
        return nil
    }

    /// How many chains this die could still feed from where the plan stands.
    private func count(_ face: RolledFace) -> Int { chainCounts[face.id] ?? 0 }

    /// A die that nothing left in reach can use.
    private func isDeadWeight(_ face: RolledFace) -> Bool {
        !freezeArmed && !chainCounts.isEmpty && count(face) == 0
    }

    /// The letters carved on a die: every chain this die could feed, each in
    /// its chain's own colour. These are the whole combo read now that the
    /// rail under the tray is folded away — tap a letter to fuse that chain,
    /// tap a gold one to dissolve it. Letters fall away as dice commit
    /// elsewhere, so a die's remaining options are always literally on it.
    @ViewBuilder
    private func chainCountBadge(_ face: RolledFace) -> some View {
        let markers = engine.comboMarkers[face.id] ?? []
        if !markers.isEmpty && !freezeArmed {
            HStack(spacing: 2.5) {
                ForEach(markers.prefix(4)) { marker in
                    chainLetter(marker)
                }
                if markers.count > 4 {
                    Text("+\(markers.count - 4)")
                        .font(.system(size: max(8, width * 0.1), weight: .black))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(Theme.bg.opacity(0.85), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.rule.opacity(0.45), lineWidth: 1))
            .padding(4)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }

    /// One tappable chain letter. A planned chain wears gold and a ring so a
    /// glance tells you which chains you have already committed to.
    private func chainLetter(_ marker: ComboMarker) -> some View {
        let diameter = max(16, width * 0.215)
        return Button {
            engine.toggleCombo(marker.comboID)
        } label: {
            Text(marker.letter)
                .font(.system(size: max(10, width * 0.135), weight: .black))
                .foregroundStyle(Theme.bg)
                .frame(width: diameter, height: diameter)
                .background(marker.isPlanned ? Theme.gold : marker.color, in: .circle)
                .overlay(
                    Circle().strokeBorder(marker.isPlanned ? Theme.gold : Theme.bg.opacity(0.6),
                                          lineWidth: marker.isPlanned ? 1.6 : 0.5)
                        .padding(marker.isPlanned ? -1.6 : 0)
                )
                .shadow(color: marker.isPlanned ? Theme.gold.opacity(0.7) : .clear, radius: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(marker.name), \(marker.staminaCost) stamina")
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
            DuatImage(name: DuatArt.utilityForward, width: 12, fit: .fit)
                .colorMultiply(Theme.ptahCopper)
                .rotationEffect(.degrees(up ? -90 : 90))
                .frame(width: 19, height: 19)
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
            HStack(spacing: 2.5) {
                DuatIcon(name: DuatArt.Status.critical, size: max(11, width * 0.13))
                Text("CRIT")
                    .font(.system(size: max(8.5, width * 0.1), weight: .black))
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
                    DuatIcon(name: DuatArt.interactionHeld, size: 18)
                        .opacity(isFrozen ? 0.95 : 0.55)
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

    /// A reel whose face has gone down to the plan, or been spent outright.
    private func emptyReel(spent: Bool) -> some View {
        Color.clear
            .background { reelGround(opacity: spent ? 0.5 : 0.3) }
            .dieFrame(spent ? .spent : .empty, opacity: spent ? 0.8 : 0.6)
            .overlay {
                if spent {
                    DuatIcon(name: DuatArt.interactionSpent, size: 26)
                        .opacity(0.65)
                }
            }
    }

    private var reelName: some View {
        Text(slot.isCarried ? "Held · \(slot.die.name)" : slot.die.name)
            .font(.system(size: max(8.5, width * 0.105), weight: .semibold))
            .foregroundStyle(Theme.parchmentDim)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 3)
    }
}
