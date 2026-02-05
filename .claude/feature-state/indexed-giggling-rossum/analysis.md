# Analysis: CMS Personal Trainer Integration

## Feature Overview

This feature enables FitToday users (students) to connect with personal trainers who use a separate CMS (React/Next.js). Both systems share the same Firebase project (`fittoday-2aaff`), allowing real-time synchronization of trainer-assigned workouts.

## Requirements Summary

### Core Capabilities

1. **Feature Flags via Firebase Remote Config**
   - Dynamic enable/disable of features without app updates
   - Combine flags with existing entitlement checks (flag AND subscription)
   - Keys: `personal_trainer_enabled`, `cms_workout_sync_enabled`, `trainer_chat_enabled`

2. **Trainer-Student Connection**
   - Students search trainers by name or invite code
   - Connection request flow: pending -> active -> cancelled
   - Real-time relationship status updates

3. **Trainer Workout Sync**
   - Real-time sync of workouts assigned by trainers
   - Map CMS workout format to existing `WorkoutPlan` structure
   - Workouts appear in dedicated section with trainer attribution

## Existing Codebase Integration Points

### 1. EntitlementPolicy.swift

**Current State:**
- `ProFeature` enum defines gated features (e.g., `aiWorkoutGeneration`, `premiumPrograms`)
- `FeatureAccessResult` returns `.allowed`, `.limitReached`, `.requiresPro`, `.trialExpired`
- `EntitlementPolicy.canAccess()` checks subscription status

**Required Changes:**
- Add new `ProFeature` cases: `personalTrainer`, `trainerWorkouts`
- No changes to `FeatureAccessResult` - `.requiresPro` covers feature-disabled case

### 2. FeatureGatingUseCase.swift

**Current State:**
- `FeatureGating` protocol with `checkAccess(to:)` method
- `FeatureGatingUseCase` checks entitlement and usage limits
- Uses `EntitlementRepository` and `AIUsageTracking`

**Required Changes:**
- Add optional `FeatureFlagRepository` dependency
- New method: `checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey)` that:
  1. Checks if feature flag is enabled (returns `.requiresPro` if disabled)
  2. If enabled, delegates to existing entitlement check

### 3. AppContainer.swift

**Current State:**
- Registers all services using Swinject
- Organized by feature area (StoreKit, Firebase, HealthKit, Groups, Check-In)
- Uses `.inObjectScope(.container)` for singletons

**Required Changes:**
- Add `RemoteConfigService` registration
- Add `FeatureFlagRepository` registration
- Update `FeatureGating` registration to inject flag repository
- Add Personal Trainer services and repositories
- Add Trainer Workout services and repositories
- Add Use Cases for trainer features

### 4. WorkoutModels.swift

**Current State:**
- `WorkoutPlan`: id, title, focus, estimatedDurationMinutes, intensity, phases, createdAt
- `WorkoutPlanPhase`: id, kind, title, rpeTarget, items
- `ExercisePrescription`: exercise, sets, reps, restInterval, tip
- `WorkoutExercise`: id, name, mainMuscle, equipment, instructions, media
- `DailyFocus`: fullBody, upper, lower, cardio, core, surprise

**Mapping Strategy:**
- CMS `focus` string maps directly to `DailyFocus` enum (case insensitive)
- CMS `intensity` ("low"/"moderate"/"high") maps to `WorkoutIntensity`
- CMS phases map to `WorkoutPlanPhase` (kind derived from phase name)
- CMS workout items map to `ExercisePrescription`

### 5. AppRouter.swift

**Current State:**
- `AppRoute` enum with various destinations
- `AppTab` enum: home, workout, create, activity, profile
- `DeepLink` struct for URL handling

**Required Changes:**
- Add new routes: `personalTrainer`, `trainerSearch`, `trainerWorkouts`
- Add deep link support for trainer invite codes

## Critical Decisions

### 1. Feature Flag + Entitlement Combination

**Decision:** Feature flag check runs FIRST, then entitlement check.
- If flag is OFF: Return `.requiresPro` (feature not available)
- If flag is ON: Delegate to normal entitlement check

**Rationale:** This allows:
- Gradual rollout (flag controls availability)
- Future monetization (entitlement controls payment)

### 2. WorkoutPlan Mapping Strategy

