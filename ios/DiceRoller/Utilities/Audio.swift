import AVFoundation
import Foundation
import Observation

/// Every sound the game can make, named for what it *is* rather than for the
/// file behind it — so a sound can be re-cut later without touching call sites.
enum SoundCue: String, CaseIterable {
    // The dice, which the player touches most
    case diceRoll
    case dicePlace
    case diceTake
    case diceFreeze
    case diceLock

    // Leaving the hand
    case fireBow
    case fireBlade
    case fireSwing
    case fireFlame
    case fireFrost
    case fireArcane
    case fireLightning

    // Landing
    case hitArrow
    case hitSlash
    case hitBlunt
    case hitFlame
    case hitFrost
    case hitArcane

    // Answers
    case crit
    case block
    case evade
    case death
    case heal
    case chain

    // Interface
    case uiTap
    case uiConfirm
    case uiTransition
    case gate
    case boon

    /// The bundled resource behind this cue.
    var resource: String {
        switch self {
        case .diceRoll: "bone_dice_clatter"
        case .dicePlace: "wooden_knock"
        case .diceTake: "wooden_piece_lift"
        case .diceFreeze: "frost_chime_shimmer"
        case .diceLock: "stone_reel_lock"
        case .fireBow: "arrow_release_twang"
        case .fireBlade: "blade_slice_whistle"
        case .fireSwing: "axe_swing_heavy"
        case .fireFlame: "fireball_whoosh_cast"
        case .fireFrost: "ice_shard_launch"
        case .fireArcane: "arcane_energy_bolt"
        case .fireLightning: "lightning_crack_strike"
        case .hitArrow: "arrow_body_impact"
        case .hitSlash: "flesh_cut_slash"
        case .hitBlunt: "bone_crunch_impact"
        case .hitFlame: "flesh_ignite_crackle"
        case .hitFrost: "ice_shatter_smash"
        case .hitArcane: "arcane_crystal_burst"
        case .crit: "golden_bell_strike"
        case .block: "bronze_shield_hit"
        case .evade: "cloth_dodge_whoosh"
        case .death: "body_collapse_stone"
        case .heal: "healing_shimmer_bells"
        case .chain: "epic_orchestral_swell"
        case .uiTap: "papyrus_press_tap"
        case .uiConfirm: "stone_slab_thud"
        case .uiTransition: "papyrus_page_whoosh"
        case .gate: "bronze_gong_strike"
        case .boon: "divine_blessing_shimmer"
        }
    }

    /// How loud this cue sits against the others, before the player's own
    /// slider. Dice and interface taps are constant company, so they are mixed
    /// well down; the chain swell and the gate gong are events and stay big.
    var mix: Float {
        switch self {
        case .uiTap, .diceTake: 0.4
        case .dicePlace, .diceLock: 0.55
        case .diceRoll, .diceFreeze, .uiTransition: 0.65
        case .chain, .gate: 1.0
        default: 0.8
        }
    }

    /// Cues that may drift in pitch so a repeated sound never reads as a
    /// copy-paste. The dice are the main offender — they fire constantly.
    var variesPitch: Bool {
        switch self {
        case .diceRoll, .dicePlace, .diceTake, .diceLock,
             .hitArrow, .hitSlash, .hitBlunt, .fireBlade, .fireBow:
            true
        default:
            false
        }
    }
}

/// The four tracks under the night.
enum MusicTrack: String {
    case title
    case river
    case battle
    case boss

    var resource: String {
        switch self {
        case .title: "egyptian_ceremonial_theme"
        case .river: "egyptian_underworld_ambience"
        case .battle: "ancient_egyptian_battle_drums"
        case .boss: "ancient_god_boss_battle"
        }
    }

    /// Per-track trim so the drums do not tower over the drifting river.
    var mix: Float {
        switch self {
        case .title: 0.8
        case .river: 0.7
        case .battle: 0.75
        case .boss: 0.85
        }
    }
}

