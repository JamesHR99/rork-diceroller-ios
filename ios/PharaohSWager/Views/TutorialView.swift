import SwiftUI

/// The opening briefing: a short run of pages before the first fight, taught
/// in the demigod's own dice.
///
/// The page that matters is the third one, which is not text at all — it is a
/// live row of your own faces you can actually tap into a plan and drag
/// around. Put the right two next to each other and the plan visibly reacts.
/// It never names what you made: chains stay found, not taught.
struct TutorialView: View {
    @Environment(GameManager.self) private var game

    /// The demigod being taught. Falls back to the first class so the page can
    /// never end up empty.
    private var hero: HeroClass {
        game.tutorialHero ?? game.heroClass ?? GameData.classes[0]
    }

    @State private var page = 0
    @State private var suppress = false

    private var pages: [BriefingPage] { BriefingPage.pages(for: hero) }
    private var isLastPage: Bool { page >= pages.count - 1 }

    var body: some View {
        ZStack {
            Theme.bg.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 10) {
                header

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, entry in
                        pageBody(entry)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
        }
        .onChange(of: page) { _, _ in
            Haptics.light()
            Audio.shared.play(.uiTransition, volumeScale: 0.7)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 11) {
            PharaohSWagerSymbol(art: PharaohSWagerArt.classSigil(hero.id), fallback: hero.symbol,
                       size: 26, tint: hero.accent)
                .frame(width: 40, height: 40)
                .background(Theme.bgCard, in: .circle)
                .overlay(Circle().strokeBorder(hero.accent.opacity(0.5), lineWidth: 1.4))

            VStack(alignment: .leading, spacing: 1) {
                Text("BEFORE YOU CAST OFF")
                    .font(.fantasy(17, weight: .black))
                    .kerning(2)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.parchment, Theme.gold],
                                       startPoint: .top, endPoint: .bottom)
                    )
                Text("\(hero.name) · \(hero.title)")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
            }

            Spacer(minLength: 0)

            // Skip is on every page — a briefing you cannot leave is a wall.
            Button {
                game.finishBriefing()
            } label: {
                Text("SKIP")
                    .font(.system(size: 10.5, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.parchmentDim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.bgCard.opacity(0.8), in: .capsule)
                    .overlay(Capsule().strokeBorder(Theme.parchmentDim.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func pageBody(_ entry: BriefingPage) -> some View {
        // Scrolling rather than squeezing: a long page on a short screen keeps
        // every word reachable instead of clipping the last paragraph.
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    PharaohSWagerSymbol(art: entry.art, fallback: entry.fallbackSymbol,
                               size: 22, tint: entry.tint)
                    Text(entry.title.uppercased())
                        .font(.fantasy(19, weight: .black))
                        .kerning(1.6)
                        .foregroundStyle(entry.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(entry.body)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.parchment.opacity(0.92))
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)

                // The live pieces: the pokable demo, and the found-count.
                switch entry.kind {
                case .plain:
                    EmptyView()
                case .orderDemo:
                    OrderDemoView(hero: hero)
                case .loreCount:
                    loreCount
                case .classDice:
                    classDice
                case .actionOrder:
                    actionOrderBlock
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bgCard, strength: 0.65, shade: 0.42)
                .clipShape(.rect(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1.2)
        )
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
    }

    private var actionOrderBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Order defence before the hit you want to stop", systemImage: "shield.fill")
            Label("Your action → enemy action → your action", systemImage: "arrow.left.arrow.right")
            Text("A 1–3 die Attack takes one event; 4–6 dice take two. Singles never give enemies extra attacks. When one side runs out, the other finishes its announced actions.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.frost)
        .padding(12)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 12))
    }

    /// How many chains this player has ever found, so the hunt is framed as
    /// the long game it is.
    private var loreCount: some View {
        let all = GameData.combos(for: hero.id)
        let found = ComboLore.knownCount(among: all)
        return HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text("\(found)")
                    .font(.fantasy(30, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                Text("FOUND")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.parchmentDim)
            }
            .frame(width: 70)

            VStack(spacing: 0) {
                Text("\(all.count)")
                    .font(.fantasy(30, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchmentDim)
                Text("IN THE NIGHT")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.parchmentDim)
            }
            .frame(width: 96)

            Text(found == 0
                 ? "Nothing found yet. Every one of them is still out there."
                 : "They stay found across every run, and across every death.")
                .font(.system(size: 12, weight: .semibold))
                .italic()
                .foregroundStyle(Theme.gold.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 12))
    }

    /// The demigod's actual dice, face by face, with what each one does alone.
    private var classDice: some View {
        let loadout = hero.startingLoadout
        return VStack(alignment: .leading, spacing: 8) {
            diceBlock(title: "\(hero.weaponName) · \(GameData.ownedWeaponDice) dice",
                      die: loadout.weapon.dice.first)
            diceBlock(title: "\(hero.armorName) · \(GameData.ownedArmourDice) dice",
                      die: loadout.armor.dice.first)

            HStack(spacing: 6) {
                PharaohSWagerIcon(name: PharaohSWagerArt.Status.stamina, size: 15)
                Text("6 dice · 2 reroll passes each round · \(hero.battleIdentity.lowercased())")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Theme.gold.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func diceBlock(title: String, die: Die?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .black))
                .kerning(1)
                .foregroundStyle(hero.accent)

            if let die {
                // Each distinct face once, with what it does on its own.
                let faces = uniqueFaces(die)
                ForEach(faces, id: \.self) { face in
                    HStack(spacing: 6) {
                        PharaohSWagerSymbol(art: face.artName, fallback: face.symbol,
                                   size: 17, tint: face.tint)
                            .frame(width: 22)
                        Text(face.label)
                            .font(.system(size: 11.5, weight: .black))
                            .foregroundStyle(Theme.parchment)
                            .frame(width: 84, alignment: .leading)
                        Text(face.soloEffect)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.parchmentDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.opacity(0.45), in: .rect(cornerRadius: 11))
    }

    private func uniqueFaces(_ die: Die) -> [FaceKind] {
        var seen: [FaceKind] = []
        for face in die.faces where !seen.contains(face.kind) {
            seen.append(face.kind)
        }
        return seen
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            // Page pips, so the briefing's length is never a mystery.
            HStack(spacing: 5) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Theme.gold : Theme.parchmentDim.opacity(0.35))
                        .frame(width: index == page ? 8 : 6, height: index == page ? 8 : 6)
                }
            }

            Spacer(minLength: 0)

            if isLastPage {
                Button {
                    suppress.toggle()
                    Haptics.light()
                    Audio.shared.play(.uiTap)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: suppress ? "checkmark.square.fill" : "square")
                            .font(.system(size: 13, weight: .bold))
                        Text("Don't show this again")
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .foregroundStyle(suppress ? Theme.gold : Theme.parchmentDim)
                }
                .buttonStyle(PressableButtonStyle())
            }

            Button {
                if isLastPage {
                    game.finishBriefing(suppressFuture: suppress)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        page += 1
                    }
                }
            } label: {
                Text(isLastPage
                     ? (game.tutorialIsPreview ? "Back to the Bank" : "Cast Off")
                     : "Next")
                    .font(.fantasy(18, weight: .bold))
                    .kerning(1)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.parchment, Theme.gold],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 190, height: 50)
                    .background {
                        DeckButtonSurface(tone: .primary, state: .highlighted,
                                          rim: hero.accent, cornerRadius: 15, emphasis: 1)
                    }
                    .goldCorners(size: 15, inset: 3, opacity: 0.8)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}

