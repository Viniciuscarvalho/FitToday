//
//  HistoryView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Combine
import Swinject

struct HistoryView: View {
    @Environment(\.dependencyResolver) private var resolver
    @StateObject private var viewModel: HistoryViewModel
    @EnvironmentObject private var sessionStore: WorkoutSessionStore

    init(resolver: Resolver) {
        guard let repository = resolver.resolve(WorkoutHistoryRepository.self) else {
            fatalError("WorkoutHistoryRepository não registrado.")
        }
        _viewModel = StateObject(wrappedValue: HistoryViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if viewModel.sections.isEmpty && !viewModel.isLoading {
                EmptyState
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        Section(header: Text(section.title)) {
                            ForEach(section.entries) { entry in
                                HistoryRow(entry: entry)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Histórico")
        .task {
            viewModel.loadHistory()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onReceive(sessionStore.$lastCompletionStatus.dropFirst()) { _ in
            viewModel.loadHistory()
        }
        .alert("Ops!", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Algo inesperado aconteceu.")
        }
    }

    private var EmptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.brandPrimary)
            Text("Nada por aqui ainda")
                .font(.title3.bold())
            Text("Conclua ou pule um treino para ver seu progresso aparecer aqui.")
                .font(.body)
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private struct HistoryRow: View {
    let entry: WorkoutHistoryEntry

    private var statusText: String {
        switch entry.status {
        case .completed: return "Concluído"
        case .skipped: return "Pulou"
        }
    }

    private var statusStyle: FitBadge.Style {
        entry.status == .completed ? .success : .warning
    }

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(entry.title)
                    .font(.headline)
                Text("\(entry.focusTitle) • \(hourString)")
                    .font(.subheadline)
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            Spacer()
            FitBadge(text: statusText, style: statusStyle)
        }
        .padding(.vertical, FitTodaySpacing.sm)
    }
}

private extension WorkoutHistoryEntry {
    var focusTitle: String {
        switch focus {
        case .upper: return "Superior"
        case .lower: return "Inferior"
        case .cardio: return "Cardio"
        case .core: return "Core"
        case .fullBody: return "Full body"
        case .surprise: return "Surpresa"
        }
    }
}

