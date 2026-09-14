import SwiftUI

/// The Trial prompt: as an ordinary fight opens, a god's sigil rises over the
/// arena, names its champion, states the exact power being lent and the boon
/// on offer — then the player chooses. Declining costs nothing and offends
/// nobody; the encounter is fought as normal.
struct TrialPromptView: View {
    let engine: BattleEngine
    @State private var shown = false

    private var trial: DivineTrial? { engine.trial }

    var body: some View {
        ZStack {
            Theme.bg.opacity(0.86).ignoresSafeArea()

            if let trial {
                let tint = trial.deity.tint
                HStack(spacing: 26) {
                    sigil(trial, tint: tint)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 7) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tint)
                            Text("A DIVINE TRIAL")
                                .font(.system(size: 10, weight: .black))
                                .kerning(3)
                                .foregroundStyle(tint)
                        }

                        Text(trial.name.uppercased())
                            .font(.fantasy(26, weight: .black))
                            .kerning(1.5)
                            .foregroundStyle(
                                LinearGradient(colors: [Theme.parchment, tint],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        HieroglyphBand(tint: tint, height: 7, opacity: 0.5)
                            .frame(width: 260)

                        Text(trial.power)
                            .font(.paper(12))
                            .foregroundStyle(Theme.parchment.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 380, alignment: .leading)

                        Text(trial.boonLine)
                            .font(.system(size: 10, weight: .semibold))
                            .italic()
                            .foregroundStyle(Theme.parchmentDim)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 380, alignment: .leading)

                        Text("In a pack, the champion is ringed in \(trial.deity.name)'s colour for the whole fight.")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.parchmentDim.opacity(0.8))

                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.easeOut(duration: 0.3)) { shown = false }
                                Haptics.heavy()
                                Task {
                                    try? await Task.sleep(for: .milliseconds(280))
                                    engine.acceptTrial()
                                }
                            } label: {
                                Text("Take the Trial")
                                    .font(.fantasy(15, weight: .bold))
                                    .foregroundStyle(Theme.bg)
                                    .frame(width: 210, height: 44)
                                    .background(
                                        LinearGradient(colors: [Theme.gold, tint],
                                                       startPoint: .top, endPoint: .bottom),
                                        in: .capsule
                                    )
                            }
                            .buttonStyle(PressableButtonStyle())

                            Button {
                                withAnimation(.easeOut(duration: 0.3)) { shown = false }
                                Haptics.light()
                                Task {
                                    try? await Task.sleep(for: .milliseconds(280))
                                    engine.declineTrial()
                                }
                            } label: {
                                Text("Fight On — no penalty")
                                    .font(.fantasy(13, weight: .bold))
                                    .foregroundStyle(Theme.parchmentDim)
                                    .frame(width: 220, height: 44)
                                    .background(Theme.bgCard.opacity(0.9), in: .capsule)
                                    .overlay(Capsule().strokeBorder(Theme.parchmentDim.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(28)
                .scaleEffect(shown ? 1 : 0.92)
                .opacity(shown ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { shown = true }
            Haptics.heavy()
        }
    }

    /// The god's sigil rising over the arena on a shaft of light.
    private func sigil(_ trial: DivineTrial, tint: Color) -> some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [tint.opacity(0.32), .clear],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 70, height: 150)
                .blur(radius: 12)

            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.4), .clear],
                                     center: .center, startRadius: 2, endRadius: 64))
                .frame(width: 130, height: 130)

            PortraitMedallionView(art: CharacterArt.god(trial.deity),
                                  fallbackSymbol: trial.deity.symbol,
                                  tint: tint,
                                  diameter: 100)
                .shadow(color: tint.opacity(0.75), radius: 20)

            Text(trial.deity.name.uppercased())
                .font(.system(size: 10, weight: .black))
                .kerning(2.4)
                .foregroundStyle(tint)
                .offset(y: 84)
        }
        .frame(width: 150)
    }
}
