//
//  StoreKitService.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import StoreKit

/// Serviço responsável por interagir com StoreKit 2 para compras e assinaturas.
// 💡 Learn: @Observable substitui ObservableObject para gerenciamento de estado moderno
@MainActor
@Observable final class StoreKitService {
    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var hasActiveSubscription = false

    // 💡 Learn: nonisolated(unsafe) permite acesso de deinit sem isolamento do MainActor
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
            let storeProducts = try await Product.products(for: StoreKitProductID.allSubscriptions)
            products = storeProducts.sorted { $0.price < $1.price }
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
                await refreshSubscriptionStatus()
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
            await refreshSubscriptionStatus()
            purchaseState = hasActiveSubscription ? .success : .idle
            logger("Restore completed. Has subscription: \(hasActiveSubscription)")
            return hasActiveSubscription
        } catch {
            purchaseState = .failed("Não foi possível restaurar compras.")
            logger("Restore failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Check Subscription Status
    
    func refreshSubscriptionStatus() async {
        var isActive = false
        
        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                if StoreKitProductID.allSubscriptions.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        isActive = true
                        logger("Active subscription found: \(transaction.productID)")
                    }
                }
            case .unverified(_, let error):
                logger("Unverified transaction: \(error.localizedDescription)")
            }
        }
        
        hasActiveSubscription = isActive
    }
    
    // MARK: - Get Current Entitlement Info
    
    func getCurrentEntitlement() async -> ProEntitlement {
        var latestTransaction: Transaction?
        
        for await verificationResult in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificationResult {
                if StoreKitProductID.allSubscriptions.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        latestTransaction = transaction
                    }
                }
            }
        }
        
        guard let transaction = latestTransaction else {
            return .free
        }
        
        return ProEntitlement(
            isPro: true,
            source: .storeKit,
            expirationDate: transaction.expirationDate
        )
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
            await refreshSubscriptionStatus()
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
    
    // MARK: - Subscription Products
    
    var monthlyProduct: Product? {
        products.first { $0.id == StoreKitProductID.proMonthly }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == StoreKitProductID.proYearly }
    }
}

// MARK: - Product Extensions

extension Product {
    var localizedPricePerMonth: String {
        switch subscription?.subscriptionPeriod.unit {
        case .year:
            let monthlyPrice = price / 12
            return monthlyPrice.formatted(.currency(code: priceFormatStyle.currencyCode ?? "BRL"))
        default:
            return displayPrice
        }
    }
    
    var periodDescription: String {
        guard let period = subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .day: return period.value == 1 ? "diário" : "\(period.value) dias"
        case .week: return period.value == 1 ? "semanal" : "\(period.value) semanas"
        case .month: return period.value == 1 ? "mensal" : "\(period.value) meses"
        case .year: return period.value == 1 ? "anual" : "\(period.value) anos"
        @unknown default: return ""
        }
    }
    
    var hasIntroOffer: Bool {
        subscription?.introductoryOffer != nil
    }
    
    var introOfferDescription: String? {
        guard let offer = subscription?.introductoryOffer else { return nil }
        switch offer.paymentMode {
        case .freeTrial:
            let period = offer.period
            switch period.unit {
            case .day: return "\(period.value) dia(s) grátis"
            case .week: return "\(period.value) semana(s) grátis"
            case .month: return "\(period.value) mês(es) grátis"
            case .year: return "\(period.value) ano(s) grátis"
            @unknown default: return nil
            }
        default:
            return nil
        }
    }
}

