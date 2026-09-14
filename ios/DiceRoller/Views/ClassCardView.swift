import SwiftUI

/// A demigod-select card framed as a tomb-wall panel: identity and stats on
/// the left, starting dice and signature combos on the right.
struct ClassCardView: View {
    let hero: HeroClass

    private var signatureCombos: [ComboDef] {
        Array(GameData.classCombos(hero.id)
            .filter { $0.source == .weapon }
            .sorted { $0.damage > $1.damage }
            .prefix(3))
    }

    var body: some View {
        HStack(spacing: 14) {
            identityColumn
            detailColumn
        }
        .padding(14)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .duatPanel(tint: hero.accent, cornerRadius: 22)
        .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
    }

    private var identityColumn: some View {
        VStack(spacing: 7) {
            PortraitMedallionView(art: CharacterArt.demigod(hero.id),
                                  fallbackSymbol: hero.symbol,
                                  tint: hero.accent,
                                  diameter: 84)

            VStack(spacing: 3) {
                CartoucheView(text: hero.name, tint: hero.accent, size: 15)
                Text(hero.title)
                    .font(.paper(11.5))
                    .foregroundStyle(hero.accent)
                    .italic()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(spacing: 5) {
                statPill(icon: "heart.fill", value: "\(hero.maxHP)", label: "HP", tint: Theme.blood)
                statPill(icon: "bolt.fill", value: "\(hero.maxStamina)", label: "STAM", tint: Theme.gold)
                statPill(icon: "arrow.clockwise", value: "FULL", label: "REFILL", tint: Theme.forest)
            }

            Text(hero.playstyle.uppercased())
                .font(.system(size: 8.5, weight: .black))
                .kerning(1)
                .foregroundStyle(Theme.parchmentDim)

            Text(hero.blurb)
                .font(.paper(10.5))
                .foregroundStyle(Theme.parchmentDim)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 208)
    }

    private var detailColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            gearBlock(
                title: "\(hero.weaponName) · 3 dice",
                symbol: "burst.fill",
                die: hero.startingLoadout.weapon.dice.first
            )
            gearBlock(
                title: "\(hero.armorName) · 2 dice",
                symbol: "shield.lefthalf.filled",
                die: hero.startingLoadout.armor.dice.first
            )

            HStack(spacing: 6) {
                Image(systemName: "bag")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
                Text("Item slot — empty. Find one on the river.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim)
            }

            Divider().overlay(Theme.parchmentDim.opacity(0.2))

            Text("SIGNATURE COMBOS")
                .font(.system(size: 9, weight: .black))
                .kerning(1.2)
                .foregroundStyle(hero.accent)

            ForEach(signatureCombos) { combo in
                HStack(spacing: 7) {
                    ComboRecipeView(combo: combo, tileSize: 18)
                    Text(combo.name)
                        .font(.fantasy(11, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("\(combo.damage) dmg")
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                        .foregroundStyle(hero.accent)
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg.opacity(0.65), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.rule.opacity(0.5), lineWidth: 0.75))
    }

    private func gearBlock(title: String, symbol: String, die: Die?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(hero.accent)
                Text(title)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
            }
            if let die {
                DieStripView(die: die, tileSize: 21, showCrit: false)
            }
        }
    }

    private func statPill(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.fantasy(14, weight: .bold))
                .foregroundStyle(Theme.parchment)
            Text(label)
                .font(.system(size: 7.5, weight: .black))
                .kerning(0.5)
                .foregroundStyle(Theme.parchmentDim)
        }
        .frame(width: 48)
        .padding(.vertical, 5)
        .background(Theme.bg.opacity(0.6), in: .rect(cornerRadius: 9))
    }
}
