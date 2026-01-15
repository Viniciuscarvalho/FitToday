//
//  ProfileHeader.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Header do perfil com avatar e status de assinatura
// Componente extraído para manter a view principal < 100 linhas
struct ProfileHeader: View {
    let entitlement: ProEntitlement

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                )

            if entitlement.isPro {
                proStatusView
            } else {
                freeStatusView
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FitTodaySpacing.lg)
    }

    // MARK: - Pro Status

    private var proStatusView: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("Assinante Pro")
                    .font(.system(.headline, weight: .semibold))
            }

            if let expiration = entitlement.expirationDate {
                Text("Renova em \(expiration.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }

    // MARK: - Free Status

    private var freeStatusView: some View {
        Text("Usuário Free")
            .font(.system(.headline))
            .foregroundStyle(FitTodayColor.textSecondary)
    }
}
