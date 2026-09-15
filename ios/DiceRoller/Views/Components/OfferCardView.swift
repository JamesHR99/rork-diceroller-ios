import SwiftUI

/// A single offer card used on the reward screen and the shop shelf.
struct OfferCardView: View {
    let offer: Offer
    let isSelected: Bool
    let affordable: Bool
    /// Fixed card width for scrolling shelves; pass `nil` to let the card share
    /// the row's width evenly (used by the three-card altar).
    var width: CGFloat? = 168
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    // Rarity reads as a material swatch: clay, copper, lapis, gold leaf.
                    RoundedRectangle(cornerRadius: 2)
                        .fill(offer.rarity.materialGradient)
                        .frame(width: 9, height: 9)
                        .overlay(RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Theme.bg.opacity(0.6), lineWidth: 0.6))
                    Text(offer.rarity.label.uppercased())
                        .font(.system(size: 7.5, weight: .black))
                        .kerning(0.8)
                        .foregroundStyle(offer.rarity.tint)
                    Spacer(minLength: 0)
                    if !offer.isFree {
                        HStack(spacing: 3) {
                            DuatIcon(name: DuatArt.currency, size: 12)
                            Text("\(offer.price)")
                                .font(.system(size: 11, weight: .black).monospacedDigit())
                                .foregroundStyle(affordable ? Theme.gold : Theme.blood)
                        }
                    }
                }

                // What is on offer, inside its rarity's painted frame.
                DuatSymbol(art: offer.artName, fallback: offer.symbol,
                           size: 34, tint: isSelected ? Theme.gold : offer.tint)
                    .frame(width: 46, height: 46)
                    .background {
                        DuatImage(name: offer.rarity.frameArt, width: 52, height: 52, fit: .fit)
                            .modifier(TintWash(tint: offer.deity?.tint))
                    }
                    .shadow(color: offer.deity?.tint.opacity(0.5) ?? .clear, radius: 8)

                Text(offer.name)
                    .font(.fantasy(13, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                Text(offer.detail)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)
                    .frame(maxHeight: .infinity, alignment: .top)

                if case .die(let die) = offer.kind {
                    DieStripView(die: die, tileSize: 15, showCrit: false)
                } else if case .patron = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(offer.deity?.artName, offer.deity?.symbol ?? "sparkles",
                                  tint: offer.deity?.tint ?? Theme.gold)
                        Text(offer.isReplacingPatron ? "takes a claimed die" : "claims one die")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .upgrade(let upgrade) = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(offer.deity?.artName, upgrade.symbol, tint: offer.tint)
                        Text("one upgrade · needs a blessed die")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .capstone = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(DuatArt.Status.champion, "crown.fill", tint: offer.tint)
                        Text("capstone · one per run")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .pairing(let pairing) = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(pairing.first.artName, pairing.first.symbol, tint: pairing.first.tint)
                        sealBadge(pairing.second.artName, pairing.second.symbol, tint: pairing.second.tint)
                        Text("2 gods · once per turn")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .item(let item) = offer.kind {
                    faceDigest(FaceProfile(item.faces), diceCount: 2)
                } else if case .relic(let relic) = offer.kind {
                    faceDigest(FaceProfile(relic.dice.flatMap { $0 }), diceCount: relic.dice.count)
                } else if case .breath = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(DuatArt.Status.stamina, "wind.circle.fill", tint: Theme.gold)
                        Text("permanent · once per offer")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .chisel = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(DuatArt.upgradeHammer, "hammer.fill", tint: Theme.ptahCopper)
                        Text("opens Ptah's workshop")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                }

                HStack(spacing: 4) {
                    DuatImage(name: DuatArt.chainConnector, width: 12, fit: .fit)
                        .colorMultiply(Theme.gold)
                    Text(offer.comboHint)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.gold.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.gold.opacity(0.12), in: .capsule)
            }
            .padding(10)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil, maxHeight: .infinity)
            .papyrusPanel(tint: Theme.bgCard, cornerRadius: 16)
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
            .scaleEffect(isSelected ? 1.03 : 1)
            .opacity(affordable ? 1 : 0.5)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// What a multi-dice offer hands you, at a glance: the few faces that give
    /// it its character, plus how the whole set leans. Drawing all eighteen
    /// relic faces never fit the card, and told you less.
    private func faceDigest(_ profile: FaceProfile, diceCount: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(profile.signature.prefix(3)) { tally in
                    HStack(spacing: 2) {
                        DuatSymbol(art: tally.kind.artName, fallback: tally.kind.symbol,
                                   size: 13, tint: tally.kind.tint)
                        if tally.count > 1 {
                            Text("\u{00D7}\(tally.count)")
                                .font(.system(size: 7.5, weight: .black).monospacedDigit())
                                .foregroundStyle(Theme.parchmentDim)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(Theme.bgElevated, in: .rect(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(tally.kind.tint.opacity(0.3), lineWidth: 0.75))
                }
            }

            Text("\(diceCount) dice \u{00B7} \(profile.leaning)")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// A small god-sigil tile used on blessing cards.
    private func sealBadge(_ art: String?, _ symbol: String, tint: Color) -> some View {
        DuatSymbol(art: art, fallback: symbol, size: 15, tint: tint)
            .frame(width: 21, height: 21)
            .background(tint.opacity(0.16), in: .rect(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(tint.opacity(0.55), lineWidth: 1))
    }
}
