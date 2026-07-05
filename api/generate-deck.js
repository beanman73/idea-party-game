const CARD_COUNT = 30;
const MAX_PROMPT_LENGTH = 180;
const DEFAULT_MODEL = "gpt-5.6-luna";

const ALLOWED_SHAPES = new Set([
  "circle",
  "box",
  "bottle",
  "tool",
  "vehicle",
  "plant",
  "flower",
  "food",
  "device",
  "house",
  "door",
  "tent",
  "crystal",
  "wheel",
  "lantern",
  "star",
]);

const ALLOWED_COLORS = new Set(["tomato", "mustard", "teal", "grape", "leaf", "sky"]);
const ALLOWED_DETAILS = new Set([
  "handle",
  "wheels",
  "stripes",
  "buttons",
  "steam",
  "legs",
  "sparkles",
  "label",
  "portal",
]);

module.exports = async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === "OPTIONS") {
    return res.status(204).end();
  }

  if (req.method !== "POST") {
    return sendError(res, 405, "Use POST to generate a deck.");
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return sendError(res, 500, "AI deck generation is not configured.");
  }

  try {
    const body = await readRequestBody(req);
    const prompt = cleanPrompt(body.prompt);
    const cardCount = clampCardCount(body.cardCount);

    if (!prompt) {
      return sendError(res, 400, "Add a deck prompt first.");
    }

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || DEFAULT_MODEL,
        input: [
          { role: "developer", content: developerInstructions(cardCount) },
          { role: "user", content: `Theme: ${prompt}` },
        ],
        max_output_tokens: 2400,
      }),
    });

    const responseBody = await response.json().catch(() => null);
    if (!response.ok) {
      const message = responseBody?.error?.message || "The AI service could not generate a deck.";
      return sendError(res, response.status, message);
    }

    const text = extractOutputText(responseBody);
    const cards = parseCards(text, cardCount);

    if (cards.length < 2) {
      return sendError(res, 502, "The AI service returned too few cards. Try a broader theme.");
    }

    return res.status(200).json({ cards });
  } catch (error) {
    return sendError(res, 500, error.message || "AI deck generation failed.");
  }
};

function developerInstructions(cardCount) {
  return `
You generate object card decks for a party game where players combine two random objects into an invention.
Return JSON only, with this exact compact shape:
{"cards":[{"n":"Airlock Door","s":"door","c":"sky","d":["label","buttons"]}]}

Internally brainstorm many candidate cards for the user's theme, then choose the best ${cardCount}.
A great card is concrete, visual, and full of affordances: it can hold, move, protect, sense, signal, scan, open, close, connect, sort, heat, cool, launch, track, clean, transform, automate, notify, record, recommend, map, or personalize.
Include a healthy mix of physical objects and technology-flavored objects. Tech cards should still be concrete and playable, such as Motion Sensor, Smart Button, QR Sticker, Weather App, AI Coach, Camera Trap, Voice Remote, Map Pin, Wi-Fi Beacon, Notification Bell, Recipe Scanner, or Voting App.
Make cards specific but not too specific: objects, props, tools, containers, toys, simple devices, wearable items, app-like tools, sensors, interfaces, and smart accessories.
Avoid proper nouns, brands, people, vague sci-fi words, pure abstractions, animals as standalone cards, and objects that are mostly the same as each other.
Avoid cards that sound cool but are unclear or not really objects, like Orbit Ring, Nebula Bottle, Cosmic Vibe, Dream Energy, or Future Zone.
Use 1 to 3 words per card, Title Case, no emoji, no numbering.
Return exactly ${cardCount} final cards. Do not return scores, notes, or rejected candidates.

Doodle tags:
- n is the card name.
- s is one shape from: circle, box, bottle, tool, vehicle, plant, flower, food, device, house, door, tent, crystal, wheel, lantern, star.
- c is one color from: tomato, mustard, teal, grape, leaf, sky.
- a is optional accent shape from the same shape list, or omit it.
- d is 0 to 4 details from: handle, wheels, stripes, buttons, steam, legs, sparkles, label, portal.
Choose doodle tags by visual resemblance, not by category.
`.trim();
}

