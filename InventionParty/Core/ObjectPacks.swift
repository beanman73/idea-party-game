//
//  ObjectPacks.swift
//  Invention Party
//
//  Ported from app/data/objectPacks.ts.
//

import Foundation

enum ObjectPacks {
    static let all: [ObjectPack] = [
        ObjectPack(id: "starter", name: "Household Items", isLocked: false, objects: [
            themed("h1", "Remote Control", "device", "grape", ["buttons"]),
            themed("h2", "Smart Speaker", "device", "grape", ["buttons"]),
            themed("h3", "Doorbell", "device", "tomato", ["buttons"]),
            themed("h4", "Flashlight", "tool", "mustard", ["sparkles"]),
            themed("h5", "Laundry Basket", "container", "teal", ["stripes"]),
            themed("h6", "Robot Vacuum", "vehicle", "sky", ["wheels"]),
            themed("h7", "Security Camera", "device", "leaf", ["buttons"]),
            themed("h8", "Hand Mirror", "circle", "sky", ["handle"]),
            themed("h9", "Thermostat", "circle", "silver", ["buttons"]),
            themed("h10", "Soap Dispenser", "bottle", "teal", ["label"]),
            themed("h11", "Spray Bottle", "bottle", "sky", ["handle"]),
            themed("h12", "Mop Bucket", "container", "leaf", ["handle"]),
            themed("h13", "Clock", "circle", "mustard", ["buttons"]),
            themed("h14", "Umbrella", "tent", "tomato", ["handle"]),
            themed("h15", "Key", "tool", "mustard", ["handle"]),
            themed("h16", "Light Bulb", "lantern", "mustard", ["sparkles"]),
            themed("h17", "Extension Cord", "tool", "teal", ["handle"]),
            themed("h18", "Tape Roll", "circle", "sky", ["label"]),
            themed("h19", "Battery", "box", "leaf", ["stripes"]),
            themed("h20", "Trash Can", "container", "silver", ["label"]),
            themed("h21", "Coat Hanger", "tool", "grape", ["handle"]),
            themed("h22", "Wi-Fi Router", "device", "sky", ["buttons"]),
            themed("h23", "Doorknob", "circle", "mustard", ["sparkles"]),
            themed("h24", "Storage Bin", "container", "sky", ["label"]),
            themed("h25", "Leak Sensor", "device", "teal", ["buttons"]),
            themed("h26", "Door Sensor", "device", "silver", ["buttons"]),
            themed("h27", "Motion Sensor", "device", "teal", ["buttons"]),
            themed("h28", "Wall Hook", "tool", "silver", ["handle"]),
            themed("h29", "Broom", "tool", "leaf", ["handle"]),
            themed("h30", "Smart Plug", "device", "mustard", ["buttons"]),
        ]),
        ObjectPack(id: "tech", name: "Tech & Gadgets", isLocked: false, objects: [
            themed("tg1", "Smart Button", "device", "tomato", ["buttons"]),
            themed("tg2", "Motion Sensor", "device", "teal", ["buttons"]),
            themed("tg3", "QR Code Sticker", "box", "sky", ["label"]),
            themed("tg4", "GPS Tag", "device", "leaf", ["label"]),
            themed("tg5", "Smart Camera", "device", "grape", ["buttons"]),
            themed("tg6", "Voice Remote", "device", "mustard", ["buttons"]),
            themed("tg7", "Wi-Fi Hotspot", "device", "sky", ["sparkles", "buttons"]),
            themed("tg8", "Robot Arm", "tool", "silver", ["handle"]),
            themed("tg9", "Hand Scanner", "tool", "teal", ["buttons", "sparkles"]),
            themed("tg10", "Alert Bell", "device", "tomato", ["buttons"]),
            themed("tg11", "Weather App", "device", "sky", ["buttons", "label"]),
            themed("tg12", "Voting App", "device", "grape", ["buttons", "label"]),
            themed("tg13", "Battery Pack", "box", "leaf", ["stripes"]),
            themed("tg14", "Tracker Tag", "device", "mustard", ["label"]),
            themed("tg15", "Touch Screen", "screen", "teal", ["buttons"]),
            themed("tg16", "Mini Drone", "vehicle", "silver", ["wheels"]),
            themed("tg17", "Smart Lock", "device", "tomato", ["buttons"]),
            themed("tg18", "Data Recorder", "device", "grape", ["label", "buttons"]),
            themed("tg19", "Alert Badge", "device", "mustard", ["label"]),
            themed("tg20", "AI Coach", "device", "leaf", ["buttons", "label"]),
            themed("tg21", "Timer Button", "device", "sky", ["buttons"]),
            themed("tg22", "Map Marker", "circle", "tomato", ["label"]),
            themed("tg23", "Bluetooth Tag", "device", "teal", ["label"]),
            themed("tg24", "Charging Dock", "device", "silver", ["buttons"]),
            themed("tg25", "Camera Lens", "circle", "sky", ["handle"]),
            themed("tg26", "Delivery Tracker", "device", "leaf", ["label", "buttons"]),
            themed("tg27", "Barcode Scanner", "device", "mustard", ["buttons", "label"]),
            themed("tg28", "Call Button", "device", "grape", ["buttons"]),
            themed("tg29", "Wi-Fi Booster", "device", "sky", ["sparkles", "buttons"]),
            themed("tg30", "Smart Watch", "device", "teal", ["buttons"]),
        ]),
        ObjectPack(id: "kitchen", name: "Kitchen", isLocked: false, objects: [
            themed("ki1", "Spatula", "tool", "silver", ["handle"]),
            themed("ki2", "Mixing Bowl", "circle", "teal", ["stripes"]),
            themed("ki3", "Rolling Pin", "tool", "mustard", ["handle"]),
            themed("ki4", "Measuring Cup", "bottle", "sky", ["label"]),
            themed("ki5", "Whisk", "wand", "silver", ["handle"]),
            themed("ki6", "Saucepan", "container", "tomato", ["handle", "steam"]),
            themed("ki7", "Cutting Board", "box", "mustard", ["stripes"]),
            themed("ki8", "Grocery Scanner", "device", "leaf", ["buttons", "label"]),
            themed("ki9", "Salt Shaker", "bottle", "silver", ["buttons"]),
            themed("ki10", "Oven Mitt", "box", "tomato", ["stripes"]),
            themed("ki11", "Lemon Squeezer", "tool", "mustard", ["handle"]),
            themed("ki12", "Fridge Camera", "device", "grape", ["buttons"]),
            themed("ki13", "Soup Ladle", "tool", "teal", ["handle"]),
            themed("ki14", "Dish Sponge", "box", "leaf", ["stripes"]),
            themed("ki15", "Recipe Scanner", "device", "sky", ["buttons", "label"]),
            themed("ki16", "Pepper Grinder", "bottle", "grape", ["stripes"]),
            themed("ki17", "Cookie Cutter", "star", "tomato", ["sparkles"]),
            themed("ki18", "Pasta Strainer", "container", "silver", ["buttons"]),
            themed("ki19", "Waffle Iron", "device", "mustard", ["stripes"]),
            themed("ki20", "Food Thermometer", "device", "tomato", ["buttons"]),
            themed("ki21", "Pizza Cutter", "wheel", "silver", ["handle"]),
            themed("ki22", "Tea Kettle", "lantern", "sky", ["steam"]),
            themed("ki23", "Kitchen Scale", "device", "mustard", ["buttons"]),
            themed("ki24", "Ice Cream Scoop", "tool", "teal", ["handle"]),
            themed("ki25", "Smart Pan", "device", "grape", ["buttons"]),
            themed("ki26", "Smart Faucet", "device", "leaf", ["buttons"]),
            themed("ki27", "Can Opener", "tool", "silver", ["handle"]),
            themed("ki28", "Kitchen Timer", "circle", "tomato", ["buttons"]),
            themed("ki29", "Food Sealer", "device", "mustard", ["buttons"]),
            themed("ki30", "Compost Bin", "container", "teal", ["label"]),
        ]),
        ObjectPack(id: "sports", name: "Sports Gear", isLocked: false, objects: [
            themed("sg1", "Whistle", "device", "mustard", ["handle"]),
            themed("sg2", "Goal Net", "box", "teal", ["stripes"]),
            themed("sg3", "Baseball Glove", "container", "mustard", ["stripes"]),
            themed("sg4", "Tennis Racket", "circle", "leaf", ["handle", "stripes"]),
            themed("sg5", "Scoreboard", "screen", "grape", ["buttons"]),
            themed("sg6", "Water Bottle", "bottle", "sky", ["label"]),
            themed("sg7", "Knee Pad", "box", "tomato", ["stripes"]),
            themed("sg8", "Soccer Cleat", "vehicle", "silver", ["stripes"]),
            themed("sg9", "Basketball Hoop", "circle", "tomato", ["stand"]),
            themed("sg10", "Hockey Puck", "circle", "ink", ["stripes"]),
            themed("sg11", "Bike Helmet", "circle", "teal", ["stripes"]),
            themed("sg12", "Referee Flag", "stand", "mustard", ["stripes"]),
            themed("sg13", "Baseball Tee", "stand", "leaf", ["legs"]),
            themed("sg14", "Replay Camera", "device", "tomato", ["buttons"]),
            themed("sg15", "Stopwatch", "device", "sky", ["buttons"]),
            themed("sg16", "Skate Ramp", "stand", "grape", ["stripes"]),
            themed("sg17", "Dumbbell", "tool", "silver", ["handle"]),
            themed("sg18", "Heart Monitor", "device", "leaf", ["buttons"]),
            themed("sg19", "Swim Goggles", "circle", "sky", ["handle"]),
            themed("sg20", "Fitness Tracker", "device", "mustard", ["buttons"]),
            themed("sg21", "Jump Rope", "tool", "tomato", ["handle"]),
            themed("sg22", "Practice Cones", "stand", "mustard", ["stripes"]),
            themed("sg23", "Golf Tee", "stand", "leaf", ["legs"]),
            themed("sg24", "Boxing Glove", "container", "tomato", ["stripes"]),
            themed("sg25", "Yoga Mat", "box", "grape", ["stripes"]),
            themed("sg26", "Speed Sensor", "device", "silver", ["buttons"]),
            themed("sg27", "Race Timer", "device", "sky", ["buttons"]),
            themed("sg28", "Training App", "device", "tomato", ["buttons", "label"]),
            themed("sg29", "Ping Pong Paddle", "circle", "teal", ["handle"]),
            themed("sg30", "Climbing Hold", "crystal", "leaf", ["sparkles"]),
        ]),
        ObjectPack(id: "school", name: "School Supplies", isLocked: false, objects: [
            themed("sc1", "Glue Stick", "bottle", "tomato", ["label"]),
            themed("sc2", "Ruler", "tool", "mustard", ["stripes"]),
            themed("sc3", "Locker Door", "door", "teal", ["buttons"]),
            themed("sc4", "Whiteboard Eraser", "box", "silver", ["stripes"]),
            themed("sc5", "Tablet Cart", "cart", "leaf", ["wheels"]),
            themed("sc6", "Attendance Scanner", "device", "sky", ["buttons"]),
            themed("sc7", "Pencil Case", "container", "grape", ["label"]),
            themed("sc8", "Binder Clip", "tool", "silver", ["handle"]),
            themed("sc9", "Spiral Notebook", "box", "tomato", ["stripes"]),
            themed("sc10", "Flashcard App", "device", "mustard", ["buttons"]),
            themed("sc11", "Crayon Box", "container", "sky", ["stripes"]),
            themed("sc12", "Projector Remote", "device", "teal", ["buttons"]),
            themed("sc13", "Due Date Stamp", "tool", "grape", ["label"]),
            themed("sc14", "Desk Bell", "circle", "mustard", ["handle"]),
            themed("sc15", "Protractor", "circle", "leaf", ["stripes"]),
            themed("sc16", "Science Goggles", "circle", "sky", ["handle"]),
            themed("sc17", "Chalk Tray", "container", "silver", ["label"]),
            themed("sc18", "Smart Pen", "tool", "tomato", ["buttons"]),
            themed("sc19", "Library Cart", "cart", "teal", ["wheels"]),
            themed("sc20", "Class Poll App", "device", "leaf", ["buttons"]),
            themed("sc21", "Marker Cap", "bottle", "tomato", ["label"]),
            themed("sc22", "Paper Tray", "container", "sky", ["label"]),
            themed("sc23", "Counting Cube", "box", "mustard", ["buttons"]),
            themed("sc24", "Smart Worksheet", "box", "grape", ["label"]),
            themed("sc25", "Classroom Timer", "circle", "teal", ["buttons"]),
            themed("sc26", "Staple Remover", "tool", "silver", ["handle"]),
            themed("sc27", "Reading Lamp", "lantern", "mustard", ["sparkles"]),
            themed("sc28", "Noise Meter", "device", "leaf", ["buttons"]),
            themed("sc29", "School Folder", "box", "tomato", ["label"]),
            themed("sc30", "Homework App", "device", "sky", ["buttons", "label"]),
        ]),
    ]

