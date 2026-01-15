# [14.0] In-App Notifications System (M)

## status: pending

<task_context>
<domain>presentation/notifications</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>firestore|notification_repository</dependencies>
</task_context>

# Task 14.0: In-App Notifications System

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create an in-app notification system that alerts users to key group events (new members, rank changes, week ended). Display notifications in a feed within the Groups tab and show badge count on tab icon.

<requirements>
- Create GroupNotification entity (already exists from Task 4.0)
- Implement NotificationRepository with Firestore operations
- Create NotificationFeedView to display recent notifications
- Show badge count on Groups tab when unread notifications exist
- Mark notifications as read when viewed
- Support notification types: newMember, rankChange, weekEnded
- Auto-expire notifications after 7 days
- NO push notifications (only in-app for MVP)
</requirements>

## Subtasks

- [ ] 14.1 Verify GroupNotification entity exists
  - Should already exist from Task 4.0 in SocialModels.swift
  - struct GroupNotification: id, userId, groupId, type, message, isRead, createdAt

- [ ] 14.2 Create FBNotification DTO and mapper
  - `/Data/Models/FirebaseModels.swift`: FBNotification
  - `/Data/Mappers/NotificationMapper.swift`: FBNotification ↔ GroupNotification

- [ ] 14.3 Implement FirebaseNotificationService
  - `/Data/Services/Firebase/FirebaseNotificationService.swift`
  - Method: fetchNotifications(userId) -> [FBNotification]
  - Method: markAsRead(notificationId)
  - Method: createNotification(userId, groupId, type, message)

- [ ] 14.4 Implement FirebaseNotificationRepository
  - `/Data/Repositories/FirebaseNotificationRepository.swift`
  - Wraps FirebaseNotificationService
  - Conforms to NotificationRepository protocol

- [ ] 14.5 Create NotificationFeedView
  - `/Presentation/Features/Groups/NotificationFeedView.swift`
  - List of recent notifications (last 7 days)
  - Group by date (Today, Yesterday, Earlier)
  - Icon/badge for notification type
  - Mark as read on view appear

- [ ] 14.6 Create NotificationFeedViewModel
  - @MainActor, @Observable
  - Properties: notifications, unreadCount, isLoading
  - Methods: loadNotifications(), markAllAsRead()

- [ ] 14.7 Add badge count to Groups tab
  - Modify TabRootView to show badge(viewModel.unreadCount)
  - Badge displays number of unread notifications
  - Clears when user opens NotificationFeedView

- [ ] 14.8 Integrate notification feed into GroupsView
  - Add bell icon in toolbar → navigates to NotificationFeedView
  - Badge on bell icon if unread notifications exist

- [ ] 14.9 Create notification triggers in Firebase operations
  - When member joins group → create "newMember" notification for all existing members
  - When rank changes → create "rankChange" notification (optional for MVP, can defer)
  - Every Sunday night → create "weekEnded" notification (via Cloud Functions - out of scope for MVP)

- [ ] 14.10 Implement notification auto-expiry
  - Firestore TTL or manual cleanup (query old notifications and delete)
  - Optional for MVP: can show all notifications, filter by date in UI

## Implementation Details

Reference **techspec.md** sections:
- "Implementation Design > Data Models > Domain Entities > GroupNotification"
- PRD: "Core Features > 5. Notifications (In-App Only, MVP)"

### Firestore Schema (from techspec.md)
```
/notifications/{notificationId}
  ├─ userId: String (indexed - recipient)
  ├─ groupId: String
  ├─ type: String (new_member/rank_change/week_ended)
  ├─ message: String
  ├─ isRead: Bool
  ├─ createdAt: Timestamp
  └─ expiresAt: Timestamp (7 days from creation)
```

### NotificationFeedView Structure
```swift
struct NotificationFeedView: View {
  @State private var viewModel: NotificationFeedViewModel

  var body: some View {
    List {
      Section("Today") {
        ForEach(viewModel.todayNotifications) { notification in
          NotificationRowView(notification: notification)
        }
      }

      Section("Earlier") {
        ForEach(viewModel.olderNotifications) { notification in
          NotificationRowView(notification: notification)
        }
      }
    }
    .navigationTitle("Notifications")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Mark All Read") {
          Task {
            await viewModel.markAllAsRead()
          }
        }
      }
    }
    .task {
      await viewModel.loadNotifications()
    }
  }
}
```

