//
//  FeatureComparisonTable.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Tabela de comparação Free vs Pro
// Componente extraído para manter a view principal < 100 linhas
struct FeatureComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recurso")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .frame(width: 60)
                Text("Pro")
                    .frame(width: 60)
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .font(FitTodayFont.ui(size: 12, weight: .semiBold))
            .foregroundStyle(FitTodayColor.textSecondary)
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
            .background(FitTodayColor.surface)

            Divider().background(FitTodayColor.outline.opacity(0.2))

            // Features
            FeatureComparisonRow(
                feature: "Treinos IA personalizados",
                freeValue: .limited("1/sem"),
                proValue: .limited("2/dia")
            )
            FeatureComparisonRow(
                feature: "Desafios simultâneos",
                freeValue: .limited("5"),
                proValue: .unlimited
            )
            FeatureComparisonRow(
                feature: "Ajuste por dor muscular",
                freeValue: .no,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Substituição inteligente",
                freeValue: .no,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Histórico de treinos",
                freeValue: .limited("7 dias"),
                proValue: .unlimited
            )
            FeatureComparisonRow(
                feature: "Personal Trainer",
                freeValue: .no,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Exercícios com GIFs",
                freeValue: .yes,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Programas da Biblioteca",
                freeValue: .yes,
                proValue: .yes
            )
        }
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Feature Comparison Row

struct FeatureComparisonRow: View {
    let feature: String
    let freeValue: FeatureValue
    let proValue: FeatureValue

    enum FeatureValue {
        case yes
        case no
        case limited(String)
        case unlimited

        var icon: String {
            switch self {
            case .yes, .unlimited: return "checkmark.circle.fill"
            case .no: return "xmark.circle"
            case .limited: return "minus.circle"
            }
        }

        var color: Color {
            switch self {
            case .yes, .unlimited: return FitTodayColor.brandPrimary
            case .no: return FitTodayColor.textSecondary.opacity(0.5)
            case .limited: return .orange
            }
        }

        var text: String? {
            switch self {
            case .limited(let text): return text
            case .unlimited: return "∞"
            default: return nil
            }
        }
    }

    var body: some View {
        HStack {
            Text(feature)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            featureIcon(for: freeValue)
                .frame(width: 60)

            featureIcon(for: proValue)
                .frame(width: 60)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
    }

    private func featureIcon(for value: FeatureValue) -> some View {
        Group {
            if let text = value.text {
                Text(text)
                    .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                    .foregroundStyle(value.color)
            } else {
                Image(systemName: value.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(value.color)
            }
        }
    }
}
