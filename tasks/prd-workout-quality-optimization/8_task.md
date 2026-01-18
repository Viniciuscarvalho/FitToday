# [8.0] Add HealthKit sync toggle in settings (S)

## status: pending

<task_context>
<domain>presentation/features</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>low</complexity>
<dependencies>task_7</dependencies>
</task_context>

# Task 8.0: Add HealthKit sync toggle in settings

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add a toggle in the app settings to enable/disable automatic HealthKit synchronization. When disabled, workouts will not be exported to Apple Health. The setting should persist across app launches.

<requirements>
- Add "Sincronizar com Apple Health" toggle in settings
- Show HealthKit authorization status
- Prompt for authorization when enabling (if not yet authorized)
- Persist preference using UserDefaults or AppStorage
- Show explanation text about what data is shared
</requirements>

## Subtasks

- [ ] 8.1 Add `healthKitSyncEnabled` to UserPreferences/Settings
- [ ] 8.2 Create HealthKit settings section in SettingsView
- [ ] 8.3 Show current authorization status indicator
- [ ] 8.4 Trigger authorization flow when enabling toggle
- [ ] 8.5 Add explanatory text about data sharing
- [ ] 8.6 Handle authorization denied state (show Settings link)
- [ ] 8.7 Write UI tests for settings flow

## Implementation Details

### Settings UI Design

```
┌─────────────────────────────────────────┐
│ Apple Health                            │
├─────────────────────────────────────────┤
│                                         │
│ Sincronizar com Apple Health      [ON]  │
│ Exporta seus treinos para o app Saúde   │
│                                         │
│ Status: ✓ Autorizado                    │
│         ○ Não autorizado (Configurar)   │
│                                         │
└─────────────────────────────────────────┘
```

### Authorization States

| State | UI | Action |
|-------|-----|--------|
| `.authorized` | ✓ Autorizado (green) | Toggle works |
| `.notDetermined` | Toggle triggers auth prompt | Request authorization |
| `.denied` | ⚠️ Não autorizado | Show "Abrir Ajustes" link |
| `.notAvailable` | Section hidden | N/A (no HealthKit) |

### Preference Storage

```swift
@AppStorage("healthKitSyncEnabled") var healthKitSyncEnabled: Bool = true
```

## Success Criteria

- [ ] Toggle appears in Settings view
- [ ] Toggle state persists across app launches
- [ ] Enabling toggle triggers authorization when needed
- [ ] Denied state shows link to Settings app
- [ ] Toggle disabled/hidden when HealthKit not available
- [ ] Explanatory text is clear and localized
- [ ] Disabling toggle prevents workout export

## Dependencies

- Task 7.0: HealthKit sync implementation

## Notes

- Default to enabled (true) for new users
- Use `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)` for Settings link
- Consider showing last sync date/time
- Test on iPad (HealthKit available but no Apple Watch)

## Relevant Files

### Files to Modify
- `/FitToday/Presentation/Features/Settings/SettingsView.swift`
- `/FitToday/Presentation/Features/Settings/SettingsViewModel.swift`
- `/FitToday/Domain/UseCases/CompleteWorkoutSessionUseCase.swift` (check preference)

### Files to Create
- `/FitToday/Presentation/Features/Settings/HealthKitSettingsSection.swift`
- `/FitToday/Data/Preferences/UserPreferences.swift` (if not exists)
