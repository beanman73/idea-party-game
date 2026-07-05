//
//  LaunchPricing.swift
//  Invention Party
//
//  Central launch pricing for the pack shop and AI deck generator.
//

import Foundation

enum LaunchPricing {
    static let starterAICredits = 1
    static let textDeckCreditCost = 1
    static let illustratedDeckCreditCost = 6
    static let partyPassMonthlyCredits = 10

    static let partyPass = PaidOffering(productID: "soysaucelabs.inventionparty.party.pass.monthly",
                                        title: "Party Pass",
                                        subtitle: "Premium deck packs + 10 AI credits every month.",
                                        price: "$4.99/mo",
                                        badge: "BEST")

    static let fullLibrary = PaidOffering(productID: "soysaucelabs.inventionparty.pack.library",
                                          title: "Full Deck Library",
                                          subtitle: "Unlock every premium deck pack in this release.",
                                          price: "$4.99",
                                          badge: "ONE TIME")

    static let creditPacks: [PaidOffering] = [
        PaidOffering(productID: "soysaucelabs.inventionparty.credits.10",
                     title: "10 Credits",
                     subtitle: "Good for 10 text decks or 1 illustrated deck.",
                     price: "$4.99",
                     badge: nil,
                     creditAmount: 10),
        PaidOffering(productID: "soysaucelabs.inventionparty.credits.24",
                     title: "24 Credits",
                     subtitle: "Best starter bundle for AI decks.",
                     price: "$9.99",
                     badge: nil,
                     creditAmount: 24),
        PaidOffering(productID: "soysaucelabs.inventionparty.credits.50",
                     title: "50 Credits",
                     subtitle: "Best value for frequent party hosts.",
                     price: "$19.99",
                     badge: "VALUE",
                     creditAmount: 50)
    ]

    static let premiumPackPrice = "$1.99"

    static let premiumPackProductIDs: [String: String] = [
        "tech": "soysaucelabs.inventionparty.pack.tech",
        "kitchen": "soysaucelabs.inventionparty.pack.kitchen",
        "sports": "soysaucelabs.inventionparty.pack.sports",
        "school": "soysaucelabs.inventionparty.pack.school"
    ]

    static var allProductIDs: Set<String> {
        Set(creditPacks.map(\.productID))
            .union([partyPass.productID, fullLibrary.productID])
            .union(premiumPackProductIDs.values)
    }

    static func aiDeckCreditCost(illustrated: Bool) -> Int {
        illustrated ? illustratedDeckCreditCost : textDeckCreditCost
    }

    static func isPremiumPack(_ packID: String) -> Bool {
        premiumPackProductIDs[packID] != nil
    }

    static func productID(forPackID packID: String) -> String? {
        premiumPackProductIDs[packID]
    }

    static func creditAmount(for productID: String) -> Int? {
        creditPacks.first { $0.productID == productID }?.creditAmount
    }
}

struct PaidOffering: Identifiable, Hashable {
    var id: String { productID }
    let productID: String
    let title: String
    let subtitle: String
    let price: String
    let badge: String?
    var creditAmount: Int? = nil
}
