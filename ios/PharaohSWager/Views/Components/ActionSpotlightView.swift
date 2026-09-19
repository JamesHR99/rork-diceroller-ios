import SwiftUI

/// One action, named and held still for a beat before it resolves.
///
/// A fight used to be legible only if you could read floaters while the
/// numbers were still moving: you saw a colour fly past and never learned
/// which blow it belonged to or what it was worth. This card stops the board
/// for a moment and states the whole action in one place — who is acting,
/// what they are doing, the faces that fed it, what it will cost, who it is
/// pointed at, and every god power riding it.
///
/// It is not the chain spectacle: no shockwave, no embers, nothing that
/// competes with a landing combo. A carved tablet rising out of the dark,
/// then gone.
struct ActionSpotlightView: View {
    let card: ActionSpotlight

    @State private var risen = false
    @State private var glow = false

    /// The gods answering, in the order they landed, each named once even when
    /// several of their powers spoke.
    private var gods: [Deity] {
        var seen: Set<Deity> = []
        return card.entries.compactMap { entry in
            guard !seen.contains(entry.god) else { return nil }
            seen.insert(entry.god)
            return entry.god
        }
    }

    /// The card takes its colour from the action itself, so a blow of yours
    /// and a blow against you never read the same.
    private var accent: Color { card.tint }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            tablet
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) { risen = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private var tablet: some View {
        VStack(spacing: 8) {
            actorLine
            titleLine
            facesRow
            detailLine

            if !card.entries.isEmpty {
                GoldRule(height: 4, opacity: 0.6).frame(width: 210)
                godsHeading
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading),
                                         count: card.entries.count > 2 ? 2 : 1), spacing: 6) {
                    ForEach(card.entries) { entry in
                        entryRow(entry)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: card.entries.count > 2 ? 620 : 380)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bgElevated, strength: 0.6, shade: 0.42)
                .clipShape(.rect(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.35)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.6
                )
        )
        .goldCorners(size: 18, inset: 4, opacity: 0.7)
        .shadow(color: accent.opacity(glow ? 0.55 : 0.3), radius: glow ? 26 : 16)
        .shadow(color: .black.opacity(0.7), radius: 14, y: 6)
        .scaleEffect(risen ? 1 : 0.86)
        .opacity(risen ? 1 : 0)
        .blur(radius: risen ? 0 : 5)
    }

    /// Who is acting, and where the blow is going. A creature spending its
    /// round on a sequence says which part of it this is.
    private var actorLine: some View {
        HStack(spacing: 6) {
            Text(card.actor.uppercased())
                .font(.system(size: 9.5, weight: .black))
                .kerning(2.4)
                .foregroundStyle(card.isPlayer ? Theme.gold : Theme.blood)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let sequence = card.sequence {
                Text(sequence.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Theme.parchmentDim, in: .capsule)
            }

            if let target = card.target {
                HStack(spacing: 3) {
                    PharaohSWagerSymbol(art: PharaohSWagerArt.Status.marked, fallback: "target",
                               size: 10, tint: Theme.parchmentDim)
                    Text(target.uppercased())
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(1)
                        .foregroundStyle(Theme.parchmentDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    /// The action's own name, in full type — the thing you actually wanted to
    /// be able to read.
    private var titleLine: some View {
        Text(card.title.uppercased())
            .font(.fantasy(card.isDiscovery ? 26 : 24, weight: .black))
            .kerning(1.6)
            .foregroundStyle(
                LinearGradient(colors: [Theme.parchment, accent],
                               startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: accent.opacity(0.8), radius: 10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    /// The faces that fed this action, in order — a chain reads as one object.
    @ViewBuilder
    private var facesRow: some View {
        if !card.faces.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(card.faces.prefix(5).enumerated()), id: \.offset) { _, face in
                    PharaohSWagerSymbol(art: face.artName, fallback: face.symbol,
                               size: 22, tint: face.tint)
                        .frame(width: 28, height: 26)
                        .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(accent.opacity(0.45), lineWidth: 1)
                        )
                }
            }
        }
    }

    /// What it is worth: damage, guard, mending, statuses — the same words the
    /// plan card used, so the two read against each other.
    private var detailLine: some View {
        HStack(spacing: 5) {
            if card.charge > 0 {
                PharaohSWagerSymbol(art: PharaohSWagerArt.Status.critical,
                           fallback: "bolt.trianglebadge.exclamationmark.fill",
                           size: 14, tint: Theme.ember)
            }
            Text(card.detail)
                .font(.system(size: 13, weight: .black).monospacedDigit())
                .foregroundStyle(card.isPlayer ? Theme.ember : Theme.blood)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(Theme.bg.opacity(0.6), in: .capsule)
        .overlay(Capsule().strokeBorder(accent.opacity(0.4), lineWidth: 1))
    }

    /// The gods who spoke, haloed, over their list.
    private var godsHeading: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                ForEach(gods.prefix(3), id: \.self) { god in
                    PharaohSWagerSymbol(art: god.artName, fallback: god.symbol, size: 28, tint: god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: glow ? 12 : 7)
                }
            }

            Text(gods.count == 1
                 ? "\(gods[0].name.uppercased()) ANSWERS"
                 : "THE GODS ANSWER")
                .font(.fantasy(12, weight: .black))
                .kerning(2)
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// One power: its god's colour, its name, and exactly what it did.
    private func entryRow(_ entry: DivineFlashEntry) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(entry.god.tint)
                .frame(width: 6, height: 6)
                .shadow(color: entry.god.tint.opacity(0.9), radius: 4)

            Text(entry.name.uppercased())
                .font(.system(size: 11, weight: .black))
                .kerning(0.6)
                .foregroundStyle(Theme.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 6)

            Text(entry.effect)
                .font(.system(size: 11.5, weight: .black).monospacedDigit())
                .foregroundStyle(entry.god.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Theme.bg.opacity(0.62), in: .rect(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(entry.god.tint.opacity(0.35), lineWidth: 1)
        )
    }
}

