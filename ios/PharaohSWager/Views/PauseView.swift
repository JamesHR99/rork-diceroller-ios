import SwiftUI

/// The pause panel. The night stills behind a darkened sheet: resume, put the
/// run away for later, read the codex, set the two volumes, or abandon it.
struct PauseView: View {
    @Environment(GameManager.self) private var game
    @State private var audio = Audio.shared
    @State private var showCodex = false
    @State private var confirmingAbandon = false

    /// True while a fight is underway, so the save line can be honest about
    /// where the night will pick back up.
    private var inBattle: Bool { game.screen == .battle }

    var body: some View {
        ZStack {
            // The fight is still there, just put behind glass.
            Theme.bg.opacity(0.88)
                .ignoresSafeArea()
                .onTapGesture { resume() }

            GeometryReader { proxy in
                ScrollView(.vertical) {
                    panel
                        .padding(12)
                        .frame(minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            }
            .frame(maxWidth: 424)
        }
        .sheet(isPresented: $showCodex) {
            if let loadout = game.loadout {
                InfoSheetView(
                    loadout: loadout,
                    classID: game.classID,
                    critBonus: game.critBonus,
                    maxStamina: game.effectiveMaxStamina,
                    drawnDieIDs: [],
                    hasMetTrial: game.trialUsed,
                    boons: game.equippedBoons
                )
            }
        }
    }

    private var panel: some View {
        VStack(spacing: 12) {
            header

            GoldRule(height: 5, opacity: 0.6)
                .padding(.horizontal, 20)

            if confirmingAbandon {
                abandonConfirmation
            } else {
                buttons
                volumeSliders
            }
        }
        .padding(18)
        .frame(maxWidth: 400)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bgCard, strength: 0.7, shade: 0.4)
                .clipShape(.rect(cornerRadius: 20))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.gold.opacity(0.45), lineWidth: 1.5)
        )
        .goldCorners(size: 20, inset: 3, opacity: 0.7)
        .shadow(color: .black.opacity(0.8), radius: 30, y: 10)
    }

    private var header: some View {
        VStack(spacing: 3) {
            PharaohSWagerIcon(name: PharaohSWagerArt.Status.judgement, size: 30)
                .opacity(0.9)

            Text("THE BARQUE HOLDS")
                .font(.fantasy(21, weight: .black))
                .kerning(2.5)
                .foregroundStyle(
                    LinearGradient(colors: [Theme.parchment, Theme.gold],
                                   startPoint: .top, endPoint: .bottom)
                )

            Text(game.savedRun == nil
                 ? Voyage.fullName(game.currentHour)
                 : "\(Voyage.fullName(game.currentHour)) · \(game.gold) gold")
                .font(.paper(12))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
        }
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            pauseButton(
                title: "Resume",
                detail: "Back to the night",
                art: PharaohSWagerArt.Status.stamina,
                fallback: "play.fill",
                tone: .primary,
                rim: Theme.gold
            ) { resume() }

            pauseButton(
                title: "Save and Exit",
                detail: inBattle
                    ? "Resumes at the start of this fight"
                    : "Resumes exactly here",
                art: PharaohSWagerArt.interactionHeld,
                fallback: "square.and.arrow.down.fill",
                tone: .secondary,
                rim: Theme.frost
            ) {
                game.saveAndExit()
            }

            pauseButton(
                title: "The Codex",
                detail: "Rules, chains and statuses",
                art: PharaohSWagerArt.utilityRecords,
                fallback: "book.closed.fill",
                tone: .secondary,
                rim: Theme.parchmentDim
            ) {
                showCodex = true
                Audio.shared.play(.uiTap)
            }

            pauseButton(
                title: "Abandon the Voyage",
                detail: "The night is lost for good",
                art: PharaohSWagerArt.Status.bleed,
                fallback: "xmark.circle.fill",
                tone: .secondary,
                rim: Theme.blood
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    confirmingAbandon = true
                }
                Haptics.warning()
            }
        }
    }

    private func pauseButton(
        title: String,
        detail: String,
        art: String,
        fallback: String,
        tone: PharaohSWagerArt.ButtonTone,
        rim: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PharaohSWagerSymbol(art: art, fallback: fallback, size: 20, tint: rim)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.fantasy(17, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                    Text(detail)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                DeckButtonSurface(tone: tone, state: .normal, rim: rim, cornerRadius: 13)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Abandoning throws the night away, so it asks first.
    private var abandonConfirmation: some View {
        VStack(spacing: 10) {
            Text("Abandon the voyage?")
                .font(.fantasy(18, weight: .black))
                .foregroundStyle(Theme.blood)

            Text("Everything this night earned is lost — the dice, the blessings, the hours. The chains you discovered stay found.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.parchmentDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        confirmingAbandon = false
                    }
                } label: {
                    Text("Keep Going")
                        .font(.fantasy(16, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.gold)
                        }
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    game.abandonRun()
                } label: {
                    Text("Abandon It")
                        .font(.fantasy(16, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            DeckButtonSurface(tone: .primary, state: .highlighted,
                                              rim: Theme.blood, emphasis: 1)
                        }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: - Volumes

    private var volumeSliders: some View {
        VStack(spacing: 7) {
            volumeRow(
                label: "MUSIC",
                art: PharaohSWagerArt.Status.champion,
                fallback: "music.note",
                value: Binding(
                    get: { audio.musicVolume },
                    set: { audio.musicVolume = $0 }
                )
            )

            volumeRow(
                label: "SOUND",
                art: PharaohSWagerArt.Status.critical,
                fallback: "speaker.wave.2.fill",
                value: Binding(
                    get: { audio.effectsVolume },
                    set: { audio.effectsVolume = $0 }
                ),
                // A nudge of the sound slider plays a tap so the level can be
                // heard as it is set rather than guessed at.
                onChange: { Audio.shared.play(.uiTap) }
            )
        }
        .padding(.top, 2)
    }

    private func volumeRow(
        label: String,
        art: String,
        fallback: String,
        value: Binding<Float>,
        onChange: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 9) {
            PharaohSWagerSymbol(art: art, fallback: fallback, size: 15, tint: Theme.gold)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 9.5, weight: .black))
                .kerning(1)
                .foregroundStyle(Theme.parchmentDim)
                .frame(width: 48, alignment: .leading)

            Slider(value: value, in: 0...1) { editing in
                if !editing { onChange?() }
            }
            .tint(Theme.gold)

            Text("\(Int(value.wrappedValue * 100))")
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.gold)
                .frame(width: 26, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 11))
    }

    private func resume() {
        Audio.shared.play(.uiTap)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            game.isPaused = false
        }
    }
}

/// The gold pause glyph that sits in the top right of every screen of a run.
struct PauseButton: View {
    @Environment(GameManager.self) private var game

    var body: some View {
        Button {
            Haptics.light()
            Audio.shared.play(.uiTap)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                game.isPaused = true
            }
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Theme.gold)
                .frame(width: 34, height: 34)
                .background(Theme.bg.opacity(0.7), in: .circle)
                .overlay(Circle().strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1.2))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Pause")
    }
}
