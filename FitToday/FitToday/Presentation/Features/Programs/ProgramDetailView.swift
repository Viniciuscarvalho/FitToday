//
//  ProgramDetailView.swift
//  FitToday
//
//  Tela de detalhe de um programa, listando os treinos que o compõem.
//

import SwiftUI
import Swinject
import Combine

struct ProgramDetailView: View {
    let programId: String
    
    @Environment(\.dependencyResolver) private var resolver
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ProgramDetailViewModel
    
    init(programId: String, resolver: Resolver) {
        self.programId = programId
        guard let programRepo = resolver.resolve(ProgramRepository.self),
              let workoutRepo = resolver.resolve(LibraryWorkoutsRepository.self) else {
            fatalError("Repositories não registrados")
        }
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(
            programId: programId,
            programRepository: programRepo,
            workoutRepository: workoutRepo
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                if let program = viewModel.program {
                    heroSection(program)
                    workoutsSection
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    Text("Programa não encontrado")
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle(viewModel.program?.name ?? "Programa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Hero Section
    
    private func heroSection(_ program: Program) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: gradientColors(for: program.goalTag),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Conteúdo
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Spacer()
                
                // Tag
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: program.goalTag.iconName)
                    Text(program.goalTag.displayName)
                }
                .font(.system(.caption, weight: .semibold))
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                
                Text(program.name)
                    .font(.system(.title, weight: .bold))
                
                Text(program.subtitle)
                    .font(.system(.body))
                    .opacity(0.9)
                
                // Metadados
                HStack(spacing: FitTodaySpacing.lg) {
                    VStack(alignment: .leading) {
                        Text(program.durationDescription)
                            .font(.system(.headline, weight: .bold))
                        Text("Duração")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(program.totalWorkouts)")
                            .font(.system(.headline, weight: .bold))
                        Text("Treinos")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(program.sessionsDescription)
                            .font(.system(.headline, weight: .bold))
                        Text("Frequência")
                            .font(.system(.caption))
                            .opacity(0.7)
                    }
                }
                .padding(.top, FitTodaySpacing.sm)
            }
            .foregroundStyle(.white)
            .padding(FitTodaySpacing.lg)
        }
        .frame(height: 280)
    }
    
    // MARK: - Workouts Section
    
    @ViewBuilder
    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Treinos do Programa")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal)
            
            if viewModel.workouts.isEmpty && !viewModel.isLoading {
                Text("Nenhum treino encontrado")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                        WorkoutRowCard(
                            workout: workout,
                            index: index + 1
                        ) {
                            // Usa a tab atual para manter a navegação na mesma tab (home ou programs)
                            router.push(.programWorkoutDetail(workout.id), on: router.selectedTab)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.top, FitTodaySpacing.md)
    }
    
    private func gradientColors(for goalTag: ProgramGoalTag) -> [Color] {
        switch goalTag {
        case .metabolic: return [.orange, .red]
        case .strength: return [.blue, .purple]
        case .conditioning: return [.green, .teal]
        case .mobility: return [.cyan, .mint]
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ProgramDetailViewModel: ObservableObject {
    @Published private(set) var program: Program?
    @Published private(set) var workouts: [LibraryWorkout] = []
    @Published private(set) var isLoading = false
    
    private let programId: String
    private let programRepository: ProgramRepository
    private let workoutRepository: LibraryWorkoutsRepository
    
    init(
        programId: String,
        programRepository: ProgramRepository,
        workoutRepository: LibraryWorkoutsRepository
    ) {
        self.programId = programId
        self.programRepository = programRepository
        self.workoutRepository = workoutRepository
    }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            program = try await programRepository.getProgram(id: programId)
            
            if let program = program {
                let allWorkouts = try await workoutRepository.loadWorkouts()
                workouts = program.workoutTemplateIds.compactMap { templateId in
                    allWorkouts.first { $0.id == templateId }
                }
            }
        } catch {
            #if DEBUG
            print("[ProgramDetail] Erro ao carregar: \(error)")
            #endif
        }
    }
}

// MARK: - Workout Row Card

private struct WorkoutRowCard: View {
    let workout: LibraryWorkout
    let index: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.md) {
                // Número do treino
                Text("\(index)")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(width: 32, height: 32)
                    .background(FitTodayColor.brandPrimary.opacity(0.15))
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workout.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: FitTodaySpacing.sm) {
                        Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                        Label("\(workout.exerciseCount) exercícios", systemImage: "figure.run")
                    }
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(programId: "prog_push_pull_legs", resolver: Container())
            .environmentObject(AppRouter())
    }
}

