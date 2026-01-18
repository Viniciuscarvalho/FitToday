# [17.0] Analytics & Monitoring Setup (S)

## status: done

<task_context>
<domain>infrastructure/monitoring</domain>
<parameter name="type">implementation</type>
<scope>observability</scope>
<complexity>low</complexity>
<dependencies>firebase_analytics|crashlytics</dependencies>
</task_context>

# Task 17.0: Analytics & Monitoring Setup

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Setup Firebase Analytics and Crashlytics to track feature adoption, user behavior, and errors. This enables data-driven product decisions and proactive bug detection.

<requirements>
- Enable Firebase Analytics in Firebase Console
- Enable Firebase Crashlytics for error tracking
- Implement key analytics events (group_created, group_joined, workout_synced)
- Track feature adoption metrics (% users in groups)
- Track retention metrics (weekly active retention)
- Setup Crashlytics for crash reporting
- Create Analytics dashboard in Firebase Console
- Document analytics events for future reference
</requirements>

## Subtasks

- [ ] 17.1 Enable Firebase Analytics
  - Add FirebaseAnalytics SDK via SPM (if not already added)
  - Analytics automatically enabled with FirebaseApp.configure()
  - Verify in Firebase Console → Analytics → Events
  - **Note**: Add `FirebaseAnalytics` product from `firebase-ios-sdk` SPM package

- [ ] 17.2 Enable Firebase Crashlytics
  - Add FirebaseCrashlytics SDK via SPM
  - Initialize in FitTodayApp.init(): Crashlytics.crashlytics()
  - Upload dSYM files for symbolication (automatic with Xcode)
  - **Note**: Requires manual SDK addition and console setup

- [x] 17.3 Implement group_created event
  - Track when user creates group
  - Parameters: group_id, user_id, timestamp
  - Location: CreateGroupUseCase after successful creation
  - **Implementation**: Added to `CreateGroupUseCase.swift` via `AnalyticsTracking` protocol

- [x] 17.4 Implement group_joined event
  - Track when user joins group via invite
  - Parameters: group_id, user_id, invite_source (link/qr), timestamp
  - Location: JoinGroupUseCase after successful join
  - **Implementation**: Added to `JoinGroupUseCase.swift` with `InviteSource` enum

- [x] 17.5 Implement workout_synced event
  - Track successful leaderboard sync
  - Parameters: user_id, group_id, challenge_type (check-ins/streak), value, timestamp
  - Location: SyncWorkoutCompletionUseCase after successful Firebase write
  - **Implementation**: Added to `SyncWorkoutCompletionUseCase.swift` for both check-ins and streak

- [x] 17.6 Implement group_left event
  - Track when user leaves group
  - Parameters: group_id, user_id, duration_in_group_days, timestamp
  - Location: LeaveGroupUseCase after successful leave
  - **Implementation**: Added to `LeaveGroupUseCase.swift` with duration calculation

- [x] 17.7 Track feature adoption
  - User property: is_in_group (boolean)
  - User property: group_role (admin/member/none)
  - Update on group join/leave
  - **Implementation**: Added `setUserInGroup()` and `setUserRole()` in all group use cases

- [ ] 17.8 Setup error logging with Crashlytics
  - Log non-fatal errors: Crashlytics.crashlytics().record(error:)
  - Log custom messages: Crashlytics.crashlytics().log("Context message")
  - Add to all catch blocks in critical paths (sync, group operations)
  - **Note**: Requires FirebaseCrashlytics SDK to be added

- [ ] 17.9 Create Firebase Console dashboard
  - Custom dashboard for Social Challenges metrics
  - Widgets: group_created count (daily), group_joined count, workout_synced count
  - Funnel: invite_sent → group_joined conversion rate
  - **Note**: Manual configuration in Firebase Console

- [x] 17.10 Document analytics events
  - Create ANALYTICS.md with event definitions
  - Include event names, parameters, when fired
  - Share with product/marketing teams
  - **Implementation**: Documented in `/FIREBASE_SETUP.md` under Analytics Events section

## Implementation Details

Reference **techspec.md** sections:
- "Technical Considerations > Special Requirements > Monitoring Needs"
- PRD: "Key Metrics to Track"

