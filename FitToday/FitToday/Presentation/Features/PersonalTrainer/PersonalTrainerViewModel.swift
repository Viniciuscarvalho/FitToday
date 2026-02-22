//
//  PersonalTrainerViewModel.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import Foundation
import Swinject

@Observable
@MainActor
final class PersonalTrainerViewModel {
    // MARK: - State

    private(set) var currentTrainer: PersonalTrainer?
    private(set) var connectionStatus: TrainerConnectionStatus?
    private(set) var relationshipId: String?
    private(set) var assignedWorkouts: [TrainerWorkout] = []
    private(set) var searchResults: [PersonalTrainer] = []
    var searchQuery: String = ""
    var inviteCode: String = ""
    private(set) var isLoading: Bool = false
    private(set) var isSearching: Bool = false
    private(set) var isRequestingConnection: Bool = false
    private(set) var error: Error?
    var showConnectionSheet: Bool = false
    var selectedTrainer: PersonalTrainer?
    private(set) var isFeatureEnabled: Bool = false
    private(set) var isChatEnabled: Bool = false

    // MARK: - Dependencies

    private let discoverTrainersUseCase: DiscoverTrainersUseCaseProtocol?
    private let requestConnectionUseCase: RequestTrainerConnectionUseCaseProtocol?
    private let cancelConnectionUseCase: CancelTrainerConnectionUseCaseProtocol?
    private let getCurrentTrainerUseCase: GetCurrentTrainerUseCaseProtocol?
    private let fetchAssignedWorkoutsUseCase: FetchAssignedWorkoutsUseCaseProtocol?
    private let fetchCMSWorkoutsUseCase: FetchCMSWorkoutsUseCase?
    private let featureFlagChecker: FeatureFlagChecking?
    private let cmsWorkoutRepository: CMSWorkoutRepository?
    private let authRepository: AuthenticationRepository?

