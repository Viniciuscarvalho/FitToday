# [7.0] Groups UI & Navigation (L)

## status: pending

<task_context>
<domain>presentation/groups</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>swiftui|navigation|deep_linking</dependencies>
</task_context>

# Task 7.0: Groups UI & Navigation

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the Groups tab UI with group dashboard, create group flow, join group flow, and invite sharing. Implement deep link handling for group invites. Add Groups tab to TabRootView as the 5th tab.

<requirements>
- Add Groups tab (5th tab) to TabRootView with icon person.3.fill
- Create GroupsView with empty state and group dashboard
- Create GroupsViewModel with @Observable pattern
- Implement CreateGroupView with group name input
- Implement JoinGroupView for invite preview and confirmation
- Implement InviteShareSheet with iOS native share sheet
- Add deep link handler for fittoday://group/invite/{groupId}
- Support Universal Links for https://fittoday.app/group/invite/{groupId}
- Follow FitToday's SwiftUI patterns and navigation architecture
</requirements>

## Subtasks

- [ ] 7.1 Add Groups tab to TabRootView
  - Modify `/Presentation/TabRootView.swift`
  - Add `.groups` case to AppTab enum
  - Icon: `person.3.fill`
  - Label: "Groups"

- [ ] 7.2 Create GroupsViewModel
  - `/Presentation/Features/Groups/GroupsViewModel.swift`
  - @MainActor, @Observable
  - Properties: currentGroup, members, isLoading, errorMessage
  - Methods: onAppear(), createGroup(), leaveGroup()
  - Inject use cases via Resolver

- [ ] 7.3 Create GroupsView with conditional rendering
  - `/Presentation/Features/Groups/GroupsView.swift`
  - If no group → show EmptyGroupsView (CTA: "Create Your First Group")
  - If has group → show GroupDashboardView (group name, members, leaderboards placeholder)

- [ ] 7.4 Create EmptyGroupsView
  - Illustration/icon for empty state
  - Text: "Train together, stay motivated"
  - Button: "Create Your First Group"
  - Navigates to CreateGroupView

- [ ] 7.5 Create CreateGroupView
  - Modal sheet with text field for group name
  - "Create" button (disabled if name empty)
  - Calls CreateGroupUseCase
  - Dismisses on success, navigates to GroupDashboardView

- [ ] 7.6 Create CreateGroupViewModel
  - @MainActor, @Observable
  - Property: groupName (bindable)
  - Method: createGroup() async
  - Error handling

- [ ] 7.7 Create GroupDashboardView
  - Display group name and member count
  - List of members (name + avatar/initials)
  - "Invite Friends" button → opens InviteShareSheet
  - "..." menu → Leave Group, Manage Group (admin only)
  - Placeholder for leaderboards (will add in Task 10.0)

- [ ] 7.8 Create InviteShareSheet
  - Wraps UIActivityViewController (iOS Share Sheet)
  - Generate invite URL via GenerateInviteLinkUseCase
  - Pre-fill message: "Join my fitness group on FitToday: [link]"
  - ShareLink API for SwiftUI (iOS 16+)

- [ ] 7.9 Implement JoinGroupView
  - Shows group preview (name, member count)
  - "Join [Group Name]" button
  - "Cancel" button
  - Calls JoinGroupUseCase on confirmation
  - Navigates to GroupDashboardView on success

- [ ] 7.10 Create JoinGroupViewModel
  - @MainActor, @Observable
  - Property: groupPreview (Group?)
  - Method: loadGroupPreview(groupId) async
  - Method: joinGroup(groupId) async

- [ ] 7.11 Add deep link routes to AppRoute
  - `/Presentation/Router/AppRoute.swift`
  - Add `.groupInviteAuth(groupId: String)` - for unauthenticated users
  - Add `.groupInvitePreview(groupId: String)` - for authenticated users
  - Add `.createGroup`

- [ ] 7.12 Implement deep link handler in AppRouter
  - Modify `/Presentation/Router/AppRouter.swift`
  - Parse URL: `fittoday://group/invite/{groupId}`
  - Check authentication state
  - If authenticated → navigate to `.groupInvitePreview`
  - If not authenticated → navigate to `.groupInviteAuth` (show auth with context)

- [ ] 7.13 Configure Universal Links (optional for MVP)
  - Add Associated Domains capability in Xcode
  - Domain: `fittoday.app`
  - Upload apple-app-site-association file to server
  - Handle https://fittoday.app/group/invite/{groupId}

## Implementation Details

Reference **techspec.md** sections:
- "Presentation Layer" component overview
- "Integration Points > Deep Linking for Invites"
- PRD section: "Main User Flows"

