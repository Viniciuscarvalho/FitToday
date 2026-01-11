//
//  ListRowStyles.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import SwiftUI

struct LibraryRowView: View {
    struct Model: Identifiable {
        let id = UUID()
        let title: String
        let duration: String
        let badge: String
    }

    let model: Model

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.system(.headline, weight: .semibold))
                Text(model.duration)
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            Spacer()
            FitBadge(text: model.badge, style: .info)
        }
        .padding(.vertical, FitTodaySpacing.sm)
        .contentShape(Rectangle())
    }
}

struct HistoryRowView: View {
    enum Status {
        case completed
        case skipped

        var display: (text: String, color: Color, icon: String) {
            switch self {
            case .completed:
                return ("Concluído", Color.green, "checkmark.circle.fill")
            case .skipped:
                return ("Pulou", Color.orange, "xmark.circle.fill")
            }
        }
    }

    struct Model: Identifiable {
        let id = UUID()
        let date: String
        let type: String
        let status: Status
    }

    let model: Model

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.date)
                    .font(.system(.subheadline, weight: .medium))
                Text(model.type)
                    .font(.system(.footnote))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            Spacer()
            Label {
                Text(model.status.display.text)
            } icon: {
                Image(systemName: model.status.display.icon)
            }
            .font(.system(.footnote, weight: .medium))
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(model.status.display.color.opacity(0.12))
            .foregroundColor(model.status.display.color)
            .clipShape(Capsule())
        }
        .padding(.vertical, FitTodaySpacing.sm)
        .contentShape(Rectangle())
    }
}

#Preview("List Rows") {
    List {
        Section("Biblioteca") {
            LibraryRowView(model: .init(title: "Hipertrofia superior", duration: "45 min • Halteres", badge: "Básico"))
            LibraryRowView(model: .init(title: "Full body express", duration: "30 min • Peso corporal", badge: "Básico"))
        }
        Section("Histórico") {
            HistoryRowView(model: .init(date: "Qui, 3 jan", type: "Full Body", status: .completed))
            HistoryRowView(model: .init(date: "Qua, 2 jan", type: "Inferior", status: .skipped))
        }
    }
}