// MARK: - Pages

/// One page of the briefing. Most are a heading and a paragraph; three carry a
/// live piece of the game underneath.
struct BriefingPage: Identifiable {
    enum Kind {
        case plain
        /// The pokable row of dice — the page that actually teaches the game.
        case orderDemo
        /// The codex's found-count.
        case loreCount
        /// The demigod's own dice, face by face.
        case classDice
        /// Agility worked out in this demigod's own numbers.
        case actionOrder
    }

    let id: String
    let title: String
    let body: String
    let art: String
    let fallbackSymbol: String
    let tint: Color
    let kind: Kind

    /// The briefing, in order, written for the demigod who will fight it.
    static func pages(for hero: HeroClass) -> [BriefingPage] {
        [
            BriefingPage(
                id: "why",
                title: "Why you are here",
                body: "You guard Ra's barque through the twelve hours of the night. The river runs one way, under three great gates, and everything in the water wants the sun put out.\n\nIt ends at dawn, or it ends when you go under. There is no third way off the boat.",
                art: PharaohSWagerArt.Status.champion,
                fallbackSymbol: "sun.max.fill",
                tint: Theme.sunGold,
                kind: .plain
            ),
            BriefingPage(
                id: "roll",
                title: "The roll",
                body: "You own eight dice. Six of them fill the night's slots each round, drawn at random, and they roll as they arrive.\n\nThe faces you get are what you have to work with — not what you would have chosen. Every round is a hand you have to make something of.",
                art: PharaohSWagerArt.interactionRoll,
                fallbackSymbol: "dice.fill",
                tint: Theme.gold,
                kind: .plain
            ),
            BriefingPage(
                id: "order",
                title: "Combining is the game",
                body: "Tap these faces into the plan. Dice standing side by side can be combined; dice with a gap cannot.\n\nWhen they make something, a seam appears. Tap it to see exactly what you would get, then choose Combine. Nothing ever fuses on its own, and Separate undoes it.",
                art: PharaohSWagerArt.chainConnector,
                fallbackSymbol: "arrow.left.arrow.right",
                tint: Theme.ember,
                kind: .orderDemo
            ),
            BriefingPage(
                id: "rerolls",
                title: "Six dice. Two reroll passes.",
                body: "Each round draws six dice from your collection. Use each die once; there is no stamina bar.\n\nTap REROLL, select any subset of unplayed dice, then confirm. Unselected results become Prepared. You have two passes; a boon may grant a third. Every round starts with a fresh draw.",
                art: PharaohSWagerArt.Status.stamina,
                fallbackSymbol: "bolt.circle.fill",
                tint: Theme.gold,
                kind: .plain
            ),
            BriefingPage(
                id: "action-order",
                title: "Who moves first",
                body: "Block gives 8 shield; Evade gives one guaranteed dodge. Focus primes +50% damage for your next Attack. Each support action takes one event. Attacks using four to six matching dice take a wind-up event and a release event.\n\nThen actions alternate, starting with you. Twin Shot plus a separate Block gives you both damage and protection. Check TURN ORDER before committing.",
                art: PharaohSWagerArt.Status.stamina,
                fallbackSymbol: "hare.fill",
                tint: Theme.frost,
                kind: .actionOrder
            ),
            BriefingPage(
                id: "chains",
                title: "Recipes are yours to find",
                body: "Nothing here suggests a recipe. No list, no hint, no book.\n\nAssemble one and it names itself on the spot, tells you what it does, and is written into your codex for good — across every run, and every death.",
                art: PharaohSWagerArt.Status.critical,
                fallbackSymbol: "sparkles",
                tint: Theme.gold,
                kind: .loreCount
            ),
            BriefingPage(
                id: "class",
                title: hero.name,
                body: "\(hero.blurb)\n\n\(demigodTruth(hero))",
                art: PharaohSWagerArt.classSigil(hero.id) ?? PharaohSWagerArt.Status.champion,
                fallbackSymbol: hero.symbol,
                tint: hero.accent,
                kind: .classDice
            ),
        ]
    }

