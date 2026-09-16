import SwiftUI

/// The hour strip: one carved line carrying your plan and every foe's
/// telegraphed blow in the order they will actually resolve. This is where the
/// enemy's intent is read now — the capsules under the health bars are gone,
/// because a blow you cannot place in time is not information you can use.
///
/// Your actions sit above the line, theirs below it, and the beat each one
/// lands on is inked between them. Ties resolve in your favour, which the strip
/// shows by putting you first.
struct TimelineStripView: View {
    let engine: BattleEngine
    /// Height of the whole band, handed down so it shrinks with the deck.
    var height: CGFloat = 60

    private var entries: [TimelineEntry] { engine.timeline }

    var body: some View {
        VStack(spacing: 3) {
            header

            if entries.isEmpty {
                emptyLine
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(entries) { entry in
                            TimelineBeadView(
                                entry: entry,
                                foeName: name(for: entry),
                                isNow: engine.currentBeat > 0 && entry.beat == engine.currentBeat,
                                isPast: engine.currentBeat > entry.beat,
                                height: beadHeight
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .contentMargins(.horizontal, 10, for: .scrollContent)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(height: height)
        .background {
            // A sunk channel of stone, so the strip reads as carved into the
            // deck rather than floating above it.
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.bg.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Theme.rule.opacity(0.4), lineWidth: 1)
                }
                .allowsHitTesting(false)
        }
    }

    private var beadHeight: CGFloat { max(24, height - 26) }

    private var header: some View {
        HStack(spacing: 5) {
            Text("THE HOUR")
                .font(.system(size: 8.5, weight: .black))
                .kerning(1.6)
                .foregroundStyle(Theme.gold.opacity(0.85))

            Rectangle()
                .fill(Theme.rule.opacity(0.35))
                .frame(height: 1)

            // What the round is going to cost you, read straight off the strip.
            if let firstHit = entries.first(where: { !$0.isPlayer && $0.roles.contains(.attack) }) {
                Text("INCOMING BEAT \(firstHit.beat)")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.blood.opacity(0.9))
            }
        }
    }

    private var emptyLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.parchmentDim)
            Text("Lay dice into the plan — the hour fills as you build it.")
                .font(.paper(11))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }

    private func name(for entry: TimelineEntry) -> String {
        guard case .foe(let id) = entry.side else { return "" }
        return engine.enemies.first { $0.id == id }?.displayName ?? ""
    }
}

/// One scheduled action on the strip: its beat, its name and what it will do.
private struct TimelineBeadView: View {
    let entry: TimelineEntry
    let foeName: String
    let isNow: Bool
    let isPast: Bool
    let height: CGFloat

    private var tint: Color {
        if entry.isPlayer {
            return entry.roles.contains(.attack) ? Theme.gold : Theme.steelBlue
        }
        return entry.roles.contains(.attack) ? Theme.blood : Theme.steel
    }

    var body: some View {
        VStack(spacing: 1) {
            // The beat number, inked in a cartouche tick.
            Text("\(entry.beat)")
                .font(.system(size: 9, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.bg)
                .frame(width: 15, height: 13)
                .background(tint.opacity(isPast ? 0.4 : 1), in: .capsule)

            Text(entry.title.uppercased())
                .font(.system(size: 8, weight: .black))
                .kerning(0.3)
                .foregroundStyle(entry.isPlayer ? Theme.parchment : Theme.blood.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(entry.detail)
                .font(.system(size: 7.5, weight: .bold))
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .frame(minWidth: 62, maxWidth: 96)
        .frame(height: height)
        .background {
            RoundedRectangle(cornerRadius: 7)
                .fill(entry.isPlayer ? Theme.bgCard.opacity(0.9) : Theme.bgElevated.opacity(0.85))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(tint.opacity(isNow ? 0.95 : 0.45),
                                      lineWidth: isNow ? 1.6 : 0.8)
                }
        }
        // Your side rides a little high and theirs a little low, so the two
        // halves of the round read apart at a glance.
        .offset(y: entry.isPlayer ? -2 : 2)
        .opacity(isPast ? 0.45 : 1)
        .overlay(alignment: .topTrailing) {
            // Haste is shown honestly: the beats it actually saved.
            if entry.hastened > 0 {
                Text("-\(entry.hastened)")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Theme.frost, in: .capsule)
                    .offset(x: 3, y: -3)
            }
        }
        .accessibilityLabel("\(entry.isPlayer ? "Your" : foeName) \(entry.title) at beat \(entry.beat), \(entry.detail)")
    }
}
