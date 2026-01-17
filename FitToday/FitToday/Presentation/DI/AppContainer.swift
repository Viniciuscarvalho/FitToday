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
        
        // Workout Composition Cache (F7)
        container.register(WorkoutCompositionCacheRepository.self) { _ in
            SwiftDataWorkoutCompositionCacheRepository(modelContainer: modelContainer)
        }.inObjectScope(.container)

        // WorkoutBlocksRepository é registrado após configurar ExerciseDB (para permitir enriquecimento de mídia/instruções).

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

        // ExerciseDB Service e Media Resolver
        // Usa chave do usuário (Keychain) se disponível, fallback para plist (legado)
        let exerciseDBConfig = ExerciseDBConfiguration.loadFromUserKey() ?? ExerciseDBConfiguration.loadFromBundle()
        container.register(ExerciseDBConfiguration?.self) { _ in exerciseDBConfig }
            .inObjectScope(.container)

        if let config = exerciseDBConfig {
            let exerciseDBService = ExerciseDBService(configuration: config)
            container.register(ExerciseDBServicing.self) { _ in exerciseDBService }
                .inObjectScope(.container)

            let targetCatalog = ExerciseDBTargetCatalog(service: exerciseDBService)
            container.register(ExerciseDBTargetCataloging.self) { _ in targetCatalog }
                .inObjectScope(.container)

            // 💡 Learn: ExerciseNameNormalizer para normalização de nomes de exercícios
            let exerciseNameNormalizer = ExerciseNameNormalizer(exerciseDBService: exerciseDBService)
            container.register(ExerciseNameNormalizing.self) { _ in exerciseNameNormalizer }
                .inObjectScope(.container)

            let mediaResolver = ExerciseMediaResolver(
                service: exerciseDBService,
                targetCatalog: targetCatalog,
                baseURL: config.baseURL
            )
            container.register(ExerciseMediaResolving.self) { _ in mediaResolver }
                .inObjectScope(.container)

            let blocksRepository = BundleWorkoutBlocksRepository(mediaResolver: mediaResolver, exerciseService: exerciseDBService)
            container.register(WorkoutBlocksRepository.self) { _ in blocksRepository }
                .inObjectScope(.container)

            let libraryRepository = BundleLibraryWorkoutsRepository(mediaResolver: mediaResolver)
            container.register(LibraryWorkoutsRepository.self) { _ in libraryRepository }
                .inObjectScope(.container)
        } else {
            // Sem configuração, usa resolver sem serviço (apenas fallback/placeholder)
            let mediaResolver = ExerciseMediaResolver(service: nil as (any ExerciseDBServicing)?)
            container.register(ExerciseMediaResolving.self) { _ in mediaResolver }
                .inObjectScope(.container)
            #if DEBUG
            print("[AppContainer] ExerciseDB não configurado - usando apenas fallback local")
            #endif

            let blocksRepository = BundleWorkoutBlocksRepository()
            container.register(WorkoutBlocksRepository.self) { _ in blocksRepository }
                .inObjectScope(.container)

            let libraryRepository = BundleLibraryWorkoutsRepository(mediaResolver: mediaResolver)
            container.register(LibraryWorkoutsRepository.self) { _ in libraryRepository }
                .inObjectScope(.container)
        }

        // ProgramRepository - carrega programas do bundle
        let programRepository = BundleProgramRepository()
        container.register(ProgramRepository.self) { _ in programRepository }
            .inObjectScope(.container)

        // OpenAI - Usa chave do usuário (armazenada no Keychain)
        // O cliente é criado sob demanda quando a chave estiver configurada
        let localComposer = LocalWorkoutPlanComposer()
        container.register(LocalWorkoutPlanComposer.self) { _ in localComposer }
            .inObjectScope(.container)

        let usageLimiter = OpenAIUsageLimiter()
        container.register(OpenAIUsageLimiting.self) { _ in usageLimiter }
            .inObjectScope(.container)

        // WorkoutPlanComposing verifica em tempo de execução se há chave do usuário
        container.register(WorkoutPlanComposing.self) { resolver in
            let entitlementRepo = resolver.resolve(EntitlementRepository.self)
            let historyRepo = resolver.resolve(WorkoutHistoryRepository.self)
            let normalizer = resolver.resolve(ExerciseNameNormalizing.self)
            let mediaResolver = resolver.resolve(ExerciseMediaResolving.self)
            return DynamicHybridWorkoutPlanComposer(
                localComposer: localComposer,
                usageLimiter: usageLimiter,
                exerciseNameNormalizer: normalizer,
                mediaResolver: mediaResolver,
                entitlementProvider: {
                    return (try? await entitlementRepo?.currentEntitlement()) ?? .free
                },
                historyRepository: historyRepo
            )
        }
        .inObjectScope(.container)
        
        // HealthKit (iPhone) - serviço de integração (PRO gating é feito na UI/fluxos)
        let healthKitService = HealthKitService()
        container.register(HealthKitServicing.self) { _ in healthKitService }
            .inObjectScope(.container)
        
        container.register(HealthKitHistorySyncService.self) { resolver in
            HealthKitHistorySyncService(
                healthKit: resolver.resolve(HealthKitServicing.self)!,
                historyRepository: resolver.resolve(WorkoutHistoryRepository.self)!
            )
        }
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

        return AppContainer(container: container, router: router, modelContainer: modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            SDUserProfile.self,
            SDWorkoutHistoryEntry.self,
            SDProEntitlementSnapshot.self,
            SDCachedWorkout.self
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

