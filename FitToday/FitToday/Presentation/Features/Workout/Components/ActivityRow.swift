//
//  ActivityRow.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Row card para atividade guiada (aeróbio, mobilidade, etc.)
// Componente extraído para manter a view principal < 100 linhas
struct ActivityRow: View {
    let activity: ActivityPrescription

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            Image(systemName: iconName)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(activity.title)
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("\(activity.durationMinutes) min")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                if let notes = activity.notes {
                    Text(notes)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            FitBadge(text: "GUIADO", style: .info)
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.title), \(activity.durationMinutes) minutos")
    }

    private var iconName: String {
        switch activity.kind {
        case .mobility: return "figure.cooldown"
        case .aerobicZone2: return "heart"
        case .aerobicIntervals: return "waveform.path.ecg"
        case .breathing: return "lungs"
        case .cooldown: return "leaf"
        }
    }
}
