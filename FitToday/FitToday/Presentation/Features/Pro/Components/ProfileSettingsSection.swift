//
//  ProfileSettingsSection.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Seção de configurações do perfil
// Componente extraído para manter a view principal < 100 linhas
struct ProfileSettingsSection: View {
    let onEditProfile: () -> Void
    let onRedoDailyQuestionnaire: () -> Void
    let onOpenHealthKit: () -> Void
    let onRestorePurchases: () -> Void
    let onOpenSupport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Configurações", actionTitle: nil)

            VStack(spacing: 0) {
                SettingsRow(icon: "person.text.rectangle", title: "Editar Perfil de Treino", action: onEditProfile)

                Divider().padding(.leading, 56)

                SettingsRow(icon: "flame", title: "Refazer Questionário Diário", action: onRedoDailyQuestionnaire)

                Divider().padding(.leading, 56)

                SettingsRow(icon: "heart.fill", title: "Apple Health", action: onOpenHealthKit)

                Divider().padding(.leading, 56)

                SettingsRow(icon: "arrow.counterclockwise", title: "Restaurar Compras", action: onRestorePurchases)

                Divider().padding(.leading, 56)

                SettingsRow(icon: "questionmark.circle", title: "Ajuda e Suporte", action: onOpenSupport)
            }
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let title: String
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.md) {
                Image(systemName: icon)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, FitTodaySpacing.sm)
                        .padding(.vertical, FitTodaySpacing.xs)
                        .background(FitTodayColor.warning)
                        .cornerRadius(FitTodayRadius.pill)
                }

                Image(systemName: "chevron.right")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}
