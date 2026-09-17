import SwiftUI

/// The overlay that appears whenever an upgrade needs a target: pick the die
/// and face to reforge or imbue, choose which die a god claims as patron,
/// or pick which die a new one replaces. God upgrades, capstones and pairings
/// need no target — they apply the moment they are taken, so they never reach
/// this overlay.
struct SelectionOverlayView: View {
    let selection: PendingSelection
    @Environment(GameManager.self) private var game

    @State private var chosenDieID: UUID?
    @State private var chosenFaceID: UUID?
    /// The equipped power a new one will take the place of.
    @State private var chosenBoonID: String?

    /// Can this face receive the offered work? Reforges and imbues land on
    /// any face; nothing is off limits any more.
    private func isEligible(_ face: DieFace) -> Bool {
        true
    }

    var body: some View {
        ZStack {
            Theme.bg.opacity(0.94).ignoresSafeArea()

            VStack(spacing: 10) {
                header

                switch selection {
                case .reforge, .reforgeDie, .imbue:
                    facePicker
                case .patron:
                    patronPicker
                case .replaceBoon(let def, let rarity):
                    boonReplacePicker(incoming: def, rarity: rarity)
                case .swapDie(let die):
                    dieSwapPicker(incoming: die)
                default:
                    facePicker
                }

                footer
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear(perform: selectOpeningDie)
    }

    /// The whetstone opens on your first die, so the six faces are already laid
    /// out large instead of an empty bench.
    private func selectOpeningDie() {
        switch selection {
        case .reforge, .reforgeDie, .imbue:
            guard chosenDieID == nil else { return }
            chosenDieID = carriedDice.first?.id
        case .patron:
            guard chosenDieID == nil else { return }
            chosenDieID = claimableDice.first?.id
        default:
            break
        }
    }

    /// Every die you carry, weapon first, then armour.
    private var carriedDice: [Die] {
        (game.loadout?.pieces ?? []).flatMap(\.dice)
    }

    /// Dice the standing god may claim: unblessed ones for a first claim —
    /// or every die, on the rare explicit replace cards.
    private var claimableDice: [Die] {
        switch selection {
        case .patron(_, let replace, _):
            return replace ? carriedDice : carriedDice.filter { $0.patron == nil }
        default:
            return carriedDice
        }
    }

    /// The die currently on the bench.
    private var workingDie: Die? {
        guard let chosenDieID else { return claimableDice.first ?? carriedDice.first }
        return claimableDice.first { $0.id == chosenDieID }
            ?? carriedDice.first { $0.id == chosenDieID }
            ?? claimableDice.first
    }

    private var claimDeity: Deity? {
        if case .patron(let deity, _, _) = selection { return deity }
        return nil
    }

    // MARK: - Header / footer

    private var isPatronReplace: Bool {
        if case .patron(_, let replace, _) = selection { return replace }
        return false
    }

    private var title: String {
        switch selection {
        case .reforge(_, let title): title
        case .reforgeDie(let title): title
        case .patron(_, _, let title): title
        case .imbue(_, let title): title
        case .swapDie: "Your dice are full"
        case .replaceBoon(let def, _): "Your \(def.slot.label.lowercased()) slots are full"
        default: ""
        }
    }

    private var subtitle: String {
        switch selection {
        case .reforge(let kind, _):
            "Choose any face on any die to reforge into \(kind.label) — \(kind.soloEffect.lowercased())."
        case .reforgeDie:
            "Pick a die along the rail — every face is rolled anew from your class's pool, at that die's rarity."
        case .patron(let deity, let replace, _):
            replace
                ? "\(deity.name) takes a die from whoever holds it. The faces never change — their blessing simply starts answering every face it plays. The old god's upgrades go quiet."
                : "\(deity.name) claims one of your unblessed dice. The faces never change — their blessing answers every face that die plays. Blessed dice open this god's upgrades."
        case .imbue(let amount, _):
            "Choose a face to etch. Its crit chance rises permanently by \(Int(amount * 100))%."
        case .swapDie(let die):
            "You carry \(Loadout.maxDice) dice. Pick one to replace with \(die.name)."
        case .replaceBoon(let def, _):
            "You carry \(def.slot.capacity) \(def.slot.label.lowercased()) powers. Choose which one \(def.name) takes the place of — its level and rarity are lost."
        default:
            ""
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PharaohSWagerSymbol(art: headerArt, fallback: headerSymbol,
                       size: 34, tint: claimDeity?.tint ?? Theme.gold)
                .frame(width: 50, height: 50)
                .background(Theme.bgCard, in: .circle)
                .overlay(Circle().strokeBorder((claimDeity?.tint ?? Theme.gold).opacity(0.4), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.fantasy(22, weight: .black))
                    .kerning(2)
                    .foregroundStyle(Theme.parchment)
                Text(subtitle)
                    .font(.paper(13))
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let preview = previewText {
                Text(preview)
                    .font(.system(size: 15, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.gold.opacity(0.14), in: .capsule)
                    .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
            }
        }
    }

    private var headerSymbol: String {
        switch selection {
        case .reforge(let kind, _): kind.symbol
        case .reforgeDie: "arrow.triangle.2.circlepath"
        case .patron(let deity, _, _): deity.symbol
        case .imbue: GameData.imbueSymbol(game.classID)
        case .swapDie: "arrow.triangle.2.circlepath"
        case .replaceBoon(let def, _): def.god.symbol
        default: "sparkles"
        }
    }

    /// The painted mark for whatever choice is being made.
    private var headerArt: String? {
        switch selection {
        case .reforge(let kind, _): kind.artName
        case .reforgeDie: PharaohSWagerArt.resolve(PharaohSWagerArt.interactionReforge)
        case .patron(let deity, _, _): deity.artName
        case .imbue: PharaohSWagerArt.resolve(PharaohSWagerArt.interactionImbue)
        case .swapDie: PharaohSWagerArt.resolve(PharaohSWagerArt.interactionSwap)
        case .replaceBoon(let def, _): def.god.artName
        default: PharaohSWagerArt.resolve(PharaohSWagerArt.interactionReforge)
        }
    }

    /// Before → after read-out for the currently selected face or die.
    private var previewText: String? {
        switch selection {
        case .reforge(let kind, _):
            guard let dieID = chosenDieID, let faceID = chosenFaceID,
                  let die = game.loadout?.die(id: dieID),
                  let face = die.faces.first(where: { $0.id == faceID }) else { return nil }
            return "\(face.kind.label) → \(kind.label)"
        case .imbue(let amount, _):
            guard let dieID = chosenDieID, let faceID = chosenFaceID,
                  let die = game.loadout?.die(id: dieID),
                  let face = die.faces.first(where: { $0.id == faceID }) else { return nil }
            let after = min(DieFace.critCap, face.critChance + amount)
            return "\(Int(face.critChance * 100))% → \(Int(after * 100))% crit"
        case .patron(let deity, _, _):
            return workingDie.map { "\($0.name) → \(deity.name)" }
        default:
            return nil
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                game.cancelSelection()
            } label: {
                Text(cancelLabel)
                    .font(.fantasy(17, weight: .bold))
                    .foregroundStyle(Theme.parchment.opacity(0.75))
                    .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                    .frame(width: 200, height: 52)
                    .background {
                        DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.parchmentDim)
                    }
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                confirm()
            } label: {
                Text(confirmLabel)
                    .font(.fantasy(21, weight: .bold))
                    .kerning(1)
                    .foregroundStyle(
                        canConfirm
                            ? LinearGradient(colors: [Theme.parchment, Theme.gold],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Theme.parchmentDim, Theme.parchmentDim],
                                             startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .black.opacity(0.75), radius: 2, y: 1)
                    .frame(width: 300, height: 52)
                    .background {
                        DeckButtonSurface(tone: .primary,
                                          state: canConfirm ? .highlighted : .disabled,
                                          rim: canConfirm ? Theme.gold : Theme.parchmentDim,
                                          emphasis: canConfirm ? 1 : 0)
                    }
                    .goldCorners(size: 14, inset: 3, opacity: canConfirm ? 0.8 : 0.25)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canConfirm)
        }
    }

    private var cancelLabel: String {
        switch selection {
        case .swapDie: "Leave it behind"
        default: "Skip"
        }
    }

    private var confirmLabel: String {
        switch selection {
        case .reforge: "Reforge It"
        case .reforgeDie: "Reforge It"
        case .patron: "Claim It"
        case .imbue: "Etch It"
        case .swapDie: "Swap It In"
        case .replaceBoon: "Take Its Place"
        default: "Confirm"
        }
    }

    private var canConfirm: Bool {
        switch selection {
        case .reforge, .imbue: chosenFaceID != nil
        case .reforgeDie, .patron, .swapDie: chosenDieID != nil
        case .replaceBoon: chosenBoonID != nil
        default: false
        }
    }

    private func confirm() {
        switch selection {
        case .reforge(let kind, _):
            guard let dieID = chosenDieID, let faceID = chosenFaceID else { return }
            game.applyReforge(dieID: dieID, faceID: faceID, to: kind)
        case .reforgeDie:
            guard let dieID = chosenDieID else { return }
            game.applyDieReforge(dieID: dieID)
        case .patron(let deity, let replace, _):
            guard let dieID = chosenDieID else { return }
            game.applyPatron(dieID: dieID, deity: deity, replace: replace)
        case .imbue(let amount, _):
            guard let dieID = chosenDieID, let faceID = chosenFaceID else { return }
            game.applyImbue(dieID: dieID, faceID: faceID, amount: amount)
        case .swapDie(let die):
            guard let dieID = chosenDieID else { return }
            game.applySwap(replacing: dieID, with: die.instantiated())
        case .replaceBoon(let def, let rarity):
            guard let chosenBoonID else { return }
            game.replaceBoon(chosenBoonID, with: def, rarity: rarity)
        default:
            break
        }
    }

    // MARK: - Replacing a god power

    /// The incoming power beside the ones already in that slot, so the trade
    /// is read in full before it is made — including the investment lost.
    private func boonReplacePicker(incoming: GodBoonDef, rarity: BoonRarity) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 8) {
                Text("OFFERED")
                    .font(.system(size: 9, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(rarity.tint)
                boonCard(
                    name: incoming.name,
                    god: incoming.god,
                    text: incoming.text(rarity: rarity, level: 1),
                    footnote: "\(rarity.label) · level 1",
                    tint: rarity.tint,
                    highlighted: true
                )
            }
            .frame(width: 240)

            Divider().overlay(Theme.parchmentDim.opacity(0.2))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                    ForEach(game.boons(in: incoming.slot)) { owned in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                chosenBoonID = owned.defID
                            }
                            Haptics.light()
                        } label: {
                            boonCard(
                                name: owned.def?.name ?? "Power",
                                god: owned.def?.god ?? incoming.god,
                                text: owned.text,
                                footnote: "\(owned.rarity.label) · level \(owned.level) — lost if replaced",
                                tint: owned.rarity.tint,
                                highlighted: chosenBoonID == owned.defID
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func boonCard(
        name: String,
        god: Deity,
        text: String,
        footnote: String,
        tint: Color,
        highlighted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                PharaohSWagerSymbol(art: god.artName, fallback: god.symbol, size: 17, tint: god.tint)
                Text(name)
                    .font(.fantasy(15, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }

            Text(text)
                .font(.paper(11.5))
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(footnote.uppercased())
                .font(.system(size: 8.5, weight: .black))
                .kerning(0.8)
                .foregroundStyle(tint)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .papyrusPanel(tint: Theme.bgCard, cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(highlighted ? tint : Theme.parchmentDim.opacity(0.2),
                              lineWidth: highlighted ? 2 : 1)
        )
    }

    // MARK: - Face picker

    /// The whetstone works one die at a time: choose the die along the bottom
    /// rail and its six faces are laid out across the whole bench.
    private var facePicker: some View {
        VStack(spacing: 10) {
            faceBench
            dieRail
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var faceBench: some View {
        HStack(spacing: 10) {
            if let die = workingDie {
                ForEach(die.faces) { face in
                    Button {
                        guard isEligible(face) else {
                            Haptics.warning()
                            return
                        }
                        chosenDieID = die.id
                        chosenFaceID = face.id
                        Haptics.light()
                    } label: {
                        faceCard(face, isSelected: chosenFaceID == face.id)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: chosenDieID)
    }

    private func faceCard(_ face: DieFace, isSelected: Bool) -> some View {
        let eligible = isEligible(face)
        return VStack(spacing: 7) {
            FaceTileView(
                face: face,
                size: 60,
                critBonus: game.critBonus,
                showCrit: true,
                isSelected: isSelected
            )

            Text(face.kind.label)
                .font(.fantasy(15, weight: .bold))
                .foregroundStyle(isSelected ? Theme.gold : Theme.parchment)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)

            Text(cardCaption(face))
                .font(.paper(11.5))
                .foregroundStyle(Theme.parchmentDim)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(eligible ? 1 : 0.4)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(isSelected ? Theme.bgElevated : Theme.bgCard, in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Theme.gold : Theme.rule.opacity(0.45),
                              lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? Theme.gold.opacity(0.3) : .clear, radius: 12)
    }

    /// Under-face caption: what this face does.
    private func cardCaption(_ face: DieFace) -> String {
        face.kind.soloEffect
    }

    /// Every die you carry, as a rail of chips under the bench.
    private var dieRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(isPatronReplace || claimableDice.isEmpty ? carriedDice : claimableDice) { die in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            chosenDieID = die.id
                        }
                        chosenFaceID = nil
                        Haptics.light()
                    } label: {
                        dieChip(die, isActive: workingDie?.id == die.id)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
        .frame(height: 60)
    }

    private func dieChip(_ die: Die, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            PharaohSWagerSymbol(art: die.slot.artName, fallback: die.slot.symbol,
                       size: 18, tint: die.rarity.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(die.name)
                    .font(.fantasy(14, weight: .bold))
                    .foregroundStyle(isActive ? Theme.gold : Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(die.rarity.label.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(die.rarity.tint)
            }

            DieStripView(die: die, tileSize: 17, showCrit: false, critBonus: game.critBonus)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Theme.bgElevated : Theme.bgCard.opacity(0.9), in: .rect(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(isActive ? Theme.gold : Theme.rule.opacity(0.35),
                              lineWidth: isActive ? 1.8 : 1)
        )
    }

    // MARK: - Patron picker

    /// A god surveying the bench: pick which die they claim.
    private var patronPicker: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10)], spacing: 10) {
                ForEach(claimableDice) { die in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            chosenDieID = die.id
                        }
                        Haptics.light()
                    } label: {
                        dieCard(die, highlighted: chosenDieID == die.id,
                                tint: claimDeity?.tint ?? Theme.gold)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Die swap

    private func dieSwapPicker(incoming: Die) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 8) {
                Text("INCOMING")
                    .font(.system(size: 9, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.gold)
                dieCard(incoming, highlighted: true, tint: incoming.rarity.tint)
            }
            .frame(width: 190)

            Divider().overlay(Theme.parchmentDim.opacity(0.2))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                    ForEach((game.loadout?.allDice ?? []).filter { $0.slot == incoming.slot }) { die in
                        Button {
                            chosenDieID = die.id
                            Haptics.light()
                        } label: {
                            dieCard(die, highlighted: chosenDieID == die.id, tint: Theme.gold)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func dieCard(_ die: Die, highlighted: Bool, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                PharaohSWagerSymbol(art: die.slot.artName, fallback: die.slot.symbol,
                           size: 14, tint: die.rarity.tint)
                Text(die.name)
                    .font(.fantasy(13, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if let patron = die.patron {
                    PharaohSWagerSymbol(art: patron.artName, fallback: patron.symbol,
                               size: 14, tint: patron.tint)
                } else {
                    Text(die.rarity.label.uppercased())
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundStyle(die.rarity.tint)
                }
            }
            DieStripView(die: die, tileSize: 24, showCrit: true, critBonus: game.critBonus)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .papyrusPanel(tint: Theme.bgCard, cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(highlighted ? tint : Theme.parchmentDim.opacity(0.2),
                              lineWidth: highlighted ? 2 : 1)
        )
    }

}
