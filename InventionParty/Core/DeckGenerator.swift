//
//  DeckGenerator.swift
//  Invention Party
//
//  AI deck generator. Production calls the app's own AI service so users never
//  need to provide an API key. Debug builds can still use a local fallback.
//

import Foundation
import UIKit

enum DeckGenerator {
    static let cardCount = 30
    private static let model = "gpt-5.5"
    private static let imageModel = "gpt-image-1"
    private static let bundledBackendURLString = "https://idea-party-game-u81z.vercel.app/api/generate-deck"
    private static let backendURLInfoKey = "AI_DECK_BACKEND_URL"

    /// Main entry point used by AIDeckView.
    static func generate(prompt: String, generateImages: Bool = false,
                         progress: ((String) -> Void)? = nil) async throws -> [GameObject] {
        if let backendURL {
            do {
                return try await backendDeck(prompt: prompt,
                                             endpoint: backendURL,
                                             generateImages: generateImages,
                                             progress: progress)
            } catch {
                throw DeckGeneratorError.remoteFailed(error.localizedDescription)
            }
        }

        #if DEBUG
        let key = OpenAIAPIKeyStore.load().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return localDeck(prompt: prompt, includeFallbackDoodles: generateImages) }

        do {
            return try await remoteDeck(prompt: prompt, apiKey: key,
                                        generateImages: generateImages,
                                        progress: progress)
        } catch {
            throw DeckGeneratorError.remoteFailed(error.localizedDescription)
        }
        #else
        throw DeckGeneratorError.backendUnavailable
        #endif
    }

    private static var backendURL: URL? {
        let infoValue = Bundle.main.object(forInfoDictionaryKey: backendURLInfoKey) as? String
        return [infoValue, bundledBackendURLString]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.contains("YOUR_BACKEND") }
            .flatMap(URL.init(string:))
    }

    // MARK: - App Backend

    private static func backendDeck(prompt: String,
                                    endpoint: URL,
                                    generateImages: Bool,
                                    progress: ((String) -> Void)?) async throws -> [GameObject] {
        progress?("Generating card names...")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(BackendDeckRequest(prompt: prompt,
                                                                       generateImages: generateImages,
                                                                       cardCount: cardCount))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DeckGeneratorError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = DeckServiceErrorMessage.decode(from: data)
            throw DeckGeneratorError.httpStatus(http.statusCode, message)
        }

        let decoded = try decodeDeckResponse(from: data)
        let cards = try cleanGeneratedCards(decoded.cards)
        let objects = cards.enumerated().map { index, card in
            GameObject(id: "ai-\(UUID().uuidString)-\(index)",
                       name: card.name,
                       doodleRecipe: generateImages ? card.doodle : nil,
                       prefersTextOnly: !generateImages)
        }

        progress?("Deck ready")
        return objects
    }

    // MARK: - OpenAI API

    private static func remoteDeck(prompt: String, apiKey: String,
                                   generateImages: Bool,
                                   progress: ((String) -> Void)?) async throws -> [GameObject] {
        progress?("Generating card names...")
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45

        request.httpBody = try JSONEncoder().encode(OpenAIRequest(
            model: model,
            input: [
                .init(role: "developer", content: developerInstructions),
                .init(role: "user", content: userPrompt(prompt)),
            ],
            maxOutputTokens: 2400
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DeckGeneratorError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = OpenAIErrorMessage.decode(from: data)
            throw DeckGeneratorError.httpStatus(http.statusCode, message)
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let text = openAIResponse.outputText.isEmpty
            ? extractLikelyOutputText(fromResponseData: data)
            : openAIResponse.outputText
        let cards = try parseDeckCards(from: text)
        var objects = cards.enumerated().map { index, card in
            GameObject(id: "ai-\(UUID().uuidString)-\(index)",
                       name: card.name,
                       doodleRecipe: generateImages ? card.doodle : nil,
                       prefersTextOnly: !generateImages)
        }
 
        if generateImages {
            progress?("Drawing card art...")
            for index in objects.indices {
                progress?("Drawing \(index + 1) of \(objects.count)...")
                if let imageData = try? await generateDoodleImage(for: objects[index], theme: prompt, apiKey: apiKey) {
                    objects[index].photoData = imageData
                }
            }
        }

        progress?("Deck ready")
        return objects
    }

    private static func generateDoodleImage(for object: GameObject, theme: String,
                                            apiKey: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(ImageGenerationRequest(
            model: imageModel,
            prompt: imagePrompt(for: object, theme: theme),
            n: 1,
            size: "1024x1024",
            background: "transparent",
            quality: "low"
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DeckGeneratorError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = OpenAIErrorMessage.decode(from: data)
            throw DeckGeneratorError.httpStatus(http.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        guard let base64 = decoded.data.first?.b64JSON,
              let pngData = Data(base64Encoded: base64) else {
            throw DeckGeneratorError.imageMissing
        }
        return downscaledPNGData(from: pngData) ?? pngData
    }

    private static func imagePrompt(for object: GameObject, theme: String) -> String {
        """
        Draw a single transparent-background doodle icon for an invention party object card.
        Object: \(object.name)
        Deck theme: \(theme)
        Style: playful hand-drawn marker doodle, thick charcoal outline, simple shape language, lightly colored, kid-friendly, centered, isolated object only.
        Requirements: transparent background, no text, no letters, no border, no card frame, no shadows outside the object, no realistic photo style, no people.
        Make the object recognizable at small size.
        """
    }

    private static func downscaledPNGData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 320
        let scale = min(maxSide / max(image.size.width, image.size.height), 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return scaled.pngData()
    }

    private static var developerInstructions: String {
        """
        You generate object card decks for a party game where players combine two random objects into an invention.
        Return JSON only, with this exact compact shape:
        {"cards":[{"n":"Airlock Door","s":"door","c":"sky","d":["label","buttons"]}]}

        Work process before returning JSON:
        1. Internally brainstorm 100 candidate cards for the user's theme.
        2. Score every candidate from 1 to 5 on:
           - Invention Potential: does it suggest actions, mechanisms, problems, or features?
           - Combinability: can it combine well with many unrelated cards?
           - Clarity: will a normal player instantly picture what it is?
           - Tech Leverage: can it plausibly connect to apps, sensors, AI, cameras, maps, alerts, internet, automation, data, sharing, personalization, payments, QR codes, voice controls, timers, location, subscriptions, or smart devices?
        3. Select the best \(cardCount) candidates with the highest overall usefulness.
        4. Return only those final \(cardCount) cards. Do not return scores, notes, or the rejected candidates.

        A great card is concrete, visual, and full of affordances: it can hold, move, protect, sense, signal, scan, open, close, connect, sort, heat, cool, launch, track, clean, transform, automate, notify, record, recommend, map, or personalize.
        Include a healthy mix of physical objects and technology-flavored objects. Tech cards should still be concrete and playable, such as Motion Sensor, Smart Button, QR Sticker, Weather App, AI Coach, Camera Trap, Voice Remote, Map Pin, Wi-Fi Beacon, Notification Bell, Recipe Scanner, or Voting App.
        Make cards specific but not too specific: objects, props, tools, containers, toys, simple devices, wearable items, app-like tools, sensors, interfaces, and smart accessories.
        Avoid proper nouns, brands, people, vague sci-fi words, pure abstractions, animals as standalone cards, and objects that are mostly the same as each other.
        Avoid cards that sound cool but are unclear or not really objects, like Orbit Ring, Nebula Bottle, Cosmic Vibe, Dream Energy, or Future Zone.
        Use 1 to 3 words per card, Title Case, no emoji, no numbering.
        Prefer cards that combine well with many other cards and invite funny inventions.
        Doodle tags:
        - n is the card name.
        - s is one shape from: circle, box, bottle, tool, vehicle, plant, flower, food, device, house, door, tent, crystal, wheel, lantern, star.
        - c is one color from: tomato, mustard, teal, grape, leaf, sky.
        - a is optional accent shape from the same shape list, or omit it.
        - d is 0 to 4 details from: handle, wheels, stripes, buttons, steam, legs, sparkles, label, portal.
        Choose doodle tags by visual resemblance, not by category. For example: Motion Sensor uses device/buttons; QR Sticker uses box/label; AI Coach uses device/buttons; Airlock Door uses door; Rover Wheel uses wheel; Plasma Lantern uses lantern; Alien Flower uses flower.
        """
    }

    private static func userPrompt(_ prompt: String) -> String {
        "Theme: \(prompt)"
    }

    private static func extractLikelyOutputText(fromResponseData data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return "" }
        var candidates: [String] = []

        func walk(_ value: Any, key: String? = nil) {
            if let dict = value as? [String: Any] {
                for (childKey, childValue) in dict {
                    walk(childValue, key: childKey)
                }
            } else if let array = value as? [Any] {
                array.forEach { walk($0, key: key) }
            } else if let string = value as? String {
                let normalizedKey = key?.normalizedObjectName ?? ""
                if normalizedKey == "text" || normalizedKey == "output_text" {
                    candidates.append(string)
                }
            }
        }

        walk(json)
        return candidates
            .sorted { $0.count > $1.count }
            .first ?? ""
    }

    private static func parseDeckCards(from text: String) throws -> [GeneratedDeckCard] {
        let jsonText = extractJSON(from: text)
        guard let data = jsonText.data(using: .utf8) else {
            throw DeckGeneratorError.invalidJSON
        }

        let decoded = try decodeDeckResponse(from: data)
        return try cleanGeneratedCards(decoded.cards)
    }

    private static func cleanGeneratedCards(_ cards: [GeneratedDeckCard]) throws -> [GeneratedDeckCard] {
        let cleaned = cards
            .compactMap { card -> GeneratedDeckCard? in
                let name = cleanCardName(card.name)
                guard !name.isEmpty else { return nil }
                return GeneratedDeckCard(name: name, doodle: cleanDoodleRecipe(card.doodle, fallbackName: name))
            }
            .reduce(into: [GeneratedDeckCard]()) { result, card in
                if !result.contains(where: { $0.name.caseInsensitiveCompare(card.name) == .orderedSame }) {
                    result.append(card)
                }
            }

        guard cleaned.count >= 2 else {
            throw DeckGeneratorError.tooFewCards
        }
        return Array(cleaned.prefix(cardCount))
    }

    private static func decodeDeckResponse(from data: Data) throws -> DeckResponse {
        let decoder = JSONDecoder()
        if let response = try? decoder.decode(DeckResponse.self, from: data) {
            return response
        }
        if let objectCards = try? decoder.decode([GeneratedDeckCard].self, from: data) {
            return DeckResponse(cards: objectCards)
        }
        if let names = try? decoder.decode([String].self, from: data) {
            return DeckResponse(cards: names.map { GeneratedDeckCard(name: $0, doodle: nil) })
        }
        throw DeckGeneratorError.invalidJSON
    }

    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.first == "{" || trimmed.first == "[" {
            return trimmed
        }
        if let object = balancedJSONSubstring(in: trimmed, opening: "{", closing: "}") {
            return object
        }
        if let array = balancedJSONSubstring(in: trimmed, opening: "[", closing: "]") {
            return array
        }
        return trimmed
    }

    private static func balancedJSONSubstring(in text: String, opening: Character,
                                              closing: Character) -> String? {
        guard let start = text.firstIndex(of: opening) else { return nil }
        var depth = 0
        var inString = false
        var isEscaped = false

        var index = start
        while index < text.endIndex {
            let char = text[index]
            if inString {
                if isEscaped {
                    isEscaped = false
                } else if char == "\\" {
                    isEscaped = true
                } else if char == "\"" {
                    inString = false
                }
            } else if char == "\"" {
                inString = true
            } else if char == opening {
                depth += 1
            } else if char == closing {
                depth -= 1
                if depth == 0 {
                    return String(text[start...index])
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func cleanCardName(_ name: String) -> String {
        name
            .replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func cleanDoodleRecipe(_ recipe: DoodleRecipe?, fallbackName: String) -> DoodleRecipe {
        guard let recipe else { return guessedDoodleRecipe(for: fallbackName) }

        let allowedShapes = Set(["circle", "box", "bottle", "tool", "vehicle", "plant", "flower", "food", "device", "house", "door", "tent", "crystal", "wheel", "lantern", "star"])
        let allowedColors = Set(["tomato", "mustard", "teal", "grape", "leaf", "sky"])
        let allowedDetails = Set(["handle", "wheels", "stripes", "buttons", "steam", "legs", "sparkles", "label", "portal"])

        let fallback = guessedDoodleRecipe(for: fallbackName)
        let base = recipe.baseShape.normalizedObjectName
        let accent = recipe.accentShape?.normalizedObjectName
        let color = recipe.color.normalizedObjectName
        let details = recipe.details
            .map(\.normalizedObjectName)
            .filter { allowedDetails.contains($0) }

        return DoodleRecipe(
            baseShape: allowedShapes.contains(base) ? base : fallback.baseShape,
            accentShape: (accent == nil || accent == "none" || !allowedShapes.contains(accent!)) ? nil : accent,
            color: allowedColors.contains(color) ? color : fallback.color,
            details: details.isEmpty ? fallback.details : Array(details.prefix(4))
        )
    }

    private static func guessedDoodleRecipe(for name: String) -> DoodleRecipe {
        let key = name.normalizedObjectName
        let base = guessedBaseShape(for: key)
        let color = guessedColor(for: key)
        let accent = guessedAccentShape(for: key, base: base)
        let details = guessedDetails(for: key, base: base)
        return DoodleRecipe(baseShape: base, accentShape: accent, color: color, details: details)
    }

    private static func guessedBaseShape(for name: String) -> String {
        let key = name.normalizedObjectName
        if key.containsAny(["door", "airlock", "gate", "hatch"]) { return "door" }
        if key.containsAny(["tent", "canopy"]) { return "tent" }
        if key.containsAny(["crystal", "gem", "quartz", "shard"]) { return "crystal" }
        if key.containsAny(["wheel", "rotor", "gear"]) { return "wheel" }
        if key.containsAny(["lantern", "lamp", "beacon"]) { return "lantern" }
        if key.containsAny(["flower", "blossom", "petal"]) { return "flower" }
        if key.containsAny(["mug", "cup", "bottle", "jar", "can", "vase", "thermos", "flask", "kettle", "bucket", "barrel"]) { return "bottle" }
        if key.containsAny(["car", "cart", "scooter", "bike", "wagon", "bus", "train", "rocket", "boat", "sled", "skateboard"]) { return "vehicle" }
        if key.containsAny(["wand", "hammer", "tool", "shovel", "trowel", "brush", "roller", "rod", "key", "scissors", "pencil", "stamp", "scoop"]) { return "tool" }
        if key.containsAny(["snack", "pizza", "taco", "bread", "toast", "cookie", "cereal", "marshmallow", "lunch", "bento", "sandwich", "soup", "cake", "candy"]) { return "food" }
        if key.containsAny(["phone", "remote", "machine", "screen", "button", "camera", "clock", "lamp", "lantern", "fan", "radio", "robot", "player", "meter", "speaker", "mic", "app", "ai", "sensor", "scanner", "scan", "qr", "wi-fi", "wifi", "beacon", "tracker", "tracking", "tag", "chip", "portal", "alert", "notification", "timer", "map pin", "voice", "data", "smart"]) { return "device" }
        if key.containsAny(["plant", "garden", "tree", "leaf", "seed", "birdhouse", "gnome"]) { return "plant" }
        if key.containsAny(["house", "booth", "stand", "hut", "mailbox", "room", "locker", "closet"]) { return "house" }
        if key.containsAny(["star", "spark", "moon", "sun", "cloud", "rainbow", "ghost", "magic", "dream", "portal"]) { return "star" }
        if key.containsAny(["ball", "bubble", "globe", "hoop", "coin", "button"]) { return "circle" }
        return "box"
    }

    private static func guessedColor(for name: String) -> String {
        let key = name.normalizedObjectName
        if key.containsAny(["fire", "pizza", "taco", "button", "alarm", "rocket"]) { return "tomato" }
        if key.containsAny(["sun", "star", "lamp", "lantern", "light", "crown", "gold", "bread", "toast", "crystal", "glow", "plasma"]) { return "mustard" }
        if key.containsAny(["plant", "garden", "leaf", "grass", "forest", "tree"]) { return "leaf" }
        if key.containsAny(["water", "rain", "cloud", "ice", "snow", "beach", "pool", "sky"]) { return "sky" }
        if key.containsAny(["magic", "dream", "mystery", "portal", "ghost", "moon", "shadow"]) { return "grape" }

        let palette = ["tomato", "mustard", "teal", "grape", "leaf", "sky"]
        return palette[Int(key.hashValue.magnitude % UInt(palette.count))]
    }

    private static func guessedAccentShape(for name: String, base: String) -> String? {
        let key = name.normalizedObjectName
        if key.containsAny(["magic", "dream", "star", "spark", "glow", "wish", "plasma"]) { return "star" }
        if key.containsAny(["garden", "leaf", "plant"]) && base != "plant" { return "plant" }
        if key.containsAny(["flower", "blossom"]) && base != "flower" { return "flower" }
        if key.containsAny(["snack", "lunch", "cookie", "candy"]) && base != "food" { return "food" }
        if key.containsAny(["machine", "robot", "remote", "button", "app", "ai", "sensor", "scanner", "qr", "wi-fi", "wifi", "beacon", "tracker", "smart"]) && base != "device" { return "device" }
        if key.containsAny(["travel", "road", "ticket", "map"]) && base != "vehicle" { return "vehicle" }
        return nil
    }

    private static func guessedDetails(for name: String, base: String) -> [String] {
        let key = name.normalizedObjectName
        var details: [String] = []

        if base == "vehicle" || key.containsAny(["cart", "scooter", "bike", "wagon"]) { details.append("wheels") }
        if base == "bottle" || key.containsAny(["bag", "bucket", "basket", "box", "case", "mug", "cup"]) { details.append("handle") }
        if base == "device" || base == "door" || key.containsAny(["button", "remote", "machine", "robot", "panel", "airlock", "app", "sensor", "scanner", "tracker", "beacon", "router", "wi-fi", "wifi"]) { details.append("buttons") }
        if key.containsAny(["stripe", "rainbow", "beach", "ticket", "blanket", "flag"]) { details.append("stripes") }
        if key.containsAny(["hot", "coffee", "tea", "soup", "kettle", "toast"]) { details.append("steam") }
        if key.containsAny(["chair", "table", "stand", "stool"]) { details.append("legs") }
        if key.containsAny(["magic", "dream", "spark", "glow", "star", "party", "plasma", "crystal"]) { details.append("sparkles") }
        if key.containsAny(["label", "tag", "ticket", "map", "note", "card", "stamp", "qr", "data"]) { details.append("label") }
        if key.containsAny(["portal", "airlock", "vacuum"]) { details.append("portal") }

        if details.isEmpty {
            switch base {
            case "box", "house", "door": details = ["label"]
            case "device": details = ["buttons"]
            case "bottle": details = ["handle"]
            case "star", "crystal", "lantern": details = ["sparkles"]
            case "tent": details = ["legs"]
            default: details = []
            }
        }

        return Array(details.prefix(4))
    }

    // MARK: - Local fallback

    private static let generalFallbackCards = [
        "Smart Button", "Motion Sensor", "Map Pin", "Voice Remote", "Camera Trap",
        "QR Sticker", "AI Coach", "Weather App", "Timer Badge", "Wi-Fi Beacon",
        "Alert Bell", "Recipe Scanner", "Voting App", "Location Tag", "Robot Arm",
        "Pocket Printer", "Data Jar", "Signal Flag", "Battery Pack", "Scan Wand",
        "Tracking Tile", "Auto Scoop", "Mood Lamp", "Reminder Clock", "Share Screen",
        "Smart Goggles", "Order Button", "Magic Lock", "Sensor Glove", "Portal Pad",
    ]

    private static func localDeck(prompt: String, includeFallbackDoodles: Bool = true) -> [GameObject] {
        let names = localFallbackCardNames(for: prompt)

        return names.enumerated().map { index, name in
            return GameObject(id: "ai-local-\(Date().timeIntervalSince1970)-\(index)",
                              name: name,
                              doodleRecipe: includeFallbackDoodles ? cleanDoodleRecipe(nil, fallbackName: name) : nil,
                              prefersTextOnly: !includeFallbackDoodles)
        }
    }

    private static func localFallbackCardNames(for prompt: String) -> [String] {
        let key = prompt.normalizedObjectName
        let tokens = meaningfulPromptTokens(from: prompt)
        var candidates: [String] = []

        for topic in localFallbackTopics where topic.matches(key) {
            candidates.append(contentsOf: topic.names)
            candidates.append(contentsOf: objectNames(fromPackIDs: topic.packIDs))
        }

        if !tokens.isEmpty {
            let matchingBuiltIns = ObjectPacks.all
                .flatMap(\.objects)
                .map(\.name)
                .filter { name in
                    let normalizedName = name.normalizedObjectName
                    return tokens.contains { token in
                        normalizedName.contains(token) || token.contains(normalizedName)
                    }
                }
            candidates.append(contentsOf: matchingBuiltIns)
        }

        candidates.append(contentsOf: generalFallbackCards)
        candidates.append(contentsOf: ObjectPacks.all.flatMap { $0.objects.map(\.name) })

        return uniqueCardNames(candidates, limit: cardCount)
    }

    private static func objectNames(fromPackIDs packIDs: [String]) -> [String] {
        packIDs.flatMap { packID in
            ObjectPacks.byId(packID)?.objects.map(\.name) ?? []
        }
    }

    private static func meaningfulPromptTokens(from prompt: String) -> [String] {
        let stopWords: Set<String> = [
            "about", "after", "and", "around", "card", "cards", "deck", "for",
            "from", "fun", "funny", "make", "object", "objects", "party", "the",
            "theme", "thing", "things", "with",
        ]

        return prompt
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }

    private static func uniqueCardNames(_ names: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for rawName in names {
            let name = cleanCardName(rawName)
            let key = name.normalizedObjectName
            guard !name.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(name)
            if result.count == limit { break }
        }

        return result
    }

    private static let localFallbackTopics: [LocalFallbackTopic] = [
        LocalFallbackTopic(
            triggers: ["smart home", "house", "home", "household", "chores", "cleaning", "apartment"],
            packIDs: ["starter", "tech"],
            names: [
                "Video Doorbell", "Window Sensor", "Energy Meter", "Water Valve", "Garage Sensor",
                "Light Switch", "Keypad Lock", "Air Filter", "Pet Feeder", "Package Locker",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["tech", "gadget", "gadgets", "robot", "robots", "sensor", "sensors", "app", "apps", "ai"],
            packIDs: ["tech"],
            names: [
                "Smart Glasses", "Notification Bell", "Sensor Glove", "Data Badge", "Control Pad",
                "Signal Beacon", "Pocket Printer", "Camera Trap", "Mood Lamp", "Scan Wand",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["kitchen", "cook", "cooking", "food", "snack", "restaurant", "baking", "recipe"],
            packIDs: ["kitchen"],
            names: [
                "Lunchbox", "Cookie Jar", "Cereal Box", "Coffee Mug", "Bread Toaster",
                "Bento Tray", "Snack Tray", "Taco Shell", "Pizza Box", "Popcorn Bucket",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["school", "class", "classroom", "teacher", "homework", "library", "student", "students"],
            packIDs: ["school"],
            names: [
                "Book Light", "Name Tag", "Rubber Stamp", "Chalkboard", "Pencil Sharpener",
                "Backpack", "Lunchbox", "Desk Fan", "Hall Pass", "Reading Tracker",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["sport", "sports", "soccer", "basketball", "baseball", "tennis", "fitness", "workout", "game"],
            packIDs: ["sports"],
            names: [
                "Medal", "Trophy", "Flag", "Megaphone", "Water Station",
                "Team Badge", "Practice Timer", "Gear Bag", "Helmet Camera", "Cooling Towel",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["beach", "vacation", "summer", "pool", "ocean", "travel", "trip", "hotel"],
            packIDs: [],
            names: [
                "Beach Chair", "Sunscreen Bottle", "Picnic Cooler", "Pool Noodle", "Sand Bucket",
                "Beach Umbrella", "Flip-Flop", "Towel Clip", "Shell Jar", "Snack Cooler",
                "Water Bottle", "Swim Goggles", "Weather App", "Map Marker", "Bluetooth Speaker",
                "Ticket Wristband", "Hotel Keycard", "Luggage Tag", "Camera Lens", "Motion Sensor",
                "Smart Watch", "Call Button", "Charging Dock", "Portable Fan", "Ice Tray",
                "Snack Tray", "Shade Tent", "Toy Shovel", "Toy Boat", "Reminder Clock",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["camp", "camping", "hike", "hiking", "outdoor", "outdoors", "forest", "trail"],
            packIDs: [],
            names: [
                "Camping Lantern", "Sleeping Bag", "Compass", "Trail Map", "Rain Jacket",
                "Picnic Cooler", "Fishing Rod", "Camp Stove", "Bug Spray", "Water Bottle",
                "Flashlight", "Walkie Talkie", "Carabiner", "Solar Charger", "Signal Flag",
                "Weather App", "Motion Sensor", "Battery Pack", "Map Marker", "Fire Starter",
                "Tent Pole", "Snack Pouch", "Pocket Knife", "First Aid Kit", "Rope Coil",
                "Binoculars", "Bear Bell", "Trail Camera", "Smart Watch", "Reminder Clock",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["space", "alien", "moon", "planet", "rocket", "mars", "astronaut", "galaxy"],
            packIDs: [],
            names: [
                "Space Helmet", "Rocket Scooter", "Satellite Dish", "Moon Boots", "Airlock Door",
                "Rover Wheel", "Star Map", "Signal Beacon", "Solar Panel", "Mission Timer",
                "Tool Kit", "Sample Jar", "Gravity Boots", "Glow Lantern", "Meteor Shield",
                "Oxygen Tank", "Control Button", "Map Marker", "Camera Lens", "Robot Arm",
                "Data Recorder", "Battery Pack", "Voice Remote", "Alert Bell", "Portal Pad",
                "Mini Drone", "Hand Scanner", "Weather App", "Tracker Tag", "Smart Goggles",
            ]
        ),
        LocalFallbackTopic(
            triggers: ["birthday", "music", "dance", "festival", "celebration", "celebrate"],
            packIDs: [],
            names: [
                "Bluetooth Speaker", "Snack Bowl", "Party Hat", "Confetti Cannon", "Photo Booth",
                "Ticket Wristband", "Timer Button", "Voting App", "Call Button", "Mini Drone",
                "Light Bulb", "Mood Lamp", "Microphone", "Gift Box", "Cake Stand",
                "Balloon Pump", "Name Tag", "QR Sticker", "Share Screen", "Reminder Clock",
                "Camera Lens", "Battery Pack", "Signal Flag", "Alert Bell", "Pocket Printer",
                "Smart Button", "Weather App", "Map Marker", "Storage Bin", "Tape Roll",
            ]
        ),
    ]
}

private struct LocalFallbackTopic {
    let triggers: [String]
    let packIDs: [String]
    let names: [String]

    func matches(_ prompt: String) -> Bool {
        let promptWords = Set(prompt.split(separator: " ").map(String.init))
        return triggers.contains { trigger in
            trigger.count <= 3 && !trigger.contains(" ")
                ? promptWords.contains(trigger)
                : prompt.contains(trigger)
        }
    }
}

private struct OpenAIRequest: Encodable {
    let model: String
    let input: [InputMessage]
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, input
        case maxOutputTokens = "max_output_tokens"
    }

    struct InputMessage: Encodable {
        let role: String
        let content: String
    }
}

private struct BackendDeckRequest: Encodable {
    let prompt: String
    let generateImages: Bool
    let cardCount: Int
}

private struct ImageGenerationRequest: Encodable {
    let model: String
    let prompt: String
    let n: Int
    let size: String
    let background: String
    let quality: String
}

private struct ImageGenerationResponse: Decodable {
    let data: [ImageData]

    struct ImageData: Decodable {
        let b64JSON: String?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
        }
    }
}

private struct OpenAIResponse: Decodable {
    let output: [OutputItem]
    let topLevelOutputText: String?

    var outputText: String {
        let nestedText = output
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n")
        return nestedText.isEmpty ? (topLevelOutputText ?? "") : nestedText
    }

    enum CodingKeys: String, CodingKey {
        case output
        case topLevelOutputText = "output_text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        output = (try? container.decode([OutputItem].self, forKey: .output)) ?? []
        topLevelOutputText = try? container.decodeIfPresent(String.self, forKey: .topLevelOutputText)
    }

    struct OutputItem: Decodable {
        let content: [ContentItem]

        enum CodingKeys: String, CodingKey {
            case content
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            content = (try? container.decode([ContentItem].self, forKey: .content)) ?? []
        }
    }

    struct ContentItem: Decodable {
        let text: String?
    }
}

private struct GeneratedDeckCard: Decodable {
    let name: String
    let doodle: DoodleRecipe?

    enum CodingKeys: String, CodingKey {
        case name, title, cardName, card_name, n
        case doodle, doodleRecipe, doodle_recipe, recipe
        case s, c, a, d
    }

    init(name: String, doodle: DoodleRecipe?) {
        self.name = name
        self.doodle = doodle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .cardName)
            ?? container.decodeIfPresent(String.self, forKey: .card_name)
            ?? container.decodeIfPresent(String.self, forKey: .n)
            ?? ""
        doodle = try container.decodeIfPresent(DoodleRecipe.self, forKey: .doodle)
            ?? container.decodeIfPresent(DoodleRecipe.self, forKey: .doodleRecipe)
            ?? container.decodeIfPresent(DoodleRecipe.self, forKey: .doodle_recipe)
            ?? container.decodeIfPresent(DoodleRecipe.self, forKey: .recipe)
            ?? GeneratedDeckCard.compactRecipe(from: container)
    }

    private static func compactRecipe(from container: KeyedDecodingContainer<CodingKeys>) -> DoodleRecipe? {
        guard let shape = try? container.decodeIfPresent(String.self, forKey: .s) else { return nil }
        let color = (try? container.decodeIfPresent(String.self, forKey: .c)) ?? "teal"
        let accent = try? container.decodeIfPresent(String.self, forKey: .a)
        let details = (try? container.decodeIfPresent([String].self, forKey: .d)) ?? []
        return DoodleRecipe(baseShape: shape, accentShape: accent, color: color, details: details)
    }
}

private struct DeckResponse: Decodable {
    let cards: [GeneratedDeckCard]

    init(cards: [GeneratedDeckCard]) {
        self.cards = cards
    }

    enum CodingKeys: String, CodingKey {
        case cards, objects, deck
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = [CodingKeys.cards, .objects, .deck].first { container.contains($0) } ?? .cards
        if let objectCards = try? container.decode([GeneratedDeckCard].self, forKey: key) {
            cards = objectCards
        } else {
            let names = try container.decode([String].self, forKey: key)
            cards = names.map { GeneratedDeckCard(name: $0, doodle: nil) }
        }
    }
}

private struct OpenAIErrorMessage: Decodable {
    let error: APIError?

    var message: String? { error?.message }

    static func decode(from data: Data) -> String? {
        try? JSONDecoder().decode(OpenAIErrorMessage.self, from: data).message
    }

    struct APIError: Decodable {
        let message: String?
    }
}

private struct DeckServiceErrorMessage: Decodable {
    let error: String?
    let message: String?

    static func decode(from data: Data) -> String? {
        if let direct = try? JSONDecoder().decode(DeckServiceErrorMessage.self, from: data) {
            return direct.message ?? direct.error
        }
        return OpenAIErrorMessage.decode(from: data)
    }
}

enum DeckGeneratorError: LocalizedError {
    case backendUnavailable
    case badResponse
    case httpStatus(Int, String?)
    case invalidJSON
    case tooFewCards
    case imageMissing
    case remoteFailed(String)

    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            return "AI deck generation is not configured for this build."
        case .badResponse:
            return "The AI service returned an unreadable response."
        case let .httpStatus(status, message):
            return message ?? "The AI service returned status \(status)."
        case .invalidJSON:
            return "The AI service did not return a valid deck."
        case .tooFewCards:
            return "The AI service returned too few cards. Try a broader theme."
        case .imageMissing:
            return "The AI service did not return image data."
        case let .remoteFailed(message):
            return "AI deck generation failed: \(message)"
        }
    }
}
