# [16.0] Integration Testing & Bug Fixes (L)

## status: pending

<task_context>
<domain>testing/integration</domain>
<type>testing</type>
<scope>quality_assurance</scope>
<complexity>high</complexity>
<dependencies>firebase_emulator|all_features</dependencies>
</task_context>

# Task 16.0: Integration Testing & Bug Fixes

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Perform comprehensive end-to-end integration testing of the entire Social Challenges feature. Execute manual test checklist, use Firebase Emulator for safe testing, identify and fix bugs, optimize performance (debounce rank recomputation), and prepare for beta rollout.

<requirements>
- Setup Firebase Emulator Suite for safe testing
- Execute complete manual testing checklist from PRD
- Test all user flows end-to-end
- Identify and fix bugs discovered during testing
- Optimize performance (debounce rank recomputation if needed)
- Test edge cases and error scenarios
- Verify offline sync queue works correctly
- Test with multiple concurrent users (simulate real-world usage)
- Document known issues and workarounds
</requirements>

## Subtasks

- [ ] 16.1 Setup Firebase Emulator Suite
  - Install Firebase CLI: `npm install -g firebase-tools`
  - Initialize emulators: `firebase init emulators`
  - Select: Authentication, Firestore
  - Configure ports: Auth (9099), Firestore (8080), UI (4000)
  - Start emulators: `firebase emulators:start`

- [ ] 16.2 Configure app to use Firebase Emulator
  - Add environment flag: USE_FIREBASE_EMULATOR (debug builds only)
  - Point Firebase Auth and Firestore to localhost emulator URLs
  - Populate emulator with seed data (test groups, users)

- [ ] 16.3 Execute Manual Test Checklist
  - Run all test cases from techspec.md "Manual Testing Checklist"
  - Document results (pass/fail) in TESTING.md
  - File bugs for failures in GitHub Issues or task tracker

- [ ] 16.4 Test Create Group & Invite Flow
  - Create group as new user (no existing group)
  - Generate invite link, share via iMessage simulator
  - Tap invite link from second simulator (new user flow)
  - Verify auto-join after authentication
  - Attempt to create second group (should fail with error)

- [ ] 16.5 Test Leaderboard Real-Time Updates
  - Open Groups tab on two simulators
  - Complete workout on Simulator 1
  - Verify Simulator 2 leaderboard updates within 5 seconds
  - Check Firestore Emulator UI to verify rank values correct

- [ ] 16.6 Test Privacy Controls
  - Turn off "Share workout data" in settings
  - Complete workout
  - Verify NO Firebase sync (check Firestore Emulator)
  - Turn ON again, complete workout, verify sync works

- [ ] 16.7 Test Offline Sync Queue
  - Enable Airplane Mode
  - Complete workout (should enqueue)
  - Disable Airplane Mode
  - Verify workout syncs automatically
  - Check leaderboard updates

- [ ] 16.8 Test Edge Cases
  - Join group when already in one (should fail)
  - Join full group (10 members) (should fail)
  - Leave group as last member (group should delete)
  - Delete group as non-admin (should not see option)
  - Complete workout when not in group (should skip sync gracefully)

- [ ] 16.9 Performance Testing & Optimization
  - Test with 10 members completing workouts rapidly
  - Monitor rank recomputation frequency
  - If >10 writes/second, implement debouncing (batch every 30s)
  - Profile leaderboard fetch time (should be <2s)

- [ ] 16.10 Fix Identified Bugs
  - Prioritize critical bugs (crashes, data loss)
  - Fix P0 bugs before moving to beta
  - Document P1/P2 bugs for post-beta fixes
  - Regression test after each fix