    private static func themed(_ id: String, _ name: String, _ base: String,
                               _ color: String, _ details: [String] = [],
                               accent: String? = nil) -> GameObject {
        GameObject(id: id,
                   name: name,
                   doodleRecipe: DoodleRecipe(baseShape: base,
                                              accentShape: accent,
                                              color: color,
                                              details: details))
    }

    static func byId(_ packId: String) -> ObjectPack? {
        all.first { $0.id == packId }
    }

    private static let everydayStarterPairKeys: Set<String> = [
        pairKey("Clock", "Phone"),
        pairKey("Camera", "Phone"),
        pairKey("Microphone", "Phone"),
        pairKey("Remote Control", "Phone"),
        pairKey("Compass", "Phone"),
        pairKey("Flashlight", "Phone"),
        pairKey("Book", "Phone"),
        pairKey("Shopping Cart", "Phone"),
        pairKey("Train Ticket", "Phone"),
        pairKey("Receipt", "Phone"),
        pairKey("Name Tag", "Phone"),
        pairKey("Clock", "Light Bulb"),
        pairKey("Clock", "Camera"),
        pairKey("Clock", "Music Box"),
        pairKey("Clock", "Desk Fan"),
        pairKey("Camera", "Telescope"),
        pairKey("Camera", "Glasses"),
        pairKey("Camera", "Magnifying Glass"),
        pairKey("Microphone", "Camera"),
        pairKey("Microphone", "Walkie Talkie"),
        pairKey("Microphone", "Music Box"),
        pairKey("Light Bulb", "Flashlight"),
        pairKey("Light Bulb", "Camping Lantern"),
        pairKey("Light Bulb", "Desk Fan"),
        pairKey("Key", "Mailbox"),
        pairKey("Key", "Hotel Keycard"),
        pairKey("Key", "Doorbell"),
        pairKey("Key", "Suitcase"),
        pairKey("Book", "Light Bulb"),
        pairKey("Book", "Chalkboard"),
        pairKey("Book", "Museum Map"),
        pairKey("Scissors", "Safety Pin"),
        pairKey("Scissors", "First Aid Kit"),
        pairKey("Magnet", "Compass"),
        pairKey("Magnet", "Mailbox"),
        pairKey("Ball", "Skateboard"),
        pairKey("Ball", "Toy Car"),
        pairKey("Balloon", "Bubble Wand"),
        pairKey("Guitar", "Microphone"),
        pairKey("Guitar", "Music Box"),
        pairKey("Dice", "Board Game"),
        pairKey("Telescope", "Star"),
        pairKey("Telescope", "Moon"),
        pairKey("Telescope", "Sun"),
        pairKey("Crown", "Gem"),
        pairKey("Glasses", "Sunglasses"),
        pairKey("Hat", "Sunglasses"),
        pairKey("Backpack", "Lunchbox"),
        pairKey("Backpack", "Sleeping Bag"),
        pairKey("Backpack", "Flashlight"),
        pairKey("Compass", "Museum Map"),
        pairKey("Trophy", "Medal"),
        pairKey("Flag", "Medal"),
        pairKey("Hammer", "Toolbox"),
        pairKey("Hammer", "Safety Pin"),
        pairKey("Lunchbox", "Thermos"),
        pairKey("Lunchbox", "Bento Tray"),
        pairKey("Garden Hose", "Watering Can"),
        pairKey("Garden Hose", "Rain Barrel"),
        pairKey("Garden Hose", "Garden Trowel"),
        pairKey("Elevator Button", "Doorbell"),
        pairKey("Mailbox", "Rubber Stamp"),
        pairKey("Shopping Cart", "Receipt"),
        pairKey("Shopping Cart", "Vending Machine"),
        pairKey("Suitcase", "Hotel Keycard"),
        pairKey("Paint Roller", "Chalkboard"),
        pairKey("Dog Leash", "Dog Bowl"),
        pairKey("Birdhouse", "Wind Chime"),
        pairKey("Traffic Cone", "Parking Meter"),
        pairKey("Wind Chime", "Doorbell"),
        pairKey("Pillow", "Sleeping Bag"),
        pairKey("Skateboard", "Scooter"),
        pairKey("Fishing Rod", "Picnic Cooler"),
        pairKey("Vending Machine", "Popcorn Bucket"),
        pairKey("Pizza Box", "Receipt"),
        pairKey("Beach Chair", "Sunglasses"),
        pairKey("Beach Chair", "Picnic Cooler"),
        pairKey("Toolbox", "Carabiner"),
        pairKey("Spray Bottle", "Soap Dispenser"),
        pairKey("Spray Bottle", "Mop Bucket"),
        pairKey("Remote Control", "Desk Fan"),
        pairKey("Remote Control", "Record Player"),
        pairKey("Watering Can", "Garden Trowel"),
        pairKey("Cookie Jar", "Cereal Box"),
        pairKey("Laundry Basket", "Mop Bucket"),
        pairKey("Walkie Talkie", "Camping Lantern"),
        pairKey("Soap Dispenser", "Shower Curtain"),
        pairKey("Fire Hydrant", "Garden Hose"),
        pairKey("Snow Globe", "Snowflake"),
        pairKey("Snow Globe", "Snow Shovel"),
        pairKey("Pencil Sharpener", "Chalkboard"),
        pairKey("Cereal Box", "Coffee Mug"),
        pairKey("Camping Lantern", "Sleeping Bag"),
        pairKey("Door Mat", "Doorbell"),
        pairKey("Kite String", "Hula Hoop"),
        pairKey("Coffee Mug", "Electric Kettle"),
        pairKey("Train Ticket", "Suitcase"),
        pairKey("Picnic Blanket", "Picnic Cooler"),
        pairKey("Magnifying Glass", "Museum Map"),
        pairKey("Shower Curtain", "Soap Dispenser"),
        pairKey("Toy Car", "Traffic Cone"),
        pairKey("Sticky Note", "Rubber Stamp"),
        pairKey("Marshmallow", "Camping Lantern"),
        pairKey("Frying Pan", "Bread Toaster"),
        pairKey("Museum Map", "Train Ticket"),
        pairKey("Hotel Keycard", "Door Mat"),
        pairKey("Ice Tray", "Electric Kettle"),
        pairKey("Record Player", "Music Box"),
        pairKey("Garden Gnome", "Garden Trowel"),
        pairKey("Taco Shell", "Frying Pan"),
        pairKey("Pool Noodle", "Beach Chair"),
        pairKey("Hand Mirror", "Sunglasses"),
        pairKey("First Aid Kit", "Safety Pin"),
        pairKey("Board Game", "Dice"),
        pairKey("Picnic Cooler", "Ice Tray"),
        pairKey("Carabiner", "Compass"),
        pairKey("Bread Toaster", "Electric Kettle"),
        pairKey("Window Blinds", "Desk Fan"),
        pairKey("Name Tag", "Rubber Stamp"),
    ]

