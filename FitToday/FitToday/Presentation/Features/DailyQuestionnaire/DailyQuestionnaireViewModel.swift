//
//  DailyQuestionnaireViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine

@MainActor
final class DailyQuestionnaireViewModel: ObservableObject, ErrorPresenting {
    enum Step: Int, CaseIterable {
        case focus
        case soreness
        case energy

        var title: String {
            switch self {
            case .focus: return "Qual foco para hoje?"
            case .soreness: return "Como está seu corpo?"
            case .energy: return "Como está sua energia hoje?"
            }
        }
    }

    @Published var currentStep: Step = .focus
    @Published var selectedFocus: DailyFocus?
    @Published var selectedSoreness: MuscleSorenessLevel?
    @Published var selectedAreas: Set<MuscleGroup> = []
    /// Energia percebida (0–10). Default 5 para reduzir fricção.
    @Published var energyLevel: Int = 5
    @Published private(set) var entitlement: ProEntitlement = .free
    @Published var isLoading = false
    @Published var errorMessage: ErrorMessage? // ErrorPresenting protocol

    private let entitlementRepository: EntitlementRepository
    private let profileRepository: UserProfileRepository
    private let blocksRepository: WorkoutBlocksRepository
    private let composer: WorkoutPlanComposing
    private let buildUseCase = BuildDailyCheckInUseCase()
    private var entitlementTask: Task<Void, Never>?

    init(
        entitlementRepository: EntitlementRepository,
        profileRepository: UserProfileRepository,
        blocksRepository: WorkoutBlocksRepository,
        composer: WorkoutPlanComposing
    ) {
        self.entitlementRepository = entitlementRepository
        self.profileRepository = profileRepository
        self.blocksRepository = blocksRepository
        self.composer = composer
    }

    deinit {
        entitlementTask?.cancel()
    }

    func start() {
        if entitlementTask == nil {
            entitlementTask = Task { await observeEntitlement() }
        }
        Task {
            await loadEntitlement()
        }
    }

    var canAdvanceFromFocus: Bool {
        selectedFocus != nil
    }
    
    var canAdvanceFromSoreness: Bool {
        canSubmitSoreness
    }
    
    private var canSubmitSoreness: Bool {
        guard selectedSoreness != nil else { return false }
        if selectedSoreness == .strong {
            return !selectedAreas.isEmpty
        }
        return true
    }

    var canSubmit: Bool {
        guard selectedFocus != nil else { return false }
        guard canSubmitSoreness else { return false }
        return (0...10).contains(energyLevel)
    }

    func goToNextStep() {
        switch currentStep {
        case .focus:
            guard canAdvanceFromFocus else { return }
            currentStep = .soreness
        case .soreness:
            guard canAdvanceFromSoreness else { return }
            currentStep = .energy
        case .energy:
            return
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .energy:
            currentStep = .soreness
        case .soreness:
            currentStep = .focus
        case .focus:
            return
        }
    }

    func selectFocus(_ focus: DailyFocus) {
        selectedFocus = focus
    }

    func selectSoreness(_ level: MuscleSorenessLevel) {
        selectedSoreness = level
        if level != .strong {
            selectedAreas.removeAll()
        }
    }

    func toggleArea(_ area: MuscleGroup) {
        if selectedAreas.contains(area) {
            selectedAreas.remove(area)
        } else {
            selectedAreas.insert(area)
        }
    }

    func buildCheckIn() throws -> DailyCheckIn {
        guard let focus = selectedFocus else {
            throw DomainError.invalidInput(reason: "Selecione um foco para hoje.")
        }
        guard let soreness = selectedSoreness else {
            throw DomainError.invalidInput(reason: "Informe seu nível de dor.")
        }
        return try buildUseCase.execute(
            focus: focus,
            sorenessLevel: soreness,
            areas: Array(selectedAreas),
            energyLevel: energyLevel
        )
    }

    // MARK: - Private

    func generatePlan(for checkIn: DailyCheckIn) async throws -> WorkoutPlan {
        #if DEBUG
        print("[DailyQ] Iniciando geração de plano...")
        print("[DailyQ] CheckIn: focus=\(checkIn.focus.rawValue) soreness=\(checkIn.sorenessLevel.rawValue) energy=\(checkIn.energyLevel)")
        #endif
        
        let profileUseCase = GetUserProfileUseCase(repository: profileRepository)
        guard let profile = try await profileUseCase.execute() else {
            #if DEBUG
            print("[DailyQ] ❌ Perfil não encontrado!")
            #endif
            throw DomainError.profileNotFound
        }
        
        #if DEBUG
        print("[DailyQ] ✅ Perfil carregado: goal=\(profile.mainGoal.rawValue) structure=\(profile.availableStructure.rawValue)")
        #endif
        
        let generator = GenerateWorkoutPlanUseCase(blocksRepository: blocksRepository, composer: composer)
        
        do {
            let plan = try await generator.execute(profile: profile, checkIn: checkIn)
            #if DEBUG
            print("[DailyQ] ✅ Plano gerado: id=\(plan.id) phases=\(plan.phases.count)")
            #endif
            return plan
        } catch {
            #if DEBUG
            print("[DailyQ] ❌ Erro ao gerar plano: \(error)")
            #endif
            throw error
        }
    }

    private func loadEntitlement() async {
        do {
            isLoading = true
            entitlement = try await entitlementRepository.currentEntitlement()
        } catch {
            handleError(error) // ErrorPresenting protocol
        }
        isLoading = false
    }

    private func observeEntitlement() async {
        for await incoming in entitlementRepository.entitlementStream() {
            await MainActor.run {
                self.entitlement = incoming
            }
        }
    }
}

