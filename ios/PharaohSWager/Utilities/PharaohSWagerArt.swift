import SwiftUI
import UIKit

/// Where a painted asset's real ink sits inside its exported canvas.
///
/// Every plate in the PharaohSWager pack was drawn on a generous square (or wide)
/// canvas with a lot of empty air around the drawing. The pack's manifest
/// records the alpha bounding box of each one; displaying that rectangle
/// instead of the whole canvas is the difference between a button that fills
/// its frame and a button floating in the middle of a mostly-empty square.
struct PharaohSWagerCrop: Hashable {
    /// Content rectangle, normalised against the canvas.
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    /// Canvas width ÷ canvas height — needed to recover the drawing's own
    /// aspect from a rectangle measured in canvas fractions.
    let canvasAspect: CGFloat

    init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ canvasAspect: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.canvasAspect = canvasAspect
    }

    /// An uncropped plate — the fallback for anything not in the manifest.
    static let full = PharaohSWagerCrop(0, 0, 1, 1, 1)

    /// The drawn content's own width ÷ height.
    var aspect: CGFloat {
        (width * canvasAspect) / max(height, 0.0001)
    }
}

/// Cap insets for the two plates that are stretched rather than scaled, in
/// pixels of the already-cropped region.
struct PharaohSWagerCaps: Hashable {
    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat
}

/// The painted PharaohSWager art pack: every plate's name, its content rectangle, and
/// the mapping from the game's own identifiers to the drawing that represents
/// them. Views never hardcode an asset name — they ask here, so a missing
/// plate is a single `nil` to fall back from rather than a blank rectangle.
enum PharaohSWagerArt {

    // MARK: - Lookup

    static func crop(_ name: String) -> PharaohSWagerCrop {
        crops[name] ?? .full
    }

    /// Whether a plate really landed in the catalogue. Cached: this is asked
    /// on every frame of every fight.
    static func exists(_ name: String?) -> Bool {
        guard let name else { return false }
        if let known = existence[name] { return known }
        let found = UIImage(named: name) != nil
        existence[name] = found
        return found
    }

    /// The name if it is really there, otherwise nil — the shape every view's
    /// "painted art or inked glyph" fork wants.
    static func resolve(_ name: String?) -> String? {
        exists(name) ? name : nil
    }

    private static var existence: [String: Bool] = [:]

    /// Small UI glyphs should not composite a full export-sized texture on
    /// every frame. Crop and downsample once at the requested display scale.
    static func icon(_ name: String, pixels: Int) -> UIImage? {
        guard exists(name) else { return nil }
        let dimension = min(512, max(32, ((pixels + 31) / 32) * 32))
        let key = "\(name).\(dimension)" as NSString
        if let cached = icons.object(forKey: key) { return cached }
        guard let source = UIImage(named: name), let page = source.cgImage else { return nil }
        let box = crop(name)
        let rect = CGRect(x: box.x * CGFloat(page.width), y: box.y * CGFloat(page.height),
                          width: box.width * CGFloat(page.width), height: box.height * CGFloat(page.height)).integral
        guard let cut = page.cropping(to: rect) else { return nil }
        let edge = CGFloat(dimension)
        let ratio = min(edge / CGFloat(cut.width), edge / CGFloat(cut.height))
        let size = CGSize(width: CGFloat(cut.width) * ratio, height: CGFloat(cut.height) * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIImage(cgImage: cut).draw(in: CGRect(origin: .zero, size: size))
        }
        icons.setObject(image, forKey: key, cost: dimension * dimension * 4)
        return image
    }

