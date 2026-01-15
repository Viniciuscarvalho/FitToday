//
//  SubscriptionCard.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Card de assinatura Pro/Free com informações e ação
// Componente extraído para manter a view principal < 100 linhas
struct SubscriptionCard: View {
    let isPro: Bool
    let onManageSubscription: () -> Void
    let onShowPaywall: () -> Void

    var body: some View {
        if isPro {
            proCard
        } else {
            freeCard
        }
    }

    // MARK: - Pro Card

    private var proCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("FitToday Pro Ativo")
                        .font(.system(.headline, weight: .semibold))
                }

                Text("Você tem acesso a todos os recursos premium, incluindo treinos adaptados e questionário diário.")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Button("Gerenciar Assinatura", action: onManageSubscription)
                    .font(.system(.subheadline, weight: .medium))
            }
        }
    }

    // MARK: - Free Card

    private var freeCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "star.circle")
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text("Desbloqueie o Pro")
                        .font(.system(.headline, weight: .semibold))
                }

                Text("Tenha treinos adaptados ao seu dia, ajuste por dor muscular e muito mais.")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Button("Ver Planos", action: onShowPaywall)
                    .fitPrimaryStyle()
            }
        }
    }
}
