//
//  FirebaseAuthService.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - FirebaseAuthService

actor FirebaseAuthService {
    private let db = Firestore.firestore()
    private var currentNonce: String?

    // MARK: - Current User

    func getCurrentUser() async throws -> SocialUser? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }

        return try await fetchUserFromFirestore(userId: firebaseUser.uid)
    }

    // MARK: - Apple Sign-In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> SocialUser {
        guard let nonce = currentNonce else {
            throw AuthError.appleSignInFailed(reason: "Invalid state: nonce not set")
        }

        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed(reason: "Unable to fetch identity token")
        }

        let oAuthCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        let authResult = try await Auth.auth().signIn(with: oAuthCredential)
        let firebaseUser = authResult.user

        // Extract display name from credential or Firebase user
        var displayName = "User"
        if let fullName = credential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            let fullNameString = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
            if !fullNameString.isEmpty {
                displayName = fullNameString
            }
        }
        if displayName == "User", let firebaseDisplayName = firebaseUser.displayName, !firebaseDisplayName.isEmpty {
            displayName = firebaseDisplayName
        }

        let socialUser = SocialUser(
            id: firebaseUser.uid,
            displayName: displayName,
            email: firebaseUser.email ?? credential.email,
            photoURL: firebaseUser.photoURL,
            authProvider: .apple,
            currentGroupId: nil,
            privacySettings: PrivacySettings(shareWorkoutData: true),
            createdAt: Date()
        )

        try await saveUserToFirestore(socialUser, isNewUser: authResult.additionalUserInfo?.isNewUser ?? true)
        return try await fetchUserFromFirestore(userId: firebaseUser.uid) ?? socialUser
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> SocialUser {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        let socialUser = SocialUser(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? "User",
            email: firebaseUser.email,
            photoURL: firebaseUser.photoURL,
            authProvider: .google,
            currentGroupId: nil,
            privacySettings: PrivacySettings(shareWorkoutData: true),
            createdAt: Date()
        )

        try await saveUserToFirestore(socialUser, isNewUser: authResult.additionalUserInfo?.isNewUser ?? true)
        return try await fetchUserFromFirestore(userId: firebaseUser.uid) ?? socialUser
    }

    // MARK: - Email/Password Sign-In

    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser {
        let authResult: AuthDataResult
        do {
            authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AuthError.emailSignInFailed(reason: error.localizedDescription)
        }

        let firebaseUser = authResult.user

        guard let user = try await fetchUserFromFirestore(userId: firebaseUser.uid) else {
            throw AuthError.userNotFound
        }

        return user
    }

    // MARK: - Create Account

    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser {
        let authResult: AuthDataResult
        do {
            authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            throw AuthError.emailSignInFailed(reason: error.localizedDescription)
        }

        let firebaseUser = authResult.user

        // Update display name in Firebase Auth
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try? await changeRequest.commitChanges()

        let socialUser = SocialUser(
            id: firebaseUser.uid,
            displayName: displayName,
            email: firebaseUser.email,
            photoURL: nil,
            authProvider: .email,
            currentGroupId: nil,
            privacySettings: PrivacySettings(shareWorkoutData: true),
            createdAt: Date()
        )

        try await saveUserToFirestore(socialUser, isNewUser: true)
        return socialUser
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Auth State Observer

    nonisolated func observeAuthState() -> AsyncStream<User?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user)
            }

            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    // MARK: - Nonce Generation for Apple Sign-In

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Private Helpers

    private func saveUserToFirestore(_ user: SocialUser, isNewUser: Bool) async throws {
        let userRef = db.collection("users").document(user.id)

        if isNewUser {
            try await userRef.setData(user.toDictionary())
        } else {
            // Only update non-critical fields for existing users
            try await userRef.setData([
                "displayName": user.displayName,
                "email": user.email as Any,
                "photoURL": user.photoURL?.absoluteString as Any
            ], merge: true)
        }
    }

    private func fetchUserFromFirestore(userId: String) async throws -> SocialUser? {
        let document = try await db.collection("users").document(userId).getDocument()

        guard document.exists else {
            return nil
        }

        let fbUser = try document.data(as: FBUser.self)
        return fbUser.toDomain()
    }

    // MARK: - Crypto Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