    private static let icons: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 160
        cache.totalCostLimit = 16 * 1024 * 1024
        return cache
    }()

    // MARK: - Stretchable plates

    /// The cropped plate, decoded once, ready to be stretched from its middle.
    /// Only the two papyrus sheets go through here; everything else is scaled
    /// whole and does not need a second copy in memory.
    static func sheet(_ name: String) -> UIImage? {
        if let cached = sheets[name] { return cached }
        guard let source = UIImage(named: name), let page = source.cgImage else { return nil }
        let box = crop(name)
        let pixelWidth = CGFloat(page.width)
        let pixelHeight = CGFloat(page.height)
        let rect = CGRect(
            x: (box.x * pixelWidth).rounded(.down),
            y: (box.y * pixelHeight).rounded(.down),
            width: (box.width * pixelWidth).rounded(.down),
            height: (box.height * pixelHeight).rounded(.down)
        )
        guard let cut = page.cropping(to: rect) else { return nil }
        let image = UIImage(cgImage: cut, scale: source.scale, orientation: .up)
        sheets[name] = image
        return image
    }

    private static var sheets: [String: UIImage] = [:]

    /// Cap insets in points for a stretchable sheet, measured on the crop.
    static func caps(_ name: String) -> EdgeInsets? {
        guard let caps = nineSlice[name] else { return nil }
        return EdgeInsets(top: caps.top, leading: caps.left, bottom: caps.bottom, trailing: caps.right)
    }

    private static let nineSlice: [String: PharaohSWagerCaps] = [
        panelLarge: PharaohSWagerCaps(top: 307, left: 288, bottom: 307, right: 288),
        cardSmall: PharaohSWagerCaps(top: 282, left: 137, bottom: 282, right: 137),
    ]

    // MARK: - Named plates

    static let panelLarge = "duat_ui_panel_large"
    static let cardSmall = "duat_ui_card_small"
    static let cartouche = "duat_ui_cartouche"
    static let cornerGold = "duat_ui_corner_gold"
    static let dividerGold = "duat_ui_divider_gold"
    static let dividerWinged = "duat_ui_divider_winged"
    static let hieroglyphStrip = "duat_ui_hieroglyph_strip"
    static let banner = "duat_ui_banner"
    static let bannerVictory = "duat_ui_banner_victory"
    static let bannerDefeat = "duat_ui_banner_defeat"

    static let barTrack = "duat_ui_bar_track"
    static let barEndcap = "duat_ui_bar_endcap"
    static let barFillHealth = "duat_ui_bar_fill_health"
    static let barFillShield = "duat_ui_bar_fill_shield"
    static let barFillArmour = "duat_ui_bar_fill_armour"

    /// The empty bar frame: one long trough with a lotus cap at each end,
    /// drawn so the fill can be laid inside its channel and actually be seen.
    static let barFrame = "health_bar_frame_empty"

    /// Where the open channel sits inside `barFrame`, measured off the
    /// drawing. The plate is opaque across its channel, so a fill laid behind
    /// it is invisible — the fill has to be drawn over the frame and inset to
    /// exactly this rectangle.
    enum BarFrame {
        static let aspect: CGFloat = 10.92
        static let troughX: CGFloat = 0.0882
        static let troughWidth: CGFloat = 0.8235
        static let troughY: CGFloat = 0.2117
        static let troughHeight: CGFloat = 0.5766
    }

    /// The two plain painted grounds every panel and card sits on. They carry
    /// no border and no ornament, so text stays readable over them and they
    /// can be scaled to any shape without the frame art smearing.
    static let groundPanel = "papyrus_dark_panel"
    static let groundCard = "egyptian_papyrus_bg"

    static let staminaFull = "duat_ui_stamina_full"
    static let staminaEmpty = "duat_ui_stamina_empty"
    static let staminaReserve = "duat_ui_stamina_reserve"

    static let chainConnector = "duat_ui_chain_connector"
    static let turnSlot = "duat_ui_turn_slot"
    static let costBadge = "duat_ui_cost_badge"
    static let echoMarker = "duat_ui_echo_marker"
    static let enemyIntent = "duat_ui_enemy_intent"
    static let targetRing = "duat_ui_target_ring"
    static let trialHalo = "duat_trial_halo"

    static let nightHour = "duat_ui_night_hour"
    static let nightCurrent = "duat_ui_night_current"
    static let nightCleared = "duat_ui_night_cleared"
    static let nightBoundary = "duat_ui_night_boundary"

    static let tabSelected = "duat_ui_tab_selected"
    static let tabUnselected = "duat_ui_tab_unselected"

    static let utilityBack = "duat_utility_back"
    static let utilityForward = "duat_utility_forward"
    static let utilityClose = "duat_utility_close"
    static let utilityCodex = "duat_utility_codex"
    static let utilityRecords = "duat_utility_records"
    static let currency = "duat_utility_currency"

    static let interactionRoll = "duat_interaction_roll"
    static let interactionHeld = "duat_interaction_held"
    static let interactionSpent = "duat_interaction_spent"
    static let interactionReforge = "duat_interaction_reforge"
    static let interactionImbue = "duat_interaction_imbue"
    static let interactionSwap = "duat_interaction_swap"

    static let slotWeapon = "duat_slot_weapon"
    static let slotArmour = "duat_slot_armour"

    static let upgradeHammer = "duat_upgrade_hammer"
    static let upgradeWhetstone = "duat_upgrade_whetstone"

    static let strawEffigy = "duat_enemy_strawEffigy"

    // MARK: - Status marks

    /// Semantic status marks. Several reuse a face plate, as the pack's own
    /// reuse table prescribes — the meanings are identical, so the drawings are.
    enum Status {
        static let health = "duat_face_heal"
        static let shield = "duat_face_block"
        static let stamina = "duat_face_energize"
        static let focus = "duat_face_focus"
        static let evade = "duat_face_evade"
        static let regeneration = "duat_face_runeLife"
        static let burn = "duat_face_runeFire"
        static let poison = "duat_face_poison"
        static let frost = "duat_face_runeFrost"
        static let bleed = "duat_status_bleed"
        static let armour = "duat_status_bronzeArmour"
        static let champion = "duat_status_champion"
        static let critical = "duat_status_critical"
        static let judgement = "duat_status_judgement"
        static let marked = "duat_status_markedTarget"
        static let piercing = "duat_status_piercing"
    }

    // MARK: - Die frames

    /// Which painted frame a tray reel wears. The frames have open centres —
    /// the face plate and its live numbers are drawn inside the window.
    enum DieFrame: String {
        case empty = "duat_ui_die_empty"
        case ready = "duat_ui_die_ready"
        case rolling = "duat_ui_die_rolling"
        case selected = "duat_ui_die_selected"
        case held = "duat_ui_die_held"
        case spent = "duat_ui_die_spent"
        case critical = "duat_ui_die_critical"
    }

    /// The conservative opening in every die frame, as a fraction of its
    /// content rectangle. The manifest gives the window against the whole
    /// canvas; these are re-based so a cropped frame can use them directly.
    static func faceWindow(_ frame: DieFrame) -> CGRect {
        let box = crop(frame.rawValue)
        let canvas = CGRect(x: 0.34, y: 0.34, width: 0.32, height: 0.32)
        return CGRect(
            x: (canvas.minX - box.x) / box.width,
            y: (canvas.minY - box.y) / box.height,
            width: canvas.width / box.width,
            height: canvas.height / box.height
        )
    }

    // MARK: - Buttons

    enum ButtonTone {
        case primary
        case secondary
    }

    enum ButtonState {
        case normal
        case pressed
        case highlighted
        case disabled
        case selected
    }

    /// The painted button plate for a tone and state, falling back through the
    /// states the pack actually drew (the secondary set has no highlight, the
    /// primary set no selection).
    static func button(_ tone: ButtonTone, _ state: ButtonState) -> String {
        let stem = tone == .primary ? "duat_ui_button_primary" : "duat_ui_button_secondary"
        let candidates: [String]
        switch state {
        case .normal: candidates = ["normal"]
        case .pressed: candidates = ["pressed", "normal"]
        case .highlighted: candidates = ["highlighted", "selected", "normal"]
        case .disabled: candidates = ["disabled", "normal"]
        case .selected: candidates = ["selected", "highlighted", "pressed", "normal"]
        }
        for suffix in candidates {
            let name = "\(stem)_\(suffix)"
            if exists(name) { return name }
        }
        return "\(stem)_normal"
    }

    // MARK: - Route nodes

    enum RouteState: String {
        case available = "duat_ui_route_available"
        case selected = "duat_ui_route_selected"
        case cleared = "duat_ui_route_cleared"
        case locked = "duat_ui_route_locked"
        case boss = "duat_ui_route_boss"
    }

    // MARK: - Rarity frames

    static func rarityFrame(_ rarity: Rarity) -> String {
        switch rarity {
        case .common: "duat_ui_rarity_clay"
        case .uncommon: "duat_ui_rarity_copper"
        case .rare: "duat_ui_rarity_lapis"
        case .signature: "duat_ui_rarity_goldLeaf"
        }
    }

    // MARK: - Class plates

    /// The tall painted frame a class card wears.
    static func classFrame(_ classID: String) -> String? {
        resolve("duat_ui_class_\(classID)")
    }

    /// A compact sigil standing for a class, per the pack's reuse table.
    static func classSigil(_ classID: String) -> String? {
        switch classID {
        case "archer": resolve("duat_face_bowSmack")
        case "warrior": resolve("duat_chisel_relentlessAdvance")
        case "rogue": resolve("duat_chisel_assassinsCommitment")
        case "magician": resolve("duat_face_wandZap")
        default: nil
        }
    }

    // MARK: - Content mappings

    static func chisel(_ id: String) -> String? {
        resolve(chiselPlates[id])
    }

    private static let chiselPlates: [String: String] = [
        "ch_twinBowstring": "duat_chisel_twinBowstring",
        "ch_siegeDraw": "duat_chisel_siegeDraw",
        "ch_adjustableNock": "duat_chisel_adjustableNock",
        "ch_crescentEdge": "duat_chisel_crescentEdge",
        "ch_counterweight": "duat_chisel_counterweight",
        "ch_relentless": "duat_chisel_relentlessAdvance",
        "ch_returningKnife": "duat_chisel_returningKnife",
        "ch_concealedBlade": "duat_chisel_concealedBlade",
        "ch_assassin": "duat_chisel_assassinsCommitment",
        "ch_prismatic": "duat_chisel_prismaticFocus",
        "ch_echoingStaff": "duat_chisel_echoingStaff",
        "ch_current": "duat_chisel_alternatingCurrent",
    ]

    // MARK: - Content rectangles

    private static let crops: [String: PharaohSWagerCrop] = {
        var table: [String: PharaohSWagerCrop] = [:]
        for group in [faceCrops, deityCrops, navigationCrops, treasureCrops,
                      symbolCrops, chromeCrops, environmentCrops, figureCrops,
                      spriteSheetCrops, enemySheetCrops] {
            table.merge(group) { first, _ in first }
        }
        return table
    }()

    private static let faceCrops: [String: PharaohSWagerCrop] = [
        "duat_face_arrow1": PharaohSWagerCrop(0.0526, 0.0494, 0.9067, 0.9075, 1),
        "duat_face_arrow2": PharaohSWagerCrop(0.0774, 0.0614, 0.8461, 0.8788, 1),
        "duat_face_arrow3": PharaohSWagerCrop(0.1491, 0.0359, 0.6962, 0.9139, 1),
        "duat_face_block": PharaohSWagerCrop(0.2049, 0.0423, 0.5909, 0.9163, 1),
        "duat_face_bomb": PharaohSWagerCrop(0.1986, 0.0351, 0.6906, 0.9003, 1),
        "duat_face_bowSmack": PharaohSWagerCrop(0.0774, 0.0096, 0.8533, 0.9585, 1),
        "duat_face_channel": PharaohSWagerCrop(0.1834, 0.0431, 0.6348, 0.8716, 1),
        "duat_face_daggerThrow": PharaohSWagerCrop(0.0502, 0.3788, 0.9282, 0.2177, 1),
        "duat_face_energize": PharaohSWagerCrop(0.1699, 0.1124, 0.6603, 0.7783, 1),
        "duat_face_evade": PharaohSWagerCrop(0.1587, 0.0718, 0.7121, 0.7528, 1),
        "duat_face_focus": PharaohSWagerCrop(0.0877, 0.1411, 0.8262, 0.7281, 1),
        "duat_face_heal": PharaohSWagerCrop(0.1667, 0.1874, 0.6675, 0.6236, 1),
        "duat_face_overhead": PharaohSWagerCrop(0.2041, 0.0805, 0.6268, 0.8293, 1),
        "duat_face_poison": PharaohSWagerCrop(0.2352, 0.0845, 0.5295, 0.8278, 1),
        "duat_face_runeArcane": PharaohSWagerCrop(0.1316, 0.1037, 0.7344, 0.7576, 1),
        "duat_face_runeFire": PharaohSWagerCrop(0.1116, 0.1053, 0.7759, 0.7839, 1),
        "duat_face_runeFrost": PharaohSWagerCrop(0.0981, 0.0885, 0.8014, 0.8118, 1),
        "duat_face_runeLife": PharaohSWagerCrop(0.0550, 0.0566, 0.8900, 0.8748, 1),
        "duat_face_sideSwing": PharaohSWagerCrop(0.0399, 0.1539, 0.9226, 0.6738, 1),
        "duat_face_swiftSlash": PharaohSWagerCrop(0.1228, 0.1013, 0.7831, 0.7974, 1),
        "duat_face_wandZap": PharaohSWagerCrop(0.1659, 0.0837, 0.7560, 0.7839, 1),
    ]

    private static let deityCrops: [String: PharaohSWagerCrop] = [
        "duat_deity_anubis": PharaohSWagerCrop(0.2041, 0.0016, 0.6212, 0.9553, 1),
        "duat_deity_bastet": PharaohSWagerCrop(0.2472, 0.0303, 0.5056, 0.9195, 1),
        "duat_deity_bes": PharaohSWagerCrop(0.1316, 0.0941, 0.7376, 0.8150, 1),
        "duat_deity_horus": PharaohSWagerCrop(0.1164, 0.0742, 0.8006, 0.8485, 1),
        "duat_deity_ra": PharaohSWagerCrop(0.0510, 0.0343, 0.8971, 0.8923, 1),
        "duat_deity_sobek": PharaohSWagerCrop(0.0829, 0.1316, 0.8660, 0.7360, 1),
        "duat_trial_halo": PharaohSWagerCrop(0.0199, 0.0000, 0.9609, 0.9896, 1),
    ]

    private static let navigationCrops: [String: PharaohSWagerCrop] = [
        "duat_route_ferryman": PharaohSWagerCrop(0.0853, 0.1515, 0.8325, 0.7089, 1),
        "duat_route_guardian": PharaohSWagerCrop(0.0957, 0.0359, 0.8381, 0.9035, 1),
        "duat_route_herald": PharaohSWagerCrop(0.2600, 0.0136, 0.4809, 0.9697, 1),
        "duat_route_mooring": PharaohSWagerCrop(0.1021, 0.1691, 0.8166, 0.6675, 1),
        "duat_route_omen": PharaohSWagerCrop(0.1978, 0.1156, 0.6045, 0.7735, 1),
        "duat_route_serpentLord": PharaohSWagerCrop(0.2161, 0.0399, 0.6005, 0.9234, 1),
        "duat_route_shrine": PharaohSWagerCrop(0.0845, 0.1699, 0.8317, 0.6603, 1),
        "duat_gate_coils": PharaohSWagerCrop(0.0997, 0.0534, 0.7943, 0.9115, 1),
        "duat_gate_fire": PharaohSWagerCrop(0.1212, 0.0766, 0.7576, 0.8126, 1),
        "duat_gate_reeds": PharaohSWagerCrop(0.1364, 0.0694, 0.7273, 0.8612, 1),
        "duat_ui_route_available": PharaohSWagerCrop(0.0263, 0.0367, 0.9466, 0.9195, 1),
        "duat_ui_route_boss": PharaohSWagerCrop(0.0901, 0.0510, 0.8198, 0.8979, 1),
        "duat_ui_route_cleared": PharaohSWagerCrop(0.0391, 0.0295, 0.9219, 0.9011, 1),
        "duat_ui_route_locked": PharaohSWagerCrop(0.0423, 0.0032, 0.9139, 0.9689, 1),
        "duat_ui_route_selected": PharaohSWagerCrop(0.0072, 0.0016, 0.9856, 0.9920, 1),
        "duat_ui_night_boundary": PharaohSWagerCrop(0.0630, 0.1786, 0.8740, 0.6212, 1),
        "duat_ui_night_cleared": PharaohSWagerCrop(0.2480, 0.2337, 0.5813, 0.5191, 1),
        "duat_ui_night_current": PharaohSWagerCrop(0.2456, 0.2408, 0.5096, 0.5040, 1),
        "duat_ui_night_hour": PharaohSWagerCrop(0.3700, 0.2751, 0.2608, 0.4290, 1),
    ]

    private static let treasureCrops: [String: PharaohSWagerCrop] = [
        "duat_item_alchemistsKit": PharaohSWagerCrop(0.1037, 0.0941, 0.8030, 0.8110, 1),
        "duat_item_explosiveCharge": PharaohSWagerCrop(0.2113, 0.0343, 0.5774, 0.8086, 1),
        "duat_item_healingPotion": PharaohSWagerCrop(0.1770, 0.0136, 0.6451, 0.9530, 1),
        "duat_item_phoenixFlask": PharaohSWagerCrop(0.1404, 0.0088, 0.7193, 0.9761, 1),
        "duat_item_poisonVial": PharaohSWagerCrop(0.3796, 0.0239, 0.2384, 0.8987, 1),
        "duat_item_smokeBomb": PharaohSWagerCrop(0.2329, 0.0096, 0.5383, 0.9242, 1),
        "duat_item_warlocksCharm": PharaohSWagerCrop(0.3501, 0.0088, 0.3030, 0.9203, 1),
        "duat_relic_brazierOfDawn": PharaohSWagerCrop(0.1499, 0.0112, 0.6994, 0.9569, 1),
        "duat_relic_canopicHeart": PharaohSWagerCrop(0.2392, 0.0128, 0.5215, 0.9729, 1),
        "duat_relic_eyeOfHorus": PharaohSWagerCrop(0.0590, 0.0271, 0.9019, 0.8955, 1),
        "duat_relic_ferrymansToll": PharaohSWagerCrop(0.2026, 0.0829, 0.6404, 0.8349, 1),
        "duat_relic_vialOfNile": PharaohSWagerCrop(0.1443, 0.0813, 0.7113, 0.8365, 1),
        "duat_relic_wardOfBes": PharaohSWagerCrop(0.1651, 0.0040, 0.6699, 0.9545, 1),
        "duat_chisel_adjustableNock": PharaohSWagerCrop(0.0343, 0.0494, 0.9434, 0.8892, 1),
        "duat_chisel_alternatingCurrent": PharaohSWagerCrop(0.1380, 0.0159, 0.7249, 0.9514, 1),
        "duat_chisel_assassinsCommitment": PharaohSWagerCrop(0.0407, 0.0335, 0.9187, 0.8764, 1),
        "duat_chisel_concealedBlade": PharaohSWagerCrop(0.2002, 0.0702, 0.7049, 0.8628, 1),
        "duat_chisel_counterweight": PharaohSWagerCrop(0.2488, 0.0080, 0.4992, 0.9785, 1),
        "duat_chisel_crescentEdge": PharaohSWagerCrop(0.0494, 0.0048, 0.9019, 0.9649, 1),
        "duat_chisel_echoingStaff": PharaohSWagerCrop(0.2799, 0.0526, 0.4506, 0.8971, 1),
        "duat_chisel_prismaticFocus": PharaohSWagerCrop(0.0614, 0.0096, 0.8764, 0.9442, 1),
        "duat_chisel_relentlessAdvance": PharaohSWagerCrop(0.0550, 0.1156, 0.8684, 0.7791, 1),
        "duat_chisel_returningKnife": PharaohSWagerCrop(0.0606, 0.0630, 0.8907, 0.8636, 1),
        "duat_chisel_siegeDraw": PharaohSWagerCrop(0.0343, 0.0008, 0.9338, 0.9960, 1),
        "duat_chisel_twinBowstring": PharaohSWagerCrop(0.2201, 0.0104, 0.6946, 0.9705, 1),
    ]

    private static let symbolCrops: [String: PharaohSWagerCrop] = [
        "duat_status_bleed": PharaohSWagerCrop(0.2342, 0.0742, 0.5315, 0.8468, 1.0226),
        "duat_status_bronzeArmour": PharaohSWagerCrop(0.2041, 0.0997, 0.5901, 0.8022, 1),
        "duat_status_champion": PharaohSWagerCrop(0.2033, 0.0383, 0.5973, 0.8509, 1),
        "duat_status_critical": PharaohSWagerCrop(0.0335, 0.0279, 0.9290, 0.9091, 1),
        "duat_status_judgement": PharaohSWagerCrop(0.0303, 0.0486, 0.9394, 0.9051, 1),
        "duat_status_markedTarget": PharaohSWagerCrop(0.0558, 0.0415, 0.8884, 0.9059, 1),
        "duat_status_piercing": PharaohSWagerCrop(0.0104, 0.1300, 0.9721, 0.6603, 1),
        "duat_interaction_held": PharaohSWagerCrop(0.2257, 0.1108, 0.5439, 0.7536, 1),
        "duat_interaction_imbue": PharaohSWagerCrop(0.2536, 0.0582, 0.4944, 0.8429, 1),
        "duat_interaction_reforge": PharaohSWagerCrop(0.0742, 0.0781, 0.8684, 0.8429, 1),
        "duat_interaction_roll": PharaohSWagerCrop(0.0989, 0.1507, 0.8636, 0.7297, 1),
        "duat_interaction_spent": PharaohSWagerCrop(0.2193, 0.1834, 0.5702, 0.6411, 1),
        "duat_interaction_swap": PharaohSWagerCrop(0.0997, 0.1300, 0.7911, 0.7305, 1),
        "duat_slot_armour": PharaohSWagerCrop(0.0851, 0.0295, 0.8412, 0.9394, 0.9495),
        "duat_slot_item": PharaohSWagerCrop(0.1889, 0.0836, 0.6183, 0.7939, 1.0778),
        "duat_slot_weapon": PharaohSWagerCrop(0.1434, 0.0633, 0.7262, 0.8733, 1.0925),
        "duat_upgrade_hammer": PharaohSWagerCrop(0.1132, 0.0518, 0.7751, 0.8517, 1),
        "duat_upgrade_whetstone": PharaohSWagerCrop(0.0781, 0.1842, 0.8501, 0.5949, 1),
        "duat_utility_back": PharaohSWagerCrop(0.2926, 0.1522, 0.4221, 0.7096, 1.1887),
        "duat_utility_close": PharaohSWagerCrop(0.1515, 0.1619, 0.6970, 0.6786, 1),
        "duat_utility_codex": PharaohSWagerCrop(0.0997, 0.1882, 0.8062, 0.6324, 1),
        "duat_utility_currency": PharaohSWagerCrop(0.1004, 0.1021, 0.7992, 0.8023, 1.0332),
        "duat_utility_forward": PharaohSWagerCrop(0.2323, 0.1726, 0.5508, 0.6635, 0.9771),
        "duat_utility_records": PharaohSWagerCrop(0.2687, 0.1404, 0.4617, 0.7265, 1),
    ]

    private static let chromeCrops: [String: PharaohSWagerCrop] = [
        "duat_ui_panel_large": PharaohSWagerCrop(0.0407, 0.0455, 0.9195, 0.9067, 1),
        "duat_ui_card_small": PharaohSWagerCrop(0.2823, 0.0821, 0.4362, 0.8325, 1),
        "duat_ui_cartouche": PharaohSWagerCrop(0.1356, 0.3900, 0.7225, 0.2177, 1),
        "duat_ui_corner_gold": PharaohSWagerCrop(0.0455, 0.0502, 0.8868, 0.8748, 1),
        "duat_ui_divider_gold": PharaohSWagerCrop(0.0231, 0.4721, 0.9537, 0.0582, 1),
        "duat_ui_divider_winged": PharaohSWagerCrop(0.0488, 0.3149, 0.9024, 0.3729, 3),
        "duat_ui_hieroglyph_strip": PharaohSWagerCrop(0.0005, 0.3494, 0.9991, 0.3011, 3),
        "duat_ui_banner": PharaohSWagerCrop(0.0156, 0.2623, 0.9687, 0.4338, 2.5006),
        "duat_ui_banner_victory": PharaohSWagerCrop(0.0129, 0.1727, 0.9747, 0.6533, 3),
        "duat_ui_banner_defeat": PharaohSWagerCrop(0.0041, 0.1478, 0.9917, 0.6989, 3),
        "duat_ui_bar_track": PharaohSWagerCrop(0.0144, 0.4569, 0.9721, 0.0861, 1),
        "duat_ui_bar_fill_health": PharaohSWagerCrop(0.0486, 0.4713, 0.9027, 0.0566, 1),
        "duat_ui_bar_fill_shield": PharaohSWagerCrop(0.0654, 0.4769, 0.8692, 0.0494, 1),
        "duat_ui_bar_fill_armour": PharaohSWagerCrop(0.0662, 0.4729, 0.8676, 0.0534, 1),
        "duat_ui_bar_endcap": PharaohSWagerCrop(0.1866, 0.1738, 0.6276, 0.6499, 1),
        "duat_ui_stamina_full": PharaohSWagerCrop(0.2887, 0.1762, 0.4226, 0.6483, 1),
        "duat_ui_stamina_empty": PharaohSWagerCrop(0.2855, 0.2081, 0.4290, 0.5670, 1),
        "duat_ui_stamina_reserve": PharaohSWagerCrop(0.2217, 0.1627, 0.6188, 0.6427, 1),
        "duat_ui_chain_connector": PharaohSWagerCrop(0.0638, 0.3110, 0.8732, 0.3844, 1),
        "duat_ui_turn_slot": PharaohSWagerCrop(0.1380, 0.1443, 0.7241, 0.7105, 1),
        "duat_ui_cost_badge": PharaohSWagerCrop(0.0989, 0.1443, 0.8022, 0.7209, 1),
        "duat_ui_echo_marker": PharaohSWagerCrop(0.0837, 0.0558, 0.8549, 0.8915, 1),
        "duat_ui_enemy_intent": PharaohSWagerCrop(0.0391, 0.3477, 0.9226, 0.2895, 1),
        "duat_ui_target_ring": PharaohSWagerCrop(0.0375, 0.2974, 0.9258, 0.4258, 1),
        "duat_ui_tab_selected": PharaohSWagerCrop(0.0303, 0.3828, 0.9394, 0.2464, 1),
        "duat_ui_tab_unselected": PharaohSWagerCrop(0.0447, 0.4147, 0.9107, 0.1699, 1),
        "duat_ui_die_empty": PharaohSWagerCrop(0.1627, 0.1627, 0.6762, 0.6611, 1),
        "duat_ui_die_ready": PharaohSWagerCrop(0.1627, 0.1635, 0.6738, 0.6523, 1),
        "duat_ui_die_rolling": PharaohSWagerCrop(0.1204, 0.0981, 0.8094, 0.7751, 1),
        "duat_ui_die_selected": PharaohSWagerCrop(0.1443, 0.1467, 0.7113, 0.6898, 1),
        "duat_ui_die_held": PharaohSWagerCrop(0.1061, 0.0837, 0.7863, 0.7863, 1),
        "duat_ui_die_spent": PharaohSWagerCrop(0.1419, 0.1435, 0.7169, 0.6946, 1),
        "duat_ui_die_critical": PharaohSWagerCrop(0.0917, 0.0949, 0.8166, 0.7847, 1),
        "duat_ui_rarity_clay": PharaohSWagerCrop(0.1300, 0.1324, 0.7416, 0.7161, 1),
        "duat_ui_rarity_copper": PharaohSWagerCrop(0.1037, 0.1204, 0.7927, 0.7552, 1),
        "duat_ui_rarity_lapis": PharaohSWagerCrop(0.1132, 0.1316, 0.7735, 0.7352, 1),
        "duat_ui_rarity_goldLeaf": PharaohSWagerCrop(0.0590, 0.0781, 0.8820, 0.8429, 1),
        "duat_ui_class_archer": PharaohSWagerCrop(0.1922, 0.0048, 0.6156, 0.9856, 1),
        "duat_ui_class_warrior": PharaohSWagerCrop(0.2233, 0.0311, 0.5542, 0.9067, 1),
        "duat_ui_class_rogue": PharaohSWagerCrop(0.2281, 0.0096, 0.5447, 0.9099, 1),
        "duat_ui_class_magician": PharaohSWagerCrop(0.2536, 0.0606, 0.4928, 0.8517, 1),
        "duat_ui_button_primary_normal": PharaohSWagerCrop(0.0670, 0.4155, 0.8668, 0.1691, 1),
        "duat_ui_button_primary_pressed": PharaohSWagerCrop(0.0287, 0.3979, 0.9434, 0.1954, 1),
        "duat_ui_button_primary_highlighted": PharaohSWagerCrop(0.0183, 0.4075, 0.9641, 0.1722, 1),
        "duat_ui_button_primary_disabled": PharaohSWagerCrop(0.0351, 0.4195, 0.9298, 0.1675, 1),
        "duat_ui_button_secondary_normal": PharaohSWagerCrop(0.0566, 0.3947, 0.8868, 0.2073, 1),
        "duat_ui_button_secondary_pressed": PharaohSWagerCrop(0.0455, 0.3923, 0.9091, 0.2018, 1),
        "duat_ui_button_secondary_disabled": PharaohSWagerCrop(0.0861, 0.4378, 0.8278, 0.1244, 1),
        "duat_ui_button_secondary_selected": PharaohSWagerCrop(0.0340, 0.2633, 0.9324, 0.4502, 2.9277),
    ]

    private static let environmentCrops: [String: PharaohSWagerCrop] = [
        "duat_environment_barque": PharaohSWagerCrop(0.0085, 0.0654, 0.9882, 0.8286, 2),
        "duat_environment_battle_barque": PharaohSWagerCrop(0.002, 0.002, 0.996, 0.996, 3),
        "duat_environment_brazier": PharaohSWagerCrop(0.0494, 0.1063, 0.9020, 0.8027, 1.1369),
        "duat_environment_coil": PharaohSWagerCrop(0.0135, 0.1071, 0.9803, 0.8444, 2),
        "duat_environment_ember": PharaohSWagerCrop(0.4208, 0.1842, 0.1995, 0.5794, 0.9826),
        "duat_environment_flame": PharaohSWagerCrop(0.2355, 0.0075, 0.5610, 0.9867, 1.0942),
        "duat_environment_mist": PharaohSWagerCrop(0.0014, 0.2265, 0.9968, 0.4890, 3),
        "duat_environment_reeds_left": PharaohSWagerCrop(0.1090, 0.0217, 0.7058, 0.9558, 1.0942),
        "duat_environment_reeds_right": PharaohSWagerCrop(0.1555, 0.0108, 0.8262, 0.9800, 1.0942),
        "duat_environment_ripple_ember": PharaohSWagerCrop(0.0383, 0.2954, 0.9239, 0.4059, 2),
        "duat_environment_ripple_jade": PharaohSWagerCrop(0.0423, 0.2875, 0.9267, 0.4758, 2),
        "duat_environment_ripple_violet": PharaohSWagerCrop(0.0395, 0.2954, 0.9233, 0.4397, 2),
        "duat_environment_ruins": PharaohSWagerCrop(0.0079, 0.1105, 0.9853, 0.7790, 2),
        "duat_environment_star": PharaohSWagerCrop(0.2512, 0.0621, 0.4969, 0.8418, 1.0250),
        "duat_environment_sun_bright": PharaohSWagerCrop(0.0603, 0.0407, 0.8732, 0.8959, 1.0390),
        "duat_environment_sun_weakened": PharaohSWagerCrop(0.0457, 0.0686, 0.9054, 0.8511, 0.9556),
        "duat_environment_sun_extinguished": PharaohSWagerCrop(0.1237, 0.1219, 0.7526, 0.7482, 1.0112),
        "duat_environment_sun_halo": PharaohSWagerCrop(0.0056, 0.0032, 0.9897, 0.9848, 1.0112),
    ]

    private static let figureCrops: [String: PharaohSWagerCrop] = [
        "duat_enemy_strawEffigy": PharaohSWagerCrop(0.0227, 0.0022, 0.9301, 0.9745, 0.8333),
        "duat_hero_archer_guardUp": PharaohSWagerCrop(0.0688, 0.0888, 0.8509, 0.8512, 0.9008),
        "duat_hero_magician_defeat": PharaohSWagerCrop(0.0078, 0.0072, 0.9805, 0.9818, 0.6667),
        "duat_hero_magician_dodge": PharaohSWagerCrop(0.0059, 0.0078, 0.9922, 0.9714, 0.6667),
        "duat_hero_magician_follow": PharaohSWagerCrop(0.1629, 0.1076, 0.7567, 0.7882, 0.7778),
        "duat_hero_magician_victory": PharaohSWagerCrop(0.0322, 0.0046, 0.9609, 0.9701, 0.6667),
        "duat_hero_rogue_defeat": PharaohSWagerCrop(0.0195, 0.1647, 0.9561, 0.7233, 0.6667),
        "duat_hero_rogue_hurt": PharaohSWagerCrop(0.0826, 0.2049, 0.8237, 0.7465, 0.7778),
    ]

    /// Frames sliced out of a hand-drawn sprite sheet. Every plate in a sheet
    /// shares one canvas, one content box and one planted baseline, so they all
    /// crop identically — crop each frame to its own ink and the figure would
    /// jitter and change size from frame to frame. The box bottom sits just
    /// under that shared baseline, so the figure stands on its own shadow
    /// instead of floating above it.
    private static let spriteSheetCrops: [String: PharaohSWagerCrop] = {
        let box = PharaohSWagerCrop(0, 0.0821, 1, 0.8857, 0.6857)
        var table: [String: PharaohSWagerCrop] = [:]
        for hero in SpriteSheet.animatedHeroes {
            for clip in SpriteSheet.clips {
                for index in 0..<SpriteSheet.frameCount {
                    table["duat_hero_\(hero)_\(clip)_f\(index)"] = box
                }
            }
        }
        return table
    }()

    /// The enemy sheets, sliced the same way: every frame of one creature
    /// shares a single content box, measured across all sixteen plates so the
    /// figure never resizes or jumps between frames of an action.
    private static let enemySheetCrops: [String: PharaohSWagerCrop] = {
        var table: [String: PharaohSWagerCrop] = [:]
        for (id, box) in EnemySheet.contentBoxes {
            for clip in EnemySheet.clips {
                for index in 0..<EnemySheet.frameCount {
                    table["duat_enemy_\(id)_\(clip)_f\(index)"] = box
                }
            }
        }
        return table
    }()
}

