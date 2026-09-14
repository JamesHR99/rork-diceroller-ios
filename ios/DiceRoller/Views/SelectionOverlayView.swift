import SwiftUI

/// The overlay that appears whenever an upgrade needs a target: pick the die
/// and face to reforge or imbue, choose which die a god claims as patron,
/// pick which die a new one replaces, or confirm an item swap. God upgrades,
/// capstones and pairings need no target — they apply the moment they are
/// taken, so they never reach this overlay.
struct SelectionOverlayView: View {
    let selection: PendingSelection
    @Environment(GameManager.self) private var game

    @State private var chosenDieID: UUID?
    @State private var chosenFaceID: UUID?

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
                case .swapDie(let die):
                    dieSwapPicker(incoming: die)
                case .swapItem(let item):
                    itemSwapPicker(incoming: item)
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

    /// Every die you carry, weapon first, then armour, then the item.
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
        case .swapItem: "Swap your item?"
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
        case .swapItem(let item):
            "You already carry an item. Taking \(item.name) discards it."
        default:
            ""
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: headerSymbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(claimDeity?.tint ?? Theme.gold)
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
        case .swapItem: "bag.fill"
        default: "sparkles"
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
                    .font(.fantasy(16, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
                    .frame(width: 200, height: 50)
                    .background(Theme.bgCard, in: .capsule)
                    .overlay(Capsule().strokeBorder(Theme.parchmentDim.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                confirm()
            } label: {
                Text(confirmLabel)
                    .font(.fantasy(19, weight: .bold))
                    .foregroundStyle(canConfirm ? Theme.bg : Theme.parchmentDim)
                    .frame(width: 300, height: 50)
                    .background(
                        canConfirm
                            ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.ember],
                                                           startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Theme.bgCard),
                        in: .capsule
                    )
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canConfirm)
        }
    }

    private var cancelLabel: String {
        switch selection {
        case .swapDie, .swapItem: "Leave it behind"
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
        case .swapItem: "Take the New Item"
        default: "Confirm"
        }
    }

    private var canConfirm: Bool {
        switch selection {
        case .reforge, .imbue: chosenFaceID != nil
        case .reforgeDie, .patron, .swapDie: chosenDieID != nil
        case .swapItem: true
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
        case .swapItem(let item):
            game.applyItemSwap(to: item)
        default:
            break
        }
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
            Image(systemName: die.slot.symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(die.rarity.tint)

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
                Image(systemName: die.slot.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(die.rarity.tint)
                Text(die.name)
                    .font(.fantasy(13, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if let patron = die.patron {
                    Image(systemName: patron.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(patron.tint)
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
        .background(Theme.bgCard, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(highlighted ? tint : Theme.parchmentDim.opacity(0.2),
                              lineWidth: highlighted ? 2 : 1)
        )
    }

    // MARK: - Item swap

    private func itemSwapPicker(incoming: ItemDef) -> some View {
        HStack(spacing: 16) {
            itemCard(
                title: "CURRENTLY CARRIED",
                name: game.loadout?.item?.name ?? "None",
                symbol: game.loadout?.item?.symbol ?? "bag",
                faces: game.loadout?.item?.dice.first?.faces.map(\.kind) ?? [],
                tint: Theme.parchmentDim
            )

            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.gold)

            itemCard(
                title: "NEW ITEM",
                name: incoming.name,
                symbol: incoming.symbol,
                faces: incoming.faces,
                tint: incoming.rarity.tint
            )
        }
        .frame(maxHeight: .infinity)
    }

    private func itemCard(title: String, name: String, symbol: String, faces: [FaceKind], tint: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .black))
                .kerning(1.2)
                .foregroundStyle(tint)
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 54, height: 54)
                .background(Theme.bg, in: .circle)
            Text(name)
                .font(.fantasy(15, weight: .bold))
                .foregroundStyle(Theme.parchment)
            HStack(spacing: 4) {
                ForEach(Array(faces.enumerated()), id: \.offset) { _, face in
                    Image(systemName: face.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(face.tint)
                        .frame(width: 22, height: 22)
                        .background(Theme.bgElevated, in: .rect(cornerRadius: 5))
                }
            }
            Text("2 dice")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
        }
        .padding(16)
        .frame(width: 240)
        .background(Theme.bgCard, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(tint.opacity(0.4), lineWidth: 1.5))
    }
}
