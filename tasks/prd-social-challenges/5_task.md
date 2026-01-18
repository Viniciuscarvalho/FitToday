# [5.0] Firebase Group Service & Repository (L)

## status: completed

<task_context>
<domain>data/services/firebase</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>firestore|firebase_auth|transactions</dependencies>
</task_context>

# Task 5.0: Firebase Group Service & Repository

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement Firebase Firestore operations for group management (create, read, update, delete groups and members). This includes creating the service layer, repository implementation, DTOs, mappers, and Firestore security rules.

<requirements>
- Create FirebaseGroupService actor for Firestore operations
- Implement Firestore transactions for atomic updates (e.g., add member + increment count)
- Create FBGroup and FBMember DTOs
- Implement mappers (FBGroup ↔ Group, FBMember ↔ GroupMember)
- Create FirebaseGroupRepository implementing GroupRepository protocol
- Configure Firestore security rules for groups collection
- Handle edge cases (group full, user already in group, admin-only operations)
- Use denormalization strategy (memberCount stored in group document)
</requirements>

## Subtasks

- [ ] 5.1 Create Firestore DTOs for groups
  - `/Data/Models/FirebaseModels.swift`: FBGroup, FBMember structs
  - Use @DocumentID and @ServerTimestamp property wrappers

- [ ] 5.2 Create mappers for Group entities
  - `/Data/Mappers/GroupMapper.swift`
  - Extensions: FBGroup.toDomain(), Group.toFirestore()
  - Extensions: FBMember.toDomain(), GroupMember.toFirestore()

- [ ] 5.3 Implement FirebaseGroupService actor
  - `/Data/Services/Firebase/FirebaseGroupService.swift`
  - Method: createGroup(name, ownerId) → writes to /groups, /groups/{id}/members
  - Method: getGroup(groupId) → reads from /groups/{id}
  - Method: addMember(groupId, userId, displayName, photoURL) → transaction
  - Method: removeMember(groupId, userId) → transaction
  - Method: deleteGroup(groupId) → batch delete (group + all members)
  - Method: getMembers(groupId) → query /groups/{id}/members subcollection

- [ ] 5.4 Implement atomic transactions for member operations
  - addMember: verify memberCount < 10, write member, increment count
  - removeMember: delete member doc, decrement count
  - Use Firestore runTransaction for atomicity

- [ ] 5.5 Implement batch deletes for group deletion
  - Delete group document
  - Delete all member documents (subcollection)
  - Update all members' currentGroupId to nil

- [ ] 5.6 Create FirebaseGroupRepository
  - `/Data/Repositories/FirebaseGroupRepository.swift`
  - Wraps FirebaseGroupService
  - Conforms to GroupRepository protocol
  - Handles mapping between DTOs and domain entities

- [ ] 5.7 Configure Firestore security rules
  - `/firestore.rules` or update in Firebase Console
  - Groups readable by members only
  - Groups writable by admin only (for update/delete)
  - Member subcollection writable by member themselves

- [ ] 5.8 Handle errors and edge cases
  - Group not found → throw DomainError.groupNotFound
  - Group full (10 members) → throw DomainError.groupFull
  - Not admin trying to delete → throw DomainError.notGroupAdmin

- [ ] 5.9 Register FirebaseGroupRepository in AppContainer
  - Add to `/Presentation/DI/AppContainer.swift`
  - Register as Sendable singleton

## Implementation Details

Reference **techspec.md** sections:
- "Implementation Design > Data Models > Firestore DTOs"
- "Integration Points > Firestore Schema Design"
- "Integration Points > Firestore Security Rules"

### Firestore Schema (Reference)
```
/groups/{groupId}
  ├─ name: String
  ├─ createdAt: Timestamp
  ├─ createdBy: String (userId)
  ├─ memberCount: Int (denormalized)
  ├─ isActive: Bool
  └─ /members (subcollection)
      └─ {userId}
          ├─ displayName: String
          ├─ photoURL: String?
          ├─ joinedAt: Timestamp
          ├─ role: String (admin/member)
          └─ isActive: Bool
```

### Transaction Example (from techspec.md)
```swift
func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
  let db = Firestore.firestore()
  let groupRef = db.collection("groups").document(groupId)
  let memberRef = groupRef.collection("members").document(userId)

  try await db.runTransaction { transaction, errorPointer in
    // Read current group
    let groupDoc = try transaction.getDocument(groupRef)
    guard var group = try? groupDoc.data(as: FBGroup.self) else {
      throw DomainError.groupNotFound
    }

    // Verify not full
    guard group.memberCount < 10 else {
      throw DomainError.groupFull
    }

    // Write member
    let member = FBMember(id: userId, displayName: displayName, photoURL: photoURL?.absoluteString, role: "member", isActive: true)
    try transaction.setData(from: member, forDocument: memberRef)

    // Increment count
    transaction.updateData(["memberCount": group.memberCount + 1], forDocument: groupRef)

    return nil
  }
}
```

## Success Criteria

- [ ] Groups can be created with name and ownerId
- [ ] Group document created in Firestore with correct fields
- [ ] First member (owner) automatically added with role "admin"
- [ ] Members can be added up to 10 max (11th member throws groupFull error)
- [ ] Member count accurately reflects actual member subcollection size
- [ ] Members can be removed and count decrements
- [ ] Group deletion removes group document and all member documents
- [ ] Security rules prevent non-members from reading group data
- [ ] Security rules prevent non-admins from deleting groups
- [ ] All operations handle offline/network errors gracefully

## Dependencies

**Before starting this task:**
- Task 1.0 (Firebase SDK Setup) must be complete
- Task 4.0 (Domain Layer) must provide Group entities and GroupRepository protocol
- Firestore database must be enabled in Firebase Console

**Blocks these tasks:**
- Task 6.0 (Group Management Use Cases) - needs repository implementation
- Task 7.0 (Groups UI) - needs repository to fetch/display groups

## Notes

- **Transactions**: Use Firestore transactions for operations that read-then-write (e.g., add member). This prevents race conditions.
- **Batch Writes**: Use batch writes for deleting multiple documents (e.g., delete group + all members).
- **Denormalization**: `memberCount` stored in group document. This is intentional to avoid subcollection count queries (expensive).
- **Security**: Always validate in security rules, not just client code. Malicious clients can bypass app logic.
- **Testing**: Use Firebase Emulator for testing transactions without affecting production data (optional for MVP).

## Validation Steps

1. Create group via repository → verify in Firestore Console
2. Add member → verify member subcollection created, memberCount incremented
3. Try adding 11th member → should throw groupFull error
4. Remove member → verify deleted from subcollection, count decremented
5. Delete group as admin → verify group + all members deleted
6. Try reading group as non-member → should fail due to security rules

## Relevant Files

### Files to Create
- `/Data/Models/FirebaseModels.swift` - Add FBGroup, FBMember DTOs
- `/Data/Mappers/GroupMapper.swift` - FBGroup ↔ Group mapping
- `/Data/Services/Firebase/FirebaseGroupService.swift` - Firestore operations
- `/Data/Repositories/FirebaseGroupRepository.swift` - Repository implementation

### Files to Modify
- `/Presentation/DI/AppContainer.swift` - Register GroupRepository

### Firebase Console Configuration
- Firestore → Rules → Update security rules for /groups collection
- Firestore → Data → Verify collections structure after testing

### External Resources
- Firestore Transactions: https://firebase.google.com/docs/firestore/manage-data/transactions
- Firestore Batch Writes: https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes
