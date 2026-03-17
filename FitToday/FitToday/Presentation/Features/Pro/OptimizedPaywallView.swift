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
    @State private var loadFailed = false

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
            } else if loadFailed {
                offeringErrorView
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

    private var offeringErrorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("paywall.error.load_failed".localized)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("paywall.error.retry".localized) {
                loadFailed = false
                Task { await loadOffering() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func loadOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            offering = offerings["Fittoday"] ?? offerings.current
            if offering == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    OptimizedPaywallView()
}
