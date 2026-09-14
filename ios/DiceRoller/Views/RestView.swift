import SwiftUI

/// Mooring the Barque: tie off against the bank, heal or work the whetstone
/// while the crew watches the dark. Never both.
struct RestView: View {
    @Environment(GameManager.self) private var game
    @State private var flicker = false

    private var healAmount: Int { max(20, Int(Double(game.maxHP) * 0.35)) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    CarvedTitle(text: "Mooring the Barque", size: 19, kerning: 2.5)
                        .frame(width: 280, alignment: .leading)
                    Text("One hour of quiet water. Sleep, or work the whetstone.")
                        .font(.paper(11.5))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    RunStatusBar(game: game)
                    NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            Spacer()

            HStack(spacing: 18) {
                restCard(
                    icon: "moon.zzz.fill",
                    tint: Theme.nileGreen,
                    title: "Sleep by the Hull",
                    detail: "Restore \(healAmount) health.",
                    footnote: "The crew keeps watch. Nothing comes."
                ) {
                    game.rest(heal: true)
                }

                restCard(
                    icon: "hammer.fill",
                    tint: Theme.gold,
                    title: "Work the Whetstone",
                    detail: "Reforge one face on any die into something better.",
                    footnote: "You choose the die and the face."
                ) {
                    game.rest(heal: false)
                }
            }

            Spacer()
        }
        .background(
            ZStack {
                RadialGradient(colors: [Theme.ember.opacity(flicker ? 0.20 : 0.10), .clear],
                               center: .bottom, startRadius: 20, endRadius: 460)
                VStack {
                    Spacer()
                    BarqueView(gate: game.gate, width: 520, discGlow: game.discGlow, animated: false)
                        .opacity(0.35)
                        .offset(y: 110)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { flicker = true }
        }
    }

    private func restCard(
        icon: String,
        tint: Color,
        title: String,
        detail: String,
        footnote: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 62, height: 62)
                    .background(Theme.bg, in: .circle)
                    .overlay(Circle().strokeBorder(tint.opacity(0.5), lineWidth: 1.5))
                    .shadow(color: tint.opacity(0.5), radius: 14)

                Text(title)
                    .font(.fantasy(18, weight: .black))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(footnote)
                    .font(.paper(10.5))
                    .italic()
                    .foregroundStyle(tint.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .frame(width: 250, height: 224)
            .duatPanel(tint: tint, cornerRadius: 20)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(game.restUsed)
    }
}