    /// The plain truth of how this demigod wants to be played — never a recipe
    /// and never a chain name.
    private static func demigodTruth(_ hero: HeroClass) -> String {
        switch hero.id {
        case "archer":
            "You fight at range and you trade well. Your arrows come in three weights, and the heavier ones are worth waiting for."
        case "warrior":
            "You are the wall. Your guard goes up early and stays up, but your swings land late and heavy — so what you start this round often finishes in the next."
        case "rogue":
            "You are the fastest thing on the water and the easiest to kill. You defend almost instantly, you cut in flurries, and your blades carry venom."
        default:
            "You have no shield face, no evade and no bandage at all. Every guard, every escape and every mend has to be spelled out of runes — which is why you have more of them than anyone."
        }
    }
}

// MARK: - The pokable demo

/// A live, self-contained row of the demigod's own faces. Tap one in and it
/// joins the plan; tap it in the plan and it comes back. When neighbouring
/// dice work together the tiles visibly lock and what the plan is worth jumps.
///
/// It never names the chain — that stays found, not taught — and it drives the
/// real chain-matching rules rather than a scripted fake.
private struct OrderDemoView: View {
    let hero: HeroClass

    /// The hand, chosen so a chain is genuinely available to stumble into.
    @State private var hand: [DemoFace] = []
    @State private var plan: [UUID] = []
    /// Set the first time the player welds a chain, so the page can react.
    @State private var hasFoundChain = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            planRow

