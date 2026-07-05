//
//  InventionModifiers.swift
//  Invention Party
//
//  Optional round constraints that nudge object pairs into stranger invention
//  territory without contradicting the objects on the table.
//

import Foundation

enum InventionModifiers {
    static let all: [InventionModifier] = [
        InventionModifier(text: "for camping"),
        InventionModifier(text: "for a restaurant"),
        InventionModifier(text: "for a classroom"),
        InventionModifier(text: "for outer space"),
        InventionModifier(text: "for a road trip"),
        InventionModifier(text: "for a birthday party"),
        InventionModifier(text: "for a rainy day"),
        InventionModifier(text: "for a tiny apartment"),
        InventionModifier(text: "for a museum"),
        InventionModifier(text: "for a beach day"),
        InventionModifier(text: "for someone who is late"),
        InventionModifier(text: "for someone with full hands"),
        InventionModifier(text: "for a very forgetful person"),
        InventionModifier(text: "for a kid detective"),
        InventionModifier(text: "for a sleepy teacher"),
        InventionModifier(text: "must be wearable"),
        InventionModifier(text: "must fit in a backpack"),
        InventionModifier(text: "must be pocket-sized"),
        InventionModifier(text: "must be used by two people"),
        InventionModifier(text: "must work underwater"),
        InventionModifier(text: "must work in the dark"),
        InventionModifier(text: "must be silent",
                          blockedObjectNames: ["Bike Bell", "Doorbell", "Wind Chime", "Microphone", "Walkie Talkie", "Music Box", "Record Player"]),
        InventionModifier(text: "must not use electricity",
                          blockedObjectNames: ["Clock", "Light Bulb", "Phone", "Camera", "Telescope", "Microphone", "Flashlight", "Vending Machine", "Remote Control", "Walkie Talkie", "Camping Lantern", "Desk Fan", "Parking Meter", "Elevator Button", "Electric Kettle", "Record Player", "Bread Toaster"]),
        InventionModifier(text: "must not touch the ground",
                          blockedObjectNames: ["Traffic Cone", "Parking Meter", "Fire Hydrant", "Door Mat", "Garden Gnome"]),
        InventionModifier(text: "must survive being dropped",
                          blockedObjectNames: ["Gem", "Snow Globe", "Coffee Mug", "Hand Mirror", "Electric Kettle", "Record Player"]),
        InventionModifier(text: "must be safe for a baby",
                          blockedObjectNames: ["Scissors", "Bomb", "Hammer", "Safety Pin", "Fire", "Lightning", "Garden Trowel"]),
        InventionModifier(text: "must be edible",
                          blockedObjectNames: ["Bomb", "Robot", "Phone", "Camera", "Remote Control", "Parking Meter", "Fire Hydrant", "Toolbox", "Hammer", "Scissors", "Safety Pin"]),
        InventionModifier(text: "must float",
                          blockedObjectNames: ["Key", "Hammer", "Toolbox", "Parking Meter", "Fire Hydrant", "Frying Pan", "Electric Kettle", "Record Player"]),
        InventionModifier(text: "must be invisible",
                          blockedObjectNames: ["Rainbow", "Sun", "Fire", "Light Bulb", "Flashlight", "Camping Lantern"]),
    ]

    static func randomModifier(for objects: [GameObject]) -> InventionModifier? {
        let objectNames = Set(objects.map { $0.name.normalizedObjectName })
        let valid = all.filter { modifier in
            Set(modifier.blockedObjectNames.map(\.normalizedObjectName))
                .isDisjoint(with: objectNames)
        }
        return (valid.isEmpty ? all : valid).randomElement()
    }
}
