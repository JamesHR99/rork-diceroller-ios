import SwiftUI

/// The barque at rest on a still black river under a full star field: the
/// game's name in carved gold on the left, the four demigods as tomb-wall
/// panels on the right.
struct TitleView: View {
    @Environment(GameManager.self) private var game
    @State private var selectedIndex = 0
    @State private var glowPulse = false
    @State private var showRecords = false

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

            HStack(spacing: 0) {
                titleColumn
                    .padding(.horizontal, 20)
                    .frame(width: 288)

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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .sheet(isPresented: $showRecords) {
            RecordsSheetView()
        }
    }

    private var titleColumn: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            // Ra's disc, low and burning.
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.sunGold.opacity(glowPulse ? 0.55 : 0.28), .clear],
                                         center: .center, startRadius: 2, endRadius: 74))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(RadialGradient(colors: [Theme.parchment, Theme.sunGold, Theme.emberDeep],
                                         center: .init(x: 0.4, y: 0.35), startRadius: 0, endRadius: 26))
                    .frame(width: 42, height: 42)
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

            HieroglyphBand(tint: Theme.gold, height: 9, opacity: 0.55)
                .frame(width: 210)

            Text("Guard Ra's barque until dawn.")
                .font(.paper(12.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)

            Spacer(minLength: 0)

            classPicker

            Button {
                game.startRun(with: hero)
            } label: {
                VStack(spacing: 1) {
                    Text("Cast Off")
                        .font(.fantasy(19, weight: .bold))
                    Text("THE FIRST HOUR AWAITS")
                        .font(.system(size: 7.5, weight: .black))
                        .kerning(1.6)
                        .opacity(0.75)
                }
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(colors: [Theme.gold, hero.accent], startPoint: .top, endPoint: .bottom),
                    in: .capsule
                )
                .shadow(color: hero.accent.opacity(0.55), radius: 16, y: 4)
            }
            .buttonStyle(PressableButtonStyle())

            recordsButton
                .padding(.bottom, 14)
        }
    }

    /// Quick way into the personal leaderboard from the title screen.
    private var recordsButton: some View {
        Button {
            showRecords = true
            Haptics.light()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .bold))
                Text(bestLine)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Theme.gold)
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
                    Image(systemName: entry.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(index == selectedIndex ? Theme.bg : entry.accent)
                        .frame(width: 54, height: 40)
                        .background(
                            index == selectedIndex ? AnyShapeStyle(entry.accent) : AnyShapeStyle(Theme.bgCard.opacity(0.85)),
                            in: .rect(cornerRadius: 9)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(entry.accent.opacity(index == selectedIndex ? 0 : 0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.bottom, 6)
    }
}

/// Springy press-down style shared by primary buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview(traits: .landscapeLeft) {
    ZStack {
        Theme.bg.ignoresSafeArea()
        TitleView()
    }
    .environment(GameManager())
}
