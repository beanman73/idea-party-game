//
//  PurchaseStore.swift
//  Invention Party
//
//  StoreKit-ready purchase state for deck packs, subscriptions, and AI credits.
//

import Foundation
import StoreKit

@MainActor
final class PurchaseStore: ObservableObject {
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var aiCredits: Int

    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?

    private static let aiCreditsKey = "aiCredits"
    private static let seededStarterCreditsKey = "seededStarterAICredits"
    private static let processedConsumablesKey = "processedConsumableTransactions"
    private static let partyPassCreditMonthKey = "partyPassCreditMonth"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedCredits = defaults.integer(forKey: Self.aiCreditsKey)
        if defaults.bool(forKey: Self.seededStarterCreditsKey) {
            aiCredits = savedCredits
        } else {
            aiCredits = max(savedCredits, LaunchPricing.starterAICredits)
            defaults.set(true, forKey: Self.seededStarterCreditsKey)
            defaults.set(aiCredits, forKey: Self.aiCreditsKey)
        }

        updatesTask = listenForTransactionUpdates()
        Task { await refreshProductsAndEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
    }

    var hasPartyPass: Bool {
        purchasedProductIDs.contains(LaunchPricing.partyPass.productID)
    }

    func refreshProductsAndEntitlements() async {
        await loadProducts()
        await updatePurchasedProducts()
    }

    func displayPrice(for productID: String, fallback: String) -> String {
        productsByID[productID]?.displayPrice ?? fallback
    }

    func canUsePack(_ packID: String) -> Bool {
        // Everything is free in this release. Paid packs return in a later update.
        return true
    }

    func spendAICredits(_ count: Int) -> Bool {
        // AI decks are free in this release; generation is never gated on credits.
        return true
    }

    func refundAICredits(_ count: Int) {
        aiCredits += count
        persistCredits()
    }

    func purchase(_ offering: PaidOffering) async throws {
        try await purchase(productID: offering.productID)
    }

    func purchase(productID: String) async throws {
        if productsByID.isEmpty {
            await loadProducts()
        }

        guard let product = productsByID[productID] else {
            throw PurchaseStoreError.productUnavailable
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.verified(verification)
            await applyPurchase(transaction)
            await transaction.finish()
        case .userCancelled:
            throw PurchaseStoreError.userCancelled
        case .pending:
            throw PurchaseStoreError.purchasePending
        @unknown default:
            throw PurchaseStoreError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: Array(LaunchPricing.allProductIDs))
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        } catch {
            productsByID = [:]
        }
    }

    private func updatePurchasedProducts() async {
        var activeProductIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verified(result),
                  transaction.revocationDate == nil else {
                continue
            }
            activeProductIDs.insert(transaction.productID)
        }

        purchasedProductIDs = activeProductIDs
        grantPartyPassCreditsIfNeeded()
    }

    private func applyPurchase(_ transaction: Transaction) async {
        if let creditAmount = LaunchPricing.creditAmount(for: transaction.productID) {
            applyConsumableCredits(creditAmount, transactionID: transaction.id)
        } else {
            purchasedProductIDs.insert(transaction.productID)
            grantPartyPassCreditsIfNeeded()
        }
    }

    private func applyConsumableCredits(_ amount: Int, transactionID: UInt64) {
        let id = String(transactionID)
        var processed = Set(defaults.stringArray(forKey: Self.processedConsumablesKey) ?? [])
        guard !processed.contains(id) else { return }

        aiCredits += amount
        processed.insert(id)
        defaults.set(Array(processed), forKey: Self.processedConsumablesKey)
        persistCredits()
    }

    private func grantPartyPassCreditsIfNeeded() {
        guard hasPartyPass else { return }
        let currentMonth = Self.currentMonthKey()
        guard defaults.string(forKey: Self.partyPassCreditMonthKey) != currentMonth else { return }

        aiCredits += LaunchPricing.partyPassMonthlyCredits
        defaults.set(currentMonth, forKey: Self.partyPassCreditMonthKey)
        persistCredits()
    }

    private func persistCredits() {
        defaults.set(aiCredits, forKey: Self.aiCreditsKey)
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? Self.verified(result) else { continue }
                await self.applyPurchase(transaction)
                await transaction.finish()
            }
        }
    }

    nonisolated private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseStoreError.unverifiedTransaction
        }
    }

    private static func currentMonthKey() -> String {
        let date = Date()
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return "\(year)-\(month)"
    }
}

enum PurchaseStoreError: LocalizedError {
    case productUnavailable
    case purchasePending
    case userCancelled
    case unverifiedTransaction
    case unknown

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "This purchase is not available yet. Make sure the matching product ID is set up in App Store Connect."
        case .purchasePending:
            return "The purchase is pending approval."
        case .userCancelled:
            return "The purchase was cancelled."
        case .unverifiedTransaction:
            return "The purchase could not be verified."
        case .unknown:
            return "Something went wrong with the purchase."
        }
    }
}
