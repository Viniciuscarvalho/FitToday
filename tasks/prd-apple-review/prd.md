# Product Requirements Document (PRD)

**Project Name:** App Store Review Request
**Document Version:** 1.0
**Date:** 2026-02-18
**Author:** Claude
**Status:** Approved

---

## Executive Summary

**Problem Statement:**
FitToday has no mechanism to request App Store ratings/reviews from users. Organic reviews are critical for App Store ranking, user trust, and conversion. Without prompting, only dissatisfied users tend to leave reviews, creating a negative bias.

**Proposed Solution:**
Integrate Apple's `SKStoreReviewController.requestReview()` (StoreKit) to prompt users for App Store reviews at key success moments in the app. Use smart throttling to avoid annoying users while maximizing positive review likelihood.

**Business Value:**
- Increase App Store rating and review count
- Improve App Store ranking and discoverability
- Higher conversion rate from App Store page views to downloads

**Success Metrics:**
- App Store rating >= 4.5 stars
- Review count increases by 30% within 3 months
- Zero user complaints about review prompt frequency

---

## Functional Requirements

### FR-001: Review Request Service [MUST]

**Description:**
Create a centralized `AppReviewService` that wraps `SKStoreReviewController.requestReview(in:)` with eligibility checks and throttling logic.

**Acceptance Criteria:**
- Uses StoreKit 2's `AppStore.requestReview(in:)` API for iOS 16+ or `SKStoreReviewController.requestReview(in:)` as fallback
- Respects Apple's built-in throttling (max 3 prompts per 365 days enforced by OS)
- Adds app-level throttling: minimum 30 days between requests
- Tracks request timestamps in UserDefaults via AppStorageKeys

**Priority:** P0

### FR-002: Eligibility Criteria [MUST]

**Description:**
Define conditions that must be met before showing a review prompt.

**Acceptance Criteria:**
- User has completed at least 3 workouts total (engagement threshold)
- At least 7 days since first app launch (not brand new user)
- At least 30 days since last review request
- Current trigger is a genuine success moment (not error recovery or loading)
- Never show during onboarding flow

**Priority:** P0

### FR-003: Workout Completion Trigger [MUST]

**Description:**
Trigger review request after a successful workout completion, which is the highest-engagement moment.

**Acceptance Criteria:**
- Triggers after the workout completion screen is displayed
- Only triggers for workouts with status `.completed`
- Small delay (2 seconds) after completion screen appears to let user absorb their accomplishment
- Works for both AI-generated and custom workouts

**Priority:** P0

### FR-004: Program Completion Trigger [SHOULD]

**Description:**
Trigger review request when a user completes/saves a workout program to their routines.

**Acceptance Criteria:**
- Triggers after successful program save confirmation
- Only for first-time saves (not re-saves)

**Priority:** P1

### FR-005: Persistence & Tracking [MUST]

**Description:**
Persist review request state using AppStorageKeys pattern.

**Acceptance Criteria:**
- Store `lastReviewRequestDate` in UserDefaults
- Store `completedWorkoutsCount` or read from WorkoutHistoryRepository
- State survives app restarts

**Priority:** P0

---

## Non-Functional Requirements

### NFR-001: Non-Intrusive [MUST]
The review prompt must never interrupt an active user flow. It should only appear after a completed action.

### NFR-002: Apple Guidelines Compliance [MUST]
Must comply with Apple's App Store Review Guidelines regarding review prompts. Must use the official StoreKit API only. No custom review dialogs.

### NFR-003: Testability [SHOULD]
Service should be protocol-based for unit testing. Eligibility logic must be testable without StoreKit dependencies.

---

## Out of Scope

1. Custom in-app review/rating UI - Apple mandates using their API only
2. Review prompt A/B testing - Future consideration
3. Deep link to App Store review page - Not needed with StoreKit API
4. Analytics tracking of review submissions - Apple doesn't provide this callback

---

## Constraints

### Technical Constraints
- Apple limits `requestReview()` to 3 presentations per 365 days per device
- Apple may silently suppress the prompt based on internal heuristics
- No callback from Apple on whether the user actually left a review

### Platform Constraints
- iOS 16+ required for `AppStore.requestReview(in:)` (app already requires iOS 17+)
- StoreKit framework must be imported

---

## Release Planning

### Phase 1: MVP
- `AppReviewService` with eligibility checks
- Workout completion trigger
- AppStorageKeys for persistence
- Unit tests for eligibility logic

### Phase 2: Enhancement (Future)
- Program completion trigger
- Analytics tracking of prompt displays
- A/B testing framework integration

---

**Document End**
