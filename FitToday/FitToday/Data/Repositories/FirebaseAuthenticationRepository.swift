//
//  FirebaseAuthenticationRepository.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import AuthenticationServices
import FirebaseAuth
import Foundation

// MARK: - FirebaseAuthenticationRepository

final class FirebaseAuthenticationRepository: AuthenticationRepository, @unchecked Sendable {
    private let authService: FirebaseAuthService

    init(authService: FirebaseAuthService = FirebaseAuthService()) {
        self.authService = authService
    }

    // MARK: - AuthenticationRepository

    func currentUser() async throws -> SocialUser? {
        try await authService.getCurrentUser()
    }

    func signInWithApple() async throws -> SocialUser {
        // This will be called from the UI layer after ASAuthorizationController completes
        // The actual credential handling is done via signInWithAppleCredential
        throw AuthError.appleSignInFailed(reason: "Use signInWithAppleCredential instead")
    }

    func signInWithGoogle() async throws -> SocialUser {
        // This will be called from the UI layer after GoogleSignIn completes
        // The actual credential handling is done via signInWithGoogleTokens
        throw AuthError.googleSignInFailed(reason: "Use signInWithGoogleTokens instead")
    }

    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser {
        try await authService.signInWithEmail(email, password: password)
    }

    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser {
        try await authService.createAccount(email: email, password: password, displayName: displayName)
    }

    func signOut() async throws {
        try await authService.signOut()
    }

    func observeAuthState() -> AsyncStream<SocialUser?> {
        AsyncStream { continuation in
            Task {
                for await firebaseUser in authService.observeAuthState() {
                    if let firebaseUser {
                        do {
                            let socialUser = try await authService.getCurrentUser()
                            continuation.yield(socialUser)
                        } catch {
                            continuation.yield(nil)
                        }
                    } else {
                        continuation.yield(nil)
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Apple Sign-In Specific

    func prepareAppleSignIn() async -> String {
        await authService.prepareAppleSignIn()
    }

    func signInWithAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws -> SocialUser {
        try await authService.signInWithApple(credential: credential)
    }

    // MARK: - Google Sign-In Specific

    func signInWithGoogleTokens(idToken: String, accessToken: String) async throws -> SocialUser {
        try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken)
    }
}
