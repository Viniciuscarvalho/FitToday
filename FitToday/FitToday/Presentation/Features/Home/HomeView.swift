//
//  HomeView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore

    init(resolver: Resolver) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(resolver: resolver))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                headerSection
                mainCard
                shortcutsSection
            }
            .padding(.horizontal)
            .padding(.bottom, FitTodaySpacing.xl)
        }
        .background(FitTodayColor.background)
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.startObservingEntitlement()
        }
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
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Main Card

    @ViewBuilder
    private var mainCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: mainCardIcon)
                        .font(.title2)
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text(mainCardTitle)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }

                Text(mainCardDescription)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = viewModel.ctaSubtitle {
                    Text(subtitle)
                        .font(.system(.footnote))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }

                Button(viewModel.ctaTitle) {
                    handleCTATap()
                }
                .fitPrimaryStyle()
                .disabled(viewModel.journeyState == .loading)
            }
        }
        .overlay {
            if viewModel.journeyState == .loading {
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(Color.black.opacity(0.05))
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
            }
        }
    }

    private var mainCardIcon: String {
        switch viewModel.journeyState {
        case .loading: return "hourglass"
        case .noProfile: return "person.crop.circle.badge.plus"
        case .needsDailyCheckIn: return "questionmark.circle"
        case .workoutReady: return "figure.run"
        case .error: return "exclamationmark.triangle"
        }
    }

    private var mainCardTitle: String {
        switch viewModel.journeyState {
        case .loading: return "Carregando..."
        case .noProfile: return "Boas-vindas!"
        case .needsDailyCheckIn: return "Treino de Hoje"
        case .workoutReady: return "Treino Pronto"
        case .error: return "Ops!"
        }
    }

    private var mainCardDescription: String {
        switch viewModel.journeyState {
        case .loading:
            return "Preparando tudo para você..."
        case .noProfile:
            return "Configure seu perfil para receber treinos personalizados todos os dias."
        case .needsDailyCheckIn:
            return "Responda 2 perguntas rápidas e veja seu treino de hoje."
        case .workoutReady:
            return "Seu treino personalizado está pronto. Bora treinar?"
        case .error(let msg):
            return msg
        }
    }

    // MARK: - Shortcuts

    @ViewBuilder
    private var shortcutsSection: some View {
        SectionHeader(title: "Atalhos", actionTitle: nil, action: nil)
            .padding(.horizontal, -FitTodaySpacing.md)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FitTodaySpacing.md) {
            ShortcutCard(
                title: "Biblioteca",
                icon: "book.fill",
                color: .blue
            ) {
                router.select(tab: .library)
            }

            ShortcutCard(
                title: "Histórico",
                icon: "clock.arrow.circlepath",
                color: .green
            ) {
                router.select(tab: .history)
            }

            if !viewModel.entitlement.isPro {
                ShortcutCard(
                    title: "Pro",
                    icon: "crown.fill",
                    color: .orange
                ) {
                    router.push(.paywall, on: .home)
                }
            }
            
            // Se o usuário tem perfil, mostra opção de editar perfil
            if viewModel.userProfile != nil {
                ShortcutCard(
                    title: "Editar Perfil",
                    icon: "person.text.rectangle",
                    color: .teal
                ) {
                    router.push(.editProfile, on: .home)
                }
            }

            ShortcutCard(
                title: "Perfil",
                icon: "person.fill",
                color: .purple
            ) {
                router.select(tab: .profile)
            }
        }
    }

    // MARK: - Actions

    private func handleCTATap() {
        switch viewModel.journeyState {
        case .noProfile:
            router.push(.onboarding, on: .home)
        case .needsDailyCheckIn:
            router.push(.dailyQuestionnaire, on: .home)
        case .workoutReady:
            if let planId = sessionStore.plan?.id {
                router.push(.workoutPlan(planId), on: .home)
            }
        case .error:
            viewModel.onAppear()
        case .loading:
            break
        }
    }
}

// MARK: - Supporting Views

private struct ShortcutCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.lg)
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .fitCardShadow()
        }
        .buttonStyle(.plain)
    }
}

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

#Preview {
    let container = Container()
    // Registrar mocks para preview
    container.register(UserProfileRepository.self) { _ in MockUserProfileRepository() }
    container.register(EntitlementRepository.self) { _ in MockEntitlementRepository() }

    return NavigationStack {
        HomeView(resolver: container)
            .environmentObject(AppRouter())
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

