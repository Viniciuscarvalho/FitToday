# Analysis: Program Workout Templates Expansion

## Current State

### Workout Templates (8 total)
1. `lib_push_hypertrophy_gym` - Push Day (8 exercises, intermediate/advanced level)
2. `lib_pull_hypertrophy_gym` - Pull Day (8 exercises, intermediate/advanced level)
3. `lib_legs_hypertrophy_gym` - Leg Day (8 exercises, intermediate/advanced level)
4. `lib_fullbody_conditioning_home` - Full Body Bodyweight (8 exercises)
5. `lib_hiit_weightloss_home` - HIIT for weight loss (7 exercises)
6. `lib_upper_dumbbells_home` - Upper Body with dumbbells (8 exercises)
7. `lib_lower_dumbbells_home` - Lower Body with dumbbells (8 exercises)
8. `lib_core_strength_home` - Core workout (8 exercises)

### Programs (26 total)
All 26 programs reference the same 8 templates regardless of level:
- PPL Beginner/Intermediate/Advanced all use the same push/pull/legs templates
- No differentiation between beginner and advanced exercise selection

### Key Issues Found
1. **Same exercises for all levels** - Beginner PPL uses barbell bench press (advanced) instead of machine chest press (beginner)
2. **No level-appropriate rep ranges** - All templates use intermediate rep ranges
3. **No rest interval variation** - Beginners need longer rest, advanced need shorter
4. **Exercise preview not visible** - WorkoutRowCard only shows count, not exercise names

## Implementation Plan

### Priority 1: Add Exercise Preview to UI (Quick Win)
Modify `WorkoutRowCard` to show first 3 exercises with "+ X mais exercícios"

### Priority 2: Create Level-Specific Templates
Following the techspec guidelines:
- Beginner: 4-5 exercises, machines/cables, 3x10-15, 90-120s rest
- Intermediate: 5-6 exercises, mixed, 3-4x8-12, 60-90s rest
- Advanced: 6-8 exercises, compound focus, 4-5x6-10, 60-120s rest

### Priority 3: Update Program Mappings
After templates are created, update ProgramsSeed.json to reference appropriate templates.

## Files to Modify
1. `ProgramDetailView.swift` - Add exercise preview to WorkoutRowCard
2. `LibraryWorkoutsSeed.json` - Add new level-specific templates
3. `ProgramsSeed.json` - Update workout_template_ids references
4. `Localizable.strings` (pt-BR and en) - Add localization keys

## Complexity Assessment
- UI enhancement: Low complexity (modify existing component)
- Template creation: Medium complexity (JSON data, needs care with IDs)
- Program mapping: Low complexity (update references)
