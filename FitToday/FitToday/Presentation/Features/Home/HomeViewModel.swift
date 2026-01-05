//
//  HomeViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine
import SwiftUI
import Swinject

/// Estado da jornada do usuário na Home.
enum HomeJourneyState: Equatable {
    /// Carregando dados iniciais.
    case loading
    /// Usuário não possui perfil → deve ir para onboarding/setup.
    case noProfile
    /// Usuário possui perfil mas não respondeu questionário de hoje → ir para questionário diário.
    case needsDailyCheckIn(profile: UserProfile)
    /// Questionário respondido, treino gerado disponível.
    case workoutReady(profile: UserProfile)
    /// Erro ao carregar dados.
    case error(message: String)
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var journeyState: HomeJourneyState = .loading
    @Published private(set) var entitlement: ProEntitlement = .free

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Computed Properties

    var userProfile: UserProfile? {
        switch journeyState {
        case .needsDailyCheckIn(let profile), .workoutReady(let profile):
            return profile
        default:
            return nil
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Bom dia"
        case 12..<18:
            return "Boa tarde"
        default:
            return "Boa noite"
        }
    }

    var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: Date()).capitalized
    }

    var goalBadgeText: String? {
        guard let profile = userProfile else { return nil }
        switch profile.mainGoal {
        case .hypertrophy: return "💪 Hipertrofia"
        case .conditioning: return "🔥 Condicionamento"
        case .endurance: return "🏃 Resistência"
        case .weightLoss: return "⚖️ Emagrecimento"
        case .performance: return "🎯 Performance"
        }
    }

    var ctaTitle: String {
        switch journeyState {
        case .loading:
            return "Carregando..."
        case .noProfile:
            return "Configurar Perfil"
        case .needsDailyCheckIn:
            return "Responder Questionário"
        case .workoutReady:
            return "Ver Treino de Hoje"
        case .error:
            return "Tentar Novamente"
        }
    }

    var ctaSubtitle: String? {
        switch journeyState {
        case .needsDailyCheckIn:
            return "2 perguntas rápidas antes de começar"
        case .workoutReady:
            return "Treino personalizado pronto para você"
        default:
            return nil
        }
    }

    // MARK: - Actions

    func onAppear() {
        Task {
            await loadUserData()
        }
    }

    func refresh() async {
        await loadUserData()
    }

    private func loadUserData() async {
        journeyState = .loading

        guard let profileRepo = resolver.resolve(UserProfileRepository.self),
              let entitlementRepo = resolver.resolve(EntitlementRepository.self) else {
            journeyState = .error(message: "Erro de configuração do app.")
            return
        }

        do {
            // Carregar entitlement (respeitar debug override se ativo)
            #if DEBUG
            if DebugEntitlementOverride.shared.isEnabled {
                entitlement = DebugEntitlementOverride.shared.entitlement
            } else {
                entitlement = try await entitlementRepo.currentEntitlement()
            }
            #else
            entitlement = try await entitlementRepo.currentEntitlement()
            #endif
            
            let loadedProfile = try await profileRepo.loadProfile()

            guard let profile = loadedProfile else {
                journeyState = .noProfile
                return
            }

            // Verificar se já respondeu hoje
            let hasAnsweredToday = await checkIfAnsweredToday()

            if hasAnsweredToday {
                journeyState = .workoutReady(profile: profile)
            } else {
                journeyState = .needsDailyCheckIn(profile: profile)
            }

        } catch {
            journeyState = .error(message: error.localizedDescription)
        }
    }

    private func checkIfAnsweredToday() async -> Bool {
        // Por enquanto, verificar via UserDefaults a data da última resposta
        // Futuramente, isso pode vir de um repositório de DailyCheckIn
        guard let lastCheckIn = UserDefaults.standard.object(forKey: AppStorageKeys.lastDailyCheckInDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastCheckIn)
    }

    /// Marca que o usuário respondeu o questionário hoje.
    func markDailyCheckInCompleted() {
        UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
        Task {
            await loadUserData()
        }
    }

    /// Observar mudanças no entitlement em background.
    func startObservingEntitlement() {
        Task {
            guard let repo = resolver.resolve(EntitlementRepository.self) else { return }
            for await newEntitlement in repo.entitlementStream() {
                self.entitlement = newEntitlement
            }
        }
    }
}

