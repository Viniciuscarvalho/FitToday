//
//  HomeView.swift
//  FitToday
//
//  Nova Home com estrutura: Hero / Top for You / Week's Workout
//

import SwiftUI
import Swinject

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @State private var isGeneratingPlan = false
    @State private var heroErrorMessage: String?

    init(resolver: Resolver) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(resolver: resolver))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.xl) {
                headerSection
                heroSection
                topForYouSection
                weeksWorkoutSection
            }
            .padding(.bottom, FitTodaySpacing.xl)
        }
        .background(FitTodayColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.startObservingEntitlement()
        }
        .alert(
            "Ops!",
            isPresented: Binding(
                get: { heroErrorMessage != nil },
                set: { if !$0 { heroErrorMessage = nil } }
            ),
            actions: {
                Button("Ok", role: .cancel) {
                    heroErrorMessage = nil
                }
            },
            message: {
                Text(heroErrorMessage ?? "Algo inesperado aconteceu.")
            }
        )
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greeting)
                        .font(.system(.title, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text(viewModel.currentDateFormatted)
                        .font(.system(.subheadline))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                Spacer()
                if !viewModel.entitlement.isPro {
                    Button {
                        router.push(.paywall, on: .home)
                    } label: {
                        Label("PRO", systemImage: "crown.fill")
                            .font(.system(.footnote, weight: .bold))
                    }
                    .buttonStyle(ProBadgeButtonStyle())
                }
            }

            if let badge = viewModel.goalBadgeText {
                FitBadge(text: badge, style: .info)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Hero Section (Treino do dia)

    @ViewBuilder
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            heroCard
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient baseado no estado
            LinearGradient(
                colors: heroGradientColors,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Overlay para legibilidade
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Conteúdo
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                // Ícone e título
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: heroIcon)
                        .font(.system(.title2, weight: .bold))
                    Text(heroTitle)
                        .font(.system(.headline, weight: .semibold))
                }
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                
                Spacer()
                
                Text(heroHeadline)
                    .font(.system(.title, weight: .bold))
                
                Text(heroDescription)
                    .font(.system(.body))
                    .opacity(0.9)
                    .lineLimit(2)
                
                if let subtitle = viewModel.ctaSubtitle {
                    Text(subtitle)
                        .font(.system(.caption))
                        .opacity(0.7)
                }
                
                // CTA
                Button(action: handleHeroCTATap) {
                    HStack(spacing: FitTodaySpacing.sm) {
                        if isGeneratingPlan {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(FitTodayColor.textInverse)
                        }
                        Text(isGeneratingPlan ? "Montando treino..." : viewModel.ctaTitle)
                            .font(.system(.subheadline, weight: .bold))
                    }
                    .foregroundStyle(FitTodayColor.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.md)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                }
                .disabled(viewModel.journeyState == .loading || isGeneratingPlan)
            }
            .foregroundStyle(.white)
            .padding(FitTodaySpacing.lg)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .fitCardShadow()
        .overlay {
            if viewModel.journeyState == .loading {
                RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                    .fill(Color.black.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
            }
        }
    }

    private var heroGradientColors: [Color] {
        switch viewModel.journeyState {
        case .loading: return [.gray, .gray.opacity(0.7)]
        case .noProfile: return [.blue, .purple]
        case .needsDailyCheckIn: return [.orange, .red]
        case .workoutReady: return [.green, .teal]
        case .workoutCompleted: return [.purple, .indigo]
        case .error: return [.red, .orange]
        }
    }

    private var heroIcon: String {
        switch viewModel.journeyState {
        case .loading: return "hourglass"
        case .noProfile: return "person.crop.circle.badge.plus"
        case .needsDailyCheckIn: return "flame.fill"
        case .workoutReady: return "figure.run"
        case .workoutCompleted: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle"
        }
    }

    private var heroTitle: String {
        switch viewModel.journeyState {
        case .loading: return "Carregando"
        case .noProfile: return "Boas-vindas"
        case .needsDailyCheckIn: return "Treino de Hoje"
        case .workoutReady: return "Pronto!"
        case .workoutCompleted: return "Concluído!"
        case .error: return "Atenção"
        }
    }

    private var heroHeadline: String {
        switch viewModel.journeyState {
        case .loading: return "Preparando..."
        case .noProfile: return "Vamos começar!"
        case .needsDailyCheckIn: return "Seu treino te espera"
        case .workoutReady: return "Hora de treinar"
        case .workoutCompleted: return "Bom trabalho!"
        case .error: return "Algo deu errado"
        }
    }

    private var heroDescription: String {
        switch viewModel.journeyState {
        case .loading:
            return "Carregando seus dados..."
        case .noProfile:
            return "Configure seu perfil para receber treinos personalizados todos os dias."
        case .needsDailyCheckIn:
            return "Responda 2 perguntas rápidas e veja seu treino personalizado."
        case .workoutReady:
            return "Seu treino está pronto. Bora?"
        case .workoutCompleted:
            return "Você já treinou hoje! Descanse bem e volte amanhã para mais."
        case .error(let msg):
            return msg
        }
    }

    private func handleHeroCTATap() {
        switch viewModel.journeyState {
        case .noProfile:
            router.push(.onboarding, on: .home)
        case .needsDailyCheckIn:
            router.push(.dailyQuestionnaire, on: .home)
        case .workoutReady:
            Task { await openDailyWorkoutPlan() }
        case .workoutCompleted:
            // Não faz nada - treino já concluído
            break
        case .error:
            viewModel.onAppear()
        case .loading:
            break
        }
    }

    @MainActor
    private func openDailyWorkoutPlan() async {
        if let planId = sessionStore.plan?.id {
            DailyWorkoutStateManager.shared.markViewed()
            router.push(.workoutPlan(planId), on: .home)
            return
        }
        
        guard !isGeneratingPlan else { return }
        isGeneratingPlan = true
        do {
            let plan = try await viewModel.regenerateDailyWorkoutPlan()
            sessionStore.start(with: plan)
            DailyWorkoutStateManager.shared.markSuggested(planId: plan.id)
            DailyWorkoutStateManager.shared.markViewed()
            router.push(.workoutPlan(plan.id), on: .home)
        } catch {
            heroErrorMessage = error.localizedDescription
        }
        isGeneratingPlan = false
    }

    // MARK: - Top for You Section

    @ViewBuilder
    private var topForYouSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(
                title: "Top for You",
                actionTitle: "Ver todos",
                action: { router.select(tab: .programs) }
            )
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.md) {
                    ForEach(viewModel.topPrograms) { program in
                        ProgramCardSmall(program: program) {
                            router.push(.programDetail(program.id), on: .home)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Week's Workout Section

    @ViewBuilder
    private var weeksWorkoutSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(
                title: "Treinos da Semana",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal)

            if viewModel.weekWorkouts.isEmpty {
                Text("Complete seu perfil para ver treinos recomendados")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(viewModel.weekWorkouts) { workout in
                        WorkoutCardCompact(workout: workout) {
                            router.push(.programWorkoutDetail(workout.id), on: .home)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Views

private struct ProBadgeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Program Card Small (horizontal)

struct ProgramCardSmall: View {
    let program: Program
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                // Imagem hero do programa
                ZStack(alignment: .topLeading) {
                    Image(program.heroImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 100)
                        .clipped()
                    
                    // Overlay sutil
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Badge do objetivo
                    HStack(spacing: 4) {
                        Image(systemName: program.goalTag.iconName)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(FitTodayColor.surface.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(FitTodaySpacing.sm)
                }
                .frame(width: 150, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(program.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    Text(program.durationDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                .padding(.horizontal, 2)
            }
            .frame(width: 150)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Card Compact

struct WorkoutCardCompact: View {
    let workout: LibraryWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.md) {
                // Thumbnail placeholder (gradiente)
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "figure.run")
                            .font(.system(.title3))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workout.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: FitTodaySpacing.sm) {
                        Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                        Label("\(workout.exerciseCount)", systemImage: "figure.strengthtraining.traditional")
                        intensityBadge
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

    @ViewBuilder
    private var intensityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(intensityColor)
                .frame(width: 6, height: 6)
            Text(workout.intensity.displayName)
        }
    }

    private var intensityColor: Color {
        switch workout.intensity {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    let container = Container()
    container.register(UserProfileRepository.self) { _ in MockUserProfileRepository() }
    container.register(EntitlementRepository.self) { _ in MockEntitlementRepository() }
    container.register(ProgramRepository.self) { _ in BundleProgramRepository() }
    container.register(LibraryWorkoutsRepository.self) { _ in
        BundleLibraryWorkoutsRepository(mediaResolver: ExerciseMediaResolver(service: nil))
    }

    return NavigationStack {
        HomeView(resolver: container)
            .environmentObject(AppRouter())
            .environmentObject(WorkoutSessionStore(resolver: container))
    }
}

// MARK: - Preview Mocks

private final class MockUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    func loadProfile() async throws -> UserProfile? {
        UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4
        )
    }

    func saveProfile(_ profile: UserProfile) async throws {}
}

private final class MockEntitlementRepository: EntitlementRepository, @unchecked Sendable {
    func currentEntitlement() async throws -> ProEntitlement { .free }
    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in continuation.finish() }
    }
}
