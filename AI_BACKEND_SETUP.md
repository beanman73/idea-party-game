# AI Deck Backend Setup

The released app cannot call OpenAI directly because an API key in the app can
be extracted. The AI deck generator now expects a small backend endpoint:

```text
POST https://your-domain.example/api/generate-deck
```

## Deploy

1. Deploy this repository to Vercel or another host that supports the
   `api/generate-deck.js` serverless function.
2. Add these environment variables in the host dashboard:

```text
OPENAI_API_KEY=your OpenAI API key
OPENAI_MODEL=gpt-5.6-luna
```

`OPENAI_MODEL` is optional. If omitted, the backend uses `gpt-5.6-luna`.

## Wire the iOS App

After deployment, copy the endpoint URL and set it in one of these places:

1. Preferred: add an Xcode generated Info.plist key named
   `AI_DECK_BACKEND_URL` with the full endpoint URL.
2. Simple: paste the full endpoint URL into
   `bundledBackendURLString` in `InventionParty/Core/DeckGenerator.swift`.

Use the full API route, not only the domain:

```text
https://your-domain.example/api/generate-deck
```

## Release

Submit a new App Store build after the backend URL is set. The app version
already on users' phones cannot start using a backend unless that URL is inside
the build.

## Cost Note

The backend generates card names and doodle recipes with one text-model call.
It does not generate 30 image files per deck, so illustrated decks stay much
cheaper and faster while still showing hand-drawn doodles in the app.
