# Analysis - FitToday App Restructure v2

## Project Context

### Current State
- iOS 17+ app using SwiftUI with @Observable
- Firebase (Auth, Firestore) for backend
- ExerciseDB API for exercises (to be replaced)
- HealthKit integration for health data
- OpenAI API for AI-generated workouts
- Custom Design System with retro-futuristic theme

### Design System Analysis

The app uses a distinctive **Dark Theme with Purple Futuristic** aesthetic:

#### Color Palette
- **Primary Brand:** `#7C3AED` (Purple vibrante)
- **Secondary:** `#A78BFA` (Purple claro)
- **Accent:** `#5B21B6` (Purple escuro)
- **Background:** `#0D0D14` (Deep dark purple/navy)
- **Surface:** `#1E1E2E` (Cards)
- **Neon Cyan:** `#00E5FF` (Highlights)

#### Typography
- **Display:** Orbitron (Bold, ExtraBold, Black)
- **UI:** Rajdhani (Medium, SemiBold, Bold)
- **Accent:** Bungee

#### Visual Effects
- Retro grid overlays
- Diagonal stripe patterns
- Tech corner borders (L-shaped)
- Scanline overlays (VHS effect)
- Neon glow effects

### Architecture Analysis

#### Current Layers
1. **Presentation:** SwiftUI Views, @Observable ViewModels, Design System
2. **Domain:** Entities, Use Cases, Repository Protocols
3. **Data:** Firebase Services, API Services, Repositories

#### Dependency Injection
- Uses SwiftInject pattern
- AppContainer for service registration
- DependencyResolverKey for environment injection

### Key Changes Required

1. **API Migration:** ExerciseDB → Wger API
2. **TabBar Restructure:** Programs → Workout tab
3. **New Features:**
   - Manual workout creation
   - Programs catalog (26 programs)
   - Unified activity tracking
   - AI-powered home screen

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wger API downtime | High | Aggressive caching, local fallback |
| Data migration | Medium | Incremental rollout, backup strategy |
| UI complexity | Medium | Reuse existing Design System components |
| HealthKit sync issues | Medium | Robust merge logic, conflict resolution |

## Implementation Strategy

### Phase Order
1. **Phase 1:** Wger API Migration (foundation)
2. **Phase 2:** Workout System (core feature)
3. **Phase 3:** Programs Catalog (content)
4. **Phase 4:** Activity & Sync (integration)
5. **Phase 5:** Home & AI (enhancement)

### Parallel Work Opportunities
- Phase 3 can start while Phase 2 UI is being developed
- Phase 5 home UI can be developed alongside Phase 4

### Critical Path
```
Wger API → Workout Models → Workout UI → Programs → Activity → Home
```

## Technical Decisions

1. **SwiftData vs Core Data:** Use SwiftData (iOS 17+) for local cache
2. **Concurrency:** Swift 6 strict concurrency with async/await
3. **Navigation:** Path-based navigation with AppRouter
4. **State Management:** @Observable for ViewModels, @State for local view state

## Files to Create/Modify

### New Files (Estimated: ~50 files)
- 15+ Domain entities
- 10+ Services
- 20+ Views
- 5+ ViewModels

### Modified Files (Estimated: ~15 files)
- TabRootView
- AppRouter
- AppContainer
- Existing ViewModels using exercises

## Next Steps

1. ✅ PRD copied to tasks directory
2. ✅ Technical specification generated
3. ✅ Tasks breakdown created
4. ⏳ Create design screens in Pencil MCP
5. ⏳ Begin Phase 1 implementation
