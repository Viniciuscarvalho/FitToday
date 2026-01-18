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
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: ErrorMessage?

    private let userRepository: UserRepository?
    private let authRepository: AuthenticationRepository?
    private var currentUserId: String?

    init(resolver: Resolver) {
        self.userRepository = resolver.resolve(UserRepository.self)
        self.authRepository = resolver.resolve(AuthenticationRepository.self)
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
}