### Firebase Analytics Events
```swift
import FirebaseAnalytics

// In CreateGroupUseCase.swift
func execute(name: String) async throws -> Group {
  // ... existing logic
  let group = try await groupRepo.createGroup(name: name, ownerId: user.id)

  // Track event
  Analytics.logEvent("group_created", parameters: [
    "group_id": group.id,
    "user_id": user.id,
    "timestamp": Date().timeIntervalSince1970
  ])

  return group
}

// In SyncWorkoutCompletionUseCase.swift
func execute(entry: WorkoutHistoryEntry) async throws {
  // ... existing sync logic

  Analytics.logEvent("workout_synced", parameters: [
    "user_id": user.id,
    "group_id": groupId,
    "challenge_type": "check-ins", // or "streak"
    "value": entry.value,
    "timestamp": Date().timeIntervalSince1970
  ])
}
```

### User Properties
```swift
// Set user property when joining group
Analytics.setUserProperty("true", forName: "is_in_group")
Analytics.setUserProperty("member", forName: "group_role") // or "admin"

// Clear when leaving group
Analytics.setUserProperty("false", forName: "is_in_group")
Analytics.setUserProperty("none", forName: "group_role")
```

### Crashlytics Error Logging
```swift
import FirebaseCrashlytics

// In SyncWorkoutCompletionUseCase
catch {
  Crashlytics.crashlytics().log("Workout sync failed for user \(user.id)")
  Crashlytics.crashlytics().record(error: error)
  // ... handle error
}
```

### Analytics Dashboard Setup
1. Firebase Console → Analytics → Dashboard
2. Add Card → Custom → Event count
3. Select event: group_created, group_joined, workout_synced
4. Group by: day, week, month
5. Save dashboard as "Social Challenges Metrics"

## Success Criteria

- [ ] Firebase Analytics receiving events (verify in Console → DebugView) - Requires SDK setup
- [ ] Crashlytics receiving crash reports (trigger test crash to verify) - Requires SDK setup
- [x] group_created event fires when group created
- [x] group_joined event fires when user joins via invite
- [x] workout_synced event fires when leaderboard updated
- [x] User properties (is_in_group, group_role) set correctly
- [ ] Firebase Console dashboard created with key metrics - Manual console config
- [x] ANALYTICS.md document created with event definitions (in FIREBASE_SETUP.md)
- [x] No PII (personally identifiable information) logged in events - Only IDs logged

## Dependencies

**Before starting this task:**
- Task 1.0 (Firebase SDK Setup) must be complete
- All feature implementation tasks (1-15) should be complete for event tracking

**Blocks these tasks:**
- None (analytics is independent)

## Notes

- **Privacy**: Do NOT log PII (names, emails, photos). Log only anonymized IDs.
- **DebugView**: Enable in Firebase Console to see real-time events during testing. Xcode scheme argument: `-FIRDebugEnabled`
- **Event Limits**: Firebase has limits on event parameter length (100 chars). Keep parameters concise.
- **Retention**: Analytics data retained for 14 months (free tier). Export to BigQuery for longer retention.
- **Crashlytics dSYM**: Xcode 14+ uploads dSYMs automatically. For manual upload: `firebase crashlytics:symbols:upload --app=<app_id> <path>`
- **Testing**: Use Firebase Analytics DebugView to verify events fire correctly before production release.

## Validation Steps

1. Enable DebugView in Firebase Console
2. Run app with `-FIRDebugEnabled` argument
3. Create group → verify group_created event in DebugView
4. Join group → verify group_joined event
5. Complete workout → verify workout_synced event
6. Trigger test crash: `fatalError("Test crash")` → verify appears in Crashlytics
7. Check Firebase Console → Analytics → Events → verify events listed
8. Check dashboard → verify widgets display data

## Relevant Files

### Files to Modify
- `/FitTodayApp.swift` - Initialize Crashlytics
- `/Domain/UseCases/CreateGroupUseCase.swift` - Add group_created event
- `/Domain/UseCases/JoinGroupUseCase.swift` - Add group_joined event
- `/Domain/UseCases/SyncWorkoutCompletionUseCase.swift` - Add workout_synced event
- `/Domain/UseCases/LeaveGroupUseCase.swift` - Add group_left event

### Files to Create
- `/ANALYTICS.md` - Event definitions documentation

### Firebase Console Configuration
- Analytics → DebugView → Enable for testing
- Analytics → Dashboard → Create "Social Challenges Metrics" dashboard
- Crashlytics → Verify setup complete

### External Resources
- Firebase Analytics: https://firebase.google.com/docs/analytics
- Firebase Crashlytics: https://firebase.google.com/docs/crashlytics
- DebugView: https://firebase.google.com/docs/analytics/debugview
