# [15.0] Group Management Features (M)

## status: pending

<task_context>
<domain>presentation/groups</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>group_repository|use_cases</dependencies>
</task_context>

# Task 15.0: Group Management Features

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement group management features for members and admins: leave group (all members), remove member (admin only), and delete group (admin only). These features are accessible via the "..." menu in GroupDashboardView.

<requirements>
- Add "Leave Group" functionality for all members
- Add "Remove Member" functionality for group admin
- Add "Delete Group" functionality for group admin
- Show confirmation alerts before destructive actions
- Update UI state after actions complete
- Clear currentGroupId when user leaves/removed
- Admin badge visible on group creator in member list
- Follow SwiftUI alert/confirmation patterns
</requirements>

## Subtasks

- [ ] 15.1 Implement Leave Group functionality
  - Add "Leave Group" button in GroupDashboardView toolbar menu
  - Show confirmation alert: "Are you sure? Your stats will be removed from leaderboards."
  - Call LeaveGroupUseCase (created in Task 6.0)
  - Navigate back to empty state after successful leave

- [ ] 15.2 Implement Remove Member functionality (admin only)
  - Add swipe-to-delete on member list rows (admin only)
  - Show confirmation alert: "Remove [Name] from group?"
  - Call GroupRepository.removeMember(groupId, userId)
  - Update member list in UI

- [ ] 15.3 Implement Delete Group functionality (admin only)
  - Add "Delete Group" button in "Manage Group" sheet (admin only)
  - Show confirmation alert: "Delete group? This cannot be undone."
  - Call GroupRepository.deleteGroup(groupId)
  - Clear all members' currentGroupId
  - Navigate all members back to empty state

- [ ] 15.4 Add admin badge to member list
  - Display "Admin" badge next to group creator's name
  - Use role field from GroupMember entity
  - Visual distinction (colored badge, icon)

- [ ] 15.5 Create ManageGroupView (admin only)
  - Sheet presented from "..." menu
  - List of members with swipe-to-delete
  - "Delete Group" button at bottom (destructive style)
  - Accessible only to admin (hide for regular members)

- [ ] 15.6 Update GroupsViewModel with management methods
  - Method: leaveGroup() async
  - Method: removeMember(userId) async
  - Method: deleteGroup() async
  - Handle errors and UI state updates

- [ ] 15.7 Add confirmation alerts
  - Use SwiftUI .confirmationDialog or .alert
  - Two-step confirmation for Delete Group (extra safety)

- [ ] 15.8 Handle edge case: last member leaves
  - If last member leaves group, delete group automatically
  - Or mark group as inactive (isActive = false)

## Implementation Details

Reference **techspec.md** sections:
- PRD: "Core Features > 1. Groups" (admin operations)
- PRD: "User Flows > Flow 4: Leave or Manage Group"

### Leave Group Implementation
```swift
// In GroupsViewModel.swift
func leaveGroup() async {
  isLoading = true
  defer { isLoading = false }

  guard let group = currentGroup,
        let authRepo = resolver.resolve(AuthenticationRepository.self),
        let user = try? await authRepo.currentUser() else {
    return
  }

  do {
    let leaveUseCase = resolver.resolve(LeaveGroupUseCase.self)!
    try await leaveUseCase.execute(groupId: group.id, userId: user.id)

    // Clear UI state
    currentGroup = nil
    members = []
  } catch {
    handleError(error)
  }
}
```

### Confirmation Dialog
```swift
// In GroupDashboardView.swift
.confirmationDialog("Leave Group", isPresented: $showLeaveConfirmation) {
  Button("Leave", role: .destructive) {
    Task {
      await viewModel.leaveGroup()
    }
  }
  Button("Cancel", role: .cancel) { }
} message: {
  Text("Are you sure? Your stats will be removed from leaderboards.")
}
```

### Admin-Only UI
```swift
// Only show admin options if current user is admin
if viewModel.isCurrentUserAdmin {
  Button("Manage Group", systemImage: "gearshape") {
    showManageGroupSheet = true
  }
}
```

### Remove Member (Admin)
```swift
// In ManageGroupView.swift
List {
  ForEach(viewModel.members) { member in
    HStack {
      Text(member.displayName)
      if member.role == .admin {
        Text("Admin")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.2))
          .cornerRadius(4)
      }
    }
  }
  .onDelete { indexSet in
    // Show confirmation and remove member
  }
}
```

## Success Criteria

- [ ] "Leave Group" button appears in toolbar menu for all members
- [ ] Confirmation alert shows before leaving
- [ ] After leaving, user returned to empty state with no group
- [ ] currentGroupId cleared in Firestore after leave
- [ ] Admin sees "Manage Group" option in menu
- [ ] Admin can swipe-to-delete members in ManageGroupView
- [ ] Removing member updates group member list immediately
- [ ] "Delete Group" button appears only for admin
- [ ] Deleting group removes all members and group document
- [ ] Admin badge visible on group creator in member list
- [ ] Confirmation alerts prevent accidental deletions

## Dependencies

**Before starting this task:**
- Task 6.0 (Group Management Use Cases) must have LeaveGroupUseCase
- Task 5.0 (Firebase Group Repository) must have removeMember, deleteGroup methods
- Task 7.0 (Groups UI) must have GroupDashboardView

**Blocks these tasks:**
- None (management features are final polish)

## Notes

- **Last Member Leaves**: If last member leaves, auto-delete group. Orphaned groups waste Firestore storage.
- **Admin Transfer**: Out of scope for MVP. If admin leaves, group is deleted (no admin transfer logic).
- **Destructive Actions**: Always require confirmation. Consider two-step confirmation for Delete Group (extra safety).
- **UI Feedback**: Show loading indicator during delete operations (may take 1-2 seconds).
- **Error Handling**: If delete fails, show user-friendly error message (e.g., "Failed to delete group. Try again.").
- **Swipe-to-Delete**: iOS native gesture. Use .onDelete(perform:) on List.

## Validation Steps

1. As member: Tap "..." → "Leave Group" → confirm → verify returned to empty state
2. As admin: Tap "..." → "Manage Group" → verify member list appears
3. As admin: Swipe member → "Delete" → confirm → verify member removed
4. As admin: Tap "Delete Group" → confirm → verify group deleted
5. Verify all members' currentGroupId cleared after delete
6. Verify group document deleted in Firestore
7. Try to delete group as non-admin → should not see option
8. Last member leaves → verify group auto-deleted

## Relevant Files

### Files to Create
- `/Presentation/Features/Groups/ManageGroupView.swift` - Admin management interface

### Files to Modify
- `/Presentation/Features/Groups/GroupDashboardView.swift` - Add toolbar menu, confirmation dialogs
- `/Presentation/Features/Groups/GroupsViewModel.swift` - Add management methods
- `/Domain/UseCases/LeaveGroupUseCase.swift` - Verify exists from Task 6.0

### Reference Files
- SwiftUI confirmationDialog: https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:presenting:actions:message:)-5awjc
- List onDelete: https://developer.apple.com/documentation/swiftui/list/ondelete(perform:)
