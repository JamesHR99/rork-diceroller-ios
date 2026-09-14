import SwiftUI

/// Ptah's workshop: a stoneworker's bench in cold hammered copper and basalt,
/// set apart from the six gods' gold. The first visit lays out all three of
/// the class's Chisels; a second offers the two not yet owned. Choosing one
/// lands with a short jolt of the chisel.
struct WorkshopView: View {
    @Environment(GameManager.self) private var game
    @State private var struckID: String?
    @State private var risen = false

    private var accent: Color { Theme.ptahCopper }

    private var ownedDefs: [ChiselDef] {
        game.ownedChisels.compactMap { ChiselCatalog.def($0) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            rail
            bench
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Theme.basalt.opacity(0.55)
                RadialGradient(colors: [accent.opacity(0.22), .clear],
                               center: .leading, startRadius: 20, endRadius: 560)
                LinearGradient(colors: [Theme.basalt.opacity(0.5), .clear],
                               startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { risen = true }
            Haptics.medium()
        }
    }

    // MARK: - Left rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.7), radius: 9)
                CarvedTitle(text: "Ptah's Workshop", size: 14, kerning: 1.8)
            }

            Text("The craftsman's bench. A Chisel reshapes your whole weapon — never a single die — and your gods and their blessings are untouched.")
                .font(.paper(10.5))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)

            // Two sockets: what the run carries, and what remains.
            HStack(spacing: 8) {
                ForEach(0..<GameData.chiselMaxPerRun, id: \.self) { index in
                    HStack(spacing: 5) {
                        Image(systemName: index < ownedDefs.count ? "hammer.fill" : "hammer")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(index < ownedDefs.count ? accent : Theme.parchmentDim.opacity(0.5))
                        Text(index < ownedDefs.count
                             ? ownedDefs[index].name
                             : "empty socket")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(index < ownedDefs.count ? Theme.parchment : Theme.parchmentDim.opacity(0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Theme.bg.opacity(0.7), in: .capsule)
                    .overlay(Capsule().strokeBorder(
                        index < ownedDefs.count ? accent.opacity(0.7) : Theme.rule.opacity(0.3),
                        lineWidth: 1))
                }
            }

            Spacer(minLength: 8)

            chiselMark

            Spacer(minLength: 8)

            Text("Two different Chisels a run, both active together. Everything recomputes the moment one is struck: recipes, stamina, forecast.")
                .font(.system(size: 9.5))
                .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 216, alignment: .leading)
        .frame(maxHeight: .infinity)
    }

    /// The chisel-and-plumb-line mark, struck rather than painted.
    private var chiselMark: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.parchment, accent],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: accent.opacity(0.55), radius: 16)
            HieroglyphBand(tint: accent, height: 7, opacity: 0.5)
                .frame(width: 130)
        }
        .opacity(risen ? 1 : 0)
        .offset(y: risen ? 0 : 14)
    }

    // MARK: - The bench

    private var bench: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(Array(game.workshopOptions.enumerated()), id: \.element.id) { index, chisel in
                chiselCard(chisel)
                    .opacity(risen ? 1 : 0)
                    .offset(y: risen ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8)
                        .delay(0.12 + Double(index) * 0.08), value: risen)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func chiselCard(_ chisel: ChiselDef) -> some View {
        let isStruck = struckID == chisel.id
        return Button {
            guard struckID == nil else { return }
            struckID = chisel.id
            Haptics.heavy()
            Task {
                // The jolt of the chisel, then the choice lands.
                try? await Task.sleep(for: .milliseconds(380))
                game.chooseChisel(chisel)
            }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Image(systemName: chisel.symbol)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 40, height: 40)
                        .background(Theme.bg.opacity(0.8), in: .rect(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(accent.opacity(0.6), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(chisel.name)
                            .font(.fantasy(15, weight: .black))
                            .foregroundStyle(Theme.parchment)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(chisel.isOptional ? "armed per action · Ptah badge" : "always at work")
                            .font(.system(size: 8, weight: .black))
                            .kerning(0.8)
                            .foregroundStyle(accent)
                    }
                    Spacer(minLength: 0)
                }

                Text(chisel.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("FOR INSTANCE")
                        .font(.system(size: 7.5, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(accent)
                    Text(chisel.example)
                        .font(.paper(10))
                        .italic()
                        .foregroundStyle(Theme.parchment.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 9))

                Spacer(minLength: 0)

                Text(isStruck ? "STRUCK!" : "TAKE IT")
                    .font(.fantasy(14, weight: .black))
                    .kerning(1.6)
                    .foregroundStyle(isStruck ? Theme.bg : Theme.parchment)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        isStruck
                            ? AnyShapeStyle(accent)
                            : AnyShapeStyle(Theme.bg.opacity(0.85)),
                        in: .capsule
                    )
                    .overlay(Capsule().strokeBorder(accent.opacity(isStruck ? 0 : 0.8), lineWidth: 1.2))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Theme.bgElevated, Theme.bgCard],
                               startPoint: .top, endPoint: .bottom),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accent.opacity(isStruck ? 1 : 0.5),
                                  lineWidth: isStruck ? 2.2 : 1.2)
            )
            .shadow(color: accent.opacity(isStruck ? 0.6 : 0.18), radius: isStruck ? 18 : 8)
            .scaleEffect(isStruck ? 1.04 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(struckID != nil)
    }
}
