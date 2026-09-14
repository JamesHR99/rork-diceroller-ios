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
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.parchmentDim)
                        .frame(width: 34, height: 34)
                        .background(Theme.bgCard, in: .circle)
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
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(confirmClear ? Theme.blood : Theme.parchmentDim)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .presentationBackground(Theme.bg)
    }
}