    private var observationTask: Task<Void, Never>?
    private var workoutsObservationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.discoverTrainersUseCase = resolver.resolve(DiscoverTrainersUseCaseProtocol.self)
        self.requestConnectionUseCase = resolver.resolve(RequestTrainerConnectionUseCaseProtocol.self)
        self.cancelConnectionUseCase = resolver.resolve(CancelTrainerConnectionUseCaseProtocol.self)
        self.getCurrentTrainerUseCase = resolver.resolve(GetCurrentTrainerUseCaseProtocol.self)
        self.fetchAssignedWorkoutsUseCase = resolver.resolve(FetchAssignedWorkoutsUseCaseProtocol.self)
        self.fetchCMSWorkoutsUseCase = resolver.resolve(FetchCMSWorkoutsUseCase.self)
        self.featureFlagChecker = resolver.resolve(FeatureFlagChecking.self)
        self.cmsWorkoutRepository = resolver.resolve(CMSWorkoutRepository.self)
        self.authRepository = resolver.resolve(AuthenticationRepository.self)
    }

    // For testing
    init(
        discoverTrainersUseCase: DiscoverTrainersUseCaseProtocol? = nil,
        requestConnectionUseCase: RequestTrainerConnectionUseCaseProtocol? = nil,
        cancelConnectionUseCase: CancelTrainerConnectionUseCaseProtocol? = nil,
        getCurrentTrainerUseCase: GetCurrentTrainerUseCaseProtocol? = nil,
        fetchAssignedWorkoutsUseCase: FetchAssignedWorkoutsUseCaseProtocol? = nil,
        fetchCMSWorkoutsUseCase: FetchCMSWorkoutsUseCase? = nil,
        featureFlagChecker: FeatureFlagChecking? = nil,
        cmsWorkoutRepository: CMSWorkoutRepository? = nil,
        authRepository: AuthenticationRepository? = nil
    ) {
        self.discoverTrainersUseCase = discoverTrainersUseCase
        self.requestConnectionUseCase = requestConnectionUseCase
        self.cancelConnectionUseCase = cancelConnectionUseCase
        self.getCurrentTrainerUseCase = getCurrentTrainerUseCase
        self.fetchAssignedWorkoutsUseCase = fetchAssignedWorkoutsUseCase
        self.fetchCMSWorkoutsUseCase = fetchCMSWorkoutsUseCase
        self.featureFlagChecker = featureFlagChecker
        self.cmsWorkoutRepository = cmsWorkoutRepository
        self.authRepository = authRepository
    }

    // Note: Task cancellation is handled by onDisappear()
    // deinit removed to avoid @MainActor isolation issues

    // MARK: - Computed Properties

    var isConnected: Bool {
        connectionStatus == .active
    }

    var isPending: Bool {
        connectionStatus == .pending
    }

    var hasTrainer: Bool {
        currentTrainer != nil
    }

    var canSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canUseInviteCode: Bool {
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var pendingWorkoutsCount: Int {
        assignedWorkouts.filter { $0.isActive }.count
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task {
            await checkFeatureFlag()
            if isFeatureEnabled {
                await loadCurrentTrainer()
                startObservingRelationship()
                startObservingWorkouts()
            }
        }
    }

    func onDisappear() {
        observationTask?.cancel()
        workoutsObservationTask?.cancel()
    }

    // MARK: - Feature Flag

    private func checkFeatureFlag() async {
        guard let checker = featureFlagChecker else {
            isFeatureEnabled = false
            return
        }
        isFeatureEnabled = await checker.isFeatureEnabled(.personalTrainerEnabled)
        isChatEnabled = await checker.isFeatureEnabled(.trainerChatEnabled)
    }

    // MARK: - Load Current Trainer

    func loadCurrentTrainer() async {
        guard let useCase = getCurrentTrainerUseCase else {
            #if DEBUG
            print("[PersonalTrainerViewModel] GetCurrentTrainerUseCase not available")
            #endif
            return
        }

        isLoading = true
        error = nil

        do {
            if let result = try await useCase.execute() {
                currentTrainer = result.trainer
                connectionStatus = result.relationship.status
                relationshipId = result.relationship.id
                await loadAssignedWorkouts()
            } else {
                currentTrainer = nil
                connectionStatus = nil
                relationshipId = nil
                assignedWorkouts = []
            }
        } catch {
            self.error = error
            #if DEBUG
            print("[PersonalTrainerViewModel] Error loading trainer: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Search Trainers

    func searchTrainers() async {
        guard let useCase = discoverTrainersUseCase else {
            #if DEBUG
            print("[PersonalTrainerViewModel] DiscoverTrainersUseCase not available")
            #endif
            return
        }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        isSearching = true
        error = nil

        do {
            if query.isEmpty {
                // Load all active trainers from CMS marketplace
                searchResults = try await useCase.searchByName("", limit: 20)
            } else {
                searchResults = try await useCase.searchByName(query, limit: 20)
            }
        } catch {
            self.error = error
            searchResults = []
            #if DEBUG
            print("[PersonalTrainerViewModel] Error searching trainers: \(error)")
            #endif
        }

        isSearching = false
    }

    // MARK: - Find by Invite Code

    func findByInviteCode() async {
        guard let useCase = discoverTrainersUseCase else {
            #if DEBUG
            print("[PersonalTrainerViewModel] DiscoverTrainersUseCase not available")
            #endif
            return
        }

        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            return
        }

        isSearching = true
        error = nil

        do {
            if let trainer = try await useCase.findByInviteCode(code) {
                selectedTrainer = trainer
                showConnectionSheet = true
            } else {
                error = PersonalTrainerError.invalidInviteCode
            }
        } catch {
            self.error = error
            #if DEBUG
            print("[PersonalTrainerViewModel] Error finding by invite code: \(error)")
            #endif
        }

        isSearching = false
    }

    // MARK: - Request Connection

    func requestConnection(to trainer: PersonalTrainer) async -> Bool {
        guard let useCase = requestConnectionUseCase else {
            #if DEBUG
            print("[PersonalTrainerViewModel] RequestTrainerConnectionUseCase not available")
            #endif
            return false
        }

        isRequestingConnection = true
        error = nil

        do {
            let newRelationshipId = try await useCase.execute(trainerId: trainer.id)
            relationshipId = newRelationshipId
            currentTrainer = trainer
            connectionStatus = .pending
            showConnectionSheet = false
            selectedTrainer = nil
            searchResults = []
            searchQuery = ""
            inviteCode = ""

            // Register student in CMS so the trainer can assign workouts
            await registerStudentInCMS(trainerId: trainer.id)

            return true
        } catch {
            self.error = error
            #if DEBUG
            print("[PersonalTrainerViewModel] Error requesting connection: \(error)")
            #endif
            return false
        }
    }

    // MARK: - CMS Student Registration

    /// Registers the student in the CMS after a successful Firebase connection.
    /// This is best-effort — failure does not block the connection flow.
    private func registerStudentInCMS(trainerId: String) async {
        guard let repo = cmsWorkoutRepository,
              let authRepo = authRepository else {
            #if DEBUG
            print("[PersonalTrainerViewModel] CMS registration skipped: dependencies not available")
            #endif
            return
        }

        do {
            guard let user = try await authRepo.currentUser() else {
                #if DEBUG
                print("[PersonalTrainerViewModel] CMS registration skipped: no current user")
                #endif
                return
            }

            try await repo.registerStudent(
                firebaseUid: user.id,
                trainerId: trainerId,
                displayName: user.displayName,
                email: user.email
            )

            #if DEBUG
            print("[PersonalTrainerViewModel] Student registered in CMS for trainer \(trainerId)")
            #endif
        } catch {
            #if DEBUG
            print("[PersonalTrainerViewModel] CMS registration failed (non-blocking): \(error)")
            #endif
        }
    }

    // MARK: - Cancel Connection

    func cancelConnection() async -> Bool {
        guard let useCase = cancelConnectionUseCase,
              let relId = relationshipId else {
            #if DEBUG
            print("[PersonalTrainerViewModel] CancelTrainerConnectionUseCase not available or no relationship")
            #endif
            return false
        }

        isLoading = true
        error = nil

        do {
            try await useCase.execute(relationshipId: relId)
            currentTrainer = nil
            connectionStatus = nil
            relationshipId = nil
            assignedWorkouts = []
            return true
        } catch {
            self.error = error
            #if DEBUG
            print("[PersonalTrainerViewModel] Error canceling connection: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Load Assigned Workouts

    private func loadAssignedWorkouts() async {
        // Try CMS workouts first (primary source)
        if let cmsUseCase = fetchCMSWorkoutsUseCase {
            do {
                let result = try await cmsUseCase.execute()
                assignedWorkouts = result.workouts
                #if DEBUG
                print("[PersonalTrainerViewModel] Loaded \(result.workouts.count) CMS workouts")
                #endif
                return
            } catch {
                #if DEBUG
                print("[PersonalTrainerViewModel] CMS workouts failed, falling back to Firebase: \(error)")
                #endif
            }
        }

        // Fallback to Firebase workouts
        guard let useCase = fetchAssignedWorkoutsUseCase else {
            return
        }

        do {
            assignedWorkouts = try await useCase.execute()
        } catch {
            #if DEBUG
            print("[PersonalTrainerViewModel] Error loading workouts: \(error)")
            #endif
        }
    }

    // MARK: - Observation

    private func startObservingRelationship() {
        observationTask?.cancel()
        observationTask = Task {
            guard let useCase = getCurrentTrainerUseCase else { return }

            for await relationship in useCase.observeRelationship() {
                guard !Task.isCancelled else { break }

                if let rel = relationship {
                    connectionStatus = rel.status
                    relationshipId = rel.id

                    // Reload trainer if status changed
                    if rel.status == .active && currentTrainer == nil {
                        await loadCurrentTrainer()
                    }
                } else {
                    currentTrainer = nil
                    connectionStatus = nil
                    relationshipId = nil
                }
            }
        }
    }

    private func startObservingWorkouts() {
        workoutsObservationTask?.cancel()
        workoutsObservationTask = Task {
            guard let useCase = fetchAssignedWorkoutsUseCase else { return }

            for await workouts in useCase.observe() {
                guard !Task.isCancelled else { break }
                assignedWorkouts = workouts
            }
        }
    }

    // MARK: - UI Helpers

    func selectTrainer(_ trainer: PersonalTrainer) {
        selectedTrainer = trainer
        showConnectionSheet = true
    }

    func dismissConnectionSheet() {
        showConnectionSheet = false
        selectedTrainer = nil
    }

    func clearError() {
        error = nil
    }

    func clearSearch() {
        searchQuery = ""
        Task { await searchTrainers() }
    }
}