/// Facts about the hand-drawn sheets that both the crop table and the clip
/// library need to agree on.
enum SpriteSheet {
    /// Frames per sheet — every sheet was drawn as a 4×2 grid of eight poses.
    static let frameCount = 8
    /// The drawn actions, one sheet each, that every hero owns.
    static let clips = ["idle", "attack", "block", "hurt"]
    /// Heroes whose sheets have been keyed, baselined and bundled.
    static let animatedHeroes = ["archer", "warrior", "rogue", "magician"]
}

/// The enemy sprite sheets: four four-frame rows per creature.
///
/// The rows are named for what they *do*, not for the game's pose names:
/// `block` is the flinch a creature makes when a blow lands on it, and
/// `defend` is the guard it raises and holds. The clip library maps them onto
/// the game's poses accordingly.
enum EnemySheet {
    static let frameCount = 4
    static let clips = ["idle", "attack", "block", "defend"]

    /// Where the ink sits inside each creature's 314×314 frames, measured
    /// across all sixteen plates of that creature so the figure never resizes
    /// or hops between frames. Membership of this table is also what marks a
    /// creature as animated — anything absent falls back to a still.
    static let contentBoxes: [String: PharaohSWagerCrop] = [
        "reedLurker": PharaohSWagerCrop(0.0000, 0.1242, 1.0000, 0.7866, 1),
        "marshShade": PharaohSWagerCrop(0.0000, 0.0191, 1.0000, 0.9809, 1),
        "sandCrawler": PharaohSWagerCrop(0.0000, 0.0382, 1.0000, 0.8535, 1),
        "sekhen": PharaohSWagerCrop(0.0000, 0.0159, 1.0000, 0.9586, 1),
        "emberWraith": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "flamekeeper": PharaohSWagerCrop(0.0064, 0.0191, 0.9650, 0.9618, 1),
        "ashJackal": PharaohSWagerCrop(0.0000, 0.0605, 1.0000, 0.9045, 1),
        "nehebkau": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "devourerSpawn": PharaohSWagerCrop(0.0000, 0.1019, 1.0000, 0.8694, 1),
        "uncreatedShadow": PharaohSWagerCrop(0.0000, 0.0159, 1.0000, 0.9650, 1),
        "hourEater": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "apep": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 0.9777, 1),
        "siltColossus": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "bronzeEffigy": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "boneplateDevourer": PharaohSWagerCrop(0.0000, 0.0860, 1.0000, 0.8981, 1),
        "apep_coils": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
        "apep_maw": PharaohSWagerCrop(0.0000, 0.0000, 1.0000, 1.0000, 1),
    ]

    /// A serpent-lord re-coils into a new body partway through its fight, and
    /// each stage was drawn its own sheet.
    static let stageSheets: [String: String] = [
        "apep_head": "apep",
        "apep_coils": "apep_coils",
        "apep_maw": "apep_maw",
    ]

    /// The plate name for one frame of one creature's action.
    static func plate(_ id: String, _ clip: String, _ index: Int) -> String {
        "duat_enemy_\(id)_\(clip)_f\(index)"
    }

    /// The resting drawing used for portraits and arrival cards.
    static func portrait(_ id: String) -> String { plate(id, "idle", 0) }
}

