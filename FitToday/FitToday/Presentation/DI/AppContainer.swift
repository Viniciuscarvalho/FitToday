//
//  AppContainer.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation
import SwiftData
import Swinject

/// Responsável por montar e expor o container de dependências da aplicação.
struct AppContainer {
    let container: Container
    let router: AppRouter
    let modelContainer: ModelContainer

    @MainActor
    static func build() -> AppContainer {
        let modelContainer = makeModelContainer()
        return build(modelContainer: modelContainer)
    }

    @MainActor
    static func build(modelContainer: ModelContainer) -> AppContainer {
        let container = Container()
        container.register(ModelContainer.self) { _ in modelContainer }
            .inObjectScope(.container)

        let router = AppRouter()
        container.register(AppRouting.self) { _ in router }
            .inObjectScope(.container)

        // Image Cache Service
        let imageCacheConfig = ImageCacheConfiguration.default
        let imageCacheService = ImageCacheService(configuration: imageCacheConfig)
        container.register(ImageCaching.self) { _ in imageCacheService }
            .inObjectScope(.container)
        
        // Repositórios
        container.register(UserProfileRepository.self) { _ in
            SwiftDataUserProfileRepository(modelContainer: modelContainer)
        }.inObjectScope(.container)

        container.register(WorkoutHistoryRepository.self) { _ in
            SwiftDataWorkoutHistoryRepository(modelContainer: modelContainer)
        }.inObjectScope(.container)

        container.register(UserStatsRepository.self) { _ in
            SwiftDataUserStatsRepository(modelContainer: modelContainer)
        }.inObjectScope(.container)
        
        // Workout Composition Cache (F7)
        container.register(WorkoutCompositionCacheRepository.self) { _ in
            SwiftDataWorkoutCompositionCacheRepository(modelContainer: modelContainer)
        }.inObjectScope(.container)

        // WorkoutBlocksRepository é registrado após configurar Wger (para permitir enriquecimento de mídia/instruções).

        // StoreKit Service e EntitlementRepository
        // Nota: StoreKitService é @MainActor, então precisa ser criado no main thread
        let storeKitService = StoreKitService()
        container.register(StoreKitService.self) { _ in storeKitService }
            .inObjectScope(.container)
        
        let entitlementRepository = StoreKitEntitlementRepository(modelContainer: modelContainer, storeKitService: storeKitService)
        container.register(EntitlementRepository.self) { _ in entitlementRepository }
            .inObjectScope(.container)
        
        // Feature Gating Use Case
        let aiUsageTracker = SimpleAIUsageTracker()
        container.register(AIUsageTracking.self) { _ in aiUsageTracker }
            .inObjectScope(.container)
        
        container.register(FeatureGating.self) { resolver in
            FeatureGatingUseCase(
                entitlementRepository: resolver.resolve(EntitlementRepository.self)!,
                usageTracker: resolver.resolve(AIUsageTracking.self)
            )
        }.inObjectScope(.container)

        // ========== REMOTE CONFIG & FEATURE FLAGS ==========

        // Remote Config Service - wraps Firebase Remote Config
        let remoteConfigService = RemoteConfigService()
        container.register(RemoteConfigServicing.self) { _ in remoteConfigService }
            .inObjectScope(.container)

        // Feature Flag Repository - provides feature flag access with caching
        container.register(FeatureFlagRepository.self) { resolver in
            RemoteConfigFeatureFlagRepository(
                remoteConfigService: resolver.resolve(RemoteConfigServicing.self)!
            )
        }
        .inObjectScope(.container)

        // Feature Flag Use Case - combines feature flags with entitlement
        container.register(FeatureFlagChecking.self) { resolver in
            FeatureFlagUseCase(
                featureFlagRepository: resolver.resolve(FeatureFlagRepository.self)!,
                featureGating: resolver.resolve(FeatureGating.self)!
            )
        }
        .inObjectScope(.container)

        // ========== END REMOTE CONFIG & FEATURE FLAGS ==========

        // Wger Exercise Service (Free API - no API key needed)
        let wgerService = WgerAPIService()
        container.register(ExerciseServiceProtocol.self) { _ in wgerService }
            .inObjectScope(.container)
        container.register(WgerAPIService.self) { _ in wgerService }
            .inObjectScope(.container)

        // Workout Blocks Repository
        let blocksRepository = BundleWorkoutBlocksRepository()
        container.register(WorkoutBlocksRepository.self) { _ in blocksRepository }
            .inObjectScope(.container)

        // Library Workouts Repository - Using enriched repository for Wger media/images
        let enrichedLibraryRepository = WgerEnrichedLibraryWorkoutsRepository(
            baseRepository: BundleLibraryWorkoutsRepository(),
            wgerService: wgerService
        )
        container.register(LibraryWorkoutsRepository.self) { _ in enrichedLibraryRepository }
            .inObjectScope(.container)
        container.register(WgerEnrichedLibraryWorkoutsRepository.self) { _ in enrichedLibraryRepository }
            .inObjectScope(.container)

        // ProgramRepository - carrega programas do bundle
        let programRepository = BundleProgramRepository()
        container.register(ProgramRepository.self) { _ in programRepository }
            .inObjectScope(.container)

        // WgerProgramWorkoutRepository - carrega exercícios Wger para programas
        let wgerProgramWorkoutRepository = DefaultWgerProgramWorkoutRepository(wgerService: wgerService)
        container.register(WgerProgramWorkoutRepository.self) { _ in wgerProgramWorkoutRepository }
            .inObjectScope(.container)

        // ProgramWorkoutCustomizationRepository - salva customizações do usuário (ordem, exclusões)
        let customizationRepository = UserDefaultsProgramWorkoutCustomizationRepository()
        container.register(ProgramWorkoutCustomizationRepositoryProtocol.self) { _ in customizationRepository }
            .inObjectScope(.container)

        // LoadProgramWorkoutsUseCase - carrega treinos de programa com exercícios Wger
        container.register(LoadProgramWorkoutsUseCase.self) { resolver in
            LoadProgramWorkoutsUseCase(
                programRepository: resolver.resolve(ProgramRepository.self)!,
                workoutRepository: resolver.resolve(WgerProgramWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        // Workout Composition - New simplified OpenAI stack
        // Enhanced local composer with variation validation
        let historyRepo = container.resolve(WorkoutHistoryRepository.self)!
        let enhancedLocalComposer = EnhancedLocalWorkoutPlanComposer(
            historyRepository: historyRepo
        )
        container.register(EnhancedLocalWorkoutPlanComposer.self) { _ in enhancedLocalComposer }
            .inObjectScope(.container)

        // WorkoutPlanComposing: Use OpenAI if available, otherwise enhanced local
        container.register(WorkoutPlanComposing.self) { resolver in
            let historyRepository = resolver.resolve(WorkoutHistoryRepository.self)!

            // Try to create OpenAI composer if API key is configured
            if let client = NewOpenAIClient.fromUserKey() {
                return NewOpenAIWorkoutComposer(
                    client: client,
                    localFallback: enhancedLocalComposer,
                    historyRepository: historyRepository
                )
            } else {
                // No API key - use enhanced local composer
                return enhancedLocalComposer
            }
        }
        .inObjectScope(.container)
        
        // HealthKit (iPhone) - serviço de integração (PRO gating é feito na UI/fluxos)
        let healthKitService = HealthKitService()
        container.register(HealthKitServicing.self) { _ in healthKitService }
            .inObjectScope(.container)
        
        // Note: HealthKitHistorySyncService is registered later after SyncWorkoutCompletionUseCase is available

        // HealthKit Workout Sync Use Case - auto-exports workouts and imports calories
        container.register(SyncWorkoutWithHealthKitUseCase.self) { resolver in
            SyncWorkoutWithHealthKitUseCase(
                healthKitService: resolver.resolve(HealthKitServicing.self)!,
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!
            )
        }
        .inObjectScope(.container)

        // AI Chat Service (FitPal) - wraps OpenAI for conversational mode
        container.register(AIChatService.self) { resolver in
            try! AIChatService(resolver: resolver)
        }
        .inObjectScope(.container)

        // Firebase Analytics Service
        let analyticsService = FirebaseAnalyticsService()
        container.register(AnalyticsTracking.self) { _ in analyticsService }
            .inObjectScope(.container)

        // Firebase Authentication
        let firebaseAuthService = FirebaseAuthService()
        container.register(FirebaseAuthService.self) { _ in firebaseAuthService }
            .inObjectScope(.container)

        container.register(AuthenticationRepository.self) { resolver in
            FirebaseAuthenticationRepository(
                authService: resolver.resolve(FirebaseAuthService.self)!
            )
        }
        .inObjectScope(.container)

        // Firebase Group Management
        let firebaseGroupService = FirebaseGroupService()
        container.register(FirebaseGroupService.self) { _ in firebaseGroupService }
            .inObjectScope(.container)

        container.register(GroupRepository.self) { resolver in
            FirebaseGroupRepository(
                groupService: resolver.resolve(FirebaseGroupService.self)!
            )
        }
        .inObjectScope(.container)

        // Firebase User Repository
        let firebaseUserService = FirebaseUserService()
        container.register(FirebaseUserService.self) { _ in firebaseUserService }
            .inObjectScope(.container)

        container.register(UserRepository.self) { resolver in
            FirebaseUserRepository(
                userService: resolver.resolve(FirebaseUserService.self)!
            )
        }
        .inObjectScope(.container)

        // Firebase Notification Service and Repository
        let firebaseNotificationService = FirebaseNotificationService()
        container.register(FirebaseNotificationService.self) { _ in firebaseNotificationService }
            .inObjectScope(.container)

        container.register(NotificationRepository.self) { resolver in
            FirebaseNotificationRepository(
                notificationService: resolver.resolve(FirebaseNotificationService.self)!
            )
        }
        .inObjectScope(.container)

        // Group Management Use Cases
        container.register(CreateGroupUseCase.self) { resolver in
            CreateGroupUseCase(
                groupRepository: resolver.resolve(GroupRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                analytics: resolver.resolve(AnalyticsTracking.self)
            )
        }
        .inObjectScope(.container)

        container.register(JoinGroupUseCase.self) { resolver in
            JoinGroupUseCase(
                groupRepository: resolver.resolve(GroupRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                notificationRepository: resolver.resolve(NotificationRepository.self),
                analytics: resolver.resolve(AnalyticsTracking.self)
            )
        }
        .inObjectScope(.container)

        container.register(LeaveGroupUseCase.self) { resolver in
            LeaveGroupUseCase(
                groupRepository: resolver.resolve(GroupRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                analytics: resolver.resolve(AnalyticsTracking.self)
            )
        }
        .inObjectScope(.container)

        container.register(GenerateInviteLinkUseCase.self) { _ in
            GenerateInviteLinkUseCase()
        }
        .inObjectScope(.container)

        // Firebase Leaderboard
        let firebaseLeaderboardService = FirebaseLeaderboardService()
        container.register(FirebaseLeaderboardService.self) { _ in firebaseLeaderboardService }
            .inObjectScope(.container)

        container.register(LeaderboardRepository.self) { resolver in
            FirebaseLeaderboardRepository(
                leaderboardService: resolver.resolve(FirebaseLeaderboardService.self)!
            )
        }
        .inObjectScope(.container)

        // Firebase Group Streak
        let firebaseGroupStreakService = FirebaseGroupStreakService()
        container.register(FirebaseGroupStreakService.self) { _ in firebaseGroupStreakService }
            .inObjectScope(.container)

        container.register(GroupStreakRepository.self) { resolver in
            FirebaseGroupStreakRepository(
                streakService: resolver.resolve(FirebaseGroupStreakService.self)!,
                groupService: resolver.resolve(FirebaseGroupService.self)!
            )
        }
        .inObjectScope(.container)

        // Update Group Streak Use Case
        container.register(UpdateGroupStreakUseCaseProtocol.self) { resolver in
            UpdateGroupStreakUseCase(
                groupStreakRepository: resolver.resolve(GroupStreakRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                notificationRepository: resolver.resolve(NotificationRepository.self)
            )
        }
        .inObjectScope(.container)

        // Pause Group Streak Use Case
        container.register(PauseGroupStreakUseCaseProtocol.self) { resolver in
            PauseGroupStreakUseCase(
                groupStreakRepository: resolver.resolve(GroupStreakRepository.self)!,
                groupRepository: resolver.resolve(GroupRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!
            )
        }
        .inObjectScope(.container)

        // Offline Sync Queue - buffers workout completions when offline
        let pendingSyncQueue = PendingSyncQueue()
        container.register(PendingSyncQueue.self) { _ in pendingSyncQueue }
            .inObjectScope(.container)

        // Network Monitor - detects connectivity changes
        let networkMonitor = NetworkMonitor()
        container.register(NetworkMonitor.self) { _ in networkMonitor }
            .inObjectScope(.container)

        // Workout Sync Use Case - syncs workout completion to Firebase leaderboard
        container.register(SyncWorkoutCompletionUseCase.self) { resolver in
            SyncWorkoutCompletionUseCase(
                leaderboardRepository: resolver.resolve(LeaderboardRepository.self)!,
                userRepository: resolver.resolve(UserRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!,
                updateGroupStreakUseCase: resolver.resolve(UpdateGroupStreakUseCaseProtocol.self),
                pendingQueue: resolver.resolve(PendingSyncQueue.self),
                analytics: resolver.resolve(AnalyticsTracking.self)
            )
        }
        .inObjectScope(.container)

        // ========== CHECK-IN SERVICES ==========

        // Firebase Storage Service - uploads check-in photos
        let firebaseStorageService = FirebaseStorageService()
        container.register(StorageServicing.self) { _ in firebaseStorageService }
            .inObjectScope(.container)

        // Image Compressor - compresses photos before upload
        let imageCompressor = ImageCompressor()
        container.register(ImageCompressing.self) { _ in imageCompressor }
            .inObjectScope(.container)

        // Check-In Repository - manages check-in persistence
        container.register(CheckInRepository.self) { resolver in
            FirebaseCheckInRepository(
                storageService: resolver.resolve(StorageServicing.self)!
            )
        }
        .inObjectScope(.container)

        // Check-In Use Case - handles check-in business logic
        container.register(CheckInUseCase.self) { resolver in
            CheckInUseCase(
                checkInRepository: resolver.resolve(CheckInRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                leaderboardRepository: resolver.resolve(LeaderboardRepository.self)!,
                imageCompressor: resolver.resolve(ImageCompressing.self)!
            )
        }
        .inObjectScope(.container)

        // ========== END CHECK-IN SERVICES ==========

        // HealthKit History Sync - imports workouts from Apple Health and syncs to challenges
        container.register(HealthKitHistorySyncService.self) { resolver in
            HealthKitHistorySyncService(
                healthKit: resolver.resolve(HealthKitServicing.self)!,
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!,
                syncWorkoutUseCase: resolver.resolve(SyncWorkoutCompletionUseCase.self)
            )
        }
        .inObjectScope(.container)

        // Save Workout Rating Use Case
        container.register(SaveWorkoutRatingUseCase.self) { resolver in
            SaveWorkoutRatingUseCase(
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!
            )
        }
        .inObjectScope(.container)

        // User Stats Calculator - computes streaks, weekly/monthly aggregates
        let statsCalculator = UserStatsCalculator()
        container.register(UserStatsCalculating.self) { _ in statsCalculator }
            .inObjectScope(.container)

        // Update User Stats Use Case - updates stats after workout completion
        container.register(UpdateUserStatsUseCase.self) { resolver in
            UpdateUserStatsUseCase(
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!,
                statsRepository: resolver.resolve(UserStatsRepository.self)!,
                calculator: resolver.resolve(UserStatsCalculating.self)!
            )
        }
        .inObjectScope(.container)

        // ========== CUSTOM WORKOUT (Treinos Dinâmicos) ==========

        // Custom Workout Repository
        container.register(CustomWorkoutRepository.self) { _ in
            SwiftDataCustomWorkoutRepository(modelContainer: modelContainer)
        }
        .inObjectScope(.container)

        // Save Custom Workout Use Case
        container.register(SaveCustomWorkoutUseCase.self) { resolver in
            SaveCustomWorkoutUseCase(
                repository: resolver.resolve(CustomWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        // Complete Custom Workout Use Case
        container.register(CompleteCustomWorkoutUseCase.self) { resolver in
            CompleteCustomWorkoutUseCase(
                repository: resolver.resolve(CustomWorkoutRepository.self)!,
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!,
                syncWorkoutUseCase: resolver.resolve(SyncWorkoutCompletionUseCase.self)
            )
        }
        .inObjectScope(.container)

        // ========== SAVED ROUTINES (Minhas Rotinas) ==========

        // Saved Routine Repository - persists user's saved program routines
        container.register(SavedRoutineRepository.self) { _ in
            SwiftDataSavedRoutineRepository(modelContainer: modelContainer)
        }
        .inObjectScope(.container)

        // ========== PERSONAL TRAINER CMS INTEGRATION ==========

        // Personal Trainer Firebase Service (still used for relationships)
        let personalTrainerService = FirebasePersonalTrainerService()
        container.register(FirebasePersonalTrainerService.self) { _ in personalTrainerService }
            .inObjectScope(.container)

        // CMS Trainer Service - REST API client for trainer marketplace
        let cmsTrainerService = CMSTrainerService()
        container.register(CMSTrainerService.self) { _ in cmsTrainerService }
            .inObjectScope(.container)

        // Personal Trainer Repository — CMS-backed (marketplace, profiles, search)
        container.register(PersonalTrainerRepository.self) { resolver in
            CMSPersonalTrainerRepository(
                service: resolver.resolve(CMSTrainerService.self)!
            )
        }
        .inObjectScope(.container)

        // Trainer Student Repository (same implementation, different protocol)
        container.register(TrainerStudentRepository.self) { resolver in
            FirebasePersonalTrainerRepository(
                service: resolver.resolve(FirebasePersonalTrainerService.self)!
            )
        }
        .inObjectScope(.container)

        // Trainer Workout Firebase Service
        let trainerWorkoutService = FirebaseTrainerWorkoutService()
        container.register(FirebaseTrainerWorkoutService.self) { _ in trainerWorkoutService }
            .inObjectScope(.container)

        // Trainer Workout Repository
        container.register(TrainerWorkoutRepository.self) { resolver in
            FirebaseTrainerWorkoutRepository(
                service: resolver.resolve(FirebaseTrainerWorkoutService.self)!
            )
        }
        .inObjectScope(.container)

        // Personal Trainer Use Cases (registered as protocols for ViewModel resolution)
        container.register(DiscoverTrainersUseCaseProtocol.self) { resolver in
            DiscoverTrainersUseCase(
                repository: resolver.resolve(PersonalTrainerRepository.self)!,
                featureFlagChecker: resolver.resolve(FeatureFlagChecking.self)!
            )
        }
        .inObjectScope(.container)

        container.register(RequestTrainerConnectionUseCaseProtocol.self) { resolver in
            RequestTrainerConnectionUseCase(
                trainerStudentRepository: resolver.resolve(TrainerStudentRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                featureFlagChecker: resolver.resolve(FeatureFlagChecking.self)!
            )
        }
        .inObjectScope(.container)

        container.register(CancelTrainerConnectionUseCaseProtocol.self) { resolver in
            CancelTrainerConnectionUseCase(
                trainerStudentRepository: resolver.resolve(TrainerStudentRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                featureFlagChecker: resolver.resolve(FeatureFlagChecking.self)!
            )
        }
        .inObjectScope(.container)

        container.register(GetCurrentTrainerUseCaseProtocol.self) { resolver in
            GetCurrentTrainerUseCase(
                trainerRepository: resolver.resolve(PersonalTrainerRepository.self)!,
                trainerStudentRepository: resolver.resolve(TrainerStudentRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                featureFlagChecker: resolver.resolve(FeatureFlagChecking.self)!
            )
        }
        .inObjectScope(.container)

        container.register(FetchAssignedWorkoutsUseCaseProtocol.self) { resolver in
            FetchAssignedWorkoutsUseCase(
                trainerWorkoutRepository: resolver.resolve(TrainerWorkoutRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!,
                featureFlagChecker: resolver.resolve(FeatureFlagChecking.self)!
            )
        }
        .inObjectScope(.container)

        // ========== END PERSONAL TRAINER CMS INTEGRATION ==========

        // ========== CMS WORKOUT API INTEGRATION ==========

        // CMS Workout Service - REST API client
        let cmsWorkoutService = CMSWorkoutService()
        container.register(CMSWorkoutService.self) { _ in cmsWorkoutService }
            .inObjectScope(.container)

        // CMS Workout Repository
        container.register(CMSWorkoutRepository.self) { resolver in
            CMSWorkoutRepositoryImpl(
                service: resolver.resolve(CMSWorkoutService.self)!
            )
        }
        .inObjectScope(.container)

        // CMS Workout Use Cases
        container.register(FetchCMSWorkoutsUseCase.self) { resolver in
            FetchCMSWorkoutsUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!,
                authRepository: resolver.resolve(AuthenticationRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(FetchCMSWorkoutDetailUseCase.self) { resolver in
            FetchCMSWorkoutDetailUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(FetchWorkoutProgressUseCase.self) { resolver in
            FetchWorkoutProgressUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(FetchWorkoutFeedbackUseCase.self) { resolver in
            FetchWorkoutFeedbackUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(PostWorkoutFeedbackUseCase.self) { resolver in
            PostWorkoutFeedbackUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(CompleteCMSWorkoutUseCase.self) { resolver in
            CompleteCMSWorkoutUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        container.register(ArchiveCMSWorkoutUseCase.self) { resolver in
            ArchiveCMSWorkoutUseCase(
                repository: resolver.resolve(CMSWorkoutRepository.self)!
            )
        }
        .inObjectScope(.container)

        // ========== END CMS WORKOUT API INTEGRATION ==========

        // ========== PERSONAL WORKOUTS (Treinos do Personal) ==========

        // PDF Cache Service - caches downloaded PDFs locally
        let pdfCacheService = PDFCacheService()
        container.register(PDFCaching.self) { _ in pdfCacheService }
            .inObjectScope(.container)

        // Personal Workout Repository - fetches trainer-submitted workouts from Firebase
        container.register(PersonalWorkoutRepository.self) { _ in
            FirebasePersonalWorkoutRepository()
        }
        .inObjectScope(.container)

        // ========== END PERSONAL WORKOUTS ==========

        return AppContainer(container: container, router: router, modelContainer: modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            SDUserProfile.self,
            SDWorkoutHistoryEntry.self,
            SDProEntitlementSnapshot.self,
            SDCachedWorkout.self,
            SDUserStats.self,
            SDCustomWorkoutTemplate.self,
            SDCustomWorkoutCompletion.self,
            SDSavedRoutine.self
        ])
        
        // Configuração com migração automática leve
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            #if DEBUG
            print("[SwiftData] ✅ ModelContainer criado com sucesso")
            #endif
            return container
        } catch {
            // Em caso de erro de migração, logar mas NÃO apagar os dados
            // O usuário deve limpar manualmente se necessário
            #if DEBUG
            print("❌ [SwiftData] Erro ao criar container: \(error.localizedDescription)")
            print("❌ [SwiftData] Se persistir, limpe os dados do app manualmente")
            #endif
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

