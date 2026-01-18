# [6.0] Group Management Use Cases (M)

## status: completed

<task_context>
<domain>domain/usecases</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>repositories|authentication</dependencies>
</task_context>

# Task 6.0: Group Management Use Cases

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement business logic use cases for group management: creating groups, joining groups via invite, leaving groups, and generating invite links. These use cases orchestrate repository operations and enforce business rules (e.g., 1-group-per-user limit).

<requirements>
- Create CreateGroupUseCase with 1-group limit validation
- Create JoinGroupUseCase with group-full and duplicate-join checks
- Create LeaveGroupUseCase with cleanup logic
- Create GenerateInviteLinkUseCase for invite URL generation
- All use cases validate authentication state
- Handle errors and edge cases (already in group, group full, etc.)
- Follow Swift 6 concurrency patterns (async/await, Sendable)
</requirements>

## Subtasks

- [ ] 6.1 Create CreateGroupUseCase
  - `/Domain/UseCases/CreateGroupUseCase.swift`
  - Validate user is authenticated
  - Validate user NOT already in a group (MVP: 1 group limit)
  - Call GroupRepository.createGroup()
  - Call UserRepository.updateCurrentGroup()
  - Return created Group entity

- [ ] 6.2 Create JoinGroupUseCase
  - `/Domain/UseCases/JoinGroupUseCase.swift`
  - Validate user is authenticated
  - Validate user NOT already in a group
  - Fetch group to verify exists
  - Validate group NOT full (memberCount < 10)
  - Call GroupRepository.addMember()
  - Call UserRepository.updateCurrentGroup()

- [ ] 6.3 Create LeaveGroupUseCase
  - `/Domain/UseCases/LeaveGroupUseCase.swift`
  - Validate user is authenticated
  - Call GroupRepository.leaveGroup()
  - Call UserRepository.updateCurrentGroup(nil)
  - Handle admin leaving (last admin deletes group logic - optional for MVP)

- [ ] 6.4 Create GenerateInviteLinkUseCase
  - `/Domain/UseCases/GenerateInviteLinkUseCase.swift`
  - Take groupId as input
  - Return invite URL: `fittoday://group/invite/{groupId}`
  - Universal Link version: `https://fittoday.app/group/invite/{groupId}` (for sharing)

- [ ] 6.5 Implement UserRepository protocol implementation
  - `/Data/Repositories/FirebaseUserRepository.swift`
  - Method: updateCurrentGroup(userId, groupId)
  - Updates /users/{userId} → currentGroupId field in Firestore

- [ ] 6.6 Add error handling for all use cases
  - Throw DomainError.notAuthenticated if user nil
  - Throw DomainError.alreadyInGroup if currentGroupId not nil
  - Throw DomainError.groupFull if memberCount >= 10
  - Throw DomainError.groupNotFound if group doesn't exist

## Implementation Details

Reference **techspec.md** section: "Implementation Design > Use Cases"

### CreateGroupUseCase Example (from techspec.md)
```swift
struct CreateGroupUseCase {
  private let groupRepo: GroupRepository
  private let userRepo: UserRepository
  private let authRepo: AuthenticationRepository

  func execute(name: String) async throws -> Group {
    guard let user = try await authRepo.currentUser() else {
      throw DomainError.notAuthenticated
    }
    guard user.currentGroupId == nil else {
      throw DomainError.alreadyInGroup
    }
    let group = try await groupRepo.createGroup(name: name, ownerId: user.id)
    try await userRepo.updateCurrentGroup(userId: user.id, groupId: group.id)
    return group
  }
}
```

### JoinGroupUseCase Logic
```swift
func execute(groupId: String) async throws {
  // 1. Validate authentication
  guard let user = try await authRepo.currentUser() else {
    throw DomainError.notAuthenticated
  }

  // 2. Validate not already in group
  guard user.currentGroupId == nil else {
    throw DomainError.alreadyInGroup
  }

  // 3. Fetch group and validate exists + not full
  guard let group = try await groupRepo.getGroup(groupId) else {
    throw DomainError.groupNotFound
  }
  guard group.memberCount < 10 else {
    throw DomainError.groupFull
  }

  // 4. Add member and update user
  try await groupRepo.addMember(groupId: groupId, userId: user.id, displayName: user.displayName, photoURL: user.photoURL)
  try await userRepo.updateCurrentGroup(userId: user.id, groupId: groupId)
}
```

## Success Criteria

- [ ] CreateGroupUseCase creates group and sets user.currentGroupId
- [ ] User cannot create second group (throws alreadyInGroup error)
- [ ] JoinGroupUseCase adds user to group and updates currentGroupId
- [ ] User cannot join group if already in one (throws alreadyInGroup)
- [ ] User cannot join full group (throws groupFull)
- [ ] LeaveGroupUseCase removes user from group and clears currentGroupId
- [ ] GenerateInviteLinkUseCase returns valid URL format
- [ ] All use cases throw appropriate domain errors for validation failures
- [ ] All code compiles with Swift 6 strict concurrency (no warnings)

## Dependencies

**Before starting this task:**
- Task 4.0 (Domain Layer) must provide entity definitions
- Task 5.0 (Firebase Group Repository) must provide repository implementations
- Task 2.0 (Authentication) must provide AuthenticationRepository

**Blocks these tasks:**
- Task 7.0 (Groups UI) - ViewModels will call these use cases
- Task 13.0 (Offline Sync) - may need to queue use case operations

## Notes

- **1-Group Limit**: MVP restriction. v2 will support multiple groups. Check currentGroupId before create/join.
- **Admin Leaving**: If last admin leaves, group should be deleted (optional for MVP, can defer to v2).
- **Invite Links**: Two formats: URL scheme (`fittoday://`) for direct app open, HTTPS for universal links.
- **Error Propagation**: Use cases throw domain errors. ViewModels catch and display user-friendly messages.
- **DI**: Use cases receive repositories via constructor injection (Resolver pattern).

## Validation Steps

1. Call CreateGroupUseCase → verify group created in Firestore
2. Call CreateGroupUseCase again (same user) → should throw alreadyInGroup
3. Call JoinGroupUseCase with valid groupId → user added as member
4. Call JoinGroupUseCase when in group → should throw alreadyInGroup
5. Create group with 10 members, try to join 11th → should throw groupFull
6. Call LeaveGroupUseCase → user removed, currentGroupId cleared
7. Call GenerateInviteLinkUseCase → returns `fittoday://group/invite/{id}`

## Relevant Files

### Files to Create
- `/Domain/UseCases/CreateGroupUseCase.swift`
- `/Domain/UseCases/JoinGroupUseCase.swift`
- `/Domain/UseCases/LeaveGroupUseCase.swift`
- `/Domain/UseCases/GenerateInviteLinkUseCase.swift`
- `/Data/Repositories/FirebaseUserRepository.swift` - UserRepository implementation

### Files to Modify
- `/Presentation/DI/AppContainer.swift` - Register use cases and UserRepository

### Reference Files
- `/Domain/UseCases/` - Existing use cases for pattern reference
- `/Domain/Errors/DomainError.swift` - Error enum definitions
