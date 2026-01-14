//
//  HistoryView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct HistoryView: View {
    @Environment(\.dependencyResolver) private var resolver
    // 💡 Learn: @State funciona perfeitamente com @Observable ViewModels
    @State private var viewModel: HistoryViewModel?
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @State private var dependencyError: String?

    init(resolver: Resolver) {
        // 💡 Learn: Em vez de fatalError, use estado de erro para UI resiliente
        if let repository = resolver.resolve(WorkoutHistoryRepository.self) {
            _viewModel = State(initialValue: HistoryViewModel(repository: repository))
        } else {
            _dependencyError = State(initialValue: "Erro de configuração: repositório de histórico não encontrado")
        }
    }

    var body: some View {
        Group {
            // 💡 Learn: Mostrar UI de erro em vez de crashar o app
            if let errorMessage = dependencyError {
                DependencyErrorView(message: errorMessage)
            } else if let vm = viewModel {
                historyContent(vm: vm)
            } else {
                ProgressView("Carregando...")
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func historyContent(vm: HistoryViewModel) -> some View {
        Group {
            if vm.sections.isEmpty && !vm.isLoading {
                EmptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Insights header (scrola junto com o conteúdo)
                        if let insights = vm.insights {
                            HistoryInsightsHeader(insights: insights)
                                .padding(.horizontal, FitTodaySpacing.md)
                                .padding(.top, FitTodaySpacing.md)
                                .padding(.bottom, FitTodaySpacing.lg)
                        }

                        ForEach(vm.sections) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    HistoryRow(entry: entry)
                                        .padding(.horizontal, FitTodaySpacing.md)
                                        .padding(.vertical, FitTodaySpacing.sm)
                                        .onAppear {
                                            // Trigger load more ao aparecer último item
                                            if entry.id == vm.sections.last?.entries.last?.id {
                                                vm.loadMoreIfNeeded()
                                            }
                                        }

                                    // Divider entre items (exceto o último da seção)
                                    if entry.id != section.entries.last?.id {
                                        Divider()
                                            .padding(.leading, FitTodaySpacing.md)
                                    }
                                }
                            } header: {
                                Text(section.title)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, FitTodaySpacing.md)
                                    .padding(.top, FitTodaySpacing.lg)
                                    .padding(.bottom, FitTodaySpacing.sm)
                                    .background(FitTodayColor.background)
                                    .textCase(nil)
                            }
                        }

                        // Loading indicator para scroll infinito
                        if vm.isLoadingMore {
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
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            vm.loadHistory()
        }
        .refreshable {
            await vm.refresh()
        }
        .errorToast(errorMessage: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ))
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text("\(entry.focusTitle) • \(hourString)")
                        .font(.system(.subheadline))
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
                .padding(.top, 2)
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
                .padding(.top, 2)
            }
        }
    }
}

private struct HistoryInsightsHeader: View {
    let insights: HistoryInsights
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: insights.monthSummary.monthStart).capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack(spacing: FitTodaySpacing.md) {
                MetricCard(title: "Streak atual", value: "\(insights.currentStreak)", subtitle: "dias")
                MetricCard(title: "Melhor streak", value: "\(insights.bestStreak)", subtitle: "dias")
            }
            
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text("Minutos por semana")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                
                WeeklyMinutesSparkline(weeks: insights.weekly.map { $0.minutes })
                    .frame(height: 44)
                
                let totalSessions = insights.weekly.reduce(0) { $0 + $1.sessions }
                let totalMinutes = insights.weekly.reduce(0) { $0 + $1.minutes }
                Text("Últimas \(insights.weekly.count) semanas • \(totalSessions) sessões • \(totalMinutes) min")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding()
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .techCornerBorders(length: 12, thickness: 1.5)
            .fitCardShadow()
            
            HStack(spacing: FitTodaySpacing.md) {
                MetricCard(
                    title: "\(monthTitle) em números",
                    value: "\(insights.monthSummary.sessions)",
                    subtitle: "sessões"
                )
                MetricCard(
                    title: "Tempo no mês",
                    value: "\(insights.monthSummary.minutes)",
                    subtitle: "min"
                )
            }
        }
    }
    
    private struct MetricCard: View {
        let title: String
        let value: String
        let subtitle: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(FitTodayFont.display(size: 22, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text(subtitle)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .techCornerBorders(length: 12, thickness: 1.5)
            .fitCardShadow()
        }
    }
    
    private struct WeeklyMinutesSparkline: View {
        let weeks: [Int]
        
        var body: some View {
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let maxValue = max(1, weeks.max() ?? 1)
                let stepX = weeks.count > 1 ? w / CGFloat(weeks.count - 1) : 0
                
                Path { path in
                    for (idx, value) in weeks.enumerated() {
                        let x = CGFloat(idx) * stepX
                        let y = h - (CGFloat(value) / CGFloat(maxValue)) * h
                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(FitTodayColor.brandPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .background(
                    Path { path in
                        for (idx, value) in weeks.enumerated() {
                            let x = CGFloat(idx) * stepX
                            let y = h - (CGFloat(value) / CGFloat(maxValue)) * h
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(FitTodayColor.brandPrimary.opacity(0.12))
                )
            }
        }
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