### Creating Notifications
```swift
// In FirebaseGroupRepository.addMember()
func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
  // ... existing member add logic

  // Create notification for all existing members
  let members = try await getMembers(groupId: groupId)
  let notificationRepo = resolver.resolve(NotificationRepository.self)!

  for member in members where member.id != userId {
    try? await notificationRepo.createNotification(
      userId: member.id,
      groupId: groupId,
      type: .newMember,
      message: "\(displayName) joined your group!"
    )
  }
}
```

### Badge on Groups Tab
```swift
// In TabRootView.swift
.badge(groupsViewModel.unreadNotificationsCount)
```

## Success Criteria

- [ ] Notifications created when member joins group
- [ ] Notification feed displays recent notifications (last 7 days)
- [ ] Badge appears on Groups tab when unread notifications exist
- [ ] Badge count accurate (matches number of isRead = false)
- [ ] Tapping notification feed marks all as read
- [ ] Badge clears after viewing notifications
- [ ] Empty state displays when no notifications
- [ ] Notifications grouped by date (Today, Yesterday, Earlier)
- [ ] Notification icons/badges distinguish between types (newMember, rankChange, weekEnded)

## Dependencies

**Before starting this task:**
- Task 4.0 (Domain Layer) must have GroupNotification entity
- Task 5.0 (Firebase Group Service) to trigger notifications on member add

**Blocks these tasks:**
- None (notifications are optional enhancement)

## Notes

- **Push Notifications**: OUT OF SCOPE for MVP. In-app only. Push notifications require APNS setup, certificates, and backend integration (deferred to v2).
- **Notification Triggering**: For MVP, only trigger "newMember" notifications. Rank change and week ended notifications can be added post-MVP.
- **Auto-Expiry**: Firestore doesn't support TTL natively. Options: (1) Filter by createdAt > 7 days ago in query, (2) Use Cloud Functions to delete old docs, (3) Show all and let UI filter.
- **Real-Time Updates**: Optional for notifications. Can use polling (fetch on app open) or Firestore listeners (real-time) for immediate delivery.
- **Badge Persistence**: Store unreadCount in UserDefaults to show badge even before loading notifications.

## Validation Steps

1. User A creates group → User B joins → verify User A receives "newMember" notification
2. Open Groups tab → verify badge shows "1" unread
3. Tap bell icon → NotificationFeedView opens
4. Verify notification appears in feed with message "[Name] joined your group!"
5. Navigate back → badge cleared
6. Create notification 8 days ago → verify NOT shown in feed (expired)
7. Mark all as read → verify all isRead = true in Firestore

## Relevant Files

### Files to Create
- `/Data/Models/FirebaseModels.swift` - Add FBNotification DTO
- `/Data/Mappers/NotificationMapper.swift` - Mapping logic
- `/Data/Services/Firebase/FirebaseNotificationService.swift` - Firestore operations
- `/Data/Repositories/FirebaseNotificationRepository.swift` - Repository implementation
- `/Presentation/Features/Groups/NotificationFeedView.swift`
- `/Presentation/Features/Groups/NotificationFeedViewModel.swift`
- `/Presentation/Features/Groups/NotificationRowView.swift` - Single notification row

### Files to Modify
- `/Presentation/Features/Groups/GroupsView.swift` - Add bell icon toolbar item
- `/Presentation/Features/Groups/GroupsViewModel.swift` - Add unreadCount property
- `/Presentation/TabRootView.swift` - Add .badge() to Groups tab
- `/Data/Repositories/FirebaseGroupRepository.swift` - Trigger notifications on member add
- `/Presentation/DI/AppContainer.swift` - Register NotificationRepository

### Firebase Console Configuration
- Firestore → Indexes → Create index on notifications: (userId, createdAt DESC)
- Firestore → Rules → User can only read own notifications
