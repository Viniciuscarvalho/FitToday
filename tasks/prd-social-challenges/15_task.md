# [15.0] Group Management Features (M)

## status: done

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

- [x] 15.1 Implement Leave Group functionality
  - "Leave Group" button in GroupDashboardView actions section
  - Confirmation dialog: "Tem certeza? Suas estatísticas serão removidas dos placares."
  - Calls LeaveGroupUseCase
  - Navigates to empty state after successful leave

- [x] 15.2 Implement Remove Member functionality (admin only)
  - Swipe-to-delete on member list rows in ManageGroupView
  - Confirmation dialog: "Remover [Name] do grupo?"
  - Calls GroupsViewModel.removeMember(userId)
  - Updates member list in UI immediately

- [x] 15.3 Implement Delete Group functionality (admin only)
  - "Delete Group" button in ManageGroupView (destructive style)
  - Two-step confirmation (first dialog + final alert for safety)
  - Calls GroupsViewModel.deleteGroup()
  - Clears UI state after deletion

- [x] 15.4 Add admin badge to member list
  - Already existed in MemberRowView from previous implementation
  - Displays "Admin" badge with accent color background
  - Uses role field from GroupMember entity

- [x] 15.5 Create ManageGroupView (admin only)
  - `/Presentation/Features/Groups/ManageGroupView.swift`
  - Sheet presented from "Gerenciar Grupo" button (admin only)
  - List of members with swipe-to-delete
  - "Excluir Grupo" button at bottom (destructive style)
  - Prevents removing self (admin) or other admins

- [x] 15.6 Update GroupsViewModel with management methods
  - Added: removeMember(userId) async
  - Added: deleteGroup() async
  - leaveGroup() already existed
  - All methods handle errors and UI state updates

- [x] 15.7 Add confirmation alerts
  - Leave Group: .confirmationDialog in GroupDashboardView
  - Remove Member: .confirmationDialog in ManageGroupView
  - Delete Group: Two-step confirmation (dialog + alert)

- [x] 15.8 Handle edge case: last member leaves
  - LeaveGroupUseCase checks member count before leaving
  - If last member, auto-deletes group after leaving
  - Uses try? to avoid failing if deletion fails

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

- [x] "Leave Group" button appears in actions section for all members
- [x] Confirmation dialog shows before leaving
- [x] After leaving, user returned to empty state with no group
- [x] currentGroupId cleared in Firestore after leave
- [x] Admin sees "Manage Group" option in actions section
- [x] Admin can swipe-to-delete members in ManageGroupView
- [x] Removing member updates group member list immediately
- [x] "Delete Group" button appears only in ManageGroupView (admin only)
- [x] Deleting group clears UI state and removes group document
- [x] Admin badge visible on group creator in member list
- [x] Confirmation dialogs prevent accidental deletions (two-step for delete group)

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