- [ ] 16.11 Test Deep Linking Scenarios
  - Tap invite link when app not installed → should open App Store (manual test on device)
  - Tap invite link when app installed and signed in → should navigate to JoinGroupView
  - Tap invite link when signed out → should show auth with group context
  - Test Universal Link (https://) if implemented

- [ ] 16.12 Memory Leak Testing
  - Use Xcode Instruments (Leaks, Allocations)
  - Navigate between screens multiple times
  - Start/stop leaderboard listeners repeatedly
  - Verify no memory leaks from AsyncStream listeners

- [ ] 16.13 Create Testing Documentation
  - Document test results in TESTING.md
  - List known issues and workarounds
  - Document test data setup for QA team
  - Create video walkthrough of happy path (optional)

## Implementation Details

Reference **techspec.md** sections:
- "Testing Strategy > Manual Testing Checklist"
- "Technical Considerations > Performance Requirements"

### Firebase Emulator Configuration
```swift
#if DEBUG
let shouldUseEmulator = UserDefaults.standard.bool(forKey: "USE_FIREBASE_EMULATOR")

if shouldUseEmulator {
  let settings = Firestore.firestore().settings
  settings.host = "localhost:8080"
  settings.isSSLEnabled = false
  Firestore.firestore().settings = settings

  Auth.auth().useEmulator(withHost: "localhost", port: 9099)
}
#endif
```

### Debounce Rank Recomputation (if needed)
```swift
actor RankRecomputationDebouncer {
  private var pendingChallengeIds: Set<String> = []
  private var debounceTask: Task<Void, Never>?

  func scheduleRecomputation(challengeId: String) {
    pendingChallengeIds.insert(challengeId)

    debounceTask?.cancel()
    debounceTask = Task {
      try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
      await recomputePending()
    }
  }

  private func recomputePending() async {
    for challengeId in pendingChallengeIds {
      try? await FirebaseLeaderboardService.shared.recomputeRanks(challengeId: challengeId)
    }
    pendingChallengeIds.removeAll()
  }
}
```

## Success Criteria

- [ ] All manual test cases pass (see checklist in techspec.md)
- [ ] No critical (P0) bugs remaining
- [ ] Leaderboard updates within 5 seconds consistently
- [ ] Offline sync queue works reliably
- [ ] No memory leaks detected in Instruments
- [ ] Privacy toggle prevents sync correctly
- [ ] Deep links work for all scenarios
- [ ] Performance acceptable with 10 concurrent users
- [ ] Firebase Emulator tests pass without affecting production data
- [ ] TESTING.md document created with results

## Dependencies

**Before starting this task:**
- ALL implementation tasks (1-15) must be complete
- Firebase project configured
- Two iOS simulators available for multi-user testing

**Blocks these tasks:**
- Beta rollout (cannot release with critical bugs)

## Notes

- **Firebase Emulator**: CRITICAL for safe testing. Avoids polluting production Firestore with test data.
- **Emulator Seed Data**: Create script to populate emulator with test users, groups, challenges. Saves manual setup time.
- **Manual Testing**: Tedious but necessary. Automated UI tests can be added post-MVP (out of scope for Task 16).
- **Performance Baseline**: Leaderboard fetch <2s, update latency <5s. If not meeting, investigate (indexing, debouncing).
- **Memory Leaks**: Most likely from AsyncStream listeners. Ensure `onTermination` cleanup works correctly.
- **Bug Tracking**: Use GitHub Issues with labels: `bug`, `p0-critical`, `p1-high`, `p2-medium`. Prioritize P0 fixes.

## Validation Steps

1. Start Firebase Emulator → verify UI accessible at http://localhost:4000
2. Run app with emulator flag enabled → verify connects to emulator
3. Create test group → verify appears in Emulator Firestore UI
4. Execute all manual test cases → document pass/fail
5. Run Instruments Leaks → complete full user journey → verify no leaks
6. Profile leaderboard performance → verify fetch <2s
7. Test with 2 simulators simultaneously → verify real-time updates
8. Review bug list → fix P0 bugs → regression test
9. Sign off on testing → mark task complete

## Relevant Files

### Files to Create
- `/TESTING.md` - Test results documentation
- `/firebase.json` - Emulator configuration (if using Firebase CLI)
- `/scripts/seed-emulator-data.sh` - Script to populate test data (optional)

### Files to Modify (for emulator)
- `/FitTodayApp.swift` - Add emulator configuration in DEBUG builds

### Testing Tools
- Firebase Emulator Suite: https://firebase.google.com/docs/emulator-suite
- Xcode Instruments: Product → Profile → Leaks / Allocations
- Charles Proxy / Network Link Conditioner: Test offline scenarios

### Manual Test Checklist (from techspec.md)
- [ ] Create group as new user
- [ ] Attempt to create second group (should fail)
- [ ] Generate invite link, share via iMessage
- [ ] Tap invite link from second device (new user flow)
- [ ] Complete workout → verify leaderboards update within 5s
- [ ] Turn off "Share workout data" → complete workout → verify no Firebase sync
- [ ] Test offline: complete workout offline → go online → verify sync occurs
- [ ] Leave group → verify user removed, currentGroupId cleared

### External Resources
- Firebase Emulator: https://firebase.google.com/docs/emulator-suite
- Xcode Instruments: https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/
