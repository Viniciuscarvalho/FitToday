//
//  StoreKitService.swift
//  FitToday
//

import Foundation
import StoreKit

/// Service responsible for StoreKit 2 auto-renewable subscription purchases.
@MainActor
@Observable final class StoreKitService {
    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var activeProductID: String?

    // Backwards compat
    var hasProAccess: Bool { currentTier != .free }

    private nonisolated(unsafe) var transactionListener: Task<Void, Never>?
    private let logger: (String) -> Void

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
        case cancelled
    }

    init(logger: @escaping (String) -> Void = { print("[StoreKit]", $0) }) {
        self.logger = logger
        startTransactionListener()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Fetch Products

    func loadProducts() async {
        purchaseState = .loading
        do {
            let storeProducts = try await Product.products(for: StoreKitProductID.allProducts)
            // Sort: Elite Annual, Elite Monthly, Pro Annual, Pro Monthly
            products = storeProducts.sorted { lhs, rhs in
                let lTier = StoreKitProductID.tier(for: lhs.id).level
                let rTier = StoreKitProductID.tier(for: rhs.id).level
                if lTier != rTier { return lTier > rTier }
                return StoreKitProductID.isAnnual(lhs.id) && !StoreKitProductID.isAnnual(rhs.id)
            }
            purchaseState = .idle
            logger("Loaded \(products.count) products")
        } catch {
            logger("Failed to load products: \(error.localizedDescription)")
            purchaseState = .failed("Não foi possível carregar os planos.")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseState = .purchasing
        logger("Initiating purchase for \(product.id)")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchaseStatus()
                purchaseState = .success
                logger("Purchase successful for \(product.id)")
                return true

            case .userCancelled:
                purchaseState = .cancelled
                logger("User cancelled purchase")
                return false

            case .pending:
                purchaseState = .idle
                logger("Purchase pending approval")
                return false

            @unknown default:
                purchaseState = .idle
                return false
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            logger("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        purchaseState = .loading
        logger("Restoring purchases...")

        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
            purchaseState = currentTier != .free ? .success : .idle
            logger("Restore completed. Tier: \(currentTier.rawValue)")
            return currentTier != .free
        } catch {
            purchaseState = .failed("Não foi possível restaurar compras.")
            logger("Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Subscription Status

    func refreshPurchaseStatus() async {
        var highestTier: SubscriptionTier = .free
        var activeID: String?

        for await verificationResult in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verificationResult else { continue }
            guard StoreKitProductID.allProducts.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            // For auto-renewable: check expiration
            if let expiry = transaction.expirationDate, expiry < Date() { continue }

            let tier = StoreKitProductID.tier(for: transaction.productID)
            if tier.level > highestTier.level {
                highestTier = tier
                activeID = transaction.productID
            }
        }

        currentTier = highestTier
        activeProductID = activeID
        logger("Refreshed status — tier: \(highestTier.rawValue), product: \(activeID ?? "none")")
    }

    // MARK: - Current Entitlement

    func getCurrentEntitlement() async -> ProEntitlement {
        await refreshPurchaseStatus()
        guard currentTier != .free else { return .free }
        return ProEntitlement(
            tier: currentTier,
            source: .storeKit,
            expirationDate: await activeSubscriptionExpiry()
        )
    }

    // MARK: - Product Accessors

    func products(for tier: SubscriptionTier) -> [Product] {
        products.filter { StoreKitProductID.tier(for: $0.id) == tier }
    }

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Private Helpers

    private func activeSubscriptionExpiry() async -> Date? {
        guard let activeID = activeProductID else { return nil }
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == activeID {
                return tx.expirationDate
            }
        }
        return nil
    }

    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            logger("Transaction update: \(transaction.productID)")
            await transaction.finish()
            await refreshPurchaseStatus()
        case .unverified(_, let error):
            logger("Unverified transaction: \(error.localizedDescription)")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe): return safe
        }
    }
}