// MARK: - Model mappings

extension FaceKind {
    /// The painted plate for this face. Every face in the game was drawn.
    var artName: String? { PharaohSWagerArt.resolve("duat_face_\(rawValue)") }
}

extension Deity {
    /// The god's painted sigil.
    var artName: String? { PharaohSWagerArt.resolve("duat_deity_\(rawValue)") }
}

extension Gate {
    /// The gate's painted emblem.
    var artName: String? {
        switch self {
        case .reeds: PharaohSWagerArt.resolve("duat_gate_reeds")
        case .fire: PharaohSWagerArt.resolve("duat_gate_fire")
        case .coils: PharaohSWagerArt.resolve("duat_gate_coils")
        }
    }

    /// Which river reflection is painted on this gate's water.
    var rippleArt: String {
        switch self {
        case .reeds: "duat_environment_ripple_jade"
        case .fire: "duat_environment_ripple_ember"
        case .coils: "duat_environment_ripple_violet"
        }
    }

    /// How far Ra's disc has burned down by the time the barque reaches here.
    var sunArt: String {
        switch self {
        case .reeds: "duat_environment_sun_bright"
        case .fire: "duat_environment_sun_weakened"
        case .coils: "duat_environment_sun_extinguished"
        }
    }
}

extension StageKind {
    /// The painted marker for this kind of stop on the river.
    var artName: String? {
        switch self {
        case .battle: PharaohSWagerArt.resolve("duat_route_guardian")
        case .herald: PharaohSWagerArt.resolve("duat_route_herald")
        case .shrine: PharaohSWagerArt.resolve("duat_route_shrine")
        case .ferryman: PharaohSWagerArt.resolve("duat_route_ferryman")
        case .omen: PharaohSWagerArt.resolve("duat_route_omen")
        case .boss: PharaohSWagerArt.resolve("duat_route_serpentLord")
        }
    }
}

