import SwiftUI

/// Your device's ten deepest voyages, newest entry highlighted.
struct LeaderboardView: View {
    let records: [RunRecord]
    let highlightID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if records.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            row(record, rank: index + 1)
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            DuatIcon(name: DuatArt.utilityRecords, size: 14)
            Text("DEEPEST VOYAGES")
                .font(.system(size: 10, weight: .black))
                .kerning(1.4)
            Spacer()
            Text("TOP \(LeaderboardStore.maxEntries)")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Theme.parchmentDim)
        }
        .foregroundStyle(Theme.gold)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            DuatImage(name: "duat_environment_star", height: 26, fit: .fit)
                .opacity(0.55)
            Text("No voyage recorded yet.")
                .font(.paper(13.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
            Text("Take the barque out and this fills in.")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 18)
    }

    private func row(_ record: RunRecord, rank: Int) -> some View {
        let isNew = record.id == highlightID
        return HStack(spacing: 8) {
            Text("\(rank)")
                .font(.system(size: 10, weight: .black).monospacedDigit())
                .foregroundStyle(rank <= 3 ? Theme.bg : Theme.parchmentDim)
                .frame(width: 18, height: 18)
                .background(rank <= 3 ? AnyShapeStyle(medalTint(rank)) : AnyShapeStyle(Theme.bg), in: .circle)

            DuatSymbol(art: DuatArt.classSigil(record.classID),
                       fallback: record.classSymbol,
                       size: 15,
                       tint: classTint(record.classID))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(record.className)
                        .font(.fantasy(12, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                    if record.sawDawn {
                        DuatImage(name: "duat_environment_sun_bright", height: 12, fit: .fit)
                    }
                    if isNew {
                        Text("THIS RUN")
                            .font(.system(size: 7, weight: .black))
                            .kerning(0.6)
                            .foregroundStyle(Theme.bg)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.gold, in: .capsule)
                    }
                }
                Text("\(record.verdict) · \(record.gateLabel) · \(record.dateLabel)")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 0) {
                Text(record.hourLabel)
                    .font(.fantasy(15, weight: .black))
                    .foregroundStyle(isNew ? Theme.gold : Theme.parchment)
                Text("hour")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
            }
            .frame(width: 34)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(isNew ? Theme.gold.opacity(0.14) : Theme.bg.opacity(0.55), in: .rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isNew ? Theme.gold.opacity(0.7) : record.gate.accent.opacity(0.22), lineWidth: 1)
        )
    }

    private func medalTint(_ rank: Int) -> Color {
        switch rank {
        case 1: Theme.gold
        case 2: Theme.steel
        default: Theme.copper
        }
    }

    private func classTint(_ id: String) -> Color {
        GameData.classes.first { $0.id == id }?.accent ?? Theme.parchmentDim
    }
}
