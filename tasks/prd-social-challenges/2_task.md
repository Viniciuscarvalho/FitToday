# [2.0] Firebase Authentication Implementation (L)

## status: pending

<task_context>
<domain>data/services/authentication</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>firebase_auth|apple_signin|google_signin</dependencies>
</task_context>

# Task 2.0: Firebase Authentication Implementation

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement Firebase Authentication with support for Apple Sign-In, Google Sign-In, and Email/Password authentication. This includes creating the service layer, repository implementation, and Firestore user document management.

<requirements>
- Implement FirebaseAuthService actor with all authentication methods
- Create AuthenticationRepository protocol in Domain layer
- Implement FirebaseAuthenticationRepository in Data layer
- Create SocialUser domain entity
- Implement FBUser DTO and mapper
- Enable authentication providers in Firebase Console
- Handle user document creation/update in Firestore
- Follow Swift 6 concurrency (Sendable, actor isolation, async/await)
</requirements>

## Subtasks

- [ ] 2.1 Enable authentication providers in Firebase Console
  - Enable Apple Sign-In provider
  - Enable Google Sign-In provider (configure OAuth client)
  - Enable Email/Password provider

- [ ] 2.2 Create Domain entities and protocols
  - `/Domain/Entities/SocialModels.swift`: SocialUser, AuthProvider, PrivacySettings
  - `/Domain/Protocols/SocialRepositories.swift`: AuthenticationRepository protocol

- [ ] 2.3 Create Firestore DTOs and mappers
  - `/Data/Models/FirebaseModels.swift`: FBUser, FBPrivacySettings
  - `/Data/Mappers/SocialUserMapper.swift`: FBUser ↔ SocialUser mapping

- [ ] 2.4 Implement FirebaseAuthService
  - `/Data/Services/Firebase/FirebaseAuthService.swift`
  - Actor-isolated for thread safety
  - Methods: signInWithApple, signInWithGoogle, signInWithEmail, signOut, currentUser

- [ ] 2.5 Implement Apple Sign-In
  - Import AuthenticationServices framework
  - Generate nonce for security
  - Handle ASAuthorizationController delegate
  - Create Firebase credential from Apple ID token

- [ ] 2.6 Implement Google Sign-In
  - Add GoogleSignIn SDK via SPM (if not using Firebase's built-in)
  - Configure Google OAuth client ID
  - Handle Google Sign-In flow

- [ ] 2.7 Implement Email/Password authentication
  - Sign-in method
  - Sign-up method with email verification (optional for MVP)

- [ ] 2.8 Implement user document management
  - Create/update user document in Firestore /users collection
  - Store: displayName, email, photoURL, authProvider, privacySettings, createdAt

- [ ] 2.9 Create FirebaseAuthenticationRepository
  - `/Data/Repositories/FirebaseAuthenticationRepository.swift`
  - Wraps FirebaseAuthService
  - Conforms to AuthenticationRepository protocol

- [ ] 2.10 Add Apple Sign-In capability to Xcode
  - Enable Sign in with Apple capability
  - Add Sign in with Apple entitlement

## Implementation Details

Reference **techspec.md** section: "Integration Points > Authentication Flow"

### Key Code Structure

See techspec.md for complete implementation of:
- `actor FirebaseAuthService`
- `func signInWithApple() async throws -> SocialUser`
- `func signInWithGoogle() async throws -> SocialUser`
- `func signInWithEmail(_ email: String, password: String) async throws -> SocialUser`
- `private func saveUserToFirestore(_ user: SocialUser) async throws`

### Domain Models
```swift
struct SocialUser: Codable, Hashable, Sendable, Identifiable {
  let id: String // Firebase UID
  var displayName: String
  var email: String?
  var photoURL: URL?
  var authProvider: AuthProvider
  var currentGroupId: String?
  var privacySettings: PrivacySettings
  let createdAt: Date
}

enum AuthProvider: String, Codable, Sendable {
  case apple, google, email
}

struct PrivacySettings: Codable, Hashable, Sendable {
  var shareWorkoutData: Bool // Default: true
}
```

## Success Criteria

- [ ] All three authentication providers work (Apple, Google, Email)
- [ ] User signs in successfully and receives Firebase UID
- [ ] User document created in Firestore /users/{userId} on first sign-in
- [ ] SocialUser entity correctly populated from Firebase Auth + Firestore
- [ ] Sign out clears current user state
- [ ] Code compiles without warnings (Swift 6 strict concurrency)
- [ ] Actor isolation prevents data races
- [ ] Authentication persists across app restarts (Firebase Auth handles this automatically)

## Dependencies

**Before starting this task:**
- Task 1.0 (Firebase SDK Setup) must be complete
- Firebase project must have authentication enabled in Console

**Blocks these tasks:**
- Task 3.0 (Authentication UI) - needs repository to call
- Task 6.0 (Group Management Use Cases) - requires authenticated user
- All tasks requiring user authentication

## Notes

- **Apple Sign-In**: If user selects "Hide My Email", you'll receive a private relay email from Apple
- **Display Name**: Apple may not provide displayName if user doesn't share it. Prompt user to set name during onboarding.
- **Nonce Security**: Always generate cryptographically secure nonce for Apple Sign-In to prevent replay attacks
- **Error Handling**: Wrap Firebase errors in domain-specific DomainError enum
- **Testing**: Use Firebase Auth Emulator for testing (optional, can use real Firebase for MVP)

## Validation Steps

1. Run app and trigger Apple Sign-In → should successfully authenticate
2. Check Firebase Console → Authentication → Users → verify user appears
3. Check Firestore → users collection → verify user document created with correct fields
4. Sign out and sign in again → should retrieve existing user document (not create duplicate)
5. Try Google Sign-In → should work independently
6. Try Email/Password → should create user and sign in

## Relevant Files

### Files to Create
- `/Domain/Entities/SocialModels.swift` - SocialUser, AuthProvider, PrivacySettings
- `/Domain/Protocols/SocialRepositories.swift` - AuthenticationRepository protocol
- `/Data/Models/FirebaseModels.swift` - FBUser, FBPrivacySettings DTOs
- `/Data/Mappers/SocialUserMapper.swift` - Mapping logic
- `/Data/Services/Firebase/FirebaseAuthService.swift` - Core authentication service
- `/Data/Repositories/FirebaseAuthenticationRepository.swift` - Repository implementation

### Files to Modify
- `/FitToday.xcodeproj/project.pbxproj` - Add Sign in with Apple capability
- `/FitToday/Info.plist` - Add URL schemes if needed for Google Sign-In

### Firebase Console Configuration
- Authentication → Sign-in method → Enable Apple, Google, Email/Password providers
- Authentication → Settings → Authorized domains (add your app domain for Universal Links)
