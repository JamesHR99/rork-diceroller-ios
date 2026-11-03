import SwiftUI

/// The opening briefing: four short, practical pages before the first fight.
/// The player builds a real plan first, then learns the two resources, enemy
/// intent, and how a run grows. Story and class identity already live on the
/// title and class screens, so the briefing does not repeat them.
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
                .frame(minHeight: 0)

                footer
                    .layoutPriority(1)
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
            Group {
                switch entry.kind {
                case .orderDemo:
                    // Landscape is wide and short. Put the explanation beside the
                    // live dice so the first interactive task is visible without
                    // asking a new player to discover that this page scrolls.
                    HStack(alignment: .top, spacing: 14) {
                        pageIntro(entry, compact: true)
                            .frame(maxWidth: 240, alignment: .topLeading)
                        OrderDemoView(hero: hero)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                default:
                    VStack(alignment: .leading, spacing: 9) {
                        pageIntro(entry)
                        pageSupplement(entry)
                    }
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

    private func pageIntro(_ entry: BriefingPage, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 9) {
            HStack(spacing: 8) {
                PharaohSWagerSymbol(art: entry.art, fallback: entry.fallbackSymbol,
                           size: compact ? 19 : 22, tint: entry.tint)
                Text(entry.title.uppercased())
                    .font(.fantasy(compact ? 17 : 19, weight: .black))
                    .kerning(1.6)
                    .foregroundStyle(entry.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(entry.body)
                .font(.system(size: compact ? 13 : 14, weight: .medium))
                .foregroundStyle(Theme.parchment.opacity(0.92))
                .lineSpacing(compact ? 1.5 : 2.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func pageSupplement(_ entry: BriefingPage) -> some View {
        switch entry.kind {
        case .plain, .orderDemo:
            EmptyView()
        case .actionOrder:
            actionOrderBlock
        case .progression:
            progressionBlock
        }
    }

    private var actionOrderBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Read the enemy intent before spending Resolve", systemImage: "eye.fill")
            Label("Place actions around enemy moves → Go", systemImage: "arrow.right.circle.fill")
            Text("You have 3 Resolve. Drag a blue action along the numbered timeline until it matches your plan.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.frost)
        .padding(12)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 12))
    }

    private var progressionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Draft a die after fights — or Skip", systemImage: "die.face.5.fill")
            Label("Omens and shops tune individual faces", systemImage: "hammer.fill")
            Label("Discovered chains stay in the Codex", systemImage: "book.closed.fill")
            Text("A larger bag offers more possibilities but draws each favourite die less often. Take rewards that serve the build you want.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.gold)
        .padding(12)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 12))
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
                    .paintedContentInsets()
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
        /// A concise rules page with no additional interactive block.
        case plain
        /// The pokable row of dice — the page that actually teaches the game.
        case orderDemo
        /// The handover from the queued player turn to announced enemy intent.
        case actionOrder
        /// How rewards, bag size and the persistent Codex shape later runs.
        case progression
    }

    let id: String
    let title: String
    let body: String
    let art: String
    let fallbackSymbol: String
    let tint: Color
    let kind: Kind

    /// The briefing stays deliberately short. Each page answers a decision
    /// the player must make in the opening fight or immediately after it.
    static func pages(for hero: HeroClass) -> [BriefingPage] {
        [
            BriefingPage(
                id: "order",
                title: "Build your turn",
                body: "Draw \(BattleRules.handSize) dice. Tap faces into the plan. Matching neighbours join; a different face starts the next action.\n\nTap a queued die to take it back. Separate actions alternate into the enemy timeline.",
                art: PharaohSWagerArt.chainConnector,
                fallbackSymbol: "arrow.left.arrow.right",
                tint: Theme.ember,
                kind: .orderDemo
            ),
            BriefingPage(
                id: "rerolls",
                title: "Lock actions. Roll the rest.",
                body: "A 1–2 die action costs 1 Resolve, a 3–4 die action costs 2, and a 5–6 die action costs 3.\n\nYou get two ROLL UNUSED pulls. Dice already queued stay locked while the rest of the hand spins again.",
                art: PharaohSWagerArt.Status.stamina,
                fallbackSymbol: "bolt.circle.fill",
                tint: Theme.gold,
                kind: .plain
            ),
            BriefingPage(
                id: "action-order",
                title: "Build the exact order",
                body: "Block gives Guard, Evade softens a chosen hit, Heal restores missing HP, and Focus primes your next Attack.\n\nYour separate actions alternate into the enemy timeline. Drag a blue action to change its position, then press GO to resolve exactly what you see.",
                art: PharaohSWagerArt.Status.stamina,
                fallbackSymbol: "hare.fill",
                tint: Theme.frost,
                kind: .actionOrder
            ),
            BriefingPage(
                id: "progression",
                title: "Shape the next draw",
                body: "After a fight, draft a die or skip it to keep your bag focused. Omens, shops and gods reshape the dice you already trust.\n\nExperiment freely: every chain you discover is remembered across runs.",
                art: PharaohSWagerArt.Status.critical,
                fallbackSymbol: "point.3.connected.trianglepath.dotted",
                tint: Theme.gold,
                kind: .progression
            ),
        ]
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
        return "Those dice now land together as one action. Add Block, Evade or Focus as another action, then place it around enemy moves. Tap a queued die to remove it; Go plays the numbered timeline."
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
