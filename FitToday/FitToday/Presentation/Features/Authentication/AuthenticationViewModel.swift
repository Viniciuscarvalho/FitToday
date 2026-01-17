//
//  AuthenticationViewModel.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import AuthenticationServices
import Foundation
import Swinject

@MainActor
@Observable final class AuthenticationViewModel: ErrorPresenting {
    private(set) var isLoading = false
    var errorMessage: ErrorMessage?
    var didAuthenticate = false  // Signal for navigation

    private let authRepository: AuthenticationRepository
    private let resolver: Resolver

    // Apple Sign-In nonce
    private var currentNonce: String?

    init(resolver: Resolver) {
        self.resolver = resolver
        guard let authRepo = resolver.resolve(AuthenticationRepository.self) else {
            fatalError("AuthenticationRepository not registered")
        }
        self.authRepository = authRepo
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Prepare nonce for Apple Sign-In
            if let firebaseAuthRepo = authRepository as? FirebaseAuthenticationRepository {
                currentNonce = await firebaseAuthRepo.prepareAppleSignIn()
            }

            // The actual sign-in will be triggered by ASAuthorizationController
            // This method prepares the state
        } catch {
            handleError(error)
        }
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch result {
            case .success(let authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    throw AuthError.appleSignInFailed(reason: "Invalid credential type")
                }

                if let firebaseAuthRepo = authRepository as? FirebaseAuthenticationRepository {
                    let user = try await firebaseAuthRepo.signInWithAppleCredential(appleIDCredential)
                    await saveUserSession(user)
                }

            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == ASAuthorizationError.errorDomain,
                   nsError.code == ASAuthorizationError.canceled.rawValue {
                    // User cancelled, don't show error
                    return
                }
                throw AuthError.appleSignInFailed(reason: error.localizedDescription)
            }
        } catch {
            handleError(error)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Google Sign-In requires GoogleSignIn SDK integration
            // For MVP, we'll implement this when GoogleSignIn is configured
            errorMessage = ErrorMessage(
                title: "Em breve",
                message: "Google Sign-In será implementado em breve"
            )
        } catch {
            handleError(error)
        }
    }

    // MARK: - Email/Password

    func signInWithEmail(_ email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = ErrorMessage(
                title: "Campos obrigatórios",
                message: "Por favor, preencha email e senha"
            )
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authRepository.signInWithEmail(email, password: password)
            await saveUserSession(user)
        } catch {
            handleError(error)
        }
    }

    func createAccount(email: String, password: String, displayName: String) async {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            errorMessage = ErrorMessage(
                title: "Campos obrigatórios",
                message: "Por favor, preencha todos os campos"
            )
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authRepository.createAccount(
                email: email,
                password: password,
                displayName: displayName
            )
            await saveUserSession(user)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authRepository.signOut()
            UserDefaults.standard.removeObject(forKey: "socialUserId")
        } catch {
            handleError(error)
        }
    }

    // MARK: - Private Helpers

    private func saveUserSession(_ user: SocialUser) {
        UserDefaults.standard.set(user.id, forKey: "socialUserId")

        #if DEBUG
        print("[Auth] ✅ User signed in: \(user.displayName) (\(user.id))")
        #endif
    }
}
