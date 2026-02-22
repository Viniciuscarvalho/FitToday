# PRD: Firebase Remote Config Feature Flags

## Overview

Expand the existing Firebase Remote Config feature flag system to cover all major app features, enabling remote control of feature availability from the Firebase Console without app updates.

## Problem

Currently, only 3 feature flags exist (`personal_trainer_enabled`, `cms_workout_sync_enabled`, `trainer_chat_enabled`). All other features are hardcoded as always-on, which means:
- No ability to disable a broken feature without an App Store update
- No gradual feature rollout capability for new features
- No maintenance mode or force-update mechanism
- No A/B testing capability for feature variations

## Goals

1. Cover all major app features with remote flags
2. Provide a Firebase Remote Config key list ready for console setup
3. Enable operational flags (maintenance mode, force update)
4. Maintain offline fallback (UserDefaults cache already exists)
5. Zero breaking changes to existing architecture

## Non-Goals

- String/numeric remote config values (only boolean flags)
- A/B testing implementation (just the flag infrastructure)
- Admin dashboard UI for managing flags
- Per-user targeting (use Firebase Console conditions for that)

## Feature Flag List

### AI Features
| Remote Config Key | Default | Description |
|---|---|---|
| `ai_workout_generation_enabled` | `true` | AI-powered workout generation (OpenAI) |
| `ai_exercise_substitution_enabled` | `true` | AI exercise substitution during workout |

### Social Features
| Remote Config Key | Default | Description |
|---|---|---|
| `social_groups_enabled` | `true` | Group creation, joining, and management |
| `challenges_enabled` | `true` | Workout challenges within groups |
| `leaderboard_enabled` | `true` | Leaderboard ranking in groups |
| `check_in_enabled` | `true` | Photo check-in for challenge validation |
| `group_streaks_enabled` | `true` | Group streak tracking and display |

### Health & Sync
| Remote Config Key | Default | Description |
|---|---|---|
| `healthkit_sync_enabled` | `true` | Apple Health read/write integration |
| `stats_charts_enabled` | `true` | Activity stats with Swift Charts |

### Content
| Remote Config Key | Default | Description |
|---|---|---|
| `programs_enabled` | `true` | Structured training programs |
| `custom_workouts_enabled` | `true` | User-created workout templates |
| `exercise_library_enabled` | `true` | Exercise library/explorer (Wger API) |

### Personal Trainer (existing)
| Remote Config Key | Default | Description |
|---|---|---|
| `personal_trainer_enabled` | `false` | PT discovery and connection |
| `cms_workout_sync_enabled` | `false` | CMS workout sync from trainer |
| `trainer_chat_enabled` | `false` | In-app trainer messaging |

### Monetization & UX
| Remote Config Key | Default | Description |
|---|---|---|
| `paywall_enabled` | `true` | Show paywall/Pro upgrade prompts |
| `review_request_enabled` | `true` | App Store review request after workout |

### Operational
| Remote Config Key | Default | Description |
|---|---|---|
| `maintenance_mode_enabled` | `false` | Shows maintenance banner, disables writes |
| `force_update_enabled` | `false` | Shows non-dismissable update dialog |

**Total: 20 flags** (3 existing + 17 new)

## User Experience

- **Flag ON (default):** Feature works normally, no change for users
- **Flag OFF:** Feature section/button is hidden or shows a "temporarily unavailable" state
- **Maintenance mode:** A banner appears at the top, features still readable but writes disabled
- **Force update:** Full-screen non-dismissable dialog directing to App Store

## Technical Constraints

- Must use the existing `FeatureFlagKey` enum, `RemoteConfigService` actor, and `FeatureFlagUseCase`
- Must maintain UserDefaults cache fallback for offline
- Flags default to **enabled** for existing features (no regression)
- Flags default to **disabled** for unreleased features (Personal Trainer, Chat)
- `fetchAndActivate()` is already called on app launch

## Success Metrics

- All 20 flags configurable from Firebase Console
- Toggling a flag in Firebase Console reflects in app within 12h (prod) or immediately (debug)
- Zero regression: existing features work identically when flags are at default values
