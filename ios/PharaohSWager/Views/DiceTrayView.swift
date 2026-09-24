import SwiftUI

/// The roll tray. It takes over the middle of the arena during your turn — one
/// pull rolls every die that isn't frozen, then you tap faces into the plan.
/// Freezing is armed from the play bar. The whole tray clears away once the
/// turn is committed so the fighters have the stage to themselves.
struct DiceTrayView: View {
    let engine: BattleEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The tallest a reel may run. The deck measures the screen it has to fit
    /// into and hands this down, so a short landscape iPhone keeps the whole
    /// deck — dice and turn plan both — above the bottom edge.
    var maxReelHeight: CGFloat = 138
    /// The widest the whole row may run, measured by the deck. The dice are cut
    /// from this, so the row never pushes the lever or the last die off the
    /// side of the screen.
    var maxRowWidth: CGFloat = 690
    var compact = false

    @State private var slamKick: CGFloat = 0
    @State private var slamFlare: Double = 0

    private var selectingReroll: Bool { engine.selectingReroll }

    /// Dice grow to fill the deck, shrinking only once the row gets long — and
    /// never past the width the deck actually has. A freeze adds a carried reel
    /// on top of the loadout, so the row can run one wider than the dice cap;
    /// cutting the reels from the measured width is what keeps the outermost
    /// die on screen when it does.
    private var reelWidth: CGFloat {
        let count = max(engine.slots.count, 1)
        let ideal: CGFloat = count <= 6 ? 100 : (count <= 8 ? 88 : 74)
        // The compact battle shelf has to fit five physical dice, the roll
        // lever and both action controls on a phone. Use a much smaller lever
        // lane and bed inset there instead of letting the dice be squeezed to
        // almost zero width by desktop-sized chrome.
        let leverLane = leverWidth + (compact ? 4 : 8)
        let bedPadding: CGFloat = compact ? 8 : 20
        let gaps = reelGap * CGFloat(count - 1)
        let free = maxRowWidth - leverLane - bedPadding - gaps
        return max(compact ? 22 : 1, min(maxReelHeight, min(ideal, free / CGFloat(count))))
    }

    private var leverWidth: CGFloat {
        if compact { return 46 }
        return maxRowWidth < 620 ? 72 : 88
    }
    private var reelGap: CGFloat { compact ? 3 : 6 }

    private var reelHeight: CGFloat { reelWidth }