**Decision:** Create `TrainerWorkoutMapper` that:
- Preserves trainer workout ID for sync
- Maps CMS phases to `WorkoutPlanPhase` with best-effort kind matching
- Adds trainer attribution via custom metadata

**Rationale:** Reuses existing workout execution UI without modifications.

### 3. Real-Time Sync Approach

**Decision:** Use Firestore snapshot listeners with `AsyncStream`:
- `observeRelationship(studentId:)` for connection status
- `observeAssignedWorkouts(studentId:)` for workout changes

**Rationale:** Consistent with existing Firebase patterns in codebase.

### 4. Actor-Based Services

**Decision:** All Firebase services are actors:
- `RemoteConfigService` - actor
- `FirebasePersonalTrainerService` - actor
- `FirebaseTrainerWorkoutService` - actor

**Rationale:** Follows Swift 6 concurrency model, matches existing pattern (e.g., `SimpleAIUsageTracker`).

## Risks and Mitigations

### High Risk: Workout Format Incompatibility

**Risk:** CMS workout structure may not map cleanly to `WorkoutPlan`.

**Mitigation:**
- Create comprehensive mapper with fallback defaults
- Log unmapped fields for debugging
- Add validation in mapper to catch issues early
- Test with real CMS data before release

### Medium Risk: Feature Flag Latency

**Risk:** Remote Config fetch may delay app launch.

**Mitigation:**
- Use default values while fetching
- Cache values with 12-hour expiration
- Force refresh on app foreground
- Configurable fetch interval (0 for debug)

### Medium Risk: Security Rules Misconfiguration

**Risk:** Incorrect Firestore rules could expose data.

**Mitigation:**
- Test rules with Firebase emulator
- Students can only read their own relationships
- Workouts filtered by `assignedStudents` array-contains

### Low Risk: Offline Behavior

**Risk:** Poor UX when offline.

**Mitigation:**
- Cache feature flag values locally
- Show last-known trainer connection status
- Queue workout sync operations for retry

## Dependencies

### External
- Firebase Remote Config SDK (new package dependency)
- CMS team: Firestore collections with agreed schema
- CMS team: Remote Config parameters configured in Firebase Console

### Internal
- Existing `EntitlementRepository` and `FeatureGating`
- Existing `WorkoutPlan` and related models
- Existing `AppRouter` navigation system

## Testing Strategy

### Unit Tests (Priority)
1. `TrainerWorkoutMapperTests` - CRITICAL: Validate all field mappings
2. `RemoteConfigServiceTests` - Mock Firebase responses
3. `FeatureFlagUseCaseTests` - Combination of flags + entitlements
4. `PersonalTrainerMapperTests` - DTO to domain conversions

### Integration Tests
1. Feature flag toggle reflects in app
2. Complete connection flow (request -> accept -> active)
3. Workout sync end-to-end

## Complexity Assessment

| Component | Complexity | Reason |
|-----------|------------|--------|
| Feature Flags | Low | Standard Remote Config integration |
| Domain Models | Low | Straightforward structs |
| Firestore Services | Medium | Real-time listeners, async/await |
| WorkoutPlan Mapper | High | Must ensure 100% compatibility |
| UI/ViewModel | Medium | Standard MVVM pattern |
| AppContainer Integration | Low | Follows existing patterns |

## Estimated Effort

- Sprint 1 (Feature Flags): 2-3 days
- Sprint 2 (Personal Trainer Domain): 2-3 days
- Sprint 3 (Workout Sync): 3-4 days
- Sprint 4 (UI + Use Cases): 3-4 days

**Total: 10-14 days**

## Open Questions

1. **Trainer Photo Storage:** Does CMS store photos in Firebase Storage? Need URL format.
2. **Invite Code Expiration:** Do invite codes expire? Need to handle invalid codes.
3. **Maximum Connections:** Can a student have multiple trainers? PRD implies single trainer.
4. **Workout History Attribution:** How to display trainer-assigned workouts in history?

## Recommendation

Proceed with implementation in the defined sprint order. The feature flag infrastructure (Sprint 1) should be prioritized as it enables gradual rollout of subsequent features.

The `TrainerWorkoutMapper` (Sprint 3) is the highest-risk component and should receive extra testing attention.
