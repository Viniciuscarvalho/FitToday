//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall via RevenueCatUI — carrega o offering "Fittoday" do dashboard.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var offering: Offering?

    private let onPurchaseSuccess: () -> Void
    private let onDismiss: () -> Void

    init(
        onPurchaseSuccess: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.onPurchaseSuccess = onPurchaseSuccess
        self.onDismiss = onDismiss
    }

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering)
                    .onPurchaseCompleted { _ in
                        onPurchaseSuccess()
                        dismiss()
                    }
                    .onRestoreCompleted { _ in
                        onPurchaseSuccess()
                        dismiss()
                    }
                    .onDisappear {
                        onDismiss()
                    }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .task {
            await loadOffering()
        }
    }

    private func loadOffering() async {
        guard let offerings = try? await Purchases.shared.offerings() else { return }
        offering = offerings["Fittoday"] ?? offerings.current
    }
}

// MARK: - Preview

#Preview("Paywall") {
    OptimizedPaywallView()
}
