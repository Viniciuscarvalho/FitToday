//
//  StoreKitService.swift
//  FitToday
//

import Foundation
import StoreKit

/// Serviço responsável por interagir com StoreKit 2 para compra única (non-consumable).
@MainActor
@Observable final class StoreKitService {
    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var hasProAccess = false

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
            products = storeProducts
            purchaseState = .idle
            logger("Loaded \(products.count) products")
        } catch {
            logger("Failed to load products: \(error.localizedDescription)")
            purchaseState = .failed("Não foi possível carregar os produtos.")
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
                logger("Unknown purchase result")
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
            purchaseState = hasProAccess ? .success : .idle
            logger("Restore completed. Has Pro: \(hasProAccess)")
            return hasProAccess
        } catch {
            purchaseState = .failed("Não foi possível restaurar compras.")
            logger("Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Purchase Status

    func refreshPurchaseStatus() async {
        var isActive = false

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                if StoreKitProductID.allProducts.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        isActive = true
                        logger("Active entitlement found: \(transaction.productID)")
                    }
                }
            case .unverified(_, let error):
                logger("Unverified transaction: \(error.localizedDescription)")
            }
        }

        hasProAccess = isActive
    }

    // MARK: - Get Current Entitlement Info

    func getCurrentEntitlement() async -> ProEntitlement {
        for await verificationResult in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificationResult {
                if StoreKitProductID.allProducts.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        return ProEntitlement(
                            isPro: true,
                            source: .storeKit,
                            expirationDate: nil
                        )
                    }
                }
            }
        }

        return .free
    }

    // MARK: - Transaction Listener

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
            logger("Transaction update received: \(transaction.productID)")
            await transaction.finish()
            await refreshPurchaseStatus()
        case .unverified(_, let error):
            logger("Unverified transaction update: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Product Accessors

    var lifetimeProduct: Product? {
        products.first { $0.id == StoreKitProductID.proLifetime }
    }
}