            HStack(spacing: 6) {
                PharaohSWagerIcon(name: PharaohSWagerArt.interactionRoll, size: 14)
                Text("YOUR FACES — TAP TO PLAY")
                    .font(.system(size: 9, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.parchmentDim)
            }

            handRow

            Text(hint)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(hasFoundChain ? Theme.gold : Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.25), value: hint)
        }
        .onAppear(perform: buildHand)
    }

    // MARK: Plan

    private var planRow: some View {
        let groups = chainGroups
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                PharaohSWagerIcon(name: PharaohSWagerArt.chainConnector, size: 14)
                Text("THE PLAN")
                    .font(.system(size: 9, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.gold.opacity(0.85))

                Spacer(minLength: 0)

                // The two numbers that are always in tension: what the plan is
                // worth, and how late it lands. In the real fight the worth is
                // hidden — here it is the needle that shows adjacency working,
                // and the agility beside it is the price being paid for it.
                if !plan.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 8, weight: .black))
                        Text("\(planActions)")
                            .font(.system(size: 11, weight: .black).monospacedDigit())
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Theme.frost)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Theme.frost.opacity(0.16), in: .capsule)
                }

                Text("WORTH \(planWorth)")
                    .font(.system(size: 11, weight: .black).monospacedDigit())
                    .foregroundStyle(hasFoundChain ? Theme.ember : Theme.parchmentDim)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 3) {
                if plan.isEmpty {
                    Text("empty — tap a face below")
                        .font(.system(size: 11.5))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim.opacity(0.7))
                        .frame(height: 58)
                } else {
                    ForEach(Array(plan.enumerated()), id: \.element) { index, id in
                        if let face = hand.first(where: { $0.id == id }) {
                            let welded = groups.contains { $0.contains(index) }
                            demoTile(face, number: index + 1, welded: welded, inPlan: true)

                            // Neighbours that work together are physically
                            // joined, so the grouping is felt, not read.
                            if index < plan.count - 1,
                               groups.contains(where: { $0.contains(index) && $0.contains(index + 1) }) {
                                PharaohSWagerImage(name: PharaohSWagerArt.chainConnector, width: 13, fit: .fit)
                                    .colorMultiply(Theme.gold)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(height: 62)
            .padding(.horizontal, 7)
            .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(hasFoundChain ? Theme.ember.opacity(0.7) : Theme.gold.opacity(0.25),
                                  lineWidth: hasFoundChain ? 1.8 : 1)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: plan)
        }
    }

    private var handRow: some View {
        HStack(spacing: 4) {
            ForEach(hand) { face in
                if !plan.contains(face.id) {
                    demoTile(face, number: nil, welded: false, inPlan: false)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 58)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: plan)
    }

    private func demoTile(_ face: DemoFace, number: Int?, welded: Bool, inPlan: Bool) -> some View {
        Button {
            if inPlan {
                plan.removeAll { $0 == face.id }
                Audio.shared.play(.diceTake)
            } else {
                plan.append(face.id)
                Audio.shared.planKnock(position: plan.count - 1)
            }
            Haptics.light()
            checkForChain()
        } label: {
            VStack(spacing: 1) {
                if let number {
                    Text("\(number)")
                        .font(.system(size: 9, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.bg)
                        .frame(width: 14, height: 14)
                        .background(welded ? Theme.gold : face.kind.tint, in: .circle)
                }

                PharaohSWagerSymbol(art: face.kind.artName, fallback: face.kind.symbol,
                           size: number == nil ? 26 : 22, tint: face.kind.tint)

                Text(face.kind.soloTag)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 52, height: inPlan ? 56 : 52)
            .background {
                PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.6, shade: 0.35)
                    .clipShape(.rect(cornerRadius: 9))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(welded ? Theme.gold : face.kind.tint.opacity(0.45),
                                  lineWidth: welded ? 2 : 1)
            )
            .shadow(color: welded ? Theme.gold.opacity(0.5) : .clear, radius: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .transition(.scale(scale: 0.7).combined(with: .opacity))
    }

    // MARK: Chain detection

    /// Runs of neighbouring positions in the plan that form a chain, found
    /// with the game's own rules: greedy from the left, biggest and most
    /// specific recipe first.
    private var chainGroups: [[Int]] {
        let faces = plan.compactMap { id in hand.first { $0.id == id }?.kind }
        guard faces.count > 1 else { return [] }
        let pool = GameData.combosByPriority(for: hero.id)
        var groups: [[Int]] = []
        var cursor = 0
        while cursor < faces.count {
            var matched = false
            for combo in pool {
                let end = cursor + combo.faceCount
                guard end <= faces.count else { continue }
                let window = Array(faces[cursor..<end])
                guard combo.match(from: window) != nil else { continue }
                groups.append(Array(cursor..<end))
                cursor = end
                matched = true
                break
            }
            if !matched { cursor += 1 }
        }
        return groups.filter { $0.count > 1 }
    }

    /// What the plan is worth. Chained dice pay their recipe; a lone die pays
    /// only its own small solo value — which is the point being made.
    private var planWorth: Int {
        let faces = plan.compactMap { id in hand.first { $0.id == id }?.kind }
        let groups = chainGroups
        let grouped = Set(groups.flatMap { $0 })
        var total = 0
        let pool = GameData.combosByPriority(for: hero.id)
        for group in groups {
            let window = group.compactMap { faces.indices.contains($0) ? faces[$0] : nil }
            if let combo = pool.first(where: { $0.faceCount == window.count && $0.match(from: window) != nil }) {
                total += max(combo.damage, max(combo.heal, combo.shield))
            }
        }
        for (index, face) in faces.enumerated() where !grouped.contains(index) {
            total += face.soloValue
        }
        return total
    }

    private var planActions: Int {
        let groups = chainGroups
        let grouped = Set(groups.flatMap { $0 })
        return groups.count + plan.indices.filter { !grouped.contains($0) }.count
    }

    private func checkForChain() {
        guard !chainGroups.isEmpty, !hasFoundChain else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            hasFoundChain = true
        }
        Haptics.success()
        Audio.shared.play(.chain, volumeScale: 0.8)
    }

    private var hint: String {
        if plan.isEmpty {
            return "Tap two faces in and see whether they take to each other."
        }
        if chainGroups.isEmpty {
            return plan.count == 1
                ? "A single die is a useful action. Try adding a matching face for a combo."
                : "Those two are not working together. Take one back and try a different pairing — or a different order."
        }
        return "Those dice now land together as one action. Keep another die for Block or Evade, or put Focus before the combo to boost it. Separate gives you two individual actions again."
    }

    // MARK: Hand

    /// One face per tile, drawn from this demigod's real starting dice and
    /// arranged so at least one chain is genuinely reachable.
    private func buildHand() {
        guard hand.isEmpty else { return }
        hand = demoFaces(for: hero).map { DemoFace(kind: $0) }
    }

    private func demoFaces(for hero: HeroClass) -> [FaceKind] {
        switch hero.id {
        case "archer":
            [.arrow1, .block, .arrow1, .evade, .arrow1, .heal]
        case "warrior":
            [.overhead, .block, .sideSwing, .heal, .overhead, .focus]
        case "rogue":
            [.swiftSlash, .evade, .swiftSlash, .heal, .daggerThrow, .poison]
        default:
            [.runeFire, .channel, .runeFire, .runeLife, .runeFire, .wandZap]
        }
    }
}

/// One tile in the demo, with a stable identity so tapping it around the plan
/// animates rather than redrawing.
private struct DemoFace: Identifiable {
    let id = UUID()
    let kind: FaceKind
}

