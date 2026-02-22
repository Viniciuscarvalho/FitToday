# Firebase Remote Config — Key List

Reference document for configuring FitToday feature flags in Firebase Console.
All parameters are **boolean** type.

## How to Configure

1. Go to Firebase Console > Remote Config
2. Add each parameter below with its key, type (Boolean), and default value
3. Publish changes — the app will pick them up on next launch (or within 12h for active users)

---

## AI Features

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `ai_workout_generation_enabled` | AI Workout Generation | Boolean | `true` | Enables AI-powered workout generation (OpenAI) |
| `ai_exercise_substitution_enabled` | AI Exercise Substitution | Boolean | `true` | Enables AI exercise substitution during active workout |

## Social Features

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `social_groups_enabled` | Social Groups | Boolean | `true` | Enables group creation, joining, and management |
| `challenges_enabled` | Challenges | Boolean | `true` | Enables workout challenges within groups |
| `leaderboard_enabled` | Leaderboard | Boolean | `true` | Enables leaderboard ranking in groups |
| `check_in_enabled` | Check-In | Boolean | `true` | Enables photo check-in for challenge validation |
| `group_streaks_enabled` | Group Streaks | Boolean | `true` | Enables group streak tracking and display |

## Health & Sync

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `healthkit_sync_enabled` | Apple Health Sync | Boolean | `true` | Enables Apple Health read/write integration |
| `stats_charts_enabled` | Stats Charts | Boolean | `true` | Enables activity stats with Swift Charts |

## Content

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `programs_enabled` | Training Programs | Boolean | `true` | Enables structured training programs |
| `custom_workouts_enabled` | Custom Workouts | Boolean | `true` | Enables user-created workout templates |
| `exercise_library_enabled` | Exercise Library | Boolean | `true` | Enables exercise library/explorer (Wger API) |

## Personal Trainer

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `personal_trainer_enabled` | Personal Trainer Integration | Boolean | `false` | Enables personal trainer connection via CMS |
| `cms_workout_sync_enabled` | CMS Workout Sync | Boolean | `false` | Enables synchronization of trainer-assigned workouts |
| `trainer_chat_enabled` | Trainer Chat | Boolean | `false` | Enables chat functionality with personal trainers |

## Monetization & UX

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `paywall_enabled` | Paywall | Boolean | `true` | Enables paywall/Pro upgrade prompts |
| `review_request_enabled` | Review Request | Boolean | `true` | Enables App Store review request after workout |

## Operational

| Key | Display Name | Type | Default | Description |
|-----|-------------|------|---------|-------------|
| `maintenance_mode_enabled` | Maintenance Mode | Boolean | `false` | Shows maintenance banner and disables app |
| `force_update_enabled` | Force Update | Boolean | `false` | Shows non-dismissable update dialog |

---

**Total: 20 parameters**

### Default Value Strategy

- **`true`** (15 keys): Existing, shipped features. Setting default to `true` ensures no regression if Remote Config is unreachable.
- **`false`** (5 keys): Unreleased or operational features. These remain off until explicitly enabled from Firebase Console.

### Fetch Behavior

- **Production**: Minimum fetch interval = 12 hours (Firebase default)
- **Debug**: Minimum fetch interval = 0 seconds (immediate updates for testing)
- On app launch, flags are fetched and activated via `RemoteConfigService`
- Values are cached locally in UserDefaults via `RemoteConfigFeatureFlagRepository`
