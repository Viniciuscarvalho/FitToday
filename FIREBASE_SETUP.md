# Firebase Setup Guide for FitToday Social Challenges

This guide provides the complete Firestore schema, security rules, indexes, and setup instructions for the Social Challenges feature.

---

## Table of Contents

1. [Firebase Console Setup](#firebase-console-setup)
2. [Firestore Collections Schema](#firestore-collections-schema)
3. [Security Rules](#security-rules)
4. [Required Indexes](#required-indexes)
5. [Sample Data](#sample-data)
6. [Analytics Events](#analytics-events)

---

## Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" → Enter "FitToday"
3. Disable Google Analytics (or enable if desired)
4. Click "Create project"

### Step 2: Add iOS App

1. In Firebase Console, click iOS icon (+) to add app
2. Enter Bundle ID: `com.yourcompany.FitToday`
3. Download `GoogleService-Info.plist`
4. Add file to Xcode project (do NOT commit to Git)

### Step 3: Enable Authentication

1. Go to "Build" → "Authentication"
2. Click "Get started"
3. Enable these providers:
   - **Apple**: Follow Apple Developer setup instructions
   - **Google**: Download OAuth config, add to Info.plist
   - **Email/Password**: Enable both sign-up and sign-in

### Step 4: Enable Firestore

1. Go to "Build" → "Firestore Database"
2. Click "Create database"
3. Select "Start in production mode"
4. Choose region: `southamerica-east1` (São Paulo) for Brazil users
5. Click "Enable"

### Step 5: Deploy Security Rules

1. Go to "Firestore Database" → "Rules" tab
2. Copy the content from `firestore.rules` file in this repository
3. Click "Publish"

### Step 6: Create Indexes

1. Go to "Firestore Database" → "Indexes" tab
2. Create the indexes listed in [Required Indexes](#required-indexes) section

---

## Firestore Collections Schema

### Collection: `users`

Stores authenticated user profiles.

```
/users/{userId}
├── displayName: String           // User's display name
├── email: String?                // Optional, may be hidden (Apple Privacy)
├── photoURL: String?             // Profile photo URL
├── authProvider: String          // "apple" | "google" | "email"
├── currentGroupId: String?       // Active group ID (only one group per user)
├── privacySettings: Map
│   └── shareWorkoutData: Bool    // If true, workouts sync to leaderboard
└── createdAt: Timestamp          // Server timestamp
```

**Field Details:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `displayName` | String | Yes | User's display name for leaderboards |
| `email` | String | No | User's email (may be private relay for Apple) |
| `photoURL` | String | No | Full URL to profile photo |
| `authProvider` | String | Yes | One of: `apple`, `google`, `email` |
| `currentGroupId` | String | No | UUID of user's current group (null if not in group) |
| `privacySettings.shareWorkoutData` | Boolean | Yes | Default: `true` |
| `createdAt` | Timestamp | Yes | Server-generated creation timestamp |

---

### Collection: `groups`

Stores group information.

```
/groups/{groupId}
├── name: String                  // Group name (max 50 chars)
├── createdAt: Timestamp          // Server timestamp
├── createdBy: String             // User ID of group creator (admin)
├── memberCount: Int              // Denormalized member count
├── isActive: Bool                // False if deleted
└── /members/{userId}             // Subcollection
    ├── displayName: String       // Denormalized from user
    ├── photoURL: String?         // Denormalized from user
    ├── joinedAt: Timestamp       // When user joined
    ├── role: String              // "admin" | "member"
    └── isActive: Bool            // False if removed
```

**Field Details:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | Group name, 1-50 characters |
| `createdAt` | Timestamp | Yes | Server-generated creation timestamp |
| `createdBy` | String | Yes | User ID of creator (becomes admin) |
| `memberCount` | Integer | Yes | Count of active members (denormalized) |
| `isActive` | Boolean | Yes | `true` for active groups |

**Subcollection: `/groups/{groupId}/members/{userId}`**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `displayName` | String | Yes | Denormalized for quick reads |
| `photoURL` | String | No | Denormalized for quick reads |
| `joinedAt` | Timestamp | Yes | Server-generated |
| `role` | String | Yes | `admin` or `member` |
| `isActive` | Boolean | Yes | `false` if member removed |

---

### Collection: `challenges`

Stores weekly challenge configurations.

```
/challenges/{challengeId}
├── groupId: String               // Group this challenge belongs to
├── type: String                  // "check-ins" | "streak"
├── weekStartDate: Timestamp      // Monday 00:00 UTC
├── weekEndDate: Timestamp        // Sunday 23:59 UTC
├── isActive: Bool                // True during challenge period
├── createdAt: Timestamp          // Server timestamp
└── /entries/{userId}             // Subcollection
    ├── displayName: String       // Denormalized from user
    ├── photoURL: String?         // Denormalized from user
    ├── value: Int                // Check-in count or streak days
    ├── rank: Int                 // Pre-computed rank (1-indexed)
    └── lastUpdated: Timestamp    // Last modification time
```

**Field Details:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `groupId` | String | Yes | UUID of the group |
| `type` | String | Yes | `check-ins` (workout count) or `streak` (consecutive days) |
| `weekStartDate` | Timestamp | Yes | Monday at midnight UTC |
| `weekEndDate` | Timestamp | Yes | Sunday at 23:59:59 UTC |
| `isActive` | Boolean | Yes | `true` for current week, `false` for past weeks |
| `createdAt` | Timestamp | Yes | Server-generated |

**Subcollection: `/challenges/{challengeId}/entries/{userId}`**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `displayName` | String | Yes | Denormalized for leaderboard display |
| `photoURL` | String | No | Denormalized for leaderboard display |
| `value` | Integer | Yes | Score value (check-ins or streak days) |
| `rank` | Integer | Yes | Position in leaderboard (1 = first place) |
| `lastUpdated` | Timestamp | Yes | Last score update time |

---

### Collection: `notifications`

Stores in-app notifications for users.

```
/notifications/{notificationId}
├── userId: String                // Recipient user ID
├── groupId: String               // Related group ID
├── type: String                  // Notification type
├── message: String               // Display message
├── isRead: Bool                  // Read status
├── createdAt: Timestamp          // Server timestamp
└── expiresAt: Timestamp          // Auto-delete after 7 days (optional)
```

**Field Details:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | String | Yes | Recipient's user ID (indexed) |
| `groupId` | String | Yes | Related group UUID |
| `type` | String | Yes | See notification types below |
| `message` | String | Yes | Human-readable message |
| `isRead` | Boolean | Yes | Default: `false` |
| `createdAt` | Timestamp | Yes | Server-generated |
| `expiresAt` | Timestamp | No | Optional TTL for cleanup |

**Notification Types:**

| Type | Description | Example Message |
|------|-------------|-----------------|
| `new_member` | Someone joined the group | "Maria entrou no grupo!" |
| `rank_change` | User moved up in leaderboard | "Você subiu para 2º lugar!" |
| `week_ended` | Weekly challenge completed | "Desafio encerrado! Veja os resultados." |

---

## Security Rules

The security rules are maintained in `/firestore.rules` file. Key rules:

1. **Users**: Can only read/write their own document
2. **Groups**: Only members can read, only admin can update/delete
3. **Members**: User can write their own document, admin can manage
4. **Challenges**: Authenticated users can read, only entry owner can write
5. **Notifications**: Only recipient can read/update

Deploy rules via Firebase Console or Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

---

## Required Indexes

Create these composite indexes in Firebase Console → Firestore → Indexes:

### Index 1: Challenges by Group and Week

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `challenges` | `groupId` (Asc), `weekStartDate` (Desc), `isActive` (Asc) | Collection |

**Used by:** Fetching current week's challenge for a group

### Index 2: Challenges by Group and Type

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `challenges` | `groupId` (Asc), `type` (Asc), `weekStartDate` (Desc), `isActive` (Asc) | Collection |

**Used by:** Fetching specific challenge type for a group

### Index 3: Notifications by User

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `notifications` | `userId` (Asc), `createdAt` (Desc) | Collection |

**Used by:** Fetching user's notifications in reverse chronological order

### Index 4: Notifications Unread Count

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `notifications` | `userId` (Asc), `isRead` (Asc) | Collection |

**Used by:** Counting unread notifications for badge

### Create Index via Firebase Console

1. Go to Firestore → Indexes
2. Click "Add Index"
3. Enter collection ID
4. Add fields with sort order
5. Click "Create index"

Or use Firebase CLI with `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "challenges",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "weekStartDate", "order": "DESCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "challenges",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "weekStartDate", "order": "DESCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

---

## Sample Data

### Sample User Document

```json
{
  "displayName": "João Silva",
  "email": "joao@example.com",
  "photoURL": "https://example.com/photo.jpg",
  "authProvider": "apple",
  "currentGroupId": "abc123-uuid",
  "privacySettings": {
    "shareWorkoutData": true
  },
  "createdAt": "2026-01-15T10:30:00Z"
}
```

### Sample Group Document

```json
{
  "name": "Galera da Academia",
  "createdAt": "2026-01-15T10:30:00Z",
  "createdBy": "user123",
  "memberCount": 5,
  "isActive": true
}
```

### Sample Member Document (subcollection)

```json
{
  "displayName": "João Silva",
  "photoURL": "https://example.com/photo.jpg",
  "joinedAt": "2026-01-15T10:30:00Z",
  "role": "admin",
  "isActive": true
}
```

### Sample Challenge Document

```json
{
  "groupId": "abc123-uuid",
  "type": "check-ins",
  "weekStartDate": "2026-01-13T00:00:00Z",
  "weekEndDate": "2026-01-19T23:59:59Z",
  "isActive": true,
  "createdAt": "2026-01-13T00:00:01Z"
}
```

### Sample Challenge Entry Document (subcollection)

```json
{
  "displayName": "João Silva",
  "photoURL": "https://example.com/photo.jpg",
  "value": 5,
  "rank": 1,
  "lastUpdated": "2026-01-17T14:30:00Z"
}
```

### Sample Notification Document

```json
{
  "userId": "user456",
  "groupId": "abc123-uuid",
  "type": "new_member",
  "message": "Maria Santos entrou no grupo!",
  "isRead": false,
  "createdAt": "2026-01-17T10:00:00Z"
}
```

---

## Analytics Events

For Firebase Analytics tracking (Task 17), implement these events:

### Event: `group_created`

Fires when user creates a group.

| Parameter | Type | Description |
|-----------|------|-------------|
| `group_id` | String | UUID of created group |
| `user_id` | String | Creator's user ID |
| `timestamp` | Number | Unix timestamp |

### Event: `group_joined`

Fires when user joins a group via invite.

| Parameter | Type | Description |
|-----------|------|-------------|
| `group_id` | String | UUID of joined group |
| `user_id` | String | Joining user's ID |
| `invite_source` | String | `link` or `qr` |
| `timestamp` | Number | Unix timestamp |

### Event: `workout_synced`

Fires when workout data syncs to leaderboard.

| Parameter | Type | Description |
|-----------|------|-------------|
| `user_id` | String | User's ID |
| `group_id` | String | Group UUID |
| `challenge_type` | String | `check-ins` or `streak` |
| `value` | Number | Current score |
| `timestamp` | Number | Unix timestamp |

### Event: `group_left`

Fires when user leaves a group.

| Parameter | Type | Description |
|-----------|------|-------------|
| `group_id` | String | UUID of left group |
| `user_id` | String | User's ID |
| `duration_days` | Number | Days user was in group |
| `timestamp` | Number | Unix timestamp |

### User Properties

| Property | Type | Description |
|----------|------|-------------|
| `is_in_group` | String | `true` or `false` |
| `group_role` | String | `admin`, `member`, or `none` |

---

## Maintenance Tasks

### Weekly Challenge Rotation

Challenges should be created automatically for each group at the start of each week:

1. **Cloud Function Trigger**: Use scheduled Cloud Function (every Monday 00:00 UTC)
2. **Logic**:
   - Query all active groups
   - For each group, create two new challenges (check-ins and streak)
   - Mark previous week's challenges as `isActive: false`

### Notification Cleanup

Delete old notifications to save storage:

1. **Cloud Function Trigger**: Daily at 03:00 UTC
2. **Logic**: Delete notifications where `createdAt < now() - 7 days`

### Orphan Data Cleanup

Remove data from deleted groups:

1. **When group is deleted**: Delete all members, challenges, and entries
2. **Use batch delete** for atomic operations

---

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Check Firestore security rules
   - Verify user is authenticated
   - Check if user is member of the group

2. **Indexes not working**
   - Wait 5-10 minutes for index to build
   - Check Firebase Console → Indexes for build status

3. **Realtime updates not working**
   - Check listener registration
   - Verify network connectivity
   - Check Firestore quota limits

4. **Authentication failures**
   - Verify `GoogleService-Info.plist` is correct
   - Check bundle ID matches Firebase config
   - Verify auth providers are enabled

---

**Document Version:** 1.0
**Last Updated:** 2026-01-17
**Author:** Claude Code