    var body: some View {
        VStack(spacing: compact ? 0 : 5) {
            if !compact { header }

            HStack(spacing: compact ? 4 : 8) {
                leadingControl

                HStack(spacing: 0) {
                    HStack(spacing: reelGap) {
                        ForEach(engine.slots) { slot in
                            DiceTrayReelView(
                                slot: slot,
                                engine: engine,
                                width: reelWidth,
                                height: reelHeight
                            )
                            .anchorPreference(key: RerollChargeAnchorKey.self, value: .bounds) {
                                [slot.id.uuidString: $0]
                            }
                            .overlay {
                                if engine.rerollChargeFlights.contains(slot.id) {
                                    RoundedRectangle(cornerRadius: 12).stroke(Theme.gold, lineWidth: 3)
                                        .shadow(color: Theme.gold, radius: 12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .frame(height: reelHeight + 12)
                .background { reelBed }
            }
        }
        .padding(.horizontal, compact ? 0 : 14)
        .padding(.top, compact ? 2 : 6)
        .padding(.bottom, 2)
        // The tray takes its height from its content but never more width than
        // the deck gives it — sizing itself horizontally is what used to drag
        // the whole shelf wider than the screen and carry the stamina rail and
        // the FIGHT slab off both edges.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .offset(y: reduceMotion ? 0 : slamKick)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectingReroll)
        .onChange(of: engine.slamPulse) { _, _ in
            let heavy = engine.lastReelLocked
            slamKick = heavy ? 1.5 : 0
            slamFlare = heavy ? 0.65 : 0.2
            withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) { slamKick = 0 }
            withAnimation(.easeOut(duration: 0.18)) { slamFlare = 0 }
        }
        .onAppear {
            ReelSymbolCache.prepare(engine.slots.map(\.die))
            Audio.shared.prepareDiceRoll()
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
                        colors: selectingReroll
                            ? [Theme.frost.opacity(0.85), Theme.frost.opacity(0.25)]
                            : [Theme.gold.opacity(0.6), Theme.goldDeep.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: selectingReroll ? 2 : 1.5
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
            HieroglyphBand(tint: selectingReroll ? Theme.frost : Theme.gold, height: 8, opacity: 0.22)
                .padding(.horizontal, 20)
                .padding(.top, 2)
        }
        .shadow(color: Theme.gold.opacity(slamFlare * 0.5), radius: 26)
        .shadow(color: .black.opacity(0.55), radius: 14, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectingReroll)
        .allowsHitTesting(false)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(headerTitle)
                .font(.fantasy(13, weight: .black))
                .kerning(1.6)
                .foregroundStyle(selectingReroll ? Theme.frost : Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            // Chisels of Ptah, struck in his copper beside the title. A
            // Chisel's rule is otherwise only legible on the card it came
            // from, so each mark opens its own explanation.
            if !engine.chisels.isEmpty {
                HStack(spacing: 2) {
                    ForEach(engine.chisels.sorted(), id: \.self) { id in
                        chiselMark(id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.bg.opacity(0.7), in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.ptahCopper.opacity(0.4), lineWidth: 1))
            }

            Spacer(minLength: 6)

            Text(selectingReroll
                 ? "TAP A DIE"
                 : "\(engine.rerollChargeText)/\(engine.rerollCapacity) REROLL CHARGES")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Theme.gold)

        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(height: 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: engine.rerollSelection.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectingReroll)
    }

    /// One copper Chisel mark. Tapping it opens the rule the Chisel is quietly
    /// applying to your whole weapon, which is otherwise only written on the
    /// card you first took it from.
    private func chiselMark(_ id: String) -> some View {
        let tooltipID = "tray.chisel.\(id)"
        let isOpen = TooltipCenter.shared.isOpen(tooltipID)
        return Button {
            Haptics.light()
            Audio.shared.play(.uiTap)
            TooltipCenter.shared.toggle(tooltipID)
        } label: {
            PharaohSWagerSymbol(art: PharaohSWagerArt.chisel(id),
                       fallback: ChiselCatalog.def(id)?.symbol ?? "hammer.fill",
                       size: 13,
                       tint: Theme.ptahCopper)
                .padding(2)
                .background(Theme.ptahCopper.opacity(isOpen ? 0.28 : 0), in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
        // The bubble is drawn by the root tooltip layer, so it floats above the
        // deck and the dice instead of being clipped by this capsule.
        .tooltipAnchor(id: tooltipID, payload: isOpen
            ? ChiselCatalog.def(id).map { .chisel($0, isArmed: engine.isChiselArmed(id)) }
            : nil)
    }

    private var headerTitle: String {
        if selectingReroll { return "SELECT DICE" }
        if engine.canRoll { return "YOUR DICE" }
        if engine.isRolling { return "LOCKING \(engine.lockedReelCount)/\(engine.slots.count)" }
        return "YOUR ROLL"
    }

    // MARK: - Combo panel

    // MARK: - Roll control

    private var leadingControl: some View {
        RollLeverButton(height: reelHeight, width: leverWidth,
                        isEnabled: engine.canRoll, isRolling: engine.isRolling) {
            engine.rollAll(reduceMotion: reduceMotion)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var settled = false
    @State private var critFlash = false
    /// Shockwave ring thrown off the moment the reel locks.
    @State private var shock: CGFloat = 0
    /// Spark burst thrown off a critical as it slams home.
    @State private var sparkBurst: Double = 0
    @State private var flash: Double = 0
    /// Adjustable Nock: which way the face last shifted, so the arrow visibly
    /// travels up or down rather than silently becoming another tier.
    @State private var nockNudge: CGFloat = 0

    private var selectingReroll: Bool { engine.selectingReroll }

    private var corner: CGFloat { 15 }
    /// The battle shelf uses deliberately compact, icon-first dice. Taller
    /// presentation captures (and any future detail view) keep the face name
    /// and tag, but the live hand reads like physical dice rather than cards.
    private var dense: Bool { height < 88 }
    private var iconSize: CGFloat {
        if dense {
            return max(22, min(34, min(width * 0.48, height * 0.46)))
        }
        return max(13, min(29, min(width * 0.29, (height - 46) * 0.52)))
    }
    private var labelSize: CGFloat { max(8.5, min(10.5, width * 0.105)) }
    private func labelSize(for face: RolledFace) -> CGFloat {
        face.patron == nil ? labelSize : min(10.5, labelSize + 0.75)
    }
    private var tagSize: CGFloat { max(8, min(9.5, width * 0.095)) }

    var body: some View {
        Group {
            switch slot.state {
            case .idle:
                idleReel
            case .rolling:
                spinningReel
            case .rolled(let face):
                settledReel(face)
            case .spent:
                emptyReel(spent: true)
            }
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.playOrder)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectingReroll)
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
        VStack(spacing: 2) {
            SlotReelView(
                faces: slot.die.faces.map(\.kind),
                landing: engine.landingFace(slotID: slot.id) ?? .block,
                rollID: engine.rollID,
                startedAt: engine.rollStartedAt,
                duration: engine.lockTime(slotID: slot.id),
                symbolSize: iconSize,
                reduceMotion: reduceMotion
            )
            .frame(width: iconSize, height: iconSize)
            .accessibilityHidden(true)

            if !dense {
                Text("ROLLING")
                    .font(.system(size: labelSize, weight: .heavy))
                    .foregroundStyle(Theme.gold.opacity(0.8))
                Text("···")
                    .font(.system(size: tagSize, weight: .black))
                    .foregroundStyle(Theme.parchmentDim)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { reelGround(opacity: 0.75) }
        .overlay {
            LinearGradient(
                colors: [Color.black.opacity(0.45), .clear, .clear, Color.black.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: corner))
        .dieFrame(.rolling)
        .onAppear { resetLandingAnimation() }
        .accessibilityLabel("Rolling \(slot.die.name)")
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
    }

    // MARK: - Settled die

    private func settledReel(_ face: RolledFace) -> some View {
        Button {
            if selectingReroll {
                engine.reroll(slotID: slot.id, reduceMotion: reduceMotion)
            } else if engine.armingChisel != nil, engine.armHeldChisel(ontoFace: face.id) {
                // Optional Chisels now attach through a selected die because
                // the old action-plan cards no longer exist.
            } else {
                engine.toggleActionSelection(faceID: face.id)
            }
        } label: {
            VStack(spacing: 1) {
                PharaohSWagerSymbol(art: face.matchFace.artName,
                           fallback: face.matchFace.symbol,
                           size: iconSize,
                           tint: iconTint(face))
                    .modifier(FaceWash(tint: iconTint(face), active: face.isCrit))
                    // The shifted arrow slides into its new tier, so the
                    // change is something you watch happen.
                    .offset(y: nockNudge)
                    .id(face.matchFace)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                // The face that actually landed always keeps its name — a crit
                // is announced by the badge and the gold, never by hiding the
                // roll you are trying to read. A Chisel substitution shows the
                // tier the engine will use, in Ptah's copper.
                if !dense {
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
                        .minimumScaleFactor(0.5)
                        .frame(width: max(1, width * 0.66))
                }
            }
            .padding(.horizontal, max(8, width * 0.1))
            .padding(.vertical, max(9, height * 0.075))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { reelGround(opacity: 1) }
            .clipShape(.rect(cornerRadius: corner))
            .dieFrame(settledFrame(face), tint: frameTint(face))
            .overlay {
                if engine.playOrder.contains(face.id) && !selectingReroll {
                    RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(Theme.gold, lineWidth: 3)
                        .shadow(color: Theme.gold.opacity(0.8), radius: 10)
                        .padding(2)
                }
            }
            .overlay(alignment: .bottom) {
                if engine.playOrder.contains(face.id) && !selectingReroll {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 22, height: 22)
                        .background(Theme.gold, in: .circle)
                        .overlay(Circle().strokeBorder(Theme.parchment.opacity(0.9), lineWidth: 1))
                        .shadow(color: .black.opacity(0.8), radius: 3, y: 1)
                        .offset(y: 8)
                }
            }
            .overlay { armedHalo(face) }
            .overlay(alignment: .topTrailing) {
                if face.imbueTiers > 0 {
                    PharaohSWagerIcon(name: PharaohSWagerArt.interactionImbue, size: 15).padding(3)
                }
            }
            .overlay(alignment: .topLeading) {
                // A patron god's sigil rides the die whose faces they answer.
                if let patron = face.patron {
                    PharaohSWagerSymbol(art: patron.artName, fallback: patron.symbol,
                               size: 17, tint: patron.tint)
                        .frame(width: 23, height: 23)
                        .background(Theme.bg.opacity(0.85), in: .circle)
                        .overlay(Circle().strokeBorder(patron.tint.opacity(0.8), lineWidth: 1))
                        .padding(3)
                }
            }
            .overlay(alignment: .top) { critBadge(face) }
            .overlay(alignment: .bottom) {
                VStack(spacing: 2) {
                    heldBoonTag(face)
                    nockTag(face)
                }
                .offset(y: 7)
            }
            .overlay(alignment: .bottomTrailing) { nockControls(face) }
            .overlay { slamFlash(face) }
            .overlay { if !reduceMotion { shockRing(face) } }
            .overlay { if !reduceMotion { critSparks(face) } }
            .shadow(color: glowTint(face).opacity(face.isCrit ? 0.8 : 0.35),
                    radius: face.isCrit && critFlash ? 14 : 7)
            .scaleEffect(reduceMotion || settled ? 1 : 1.045)
            .offset(y: reduceMotion || settled ? 0 : -3)
        }
        .contextMenu {
            if let step = engine.step(containing: face.id),
               let action = step.combo,
               action.dodgeCharges > 0,
               step.faces.prefix(action.dodgeCharges).contains(where: { $0.id == face.id }) {
                Menu("Evade target: \(engine.evadeTargetLabel(faceID: face.id))") {
                    Button("Next strike") {
                        engine.assignEvade(faceID: face.id, strikeID: nil)
                    }
                    ForEach(engine.incomingStrikes) { strike in
                        Button(strike.title) {
                            engine.assignEvade(faceID: face.id, strikeID: strike.id)
                        }
                    }
                }
            }

            ForEach(engine.conversionOptions(for: face), id: \.self) { kind in
                Button("Convert to \(kind.label)") { engine.convert(faceID: face.id, to: kind) }
            }
            if engine.canPrepareManually {
                Button("Anubis: Prepare this die") { engine.prepareManually(faceID: face.id) }
            }
            if engine.canMakeCritical && !face.isCrit {
                Button("Horus: Make critical") { engine.makeCritical(faceID: face.id) }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(face.matchFace.label)
        .accessibilityValue(engine.playOrder.contains(face.id) ? "Selected" : "Not selected")
        .draggable(face.id.uuidString)
        .onAppear {
            // The reel drops the last inch and slams into its detent.
            flash = reduceMotion ? 0 : 0.55
            withAnimation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.76)) {
                settled = true
            }
            withAnimation(.easeOut(duration: face.isCrit ? 0.5 : 0.34)) { shock = 1 }
            withAnimation(.easeOut(duration: face.isCrit ? 0.42 : 0.26)) { flash = 0 }
            if face.isCrit && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { critFlash = true }
                withAnimation(.easeOut(duration: 0.72)) { sparkBurst = 1 }
            }
        }
    }

    /// Reroll retention can still trigger boons, but it no longer turns an
    /// untouched die into the old frozen/held visual. Only the face itself
    /// determines its painted frame.
    private func settledFrame(_ face: RolledFace) -> PharaohSWagerArt.DieFrame {
        face.isCrit ? .critical : .ready
    }

    private func frameTint(_ face: RolledFace) -> Color? {
        if face.effectiveFace != nil { return Theme.ptahCopper }
        if face.isCrit { return nil }
        if let patron = face.patron { return patron.tint }
        return nil
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
            // Kick the glyph the way it is travelling, then let it settle on
            // the new tier: the die itself reports the shift.
            withAnimation(.easeOut(duration: 0.12)) { nockNudge = up ? -9 : 9 }
            engine.nockShift(faceID: faceID, up: up)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { nockNudge = 0 }
            Audio.shared.play(.uiTap)
        } label: {
            PharaohSWagerImage(name: PharaohSWagerArt.utilityForward, width: 12, fit: .fit)
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

    /// A held die wearing the god who is watching it. Holding a face is only
    /// worth it because some blessing answers held faces, so the die says
    /// which god and what they will add rather than leaving you to guess
    /// whether the bonus arrived.
    @ViewBuilder
    private func heldBoonTag(_ face: RolledFace) -> some View {
        if let held = engine.heldBoon(forFace: face.id) {
            HStack(spacing: 2) {
                PharaohSWagerSymbol(art: held.god.artName, fallback: held.god.symbol,
                                    size: max(9, width * 0.1), tint: held.god.tint)
                Text(held.effect.uppercased())
                    .font(.system(size: max(7, width * 0.082), weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundStyle(held.god.tint)
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(Theme.bg.opacity(0.9), in: .capsule)
            .overlay(Capsule().strokeBorder(held.god.tint.opacity(0.85), lineWidth: 0.9))
            .shadow(color: held.god.tint.opacity(0.7), radius: 5)
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    /// Gold badge that says CRIT without stealing the face's name.
    @ViewBuilder
    private func critBadge(_ face: RolledFace) -> some View {
        if face.isCrit {
            HStack(spacing: 2.5) {
                PharaohSWagerIcon(name: PharaohSWagerArt.Status.critical, size: max(11, width * 0.13))
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

    /// Reroll mode marks eligible dice with a light dashed target. It does
    /// not replace their frame or wash the face with the old freeze effect.
    /// While freeze mode is armed, every freezable die wears a breathing icy ring.
    @ViewBuilder
    private func armedHalo(_ face: RolledFace) -> some View {
        if selectingReroll {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.frost.opacity(engine.rerollSelection.contains(slot.id) ? 1 : 0.28),
                              style: StrokeStyle(lineWidth: 2, dash: [4.5, 4]))
                .shadow(color: Theme.frost.opacity(0.24), radius: 6)
                .allowsHitTesting(false)
        } else if engine.isChiselArmed(onFace: face.id) {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.ptahCopper, lineWidth: 2.4)
                .shadow(color: Theme.ptahCopper.opacity(0.7), radius: 8)
                .allowsHitTesting(false)
        } else if engine.armableChisel(forFace: face.id) != nil {
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(Theme.ptahCopper.opacity(0.8),
                              style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .shadow(color: Theme.ptahCopper.opacity(0.35), radius: 6)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Styling helpers

    /// The settled reel's label — the face the engine will actually use,
    /// which is the true face unless a Chisel substituted a tier.
    private func reelLabel(_ face: RolledFace) -> String {
        face.matchFace.shortLabel
    }

    /// A shifted arrow says so plainly, in Ptah's copper, with the tier it
    /// came from — so the substitution is never something you have to infer.
    @ViewBuilder
    private func nockTag(_ face: RolledFace) -> some View {
        if face.effectiveFace != nil {
            Text("NOCK \(face.face.shortLabel) → \(face.matchFace.shortLabel)")
                .font(.system(size: 7.5, weight: .black))
                .foregroundStyle(Theme.ptahCopper)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Theme.bg.opacity(0.9), in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.ptahCopper.opacity(0.8), lineWidth: 0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func iconTint(_ face: RolledFace) -> Color {
        if face.isCrit { return Theme.gold }
        if let patron = face.patron { return patron.tint }
        return face.matchFace.tint
    }

    private func borderTint(_ face: RolledFace) -> Color {
        if face.effectiveFace != nil { return Theme.ptahCopper }
        if face.isCrit { return Theme.gold }
        if let patron = face.patron { return patron.tint.opacity(0.85) }
        return face.face.tint.opacity(0.55)
    }

    private func glowTint(_ face: RolledFace) -> Color {
        if let patron = face.patron { return patron.tint }
        return face.isCrit ? Theme.gold : face.face.tint
    }

    private func bottomTagTint(_ face: RolledFace) -> Color {
        if selectingReroll { return Theme.frost }
        if engine.playOrder.contains(face.id) { return Theme.gold }
        return face.isCrit ? Theme.gold : Theme.parchmentDim
    }

    /// The compact tray intentionally avoids action maths. The face itself is
    /// the choice; the only extra state shown here is whether it is selected.
    private func bottomTag(_ face: RolledFace) -> String {
        if selectingReroll { return "REROLL" }
        if engine.isChiselArmed(onFace: face.id) { return "ARMED" }
        if engine.armableChisel(forFace: face.id) != nil { return "TAP TO ARM" }
        return engine.playOrder.contains(face.id) ? "SELECTED" : "TAP"
    }

    /// A reel whose face has gone down to the plan, or been spent outright.
    private func emptyReel(spent: Bool) -> some View {
        Color.clear
            .background { reelGround(opacity: spent ? 0.5 : 0.3) }
            .dieFrame(spent ? .spent : .empty, opacity: spent ? 0.8 : 0.6)
            .overlay {
                if spent {
                    PharaohSWagerIcon(name: PharaohSWagerArt.interactionSpent, size: 26)
                        .opacity(0.65)
                }
            }
    }

    private var reelName: some View {
        Text(slot.die.name)
            .font(.system(size: max(8.5, width * 0.105), weight: .semibold))
            .foregroundStyle(Theme.parchmentDim)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 3)
    }
}