async function readRequestBody(req) {
  if (req.body && typeof req.body === "object") {
    return req.body;
  }

  if (typeof req.body === "string") {
    return JSON.parse(req.body || "{}");
  }

  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString("utf8");
  return raw ? JSON.parse(raw) : {};
}

function cleanPrompt(value) {
  return String(value || "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, MAX_PROMPT_LENGTH);
}

function clampCardCount(value) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    return CARD_COUNT;
  }
  return Math.min(Math.max(parsed, 2), CARD_COUNT);
}

function extractOutputText(payload) {
  if (!payload) {
    return "";
  }

  if (typeof payload.output_text === "string") {
    return payload.output_text;
  }

  const strings = [];
  walkResponse(payload, null, strings);
  return strings.sort((a, b) => b.length - a.length)[0] || "";
}

function walkResponse(value, key, strings) {
  if (Array.isArray(value)) {
    value.forEach((item) => walkResponse(item, key, strings));
    return;
  }

  if (value && typeof value === "object") {
    Object.entries(value).forEach(([childKey, childValue]) => {
      walkResponse(childValue, childKey, strings);
    });
    return;
  }

  if (typeof value === "string" && (key === "text" || key === "output_text")) {
    strings.push(value);
  }
}

function parseCards(text, limit) {
  const parsed = JSON.parse(extractJson(text));
  const rawCards = Array.isArray(parsed)
    ? parsed
    : parsed.cards || parsed.objects || parsed.deck || [];

  if (!Array.isArray(rawCards)) {
    throw new Error("The AI service did not return a valid deck.");
  }

  const seen = new Set();
  const cards = [];

  for (const rawCard of rawCards) {
    const card = normalizeCard(rawCard);
    if (!card) {
      continue;
    }

    const key = card.n.toLowerCase();
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    cards.push(card);
    if (cards.length === limit) {
      break;
    }
  }

  return cards;
}

function extractJson(text) {
  const trimmed = String(text || "")
    .replace(/```json/gi, "")
    .replace(/```/g, "")
    .trim();

  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    return trimmed;
  }

  return balancedJsonSubstring(trimmed, "{", "}")
    || balancedJsonSubstring(trimmed, "[", "]")
    || trimmed;
}

function balancedJsonSubstring(text, opening, closing) {
  const start = text.indexOf(opening);
  if (start < 0) {
    return null;
  }

  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let index = start; index < text.length; index += 1) {
    const char = text[index];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === "\"") {
        inString = false;
      }
    } else if (char === "\"") {
      inString = true;
    } else if (char === opening) {
      depth += 1;
    } else if (char === closing) {
      depth -= 1;
      if (depth === 0) {
        return text.slice(start, index + 1);
      }
    }
  }

  return null;
}

function normalizeCard(rawCard) {
  if (typeof rawCard === "string") {
    const name = cleanCardName(rawCard);
    return name ? { n: name, ...guessRecipe(name) } : null;
  }

  if (!rawCard || typeof rawCard !== "object") {
    return null;
  }

  const name = cleanCardName(
    rawCard.n || rawCard.name || rawCard.title || rawCard.cardName || rawCard.card_name || ""
  );
  if (!name) {
    return null;
  }

  const recipe = cleanRecipe(rawCard, name);
  return { n: name, ...recipe };
}

function cleanCardName(value) {
  return String(value || "")
    .replace(/^\d+[\.)]\s*/, "")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/^[^\w]+|[^\w]+$/g, "")
    .slice(0, 42);
}

function cleanRecipe(rawCard, name) {
  const nested = rawCard.doodle || rawCard.doodleRecipe || rawCard.doodle_recipe || rawCard.recipe || {};
  const fallback = guessRecipe(name);
  const shape = normalizeToken(rawCard.s || nested.s || nested.baseShape || nested.base_shape || nested.base || nested.shape);
  const color = normalizeToken(rawCard.c || nested.c || nested.color);
  const accent = normalizeToken(rawCard.a || nested.a || nested.accentShape || nested.accent_shape || nested.accent);
  const details = Array.isArray(rawCard.d)
    ? rawCard.d
    : Array.isArray(nested.d)
      ? nested.d
      : Array.isArray(nested.details)
        ? nested.details
        : [];

  const cleanedDetails = details
    .map(normalizeToken)
    .filter((detail) => ALLOWED_DETAILS.has(detail))
    .slice(0, 4);

  const recipe = {
    s: ALLOWED_SHAPES.has(shape) ? shape : fallback.s,
    c: ALLOWED_COLORS.has(color) ? color : fallback.c,
    d: cleanedDetails.length > 0 ? cleanedDetails : fallback.d,
  };

  if (ALLOWED_SHAPES.has(accent) && accent !== recipe.s) {
    recipe.a = accent;
  }

  return recipe;
}