extension Rarity {
    var frameArt: String { PharaohSWagerArt.rarityFrame(self) }
}

extension GearSlot {
    /// The painted socket for this slot.
    var artName: String? {
        switch self {
        case .weapon: PharaohSWagerArt.resolve(PharaohSWagerArt.slotWeapon)
        case .armor: PharaohSWagerArt.resolve(PharaohSWagerArt.slotArmour)
        }
    }
}

extension ChiselDef {
    var artName: String? { PharaohSWagerArt.chisel(id) }
}

extension Offer {
    /// What this card hands over, painted. Blessings wear their god's sigil;
    /// everything else wears the drawing of the thing itself.
    var artName: String? {
        switch kind {
        case .die:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.DieFrame.ready.rawValue)
        case .reforge(let face):
            return face.artName
        case .reforgeDie:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.interactionReforge)
        case .patron(let god, _):
            return god.artName
        case .boon(let def, _):
            return def.god.artName
        case .boonLevel(let owned):
            return owned.def?.god.artName ?? deity?.artName
        case .legendary(let def, _):
            return def.god.artName
        case .upgrade, .capstone:
            return deity?.artName ?? PharaohSWagerArt.resolve(PharaohSWagerArt.Status.judgement)
        case .pairing(let pairing):
            return pairing.first.artName
        case .imbue:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.interactionImbue)
        case .heal:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.Status.health)
        case .maxHP:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.Status.health)
        case .gold:
            return PharaohSWagerArt.resolve(PharaohSWagerArt.currency)
        case .chiselPick(let chisel):
            return PharaohSWagerArt.resolve(PharaohSWagerArt.chisel(chisel.id) ?? PharaohSWagerArt.upgradeHammer)
        }
    }
}
