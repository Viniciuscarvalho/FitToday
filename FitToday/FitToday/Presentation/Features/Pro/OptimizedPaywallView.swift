//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall via RevenueCatUI — configurado no RevenueCat Dashboard.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss

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
        PaywallView()
            .onPurchaseCompleted { _ in
                onPurchaseSuccess()
                dismiss()
            }
            .onRestoreCompleted { _ in
                onPurchaseSuccess()
                dismiss()
            }
            .onDismiss {
                onDismiss()
                dismiss()
            }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    OptimizedPaywallView()
}
