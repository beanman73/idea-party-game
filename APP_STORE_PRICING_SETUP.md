# Invention Party Pricing Setup

This app already has the StoreKit pricing code wired in. The last step is to create matching products in App Store Connect with the exact product IDs below.

## Product IDs

Create these in App Store Connect:

| Product | Product ID | Type | Price |
| --- | --- | --- | --- |
| Party Pass | `soysaucelabs.inventionparty.party.pass.monthly` | Auto-renewable subscription | `$4.99/month` |
| Full Deck Library | `soysaucelabs.inventionparty.pack.library` | Non-consumable | `$4.99` |
| 10 Credits | `soysaucelabs.inventionparty.credits.10` | Consumable | `$4.99` |
| 24 Credits | `soysaucelabs.inventionparty.credits.24` | Consumable | `$9.99` |
| 50 Credits | `soysaucelabs.inventionparty.credits.50` | Consumable | `$19.99` |
| Tech & Gadgets Pack | `soysaucelabs.inventionparty.pack.tech` | Non-consumable | `$1.99` |
| Kitchen Pack | `soysaucelabs.inventionparty.pack.kitchen` | Non-consumable | `$1.99` |
| Sports Gear Pack | `soysaucelabs.inventionparty.pack.sports` | Non-consumable | `$1.99` |
| School Supplies Pack | `soysaucelabs.inventionparty.pack.school` | Non-consumable | `$1.99` |

## What Each Product Does

- **Party Pass** unlocks premium deck packs and grants 10 AI credits each month.
- **Full Deck Library** unlocks the premium deck packs in this release forever.
- **AI Credits** are spent when a player generates custom AI decks.
- **Single Pack Purchases** unlock one premium deck forever.

AI deck costs in the app:

| AI Deck Type | Credit Cost |
| --- | --- |
| Text-only AI deck | `1 credit` |
| AI deck with doodle pictures | `6 credits` |

## App Store Connect Steps

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Open **Apps**, then select **Invention Party**.
3. Go to **Monetization**.
4. Create the consumable and non-consumable products under **In-App Purchases**.
5. Create **Party Pass** under **Subscriptions** as an auto-renewable subscription.
6. For each product, enter the exact product ID from the table above.
7. Add a display name, description, price, and screenshot if Apple asks for review information.
8. Make sure the products are included with the app version you submit for review.
9. Test the purchases in TestFlight before public release.

## Suggested Product Copy

Use short, plain names:

| Product | Display Name | Description |
| --- | --- | --- |
| Party Pass | Party Pass | Unlock premium deck packs and get 10 AI credits every month. |
| Full Deck Library | Full Deck Library | Unlock every premium deck pack in this release. |
| 10 Credits | 10 AI Credits | Create text-only AI decks or save credits for illustrated decks. |
| 24 Credits | 24 AI Credits | A larger bundle for making custom AI decks. |
| 50 Credits | 50 AI Credits | The best value for frequent party hosts. |
| Tech & Gadgets Pack | Tech & Gadgets Pack | Sensors, screens, trackers, and future-facing invention prompts. |
| Kitchen Pack | Kitchen Pack | Food tools, countertop gear, and kitchen chaos for invention rounds. |
| Sports Gear Pack | Sports Gear Pack | Courts, gyms, fields, and training gear for fast invention rounds. |
| School Supplies Pack | School Supplies Pack | Classroom supplies and desk gear for clever invention prompts. |

## Release Checks

Before shipping:

- Confirm the product IDs in App Store Connect exactly match `InventionParty/Core/LaunchPricing.swift`.
- Confirm Paid Apps agreements, banking, and tax forms are complete in App Store Connect.
- Run a TestFlight build and buy each product with sandbox testing.
- Tap **Restore Purchases** in the app and confirm owned decks return.
- Confirm `AI_DECK_BACKEND_URL` points at the deployed backend.
- Generate one text-only AI deck and one illustrated AI deck.
- Confirm failed AI generation refunds the spent credits.

## Important AI Billing Note

The app currently has StoreKit purchase handling and local credit spending. For a public launch with real AI costs, the strongest setup is:

1. The app buys credits through StoreKit.
2. Your backend verifies the App Store transaction.
3. Your backend tracks the user's credit balance.
4. Your backend calls OpenAI.
5. The OpenAI API key never ships inside the app.

That backend step prevents people from changing local credit values and generating expensive AI decks without paying. For a small TestFlight beta, the current app-side flow is useful for testing the experience.

## Apple Docs

- [Create consumable or non-consumable In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases)
- [Manage subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions)
- [Test In-App Purchases](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/overview-of-testing-in-sandbox)
