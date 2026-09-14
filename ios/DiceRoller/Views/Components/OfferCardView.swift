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
                            Image(systemName: "circle.hexagongrid.fill").font(.system(size: 8, weight: .bold))
                            Text("\(offer.price)")
                                .font(.system(size: 11, weight: .black).monospacedDigit())
                        }
                        .foregroundStyle(affordable ? Theme.gold : Theme.blood)
                    }
                }

                Image(systemName: offer.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.gold : offer.tint)
                    .frame(width: 42, height: 42)
                    .background(
                        offer.deity == nil
                            ? AnyShapeStyle(Theme.bg)
                            : AnyShapeStyle(RadialGradient(colors: [offer.tint.opacity(0.35), Theme.bg],
                                                           center: .center, startRadius: 1, endRadius: 30)),
                        in: .rect(cornerRadius: 11)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(offer.deity == nil ? .clear : offer.tint.opacity(0.6), lineWidth: 1)
                    )
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
                        sealBadge(offer.deity?.symbol ?? "sparkles", tint: offer.deity?.tint ?? Theme.gold)
                        Text(offer.isReplacingPatron ? "takes a claimed die" : "claims one die")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .upgrade(let upgrade) = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(upgrade.symbol, tint: offer.tint)
                        Text("one upgrade · needs a blessed die")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .capstone = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge("crown.fill", tint: offer.tint)
                        Text("capstone · one per run")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .pairing(let pairing) = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge(pairing.first.symbol, tint: pairing.first.tint)
                        sealBadge(pairing.second.symbol, tint: pairing.second.tint)
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
                        sealBadge("wind.circle.fill", tint: Theme.gold)
                        Text("permanent · once per offer")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                } else if case .chisel = offer.kind {
                    HStack(spacing: 4) {
                        sealBadge("hammer.fill", tint: Theme.ptahCopper)
                        Text("opens Ptah's workshop")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 7, weight: .bold))
                    Text(offer.comboHint)
                        .font(.system(size: 8, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Theme.gold.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.gold.opacity(0.12), in: .capsule)
            }
            .padding(10)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [Theme.bgCard, Theme.bgElevated],
                               startPoint: .top, endPoint: .bottom),
                in: .rect(cornerRadius: 16)
            )
            .overlay(alignment: .bottom) {
                HieroglyphBand(tint: offer.tint, height: 7, opacity: 0.28)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 3)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Theme.gold : offer.tint.opacity(offer.deity == nil ? 0.35 : 0.55),
                                  lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 3)
                    .strokeBorder(Theme.rule.opacity(0.16), lineWidth: 0.75)
            )
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
                        Image(systemName: tally.kind.symbol)
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(tally.kind.tint)
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
    private func sealBadge(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 20, height: 20)
            .background(tint.opacity(0.16), in: .rect(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(tint.opacity(0.55), lineWidth: 1))
    }
}
