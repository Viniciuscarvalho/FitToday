//
//  PrivacySettingsViewModel.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation
import Swinject

// MARK: - PrivacySettingsViewModel

@MainActor
@Observable final class PrivacySettingsViewModel {
    var shareWorkoutData: Bool = true
    var healthKitSyncEnabled: Bool = false
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: ErrorMessage?

    private let userRepository: UserRepository?
    private let authRepository: AuthenticationRepository?
    private let healthKitService: HealthKitServicing?
    private var currentUserId: String?

    private static let healthKitSyncKey = "healthKitSyncEnabled"

    init(resolver: Resolver) {
        self.userRepository = resolver.resolve(UserRepository.self)
        self.authRepository = resolver.resolve(AuthenticationRepository.self)
        self.healthKitService = resolver.resolve(HealthKitServicing.self)

        // Load HealthKit preference from UserDefaults
        self.healthKitSyncEnabled = UserDefaults.standard.bool(forKey: Self.healthKitSyncKey)
    }

    // MARK: - Load Settings

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let user = try await authRepository?.currentUser() else {
                shareWorkoutData = true // Default value
                return
            }
            currentUserId = user.id
            shareWorkoutData = user.privacySettings.shareWorkoutData
        } catch {
            errorMessage = ErrorMessage(title: "Erro", message: "Falha ao carregar configurações")
            #if DEBUG
            print("[PrivacySettings] Failed to load: \(error)")
            #endif
        }
    }

    // MARK: - Update Settings

    func updateSettings() async {
        guard let userId = currentUserId,
              let userRepo = userRepository else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let newSettings = PrivacySettings(shareWorkoutData: shareWorkoutData)
            try await userRepo.updatePrivacySettings(userId, settings: newSettings)
            #if DEBUG
            print("[PrivacySettings] Updated shareWorkoutData to: \(shareWorkoutData)")
            #endif
        } catch {
            errorMessage = ErrorMessage(title: "Erro", message: "Falha ao salvar configurações")
            #if DEBUG
            print("[PrivacySettings] Failed to update: \(error)")
            #endif
        }
    }

    // MARK: - HealthKit Sync

    func updateHealthKitSync(enabled: Bool) async {
        // If enabling, request HealthKit authorization first
        if enabled {
            guard let healthKit = healthKitService else {
                errorMessage = ErrorMessage(title: "Erro", message: "HealthKit não disponível")
                healthKitSyncEnabled = false
                return
            }

            let authState = await healthKit.authorizationState()

            if authState == .notAvailable {
                errorMessage = ErrorMessage(title: "Indisponível", message: "HealthKit não está disponível neste dispositivo")
                healthKitSyncEnabled = false
                return
            }

            if authState == .notDetermined || authState == .denied {
                do {
                    try await healthKit.requestAuthorization()
                    #if DEBUG
                    print("[PrivacySettings] HealthKit authorization granted")
                    #endif
                } catch {
                    errorMessage = ErrorMessage(title: "Permissão Negada", message: "Permita acesso ao Apple Health em Configurações para sincronizar treinos")
                    healthKitSyncEnabled = false
                    #if DEBUG
                    print("[PrivacySettings] HealthKit authorization failed: \(error)")
                    #endif
                    return
                }
            }
        }

        // Save preference to UserDefaults
        UserDefaults.standard.set(enabled, forKey: Self.healthKitSyncKey)
        healthKitSyncEnabled = enabled

        #if DEBUG
        print("[PrivacySettings] HealthKit sync \(enabled ? "enabled" : "disabled")")
        #endif
    }
}
