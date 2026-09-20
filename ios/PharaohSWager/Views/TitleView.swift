import SwiftUI

/// The barque at rest on a still black river under a full star field: the
/// game's name in carved gold on the left, the four demigods as tomb-wall
/// panels on the right.
struct HeroSelectionView: View {
    var onBack: () -> Void = {}
    @Environment(GameManager.self) private var game
    @State private var selectedIndex = 0
    @State private var glowPulse = false
    @State private var showRecords = false
    /// Raised when casting off would write over a night still waiting.
    @State private var confirmingOverwrite = false

    private var hero: HeroClass { GameData.classes[selectedIndex] }

    var body: some View {
        ZStack {
            // The barque waits low in the frame, moored for the night.
            VStack {
                Spacer()
                BarqueView(gate: .reeds, width: 420, discGlow: 0.9)
                    .opacity(0.9)
                    .offset(y: 44)
            }
            .allowsHitTesting(false)

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    FittingScrollColumn { titleColumn.padding(.horizontal, 14) }
                        .frame(width: min(260, max(200, proxy.size.width * 0.31)))

                    TabView(selection: $selectedIndex) {
                        ForEach(Array(GameData.classes.enumerated()), id: \.element.id) { index, entry in
                            ClassCardView(hero: entry)
                                .padding(.horizontal, 14)
                                .padding(.top, 10)
                                .padding(.bottom, 28)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .onChange(of: selectedIndex) { _, _ in
                        Haptics.light()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .sheet(isPresented: $showRecords) {
            RecordsSheetView()
        }
        .alert("Leave that night behind?", isPresented: $confirmingOverwrite) {
            Button("Cast Off Anyway", role: .destructive) {
                game.startRun(with: hero)
            }
            Button("Keep It", role: .cancel) {}
        } message: {
            if let save = game.savedRun {
                Text("\(save.hero.name) is still on the river at \(save.placeLabel). This save uses its original combat rules. Starting a new voyage uses the same-face system and replaces this save.")
            }
        }
    }

    private var titleColumn: some View {
        VStack(spacing: 10) {
            Button("Back to Menu", action: onBack)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.gold)
                .accessibilityIdentifier("heroSelect.back")
            Spacer(minLength: 0)

            // Ra's disc, low and burning inside its halo.
            ZStack {
                PharaohSWagerImage(name: "duat_environment_sun_halo", height: 122, fit: .fit)
                    .opacity(glowPulse ? 0.55 : 0.3)
                    .scaleEffect(glowPulse ? 1.05 : 1)

                PharaohSWagerImage(name: "duat_environment_sun_bright", height: 58, fit: .fit)
                    .shadow(color: Theme.sunGold.opacity(0.9), radius: glowPulse ? 26 : 12)
            }
            .frame(height: 84)

            VStack(spacing: 2) {
                Text("THE TWELVE HOURS")
                    .font(.fantasy(25, weight: .black))
                    .kerning(3.5)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.parchment, Theme.gold, Theme.goldDeep],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("OF THE DUAT")
                    .font(.fantasy(19, weight: .black))
                    .kerning(8)
                    .foregroundStyle(Theme.gold.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            WingedDivider(height: 26, opacity: 0.9)
                .frame(width: 210)

            Text("Guard Ra's barque until dawn.")
                .font(.paper(12.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)

            Spacer(minLength: 0)

            // A night still waiting is the first thing offered, above the
            // class select — with the hour and purse you would step back into.
            if let save = game.savedRun {
                continueButton(save)
            }

            classPicker

            Button {
                // Casting off over a saved night asks first.
                if game.hasSavedRun {
                    confirmingOverwrite = true
                    Haptics.warning()
                } else {
                    game.startRun(with: hero)
                }
            } label: {
                VStack(spacing: 1) {
                    Text("Cast Off")
                        .font(.fantasy(19, weight: .bold))
                    Text("THE FIRST HOUR AWAITS")
                        .font(.system(size: 7.5, weight: .black))
                        .kerning(1.6)
                        .opacity(0.75)
                }
                .foregroundStyle(Theme.parchment)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                // The same carved slab the deck's FIGHT button is cut from, so
                // the way into a run reads as a real pressable stone rather
                // than two lines of text floating on the title screen.
                .background {
                    DeckButtonSurface(tone: .primary, state: .highlighted,
                                      rim: hero.accent, cornerRadius: 16, emphasis: 1)
                }
                .shadow(color: hero.accent.opacity(0.45), radius: 18, y: 6)
            }
            .buttonStyle(PressableButtonStyle())

            HStack(spacing: 6) {
                recordsButton
                briefingButton
            }
            .padding(.bottom, 14)
        }
    }

    /// The night still waiting on the river. Shows who is out there, how deep
    /// they got and what they are carrying, so stepping back in is never a
    /// guess.
    private func continueButton(_ save: RunSave) -> some View {
        Button {
            if save.version == RunSave.currentVersion { game.continueRun() }
            else { confirmingOverwrite = true }
        } label: {
            HStack(spacing: 10) {
                PharaohSWagerSymbol(art: PharaohSWagerArt.classSigil(save.classID),
                           fallback: save.hero.symbol,
                           size: 24, tint: save.hero.accent)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(save.version == RunSave.currentVersion ? "Continue the Voyage" : "Old rules · Start a new voyage")
                        .font(.fantasy(17, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                    Text("\(save.hero.name) · \(save.placeLabel)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.parchmentDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(spacing: 3) {
                        PharaohSWagerIcon(name: PharaohSWagerArt.currency, size: 13)
                        Text("\(save.gold)")
                            .font(.system(size: 12, weight: .black).monospacedDigit())
                            .foregroundStyle(Theme.gold)
                    }
                    Text("\(save.currentHP)/\(save.maxHP) HP")
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                        .foregroundStyle(save.currentHP * 3 < save.maxHP
                                         ? Theme.blood : Theme.parchmentDim)
                }
            }
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                DeckButtonSurface(tone: .secondary, state: .normal,
                                  rim: save.hero.accent, cornerRadius: 15)
            }
            .shadow(color: save.hero.accent.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.bottom, 4)
    }

    /// The opening briefing stays reachable here, even once it has been
    /// dismissed for good — it is taught in whichever demigod is selected.
    private var briefingButton: some View {
        Button {
            game.openBriefing(for: hero)
            Haptics.light()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("How to Play")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Theme.bgCard.opacity(0.85), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Quick way into the personal leaderboard from the title screen.
    private var recordsButton: some View {
        Button {
            showRecords = true
            Haptics.light()
        } label: {
            HStack(spacing: 6) {
                PharaohSWagerIcon(name: PharaohSWagerArt.utilityRecords, size: 15)
                Text(bestLine)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.bgCard.opacity(0.85), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var bestLine: String {
        guard let best = game.bestRecord else { return "No voyage recorded — make one" }
        if best.sawDawn { return "Best: saw the dawn · \(best.className)" }
        return "Best: \(Voyage.ordinal(best.hourReached)) Hour · \(best.className)"
    }

    private var classPicker: some View {
        HStack(spacing: 6) {
            ForEach(Array(GameData.classes.enumerated()), id: \.element.id) { index, entry in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedIndex = index
                    }
                    Haptics.light()
                } label: {
                    PharaohSWagerSymbol(art: PharaohSWagerArt.classSigil(entry.id),
                               fallback: entry.symbol,
                               size: 22,
                               tint: entry.accent)
                        .frame(width: 54, height: 40)
                        .background {
                            PharaohSWagerImage(name: PharaohSWagerArt.button(.secondary,
                                                           index == selectedIndex ? .selected : .normal),
                                      fit: .stretch)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .modifier(TintWash(tint: index == selectedIndex ? entry.accent : nil))
                        }
                        .clipShape(.rect(cornerRadius: 9))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(entry.name)
                .accessibilityIdentifier("heroSelect.\(entry.id)")
                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            }
        }
        .padding(.bottom, 6)
    }
}

/// The opening menu is deliberately separate from choosing a demigod.
struct TitleView: View {
    @Environment(GameManager.self) private var game
    @State private var choosingHero = false
    @State private var showRecords = false
    @State private var showSettings = false

    var body: some View {
        Group {
            if choosingHero {
                HeroSelectionView { choosingHero = false }
            } else {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Theme.bg.ignoresSafeArea()
                        if let painting = UIImage(named: "ink_title_battle") {
                            Image(uiImage: painting).resizable().scaledToFit()
                                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .trailing)
                                .accessibilityHidden(true)
                        }
                        LinearGradient(colors: [Theme.bg.opacity(0.96), Theme.bg.opacity(0.5), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .allowsHitTesting(false)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("THE TWELVE HOURS\nOF THE DUAT")
                                    .font(.fantasy(27, weight: .black))
                                    .foregroundStyle(Theme.gold)
                                    .minimumScaleFactor(0.65)
                                    .accessibilityAddTraits(.isHeader)
                                Text("Four demigods. One night. Defy Apep.")
                                    .font(.paper(12)).foregroundStyle(Theme.parchmentDim)
                                menuButton("Play Game", symbol: "play.fill", id: "title.play") { choosingHero = true }
                                menuButton("Best Runs", symbol: "trophy.fill", id: "title.records") { showRecords = true }
                                menuButton("Settings", symbol: "gearshape.fill", id: "title.settings") { showSettings = true }
                                if let save = game.savedRun, save.version == RunSave.currentVersion {
                                    menuButton("Continue Voyage", symbol: "arrow.forward", id: "title.continue") { game.continueRun() }
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                        }
                        .frame(width: min(320, max(235, proxy.size.width * 0.35)))
                    }
                }
            }
        }
        .sheet(isPresented: $showRecords) { RecordsSheetView() }
        .sheet(isPresented: $showSettings) { TitleSettingsView() }
    }

    private func menuButton(_ title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.fantasy(19, weight: .bold))
                .foregroundStyle(Theme.parchment)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 15)
                .background {
                    DeckButtonSurface(tone: id == "title.play" ? .primary : .secondary,
                                      state: .normal, rim: Theme.gold, cornerRadius: 12)
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier(id)
    }
}

private struct TitleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var audio = Audio.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Slider(value: Binding(get: { audio.musicVolume }, set: { audio.musicVolume = $0 }), in: 0...1) {
                        Text("Music volume")
                    }
                    Text("Music: \(Int(audio.musicVolume * 100))%")
                    Slider(value: Binding(get: { audio.effectsVolume }, set: { audio.effectsVolume = $0 }), in: 0...1,
                           onEditingChanged: { editing in if !editing { audio.play(.uiTap) } }) {
                        Text("Sound effects volume")
                    }
                    Text("Sound effects: \(Int(audio.effectsVolume * 100))%")
                }
                Section("Accessibility") {
                    Text("The game follows your device's Reduce Motion setting. Change it in iOS Settings → Accessibility → Motion.")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview(traits: .landscapeLeft) {
    ZStack {
        Theme.bg.ignoresSafeArea()
        TitleView()
    }
    .environment(GameManager())
}

