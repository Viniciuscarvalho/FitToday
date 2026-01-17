# [3.0] Authentication UI & Flows (M)

## status: completed

<task_context>
<domain>presentation/authentication</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>swiftui|authentication_repository</dependencies>
</task_context>

# Task 3.0: Authentication UI & Flows

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the authentication UI screens (login/signup) with support for Apple Sign-In, Google Sign-In, and Email/Password. Implement routing logic to show authentication flow when user is not authenticated or when invited to a group.

<requirements>
- Create AuthenticationView with provider selection (Apple, Google, Email)
- Implement AuthenticationViewModel with @Observable pattern
- Handle authentication states (loading, success, error)
- Integrate with AppRouter for navigation
- Support deep link context (e.g., "Sign up to join [Group Name]")
- Display error messages with ErrorPresenting protocol
- Follow FitToday's SwiftUI + @Observable patterns
- Persist socialUserId to UserDefaults on successful auth
</requirements>

## Subtasks

- [ ] 3.1 Create AuthenticationViewModel
  - `/Presentation/Features/Authentication/AuthenticationViewModel.swift`
  - @MainActor, @Observable
  - Conforms to ErrorPresenting
  - Methods: signInWithApple(), signInWithGoogle(), signInWithEmail()

- [ ] 3.2 Create AuthenticationView
  - `/Presentation/Features/Authentication/AuthenticationView.swift`
  - Display app logo and welcome message
  - "Sign in with Apple" button (primary CTA, native style)
  - "Sign in with Google" button (secondary)
  - Email/Password fields with "Sign In" / "Sign Up" toggle
  - Loading state during authentication
  - Error alert display

- [ ] 3.3 Add authentication state to AppRouter
  - Track isAuthenticated state
  - Navigate to authentication when required
  - Support groupInviteAuth(groupId) route for deep links

- [ ] 3.4 Implement deep link authentication context
  - Show message: "Sign up to join [Group Name]" when inviting
  - Pass groupId through authentication flow
  - Auto-redirect to JoinGroupView after successful auth

- [ ] 3.5 Persist authenticated user
  - Save socialUserId to UserDefaults on success
  - Update UserProfile entity to include socialUserId property
  - Load socialUserId on app launch

- [ ] 3.6 Handle authentication errors
  - Display user-friendly error messages
  - Handle common errors: cancelled, network failure, invalid credentials

- [ ] 3.7 Add sign out functionality (basic)
  - Add to Profile tab (temporary - will move to settings later)
  - Clear socialUserId from UserDefaults
  - Navigate back to authentication screen

## Implementation Details

Reference **techspec.md** sections:
- "Integration Points > Authentication Flow"
- "Presentation Layer" component overview

### AuthenticationViewModel Structure
```swift
@MainActor
@Observable final class AuthenticationViewModel: ErrorPresenting {
  private(set) var isLoading = false
  var errorMessage: ErrorMessage?

  private let authRepo: AuthenticationRepository
  private let resolver: Resolver

  init(resolver: Resolver) {
    self.resolver = resolver
    self.authRepo = resolver.resolve(AuthenticationRepository.self)!
  }

  func signInWithApple() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let user = try await authRepo.signInWithApple()
      UserDefaults.standard.set(user.id, forKey: "socialUserId")
      // Navigate to appropriate screen
    } catch {
      handleError(error)
    }
  }

  // Similar methods for Google and Email
}
```

### AuthenticationView Structure
```swift
struct AuthenticationView: View {
  @State private var viewModel: AuthenticationViewModel

  var body: some View {
    VStack(spacing: 24) {
      // Logo and welcome text
      Text("Welcome to FitToday")
        .font(.title)

      // Apple Sign-In button (native)
      SignInWithAppleButton(.signIn) { request in
        // Configure request
      } onCompletion: { result in
        Task {
          await viewModel.signInWithApple()
        }
      }
      .frame(height: 50)

      // Google Sign-In button
      Button("Sign in with Google") {
        Task {
          await viewModel.signInWithGoogle()
        }
      }

      // Email/Password fields (collapsed by default, expand on tap)

      if viewModel.isLoading {
        ProgressView()
      }
    }
    .padding()
    .showErrorAlert(errorMessage: $viewModel.errorMessage)
  }
}
```

## Success Criteria

- [ ] Authentication screen displays correctly with all three provider options
- [ ] Apple Sign-In button uses native SignInWithAppleButton component
- [ ] Successful authentication navigates user to Groups tab
- [ ] Deep link context (group invite) shows "Sign up to join [Group Name]" message
- [ ] After auth from invite, user automatically navigates to JoinGroupView
- [ ] socialUserId persisted to UserDefaults after successful sign-in
- [ ] Error states display user-friendly messages (not raw Firebase errors)
- [ ] Loading state prevents duplicate taps during authentication
- [ ] Sign out clears session and returns to authentication screen

## Dependencies

**Before starting this task:**
- Task 2.0 (Firebase Authentication Implementation) must be complete
- AuthenticationRepository must be available via DI (AppContainer)

**Blocks these tasks:**
- Task 7.0 (Groups UI) - authentication required before accessing groups
- All tasks requiring user to be signed in

## Notes

- **Apple Sign-In Button**: Use native `SignInWithAppleButton` from AuthenticationServices for App Store compliance
- **Google Sign-In UI**: Can use custom button styled per Google's brand guidelines
- **Email/Password**: Consider hiding behind "Sign in with Email" button to reduce visual clutter
- **Error Messages**: Localize error strings for production (out of scope for MVP)
- **Onboarding Flow**: If user signs in for first time, may want to show onboarding (defer to Task 7.0)
- **Biometric Auth**: Face ID / Touch ID can be added post-MVP

## Validation Steps

1. Launch app without existing authentication → should show AuthenticationView
2. Tap "Sign in with Apple" → Apple Sign-In sheet appears
3. Complete Apple authentication → user signed in, navigates to Groups tab
4. Force quit app and relaunch → user still signed in (persisted session)
5. Tap invite link without authentication → shows "Sign up to join [Group Name]"
6. Complete authentication from invite → auto-navigates to JoinGroupView
7. Sign out → returns to AuthenticationView, socialUserId cleared

## Relevant Files

### Files to Create
- `/Presentation/Features/Authentication/AuthenticationView.swift`
- `/Presentation/Features/Authentication/AuthenticationViewModel.swift`

### Files to Modify
- `/Domain/Entities/UserProfile.swift` - Add `socialUserId: String?` property
- `/Presentation/Router/AppRoute.swift` - Add `.authentication`, `.groupInviteAuth(groupId: String)` routes
- `/Presentation/Router/AppRouter.swift` - Add authentication routing logic
- `/Presentation/DI/AppContainer.swift` - Register AuthenticationRepository (if not already done)
- `/Presentation/TabRootView.swift` or `/FitTodayApp.swift` - Show AuthenticationView when not authenticated

### External Resources
- AuthenticationServices framework (for SignInWithAppleButton)
- GoogleSignIn SDK (if using separate Google SDK)
