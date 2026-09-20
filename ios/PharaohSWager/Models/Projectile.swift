import SwiftUI

/// What a shot actually *is*, so it can be drawn properly in code rather than
/// flying across the deck as a shrunken picture of the die face.
enum ProjectileForm: Equatable {
    /// A real shaft with a head and flights, leaning into its arc.
    case arrow
    /// A crescent wave of edge-light that widens as it travels.
    case crescent
    /// A blade tumbling end over end behind a thin steel wake.
    case tumblingBlade
    /// A churning sphere of fire trailing embers and smoke.
    case fireOrb
    /// A crystalline shard spitting cold motes.
    case frostShard
    /// Slow green motes drifting upward to their mark.
    case lifeMotes
    /// A hard geometric bolt inside rotating glyph rings.
    case arcaneBolt
    /// A jagged bolt that redraws itself, arriving instantly.
    case lightning
    /// A lobbed flask leaving a sickly trail.
    case venomFlask
}

/// How a face behaves once it has left the fighter's hand. Only faces that are
/// genuinely thrown or cast own one of these — an axe swing never leaves the
/// deck, so it has no flight.
struct ProjectileStyle: Equatable {
    /// Drawn size of the shot, in points.
    var size: CGFloat = 38
    /// How high the shot lobs over the water. 0 flies flat.
    var arc: CGFloat = 0
    /// Seconds the shot spends in the air.
    var flight: Double = 0.28
    /// Whether it tumbles end over end on the way across.
    var spins: Bool = false
    /// What it leaves behind it.
    var trail: ProjectileTrail = .streak
    /// What the shot is drawn as.
    var form: ProjectileForm = .arrow
}

/// The wake a shot drags across the water.
enum ProjectileTrail: Equatable {
    case streak
    case flame
    case frost
    case arcane
    case smoke
    case life
}

extension FaceKind {
    /// The flight this face takes when it is thrown or cast at a foe, or nil
    /// for the faces that are swung where the fighter stands. A Warrior's
    /// swings deliberately have none: an axe lands where it is swung, so it
    /// reads as a heavy arc and a shockwave at the point of contact instead.
    var projectile: ProjectileStyle? {
        switch self {
        case .arrow1:
            return ProjectileStyle(size: 34, arc: 8, flight: 0.26, form: .arrow)
        case .arrow2:
            return ProjectileStyle(size: 42, arc: 6, flight: 0.23, form: .arrow)
        case .arrow3:
            return ProjectileStyle(size: 52, arc: 4, flight: 0.2, form: .arrow)
        case .swiftSlash:
            return ProjectileStyle(size: 44, flight: 0.22, trail: .streak, form: .crescent)
        case .daggerThrow:
            return ProjectileStyle(size: 34, arc: 14, flight: 0.3, spins: true, form: .tumblingBlade)
        case .runeFire:
            return ProjectileStyle(size: 42, arc: 26, flight: 0.34, trail: .flame, form: .fireOrb)
        case .runeFrost:
            return ProjectileStyle(size: 36, flight: 0.3, spins: true, trail: .frost, form: .frostShard)
        case .runeLife:
            return ProjectileStyle(size: 34, arc: -18, flight: 0.42, trail: .life, form: .lifeMotes)
        case .runeArcane:
            return ProjectileStyle(size: 38, arc: 10, flight: 0.32, trail: .arcane, form: .arcaneBolt)
        case .wandZap:
            return ProjectileStyle(size: 40, flight: 0.14, trail: .arcane, form: .lightning)
        case .poison:
            return ProjectileStyle(size: 30, arc: 48, flight: 0.36, spins: true, trail: .smoke, form: .venomFlask)
        default:
            return nil
        }
    }
}

/// One shot in the air right now: what it is, who threw it and which foe it
/// flies to or from. Purely presentational — the damage is resolved by the
/// engine, which waits out the flight so the numbers land with the shot.
struct ProjectileShot: Identifiable, Equatable {
    let id = UUID()
    let face: FaceKind
    let style: ProjectileStyle
    let tint: Color
    /// True when the demigod threw it; false when it came out of the river.
    let fromPlayer: Bool
    /// The foe at the far end (player shots) or the one that threw it.
    let foeID: UUID
    /// How many dice fed the action this shot belongs to. A three-rune spell
    /// genuinely dwarfs a two-rune one.
    var magnitude: Int = 1
    /// True when the action it belongs to landed critical.
    var isCrit: Bool = false
    /// Presentation-only creature identity; nil denotes a hero's effect.
    var sourceEnemyID: String? = nil

    /// The drawn size once the feeding dice and a critical are taken in.
    var drawnSize: CGFloat {
        let growth = 1 + CGFloat(max(0, min(6, magnitude) - 1)) * 0.28
        return style.size * growth * (isCrit ? 1.2 : 1)
    }
}

// MARK: - Landing marks

/// What a hit leaves on the thing it struck.
enum ImpactForm: Equatable {
    /// Glowing gashes across the body, one per cut.
    case gashes(count: Int)
    /// A puncture flash with a shaft that sticks for a beat.
    case puncture
    /// A white impact star and a ring of dust — a blunt swing landing.
    case blunt
    /// A scorch that licks with flame.
    case scorch
    /// A full fireball detonation: expanding ring, core and thrown embers.
    case fireExplosion
    /// An ice crust that cracks apart.
    case frostCrust
    /// A hexagonal lattice that shatters outward.
    case lattice
    /// A soft green flare on whoever was mended.
    case bloom
    /// A sickly green wash where venom landed.
    case venom
    /// Persistent damage has its own unmistakable language.
    case bleedTick
    case poisonTick
    case burnTick
}

/// A mark drawn over a fighter and fading out, so every blow can be read on
/// the body it landed on rather than only in the numbers.
struct ImpactMark: Identifiable, Equatable {
    let id = UUID()
    let form: ImpactForm
    let tint: Color
    /// Who wears the mark.
    let target: FighterAnchorID
    /// The direction the blow arrived from, in degrees.
    let angle: Double
    /// A critical doubles the mark and washes it gold.
    let isCrit: Bool
    /// How big the blow was, for scaling the mark.
    let magnitude: Int
    var sourceEnemyID: String? = nil

    /// How long the mark stays on the body.
    var lifetime: Double {
        switch form {
        case .puncture: 0.9
        case .scorch, .frostCrust: 0.8
        case .fireExplosion: 1.05
        case .bleedTick, .poisonTick, .burnTick: 0.95
        default: 0.65
        }
    }
}

extension FaceKind {
    /// The mark this face leaves on whatever it strikes.
    var impactForm: ImpactForm? {
        switch self {
        case .arrow1, .arrow2, .arrow3:
            return .puncture
        case .bowSmack, .overhead, .sideSwing:
            return .blunt
        case .swiftSlash:
            return .gashes(count: 3)
        case .daggerThrow:
            return .gashes(count: 1)
        case .poison:
            return .venom
        case .runeFire:
            return .fireExplosion
        case .runeFrost:
            return .frostCrust
        case .runeArcane, .wandZap:
            return .lattice
        case .runeLife, .heal:
            return .bloom
        default:
            return nil
        }
    }

    /// The colour the mark burns in.
    var impactTint: Color {
        switch self {
        case .runeFire: Theme.ember
        case .runeFrost: Theme.frost
        case .runeArcane, .wandZap: Theme.arcane
        case .runeLife, .heal: Theme.forest
        case .poison: Theme.venom
        case .bowSmack, .overhead, .sideSwing: Theme.parchment
        default: Theme.blood
        }
    }
}