/// The game's mixer: one looping music bed that cross-fades between tracks,
/// and a small pool of players for the sound effects.
///
/// Everything routes through the two volumes the pause menu owns, and the
/// session is configured `.ambient` so the phone's silent switch is obeyed and
/// the player's own music is never interrupted.
@Observable
@MainActor
final class Audio {
    static let shared = Audio()

    private static let musicKey = "diceroller.audio.music.v1"
    private static let effectsKey = "diceroller.audio.effects.v1"

    /// Music volume, 0 through 1. Persisted between sessions.
    var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: Self.musicKey)
            applyMusicVolume()
        }
    }

    /// Sound-effect volume, 0 through 1. Persisted between sessions.
    var effectsVolume: Float {
        didSet { UserDefaults.standard.set(effectsVolume, forKey: Self.effectsKey) }
    }

    /// The track currently playing, so asking for it again is a no-op rather
    /// than a restart from the top.
    private(set) var currentTrack: MusicTrack?

    private var musicPlayer: AVAudioPlayer?
    /// The outgoing player during a cross-fade, kept alive until it is silent.
    private var fadingPlayer: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?

    /// Effect players in flight. Held so a sound is not collected mid-play,
    /// and capped so a busy chain cannot spawn players without limit.
    private var effectPlayers: [AVAudioPlayer] = []
    private static let maxConcurrentEffects = 12

    /// Decoded effect data, cached on first use so a repeat cue does not go
    /// back to disk in the middle of a fight.
    private var effectData: [SoundCue: Data] = [:]

    private var sessionReady = false

    private init() {
        let defaults = UserDefaults.standard
        musicVolume = defaults.object(forKey: Self.musicKey) as? Float ?? 0.55
        effectsVolume = defaults.object(forKey: Self.effectsKey) as? Float ?? 0.8
    }

    // MARK: - Session

    /// Ambient category: the silent switch silences the game, and whatever the
    /// player already had playing keeps going underneath.
    private func prepareSession() {
        guard !sessionReady else { return }
        sessionReady = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio is a courtesy, never a requirement — a failed session just
            // means the night plays silently.
            print("[Audio] session unavailable: \(error.localizedDescription)")
        }
    }

    // MARK: - Music

    /// Bring a track up, cross-fading out whatever was playing. Asking for the
    /// track that is already up does nothing, so screens can call this freely.
    func play(_ track: MusicTrack, fade: Double = 1.2) {
        guard currentTrack != track else { return }
        prepareSession()
        guard let url = Bundle.main.url(forResource: track.resource, withExtension: "mp3") else {
            print("[Audio] missing track: \(track.resource)")
            return
        }

        fadeTask?.cancel()
        let outgoing = musicPlayer
        fadingPlayer = outgoing

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            player.play()
            musicPlayer = player
            currentTrack = track
            crossFade(incoming: player, outgoing: outgoing, target: trackVolume(track), duration: fade)
        } catch {
            print("[Audio] could not open \(track.resource): \(error.localizedDescription)")
        }
    }

    /// Fade the music out entirely — used when the run ends.
    func stopMusic(fade: Double = 0.8) {
        fadeTask?.cancel()
        let outgoing = musicPlayer
        musicPlayer = nil
        currentTrack = nil
        guard let outgoing else { return }
        fadeTask = Task { @MainActor in
            await Self.ramp(outgoing, to: 0, duration: fade)
            outgoing.stop()
        }
    }

    private func crossFade(
        incoming: AVAudioPlayer,
        outgoing: AVAudioPlayer?,
        target: Float,
        duration: Double
    ) {
        fadeTask = Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    await Self.ramp(incoming, to: target, duration: duration)
                }
                if let outgoing {
                    group.addTask { @MainActor in
                        await Self.ramp(outgoing, to: 0, duration: duration)
                    }
                }
            }
            outgoing?.stop()
            if self.fadingPlayer === outgoing { self.fadingPlayer = nil }
        }
    }

    /// Walks a player's volume to a target over time, in short steps.
    private static func ramp(_ player: AVAudioPlayer, to target: Float, duration: Double) async {
        let steps = max(1, Int(duration / 0.05))
        let start = player.volume
        for step in 1...steps {
            if Task.isCancelled { return }
            let progress = Float(step) / Float(steps)
            player.volume = start + (target - start) * progress
            try? await Task.sleep(for: .milliseconds(50))
        }
        if !Task.isCancelled { player.volume = target }
    }

    private func trackVolume(_ track: MusicTrack) -> Float {
        musicVolume * track.mix
    }

    private func applyMusicVolume() {
        guard let currentTrack, let musicPlayer else { return }
        // A live slider should move the bed immediately, not on the next fade.
        fadeTask?.cancel()
        musicPlayer.volume = trackVolume(currentTrack)
    }

    // MARK: - Effects

    /// Fire a sound effect. Silently does nothing when the player has turned
    /// effects down, so call sites never have to check.
    func play(_ cue: SoundCue, volumeScale: Float = 1) {
        guard effectsVolume > 0.001 else { return }
        prepareSession()

        guard let data = data(for: cue) else { return }
        // Let the oldest finished players go before adding another.
        effectPlayers.removeAll { !$0.isPlaying }
        guard effectPlayers.count < Self.maxConcurrentEffects else { return }

        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = min(1, effectsVolume * cue.mix * volumeScale)
            if cue.variesPitch {
                player.enableRate = true
                player.rate = Float.random(in: 0.94...1.07)
            }
            player.prepareToPlay()
            player.play()
            effectPlayers.append(player)
        } catch {
            print("[Audio] could not play \(cue.rawValue): \(error.localizedDescription)")
        }
    }

    /// Fire a cue after a delay, for landings that have to wait out a flight.
    func play(_ cue: SoundCue, after delay: Double, volumeScale: Float = 1) {
        guard effectsVolume > 0.001 else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            play(cue, volumeScale: volumeScale)
        }
    }

    private func data(for cue: SoundCue) -> Data? {
        if let cached = effectData[cue] { return cached }
        guard let url = Bundle.main.url(forResource: cue.resource, withExtension: "mp3"),
              let data = try? Data(contentsOf: url) else {
            print("[Audio] missing effect: \(cue.resource)")
            return nil
        }
        effectData[cue] = data
        return data
    }

    /// The rising run of notes as dice drop into the plan: the same knock,
    /// pitched a step higher for each die already committed.
    func planKnock(position: Int) {
        guard effectsVolume > 0.001 else { return }
        prepareSession()
        guard let data = data(for: .dicePlace) else { return }
        effectPlayers.removeAll { !$0.isPlaying }
        guard effectPlayers.count < Self.maxConcurrentEffects else { return }
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = min(1, effectsVolume * SoundCue.dicePlace.mix)
            player.enableRate = true
            // Six dice at most, so the run climbs a little over half an octave.
            player.rate = min(1.42, 1 + Float(max(0, position)) * 0.07)
            player.prepareToPlay()
            player.play()
            effectPlayers.append(player)
        } catch {
            print("[Audio] could not play plan knock: \(error.localizedDescription)")
        }
    }
}

// MARK: - Attack sounds by face

extension FaceKind {
    /// The sound this face makes leaving the fighter's hand.
    var launchCue: SoundCue? {
        switch self {
        case .arrow1, .arrow2, .arrow3: .fireBow
        case .bowSmack: .fireSwing
        case .overhead, .sideSwing: .fireSwing
        case .swiftSlash: .fireBlade
        case .daggerThrow: .fireBlade
        case .poison: .fireBlade
        case .runeFire: .fireFlame
        case .runeFrost: .fireFrost
        case .runeArcane: .fireArcane
        case .wandZap: .fireLightning
        case .runeLife: .heal
        default: nil
        }
    }

    /// The sound this face makes arriving on whatever it struck.
    var impactCue: SoundCue? {
        switch self {
        case .arrow1, .arrow2, .arrow3: .hitArrow
        case .bowSmack, .overhead, .sideSwing: .hitBlunt
        case .swiftSlash, .daggerThrow, .poison: .hitSlash
        case .runeFire: .hitFlame
        case .runeFrost: .hitFrost
        case .runeArcane, .wandZap: .hitArcane
        default: nil
        }
    }
}
