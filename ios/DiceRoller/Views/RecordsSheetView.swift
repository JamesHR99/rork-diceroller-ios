import SwiftUI

/// Personal leaderboard, opened from the title screen.
struct RecordsSheetView: View {
    @Environment(GameManager.self) private var game
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    CarvedTitle(text: "The Book of Nights", size: 19, kerning: 2.5)
                        .frame(width: 260, alignment: .leading)
                    Text("Your ten deepest voyages on this device")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    DuatIcon(name: DuatArt.utilityClose, size: 22)
                        .frame(width: 42, height: 42)
                        .background(Theme.bgCard, in: .circle)
                        .overlay(Circle().strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }

            LeaderboardView(records: game.leaderboard, highlightID: game.latestRecordID)
                .padding(14)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .duatPanel(tint: Theme.gold, cornerRadius: 18)

            if !game.leaderboard.isEmpty {
                Button {
                    if confirmClear {
                        game.clearLeaderboard()
                        confirmClear = false
                    } else {
                        confirmClear = true
                        Haptics.light()
                    }
                } label: {
                    Text(confirmClear ? "Tap again to burn the book" : "Clear records")
                        .font(.fantasy(14, weight: .bold))
                        .foregroundStyle(confirmClear ? Theme.blood : Theme.parchment.opacity(0.75))
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                        .frame(width: 250, height: 42)
                        .background {
                            DeckButtonSurface(tone: .secondary, state: .normal,
                                              rim: confirmClear ? Theme.blood : Theme.parchmentDim,
                                              cornerRadius: 11)
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: confirmClear)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .presentationBackground(Theme.bg)
    }
}
