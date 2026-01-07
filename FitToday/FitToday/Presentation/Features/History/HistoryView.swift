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
                ScrollView {
                    LazyVStack(spacing: FitTodaySpacing.md, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.sections) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    HistoryRow(entry: entry)
                                        .onAppear {
                                            // Trigger load more ao aparecer último item
                                            if entry.id == viewModel.sections.last?.entries.last?.id {
                                                viewModel.loadMoreIfNeeded()
                                            }
                                        }
                                }
                            } header: {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, FitTodaySpacing.xs)
                                    .background(FitTodayColor.background)
                            }
                        }
                        
                        // Loading indicator para scroll infinito
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .controlSize(.regular)
                                    .tint(FitTodayColor.brandPrimary)
                                Text("Carregando mais...")
                                    .font(.footnote)
                                    .foregroundStyle(FitTodayColor.textSecondary)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadHistory()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onReceive(sessionStore.$lastCompletionStatus.dropFirst()) { _ in
            Task {
                await viewModel.refresh()
            }
        }
        .errorToast(errorMessage: $viewModel.errorMessage)
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

