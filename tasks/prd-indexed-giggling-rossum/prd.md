# PRD: CMS Personal Trainer Integration

## Overview

Integrate the FitToday iOS app with a Personal Trainer CMS (React/Next.js), enabling personal trainers to manage students and assign workouts through a web interface while students receive and execute those workouts in the iOS app. Both systems share the same Firebase project (`fittoday-2aaff`).

## Problem Statement

Currently, FitToday users can only use AI-generated workouts or library workouts. Personal trainers who want to guide their students have no way to:
- Connect with students digitally
- Assign custom workouts
- Track student progress remotely

Students who work with personal trainers must manually create their assigned workouts, leading to friction and errors.

## Goals

1. **Feature Flags**: Enable/disable features dynamically via Firebase Remote Config without app updates
2. **Trainer-Student Linking**: Allow students to connect with their personal trainers through the app
3. **Workout Sync**: Sync workouts assigned by trainers to students' apps in real-time

## Non-Goals (Phase 1)

- In-app chat between trainer and student
- Video calls or live training sessions
- Payment processing for trainer services
- Trainer discovery/marketplace

## User Stories

### Feature Flags

**US-FF-01**: As a product manager, I want to enable/disable the personal trainer feature remotely so that I can control rollout without app updates.

**US-FF-02**: As a developer, I want feature flags to combine with entitlement checks so that premium features require both a subscription AND the feature being enabled.

### Student-Trainer Connection

**US-ST-01**: As a student, I want to search for my personal trainer by name or code so that I can request a connection.

**US-ST-02**: As a student, I want to see my connection request status (pending/active/rejected) so that I know where I stand with my trainer.

**US-ST-03**: As a student, I want to disconnect from my trainer so that I can manage my relationships.

**US-ST-04**: As a student, I want to receive a notification when my trainer accepts my connection request so that I know I can start receiving workouts.

### Trainer Workouts

**US-TW-01**: As a student with an active trainer connection, I want to see workouts my trainer has assigned to me so that I can follow their program.

**US-TW-02**: As a student, I want to execute trainer-assigned workouts using the same interface as other workouts so that my experience is consistent.

**US-TW-03**: As a student, I want trainer workouts to appear in my workout history so that I can track my progress.

**US-TW-04**: As a student, I want to be notified when my trainer assigns a new workout so that I don't miss it.

## Acceptance Criteria

### Feature Flags
- [ ] Remote Config values are fetched on app launch
- [ ] Feature flags are cached locally with 12-hour expiration
- [ ] Features can be toggled without user intervention
- [ ] Feature flags combine with entitlement policy (flag AND subscription)

### Trainer Connection
- [ ] Students can search trainers by display name
- [ ] Students can request connection via invite code/link
- [ ] Connection status is displayed in Profile section
- [ ] Notification sent when connection is accepted

### Workout Sync
- [ ] Trainer-assigned workouts appear in a dedicated section
- [ ] Workouts sync in real-time using Firestore listeners
- [ ] Trainer workouts convert to existing WorkoutPlan format
- [ ] Executed workouts are saved to history with trainer attribution

## Technical Constraints

1. **Firebase Project**: Must use existing `fittoday-2aaff` project
2. **Architecture**: Follow existing MVVM + Clean Architecture pattern
3. **Concurrency**: Use Swift 6 strict concurrency (actors, async/await)
4. **DI**: Register all new services in AppContainer using Swinject
5. **Compatibility**: Trainer workout structure must map to existing WorkoutPlan

## Dependencies

- Firebase Remote Config SDK (new dependency)
- CMS team to implement Firestore collections with agreed schema
- CMS team to configure Remote Config parameters in Firebase Console

## Success Metrics

1. Feature flags can be toggled in < 5 minutes across all users
2. < 2 second latency for new workout to appear in student app
3. 100% compatibility between CMS workouts and app workout execution

## Timeline

- Sprint 1 (2-3 days): Feature Flags infrastructure
- Sprint 2 (2-3 days): Personal Trainer domain models and data layer
- Sprint 3 (3-4 days): Trainer connection UI flow
- Sprint 4 (3-4 days): Workout sync implementation
- Sprint 5 (2-3 days): Polish, notifications, testing

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Workout format incompatibility | High | Mapper with fallback to simplified workout |
| Security rules misconfiguration | Medium | Test with Firebase emulator before production |
| Cache stale feature flags | Low | Force refresh on app foreground + configurable interval |
