import SwiftUI

/// A single offer card used on the reward screen and the shop shelf.
struct OfferCardView: View {
    let offer: Offer
    let isSelected: Bool
    let affordable: Bool
    /// Fixed card width for scrolling shelves; pass `nil` to let the card share
    /// the row's width evenly (used by the three-card altar).
    var width: CGFloat? = 196
    let action: () -> Void

    /// The card's own read-out, chosen by what is on offer. Split out of the
    /// body so each branch type-checks on its own — as one long chain inside
    /// the VStack the compiler could not solve it in reasonable time.
    @ViewBuilder
    private var kindDigest: some View {
        switch offer.kind {
        case .die(let die):
            DieStripView(die: die, tileSize: 15, showCrit: false)
        case .patron:
            HStack(spacing: 5) {
                sealBadge(offer.deity?.artName, offer.deity?.symbol ?? "sparkles",
                          tint: offer.deity?.tint ?? Theme.gold)
                footnote(offer.isReplacingPatron ? "takes a claimed die" : "claims one die")
            }
        case .boon(let def, let rarity):
            boonDigest(slot: def.slot, god: def.god, rarity: rarity, level: 1, isUpgrade: false)
        case .boonLevel(let owned):
            boonDigest(slot: owned.def?.slot ?? .attack,
                       god: owned.def?.god ?? .ra,
                       rarity: owned.rarity,
                       level: min(owned.level + 1, boonMaxLevel),
                       isUpgrade: true)
        case .legendary(let def, let rarity):
            boonDigest(slot: def.slot, god: def.god, rarity: rarity, level: 1, isUpgrade: false)
        case .upgrade(let upgrade):
            HStack(spacing: 5) {
                sealBadge(offer.deity?.artName, upgrade.symbol, tint: offer.tint)
                footnote("one upgrade · needs a blessed die")
            }
        case .capstone:
            HStack(spacing: 5) {
                sealBadge(PharaohSWagerArt.Status.champion, "crown.fill", tint: offer.tint)
                footnote("capstone · one per run")
            }
        case .pairing(let pairing):
            HStack(spacing: 5) {
                sealBadge(pairing.first.artName, pairing.first.symbol, tint: pairing.first.tint)
                sealBadge(pairing.second.artName, pairing.second.symbol, tint: pairing.second.tint)
                footnote("2 gods · once per turn")
            }
        case .chiselPick(let chisel):
            HStack(spacing: 5) {
                sealBadge(chisel.artName, "hammer.fill", tint: Theme.ptahCopper)
                footnote(chisel.isOptional ? "armed per action" : "always at work")
            }
        default:
            EmptyView()
        }
    }

    /// A god power's read: which slot it fills, its rarity, and its level as
    /// filled cartouche pips — so rarity and level are read apart.
    private func boonDigest(
        slot: BoonSlot,
        god: Deity,
        rarity: BoonRarity,
        level: Int,
        isUpgrade: Bool
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                sealBadge(god.artName, god.symbol, tint: rarity.tint)
                Text(rarity.label.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(rarity.tint)
                levelPips(level)
            }
            footnote(isUpgrade ? "level up · same slot" : "\(slot.label.lowercased()) slot")
        }
    }

    /// Level as pips: filled for the levels held, hollow for the room left.
    private func levelPips(_ level: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<boonMaxLevel, id: \.self) { index in
                Circle()
                    .fill(index < level ? Theme.gold : Color.clear)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().strokeBorder(Theme.gold.opacity(0.7), lineWidth: 0.8))
            }
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                HStack(spacing: 5) {
                    // Rarity reads as a material swatch: clay, copper, lapis, gold leaf.
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(offer.rarity.materialGradient)
                        .frame(width: 11, height: 11)
                        .overlay(RoundedRectangle(cornerRadius: 2.5)
                            .strokeBorder(Theme.bg.opacity(0.6), lineWidth: 0.6))
                    Text(offer.rarity.label.uppercased())
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(0.8)
                        .foregroundStyle(offer.rarity.tint)
                    Spacer(minLength: 0)
                    if !offer.isFree {
                        HStack(spacing: 3) {
                            PharaohSWagerIcon(name: PharaohSWagerArt.currency, size: 16)
                            Text("\(offer.price)")
                                .font(.system(size: 13, weight: .black).monospacedDigit())
                                .foregroundStyle(affordable ? Theme.gold : Theme.blood)
                        }
                    }
                }

                // What is on offer, inside its rarity's painted frame. Drawn
                // large: a small plate blown up reads grainy, a large one reads
                // painted, and this is the thing you are choosing.
                PharaohSWagerSymbol(art: offer.artName, fallback: offer.symbol,
                           size: 50, tint: isSelected ? Theme.gold : offer.tint)
                    .frame(width: 66, height: 66)
                    .background {
                        PharaohSWagerImage(name: offer.rarity.frameArt, width: 76, height: 76, fit: .fit)
                            .modifier(TintWash(tint: offer.deity?.tint))
                    }
                    .shadow(color: offer.deity?.tint.opacity(0.5) ?? .clear, radius: 8)

                Text(offer.name)
                    .font(.fantasy(16, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                // What the thing actually does — the line that decides the
                // choice. Long Chisel text scrolls within the card at a
                // readable size while its name and selection remain visible.
                ScrollView(.vertical) {
                    Text(offer.detail)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.parchment.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                .frame(maxHeight: .infinity)

                kindDigest
            }
            .padding(11)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil, maxHeight: .infinity)
            .papyrusPanel(tint: Theme.bgCard, cornerRadius: 16, shade: 0.5, ground: .card)
            .overlay(alignment: .bottom) {
                GoldRule(height: 5, opacity: 0.6)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Theme.gold : offer.tint.opacity(offer.deity == nil ? 0.35 : 0.55),
                                  lineWidth: isSelected ? 2 : 1)
            )
            .goldCorners(size: 16, inset: 1, opacity: isSelected ? 0.9 : 0.45)
            .shadow(color: isSelected ? Theme.gold.opacity(0.35) : .clear, radius: 10)
            .opacity(affordable ? 1 : 0.5)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// What a multi-dice offer hands you, at a glance: the few faces that give
    /// it its character, plus how the whole set leans. Drawing all eighteen
    /// relic faces never fit the card, and told you less.
    private func faceDigest(_ profile: FaceProfile, diceCount: Int) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                ForEach(profile.signature.prefix(3)) { tally in
                    HStack(spacing: 2) {
                        PharaohSWagerSymbol(art: tally.kind.artName, fallback: tally.kind.symbol,
                                   size: 20, tint: tally.kind.tint)
                        if tally.count > 1 {
                            Text("\u{00D7}\(tally.count)")
                                .font(.system(size: 10, weight: .black).monospacedDigit())
                                .foregroundStyle(Theme.parchment.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4)
                    .background(Theme.bgElevated, in: .rect(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(tally.kind.tint.opacity(0.35), lineWidth: 0.9))
                }
            }

            Text("\(diceCount) dice \u{00B7} \(profile.leaning)")
                .font(.system(size: 10.5, weight: .black))
                .foregroundStyle(Theme.parchment.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// The small print under a blessing card — small, but not so small that it
    /// stops being readable.
    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(Theme.parchment.opacity(0.7))
            .lineLimit(2)
            .minimumScaleFactor(0.75)
    }

    /// A small god-sigil tile used on blessing cards.
    private func sealBadge(_ art: String?, _ symbol: String, tint: Color) -> some View {
        PharaohSWagerSymbol(art: art, fallback: symbol, size: 21, tint: tint)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.16), in: .rect(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(tint.opacity(0.55), lineWidth: 1))
    }
}