### GroupsView Structure
```swift
struct GroupsView: View {
  @State private var viewModel: GroupsViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.currentGroup == nil {
          EmptyGroupsView(onCreateTapped: {
            // Navigate to CreateGroupView
          })
        } else {
          GroupDashboardView(
            group: viewModel.currentGroup!,
            members: viewModel.members,
            onInviteTapped: {
              // Show InviteShareSheet
            },
            onLeaveTapped: {
              Task { await viewModel.leaveGroup() }
            }
          )
        }
      }
      .navigationTitle("Groups")
      .toolbar {
        if viewModel.currentGroup != nil {
          ToolbarItem(placement: .primaryAction) {
            Menu {
              Button("Invite Friends", systemImage: "person.badge.plus") { }
              if viewModel.isAdmin {
                Button("Manage Group", systemImage: "gearshape") { }
              }
              Button("Leave Group", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) { }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
      }
    }
    .task {
      await viewModel.onAppear()
    }
  }
}
```

### Deep Link Handling
```swift
// In FitTodayApp.swift or AppRouter
.onOpenURL { url in
  if let deepLink = DeepLink(url: url) {
    switch deepLink.destination {
    case .groupInvite(let groupId):
      Task {
        await handleGroupInvite(groupId: groupId)
      }
    }
  }
}

private func handleGroupInvite(groupId: String) async {
  guard let authRepo = resolver.resolve(AuthenticationRepository.self) else { return }

  let currentUser = try? await authRepo.currentUser()
  if currentUser == nil {
    router.navigate(to: .groupInviteAuth(groupId: groupId))
  } else {
    router.navigate(to: .groupInvitePreview(groupId: groupId))
  }
}
```

## Success Criteria

- [ ] Groups tab appears in TabBar as 5th tab with correct icon
- [ ] Empty state shows when user has no group
- [ ] "Create Your First Group" button navigates to CreateGroupView
- [ ] User can create group with custom name
- [ ] Group dashboard shows group name, member count, and member list
- [ ] "Invite Friends" button opens iOS share sheet with pre-filled message
- [ ] Tapping invite link (fittoday://) opens app and shows JoinGroupView
- [ ] Authenticated user sees group preview before joining
- [ ] Unauthenticated user sees auth screen with "Sign up to join [Group Name]" context
- [ ] After joining, user sees GroupDashboardView with updated members
- [ ] Leave Group removes user and shows empty state again

## Dependencies

**Before starting this task:**
- Task 6.0 (Group Management Use Cases) must provide use cases
- Task 3.0 (Authentication UI) must provide authentication flows
- Existing AppRouter and TabRootView infrastructure

**Blocks these tasks:**
- Task 10.0 (Leaderboard UI) - will be integrated into GroupDashboardView
- Task 14.0 (Notifications) - will show badges on Groups tab

## Notes

- **Empty State Design**: Keep it simple and encouraging. Use encouraging copy like "Train together, stay motivated".
- **Share Sheet**: Use SwiftUI `ShareLink` for iOS 16+, fallback to `UIActivityViewController` wrapper for iOS 15.
- **Universal Links**: Optional for MVP. Deep link scheme `fittoday://` works for direct app opens.
- **Navigation**: Use NavigationStack (iOS 16+) for modern SwiftUI navigation.
- **Member Avatars**: If photoURL nil, show initials in colored circle (use first letter of displayName).
- **Admin Badge**: Show "Admin" badge next to creator's name in member list.

## Validation Steps

1. Launch app → tap Groups tab → see empty state
2. Tap "Create Your First Group" → modal appears
3. Enter name "Gym Bros" → tap Create → group created, dashboard shows
4. Tap "Invite Friends" → iOS share sheet appears with link
5. Copy link and paste in Notes app → tap link → app opens, shows JoinGroupView
6. Tap "Join" → user added, dashboard updates
7. Tap "..." menu → tap "Leave Group" → confirmation alert → leave → empty state again
8. Test unauthenticated: Sign out, tap invite link → auth screen shows "Sign up to join Gym Bros"

## Relevant Files

### Files to Create
- `/Presentation/Features/Groups/GroupsView.swift`
- `/Presentation/Features/Groups/GroupsViewModel.swift`
- `/Presentation/Features/Groups/EmptyGroupsView.swift`
- `/Presentation/Features/Groups/GroupDashboardView.swift`
- `/Presentation/Features/Groups/CreateGroupView.swift`
- `/Presentation/Features/Groups/CreateGroupViewModel.swift`
- `/Presentation/Features/Groups/JoinGroupView.swift`
- `/Presentation/Features/Groups/JoinGroupViewModel.swift`
- `/Presentation/Features/Groups/InviteShareSheet.swift`

### Files to Modify
- `/Presentation/TabRootView.swift` - Add .groups tab
- `/Presentation/Router/AppTab.swift` - Add .groups enum case
- `/Presentation/Router/AppRoute.swift` - Add deep link routes
- `/Presentation/Router/AppRouter.swift` - Handle deep links
- `/FitTodayApp.swift` - Add .onOpenURL handler
- `/Presentation/DI/AppContainer.swift` - Register use cases and ViewModels

### External Resources
- ShareLink API: https://developer.apple.com/documentation/swiftui/sharelink
- Universal Links: https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app
