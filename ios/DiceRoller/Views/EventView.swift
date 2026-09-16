import SwiftUI

/// An Omen: a strange sighting on the river. The story sits on the left,
/// the choices on the right.
struct EventView: View {
    @Environment(GameManager.self) private var game

    var body: some View {
        if let event = game.currentEvent {
            HStack(spacing: 20) {
                storyColumn(event)
                choiceColumn(event)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RadialGradient(colors: [Theme.duskViolet.opacity(0.16), .clear],
                               center: .leading, startRadius: 30, endRadius: 520)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
        } else {
            Color.clear
        }
    }

    private func storyColumn(_ event: RunEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                DuatSymbol(art: StageKind.omen.artName, fallback: event.symbol,
                           size: 34, tint: Theme.duskViolet)
                    .frame(width: 50, height: 50)
                    .background(Theme.bgCard, in: .circle)
                    .overlay(Circle().strokeBorder(Theme.duskViolet.opacity(0.55), lineWidth: 1.5))
                    .shadow(color: Theme.duskViolet.opacity(0.5), radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AN OMEN ON THE RIVER")
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(2)
                        .foregroundStyle(Theme.duskViolet)
                    Text(event.title)
                        .font(.fantasy(21, weight: .black))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }

            GoldRule(height: 6, opacity: 0.75)
                .frame(width: 300)

            Text(event.body)
                .font(.paper(13.5))
                .foregroundStyle(Theme.parchmentDim)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 5) {
                RunStatusBar(game: game)
                NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)
            }
        }
        .frame(width: 330, alignment: .leading)
    }

    private func choiceColumn(_ event: RunEvent) -> some View {
        VStack(spacing: 8) {
            if let outcome = game.eventOutcome {
                VStack(spacing: 10) {
                    Text(outcome)
                        .font(.fantasy(15, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        game.leaveEncounter()
                        Haptics.medium()
                    } label: {
                        Text("Row On")
                            .font(.fantasy(18, weight: .bold))
                            .kerning(1)
                            .foregroundStyle(
                                LinearGradient(colors: [Theme.parchment, Theme.gold],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: .black.opacity(0.75), radius: 2, y: 1)
                            .frame(width: 240, height: 52)
                            .background {
                                DeckButtonSurface(tone: .primary, state: .normal, rim: Theme.gold,
                                                  cornerRadius: 14, emphasis: 0.6)
                            }
                            .goldCorners(size: 14, inset: 3, opacity: 0.75)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .duatPanel(tint: Theme.gold, cornerRadius: 18)
            } else {
                ForEach(event.choices) { choice in
                    choiceRow(choice)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func choiceRow(_ choice: EventChoice) -> some View {
        let affordable = choice.goldCost <= game.gold
        return Button {
            game.choose(choice)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.label)
                        .font(.fantasy(15, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(choice.detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.parchment.opacity(0.8))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                DuatImage(name: DuatArt.utilityForward, width: 19, fit: .fit)
                    .colorMultiply(Theme.duskViolet)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .duatPanel(tint: Theme.duskViolet, cornerRadius: 14, showsBand: false)
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
    }
}
