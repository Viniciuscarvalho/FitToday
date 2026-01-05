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
        .background(FitTodayColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            historyHeader
        }
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

    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text("Histórico")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("Acompanhe treinos concluídos e evolução dos programas.")
                .font(.system(.body))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FitTodaySpacing.lg)
        .padding(.top, FitTodaySpacing.md)
        .padding(.bottom, FitTodaySpacing.sm)
        .background(
            Rectangle()
                .fill(FitTodayColor.background)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        )
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
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Título e status
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
            
            // Vínculo com programa (se houver)
            if let programName = entry.programName {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text(programName)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }
            
            // Métricas de evolução (se houver)
            if entry.status == .completed && (entry.durationMinutes != nil || entry.caloriesBurned != nil) {
                HStack(spacing: FitTodaySpacing.md) {
                    if let duration = entry.durationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                    }
                    if let calories = entry.caloriesBurned {
                        Label("\(calories) kcal", systemImage: "flame")
                    }
                }
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
            }
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

