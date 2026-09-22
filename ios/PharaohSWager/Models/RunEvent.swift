import Foundation

/// One branch of an omen: a line of flavour and what it costs / grants.
struct EventChoice: Identifiable, Hashable, Codable {
    let id: String
    let label: String
    let detail: String
    /// Health paid up front (can be zero).
    let hpCost: Int
    /// Gold paid up front.
    let goldCost: Int
    /// Permanent max health change (can be negative).
    let maxHPChange: Int
    /// What the choice hands over, if anything.
    let reward: EventReward
}

/// What an omen's choice grants.
enum EventReward: Hashable, Codable {
    case none
    case gold(Int)
    case pathRerolls(Int)
    case heal(Int)
    /// Roll a class-appropriate reforge at the current tier.
    case reforge
    /// Roll a class-appropriate crit imbue at the current tier.
    case imbue
    /// Roll a class-appropriate die at the current tier.
    case die
    /// An ultra-rare omen favour: a god claims one of your dice as patron.
    case patronOffer
    /// A gamble: `chance` to win the first reward, else take damage.
    case gamble(chance: Double, damage: Int)
}

/// A sighting on the river with a choice to make.
struct RunEvent: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let symbol: String
    let body: String
    let choices: [EventChoice]
}

enum EventContent {
    static let all: [RunEvent] = [
        RunEvent(
            id: "scales", title: "A Heart on the Scales", symbol: "scalemass.fill",
            body: "A pair of brass scales stands waist-deep in the river, unattended. On one pan sits a feather. The other is empty, and it is turned toward you.",
            choices: [
                EventChoice(id: "scales_weigh", label: "Lay your heart on the pan", detail: "Lose 12 health, one face is judged and reforged",
                            hpCost: 12, goldCost: 0, maxHPChange: 0, reward: .reforge),
                EventChoice(id: "scales_feather", label: "Take the feather instead", detail: "-25 gold, sharpen one face's edge",
                            hpCost: 0, goldCost: 25, maxHPChange: 0, reward: .imbue),
                EventChoice(id: "scales_pass", label: "Row past without looking", detail: "Nothing weighed, nothing lost",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .none),
            ]
        ),
        RunEvent(
            id: "lakeOfFire", title: "The Lake That Offers a Trade", symbol: "flame.fill",
            body: "The channel opens into standing fire. A voice comes out of it, patient and enormous: \"Put something of yourself in. I will hand it back sharper.\"",
            choices: [
                EventChoice(id: "fire_burn", label: "Hold your hand in the flame", detail: "-8 max health, imbue one face with crit",
                            hpCost: 0, goldCost: 0, maxHPChange: -8, reward: .imbue),
                EventChoice(id: "fire_offer", label: "Cast in a gold ring", detail: "-30 gold, one face reforged in fire",
                            hpCost: 0, goldCost: 30, maxHPChange: 0, reward: .reforge),
                EventChoice(id: "fire_warm", label: "Just warm the crew", detail: "Restore 22 health",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .heal(22)),
            ]
        ),
        RunEvent(
            id: "drownedCrew", title: "The Drowned Crew", symbol: "figure.wave",
            body: "Hands come out of the water on both sides of the hull — a whole crew, still counting themselves off. They only want to be counted. Counting takes time, and time is the sun's.",
            choices: [
                EventChoice(id: "crew_count", label: "Count every one of them", detail: "Lose 14 health to the cold, gain 55 gold in grave-goods",
                            hpCost: 14, goldCost: 0, maxHPChange: 0, reward: .gold(55)),
                EventChoice(id: "crew_takeOne", label: "Take one aboard", detail: "They show you a trick — reforge one face",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .reforge),
                EventChoice(id: "crew_cut", label: "Cut the hands away", detail: "+18 gold, and the river remembers it",
                            hpCost: 0, goldCost: 0, maxHPChange: -6, reward: .gold(18)),
            ]
        ),
        RunEvent(
            id: "sunkenShrine", title: "The Sunken Shrine", symbol: "building.columns.fill",
            body: "A shrine roof breaks the surface, tilted, half-swallowed. Whatever was worshipped here has been under water for a very long time, and it still has something to give away.",
            choices: [
                EventChoice(id: "shrine_dive", label: "Dive for the offering box", detail: "70% chance of 65 gold, else take 18 damage",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .gamble(chance: 0.7, damage: 18)),
                EventChoice(id: "shrine_pry", label: "Pry the lintel carefully", detail: "Lose 6 health, sharpen one face's crit",
                            hpCost: 6, goldCost: 0, maxHPChange: 0, reward: .imbue),
                EventChoice(id: "shrine_leave", label: "Leave the dead their things", detail: "Row on",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .none),
            ]
        ),
        RunEvent(
            id: "embalmer", title: "The Embalmer's Skiff", symbol: "hammer.fill",
            body: "A narrow boat drifts alongside, stacked with jars and hooks. The woman aboard looks over your gear the way she looks at everything — as something that will one day be laid out flat.",
            choices: [
                EventChoice(id: "embalm_reforge", label: "Let her rework a face", detail: "-30 gold, reforge one face",
                            hpCost: 0, goldCost: 30, maxHPChange: 0, reward: .reforge),
                EventChoice(id: "embalm_item", label: "Buy from the jars", detail: "-35 gold, restore 40 health",
                            hpCost: 0, goldCost: 35, maxHPChange: 0, reward: .heal(40)),
                EventChoice(id: "embalm_sell", label: "Sell her the night's scrap", detail: "+28 gold",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .gold(28)),
            ]
        ),
        RunEvent(
            id: "starPool", title: "The Pool of Still Stars", symbol: "sparkles",
            body: "A backwater where the current stops entirely. Every star overhead is doubled on the surface, and the doubles are the ones that are moving.",
            choices: [
                EventChoice(id: "star_drink", label: "Drink from the pool", detail: "+16 max health, restored to it",
                            hpCost: 0, goldCost: 0, maxHPChange: 16, reward: .heal(16)),
                EventChoice(id: "star_bathe", label: "Bathe the wounded crew", detail: "Restore 38 health",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .heal(38)),
                EventChoice(id: "star_read", label: "Read the moving stars", detail: "Sharpen one face's crit",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .imbue),
            ]
        ),
        RunEvent(
            id: "gatekeeper", title: "The Bored Gatekeeper", symbol: "figure.fencing",
            body: "A figure with a knife and a jackal's patience stands on the bank. \"One pass. No dying. I have eleven more hours of this and I am extremely bored.\"",
            choices: [
                EventChoice(id: "gate_spar", label: "Take the wager", detail: "55% chance of 75 gold, else take 22 damage",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .gamble(chance: 0.55, damage: 22)),
                EventChoice(id: "gate_watch", label: "Watch how it holds the knife", detail: "Imbue one face with crit",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .imbue),
                EventChoice(id: "gate_bow", label: "Bow and row on", detail: "+18 gold for the courtesy",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .gold(18)),
            ]
        ),
        RunEvent(
            id: "standingIdol", title: "The Standing Idol", symbol: "hand.raised.fill",
            body: "A gold-leafed god stands hip-deep in the shallows, one palm open. The river has worn everything away except the face, which is still watching, and still willing to deal.",
            choices: [
                EventChoice(id: "idol_palm", label: "Press your palm to the gold", detail: "A god stirs and claims one of your dice",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .patronOffer),
                EventChoice(id: "idol_litany", label: "Recite the doubled litany", detail: "-25 gold, sharpen one face's crit",
                            hpCost: 0, goldCost: 25, maxHPChange: 0, reward: .imbue),
                EventChoice(id: "idol_row", label: "Keep your eyes down and row", detail: "Some deals are not worth the price",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .none),
            ]
        ),
        RunEvent(
            id: "apepSkin", title: "A Shed Skin", symbol: "lizard.fill",
            body: "Half a mile of translucent skin lies draped over a sandbar, still warm. Apep has grown since it left this behind. So can you.",
            choices: [
                EventChoice(id: "skin_wear", label: "Cut armour from it", detail: "-10 health working it, +14 max health",
                            hpCost: 10, goldCost: 0, maxHPChange: 14, reward: .none),
                EventChoice(id: "skin_burn", label: "Burn it and take the ash", detail: "Reforge one face with serpent ash",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .reforge),
                EventChoice(id: "skin_sell", label: "Bundle it for the Ferryman", detail: "+45 gold",
                            hpCost: 0, goldCost: 0, maxHPChange: 0, reward: .gold(45)),
            ]
        ),
    ]

    /// Three genuinely hidden, shuffled gifts. Every omen includes a chance
    /// at a path reroll, and no blind selection can demand gold or health.
    static func random(excluding usedIDs: Set<String>) -> RunEvent {
        let pool = all.filter { !usedIDs.contains($0.id) }
        let story = (pool.isEmpty ? all : pool).randomElement() ?? all[0]
        let gifts: [EventReward] = [.gold(35), .heal(30), .reforge, .imbue, .patronOffer]
        let rewards = ([EventReward.pathRerolls(1)] + Array(gifts.shuffled().prefix(2))).shuffled()
        let choices = rewards.enumerated().map { index, reward in
            EventChoice(id: "seal_\(index)", label: "Sealed Omen \(index + 1)",
                detail: "Choose to reveal your fate", hpCost: 0, goldCost: 0,
                maxHPChange: 0, reward: reward)
        }
        return RunEvent(id: story.id, title: story.title, symbol: story.symbol,
            body: story.body, choices: choices)
    }
}