    private static func pairKey(_ first: String, _ second: String) -> String {
        [first.normalizedObjectName, second.normalizedObjectName].sorted().joined(separator: "|")
    }

    private static func isEverydayStarterPair(_ objects: [GameObject]) -> Bool {
        guard objects.count == 2 else { return false }
        return everydayStarterPairKeys.contains(pairKey(objects[0].name, objects[1].name))
    }

    static var everydayStarterPairCount: Int {
        everydayStarterPairKeys.count
    }

    /// Random distinct cards from a pack, rerolling starter pairs that already
    /// feel like common everyday products and leave less room for invention.
    static func randomObjects(from pack: ObjectPack, count: Int = 2,
                              avoidingRecentIds recentIds: [String] = []) -> [GameObject] {
        let recent = Set(recentIds)

        if count == 2, pack.id == "mixed" {
            let freshObjects = pack.objects.filter { !recent.contains($0.id) }
            let source = freshObjects.count >= count ? freshObjects : pack.objects
            let grouped = Dictionary(grouping: source) { object in
                object.id.components(separatedBy: "::").first ?? "mixed"
            }
            let availableGroups = grouped.keys.shuffled()
            if availableGroups.count >= 2,
               let firstKey = availableGroups[safe: 0],
               let secondKey = availableGroups[safe: 1],
               let first = grouped[firstKey]?.randomElement(),
               let second = grouped[secondKey]?.randomElement() {
                return [first, second]
            }
            return Array(source.shuffled().prefix(count))
        }

        guard count == 2, pack.id == "starter" else {
            let freshObjects = pack.objects.filter { !recent.contains($0.id) }
            let source = freshObjects.count >= count ? freshObjects : pack.objects
            return Array(source.shuffled().prefix(count))
        }

        for _ in 0..<80 {
            let objects = Array(pack.objects.shuffled().prefix(count))
            let usesRecentObject = objects.contains { recent.contains($0.id) }
            if !usesRecentObject && !isEverydayStarterPair(objects) {
                return objects
            }
        }

        let freshObjects = pack.objects.filter { !recent.contains($0.id) }
        let source = freshObjects.count >= count ? freshObjects : pack.objects
        let validPairs = source.indices.flatMap { firstIndex in
            source.indices.dropFirst(firstIndex + 1).compactMap { secondIndex -> [GameObject]? in
                let pair = [source[firstIndex], source[secondIndex]]
                return isEverydayStarterPair(pair) ? nil : pair
            }
        }

        return validPairs.randomElement() ?? Array(pack.objects.shuffled().prefix(count))
    }
}

extension String {
    var normalizedObjectName: String {
        lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    func containsAny(_ needles: [String]) -> Bool {
        needles.contains { contains($0) }
    }
}
