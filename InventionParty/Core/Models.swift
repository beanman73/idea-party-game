//
//  Models.swift
//  Invention Party
//
//  Data models ported from app/state/gameStore.tsx. Photo URIs become
//  in-memory image Data, and drawings are stored as encoded strokes.
//

import SwiftUI

// MARK: - Core game objects

struct GameObject: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var emoji: String? = nil
    var photoData: Data? = nil
    var doodleRecipe: DoodleRecipe? = nil
    var prefersTextOnly: Bool = false
}

struct DoodleRecipe: Codable, Hashable {
    var baseShape: String
    var accentShape: String? = nil
    var color: String
    var details: [String] = []

    enum CodingKeys: String, CodingKey {
        case baseShape, base_shape, base, shape, s
        case accentShape, accent_shape, accent
        case color, c, details, d
    }

    init(baseShape: String, accentShape: String? = nil, color: String, details: [String] = []) {
        self.baseShape = baseShape
        self.accentShape = accentShape
        self.color = color
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseShape = try container.decodeIfPresent(String.self, forKey: .baseShape)
            ?? container.decodeIfPresent(String.self, forKey: .base_shape)
            ?? container.decodeIfPresent(String.self, forKey: .base)
            ?? container.decodeIfPresent(String.self, forKey: .shape)
            ?? container.decodeIfPresent(String.self, forKey: .s)
            ?? "box"
        accentShape = try container.decodeIfPresent(String.self, forKey: .accentShape)
            ?? container.decodeIfPresent(String.self, forKey: .accent_shape)
            ?? container.decodeIfPresent(String.self, forKey: .accent)
        color = try container.decodeIfPresent(String.self, forKey: .color)
            ?? container.decodeIfPresent(String.self, forKey: .c)
            ?? "teal"
        details = try container.decodeIfPresent([String].self, forKey: .details)
            ?? container.decodeIfPresent([String].self, forKey: .d)
            ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseShape, forKey: .baseShape)
        try container.encodeIfPresent(accentShape, forKey: .accentShape)
        try container.encode(color, forKey: .color)
        try container.encode(details, forKey: .details)
    }
}

struct ObjectPack: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var price: String? = nil
    var isLocked: Bool
    var objects: [GameObject]
}

struct InventionModifier: Identifiable, Hashable {
    var id: String { text }
    let text: String
    var blockedObjectNames: Set<String> = []
}

struct Player: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var score: Int = 0
}

struct Submission: Identifiable, Hashable {
    var id: String { playerId }
    let playerId: String
    let playerName: String
    /// The typed idea, if the player wrote one (Writing input).
    var text: String? = nil
    /// JSON-encoded `DrawingData` from the canvas, if the player drew (Drawing input).
    var drawing: String? = nil

    /// True when the player provided neither a drawing nor any text.
    var isEmpty: Bool {
        (text?.isEmpty ?? true) && (drawing?.isEmpty ?? true)
    }
}

struct RoundResult: Hashable {
    let roundNumber: Int
    let first: String          // player id
    var second: String? = nil
    var third: String? = nil
}

// MARK: - Drawing payload

/// A single freehand stroke. CGPoint is Codable via CoreGraphics.
struct Stroke: Codable, Hashable {
    var points: [CGPoint]
}

/// What gets serialized into a `Submission.drawing` string.
struct DrawingData: Codable, Hashable {
    var strokes: [Stroke]
    var width: CGFloat
    var height: CGFloat

    func encodedString() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let str = String(data: data, encoding: .utf8) else { return "" }
        return str
    }

    static func decode(from string: String) -> DrawingData? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DrawingData.self, from: data)
    }
}

// MARK: - Game configuration enums

enum GameMode: String, Codable {
    case classic
    case speed
    case crowd
}

struct SavedDeck: Identifiable, Hashable, Codable {
    let id: String
    var title: String
    var prompt: String
    var objects: [GameObject]
    var createdAt: Date

    var packId: String { "saved-\(id)" }

    var objectPack: ObjectPack {
        ObjectPack(id: packId, name: title, isLocked: false, objects: objects)
    }
}