function normalizeToken(value) {
  return String(value || "").trim().toLowerCase().replace(/\s+/g, " ");
}

function guessRecipe(name) {
  const key = normalizeToken(name);
  let shape = "box";

  if (hasAny(key, ["door", "gate", "hatch"])) shape = "door";
  else if (hasAny(key, ["tent", "canopy"])) shape = "tent";
  else if (hasAny(key, ["crystal", "gem", "shard"])) shape = "crystal";
  else if (hasAny(key, ["wheel", "gear"])) shape = "wheel";
  else if (hasAny(key, ["lamp", "lantern", "beacon"])) shape = "lantern";
  else if (hasAny(key, ["flower", "petal"])) shape = "flower";
  else if (hasAny(key, ["mug", "cup", "bottle", "jar", "can", "thermos", "bucket"])) shape = "bottle";
  else if (hasAny(key, ["car", "cart", "scooter", "bike", "rocket", "boat", "drone"])) shape = "vehicle";
  else if (hasAny(key, ["wand", "hammer", "tool", "brush", "key", "scanner", "scoop"])) shape = "tool";
  else if (hasAny(key, ["snack", "pizza", "taco", "cookie", "lunch", "cake", "candy"])) shape = "food";
  else if (hasAny(key, ["remote", "screen", "button", "camera", "app", "sensor", "smart", "tracker", "tag", "ai", "wi-fi", "wifi"])) shape = "device";
  else if (hasAny(key, ["plant", "garden", "tree", "leaf"])) shape = "plant";
  else if (hasAny(key, ["house", "booth", "room", "locker"])) shape = "house";
  else if (hasAny(key, ["star", "spark", "moon", "sun", "magic"])) shape = "star";
  else if (hasAny(key, ["ball", "bubble", "globe", "coin"])) shape = "circle";

  const color = hasAny(key, ["fire", "button", "alarm", "rocket"]) ? "tomato"
    : hasAny(key, ["sun", "star", "lamp", "light", "gold"]) ? "mustard"
      : hasAny(key, ["plant", "garden", "leaf", "tree"]) ? "leaf"
        : hasAny(key, ["water", "rain", "beach", "pool", "sky"]) ? "sky"
          : hasAny(key, ["magic", "moon", "portal"]) ? "grape"
            : "teal";

  const details = [];
  if (shape === "vehicle" || hasAny(key, ["cart", "scooter", "bike"])) details.push("wheels");
  if (shape === "bottle" || hasAny(key, ["bag", "bucket", "box", "case"])) details.push("handle");
  if (shape === "device" || shape === "door" || hasAny(key, ["button", "remote", "sensor", "screen"])) details.push("buttons");
  if (hasAny(key, ["stripe", "ticket", "blanket", "flag"])) details.push("stripes");
  if (hasAny(key, ["hot", "coffee", "tea", "soup"])) details.push("steam");
  if (hasAny(key, ["chair", "table", "stand"])) details.push("legs");
  if (hasAny(key, ["magic", "spark", "glow", "star"])) details.push("sparkles");
  if (hasAny(key, ["label", "tag", "ticket", "map", "note", "card", "qr"])) details.push("label");
  if (hasAny(key, ["portal", "airlock"])) details.push("portal");

  return { s: shape, c: color, d: details.slice(0, 4) };
}

function hasAny(value, needles) {
  return needles.some((needle) => value.includes(needle));
}

function setCorsHeaders(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
}

function sendError(res, status, message) {
  return res.status(status).json({ error: message });
}
