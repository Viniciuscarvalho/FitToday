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

        var title: String {
            switch self {
            case .focus: return "Qual foco para hoje?"
            case .soreness: return "Como está seu corpo?"
            }
        }
    }

    @Published var currentStep: Step = .focus
    @Published var selectedFocus: DailyFocus?
    @Published var selectedSoreness: MuscleSorenessLevel?
    @Published var selectedAreas: Set<MuscleGroup> = []
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

    var canSubmit: Bool {
        guard selectedFocus != nil, let level = selectedSoreness else { return false }
        if level == .strong {
            return !selectedAreas.isEmpty
        }
        return true
    }

    func goToNextStep() {
        guard currentStep == .focus, canAdvanceFromFocus else { return }
        currentStep = .soreness
    }

    func goToPreviousStep() {
        if currentStep == .soreness {
            currentStep = .focus
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
            areas: Array(selectedAreas)
        )
    }

    // MARK: - Private

    func generatePlan(for checkIn: DailyCheckIn) async throws -> WorkoutPlan {
        let profileUseCase = GetUserProfileUseCase(repository: profileRepository)
        guard let profile = try await profileUseCase.execute() else {
            throw DomainError.profileNotFound
        }
        let generator = GenerateWorkoutPlanUseCase(blocksRepository: blocksRepository, composer: composer)
        return try await generator.execute(profile: profile, checkIn: checkIn)
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

