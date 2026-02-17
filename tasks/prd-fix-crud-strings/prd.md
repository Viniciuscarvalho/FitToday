# PRD: Fix CRUD Operations, Localization & Workout Flow

## Overview

This PRD addresses multiple critical bugs and improvements reported by users during testing:

1. **Workout Generation Flow** - After answering questionnaire, returns to home but "Generate" button does nothing
2. **Exercise Reorder** - "Add" button in exercise reorder doesn't work
3. **Hardcoded Strings** - Portuguese strings hardcoded instead of using Localizable.strings
4. **Workout Save CRUD** - Save button when creating new workout does nothing
5. **PDF Display** - PDF files from CMS should display in Personal tab

## Problem Statement

Users are experiencing multiple friction points that break core app functionality:
- Cannot generate workouts after completing the questionnaire flow
- Cannot reorder or add exercises to custom workouts
- App has inconsistent language (hardcoded Portuguese)
- Cannot save newly created workouts
- Cannot view PDF content from CMS in the Personal tab

## Success Criteria

- [ ] Workout generation completes successfully after questionnaire
- [ ] Exercise reorder/add functionality works correctly
- [ ] All user-facing strings use Localizable.strings (PT-BR and EN)
- [ ] Save workflow for custom workouts persists data correctly
- [ ] PDF files from CMS display correctly in Personal tab

## User Stories

### US-1: Workout Generation Flow
**As a** user who completed the daily questionnaire
**I want to** generate a workout using AI
**So that** I can start my training session

**Acceptance Criteria:**
- After questionnaire completion, user returns to Home with inputs preserved
- Clicking "Generate" button creates a workout using the selected parameters
- Loading state shows during generation
- Generated workout preview displays correctly

### US-2: Exercise Reorder
**As a** user customizing my workout
**I want to** reorder exercises and add new ones
**So that** I can personalize my training routine

**Acceptance Criteria:**
- "Add" button opens exercise search/selection sheet
- Selected exercises are added to the workout
- Exercises can be reordered via drag-and-drop
- Changes persist when saving

### US-3: Localization
**As a** user
**I want to** see the app in my preferred language (PT-BR or EN)
**So that** I can understand all content

**Acceptance Criteria:**
- No hardcoded Portuguese strings in code
- All strings in Localizable.strings for both PT-BR and EN
- App respects device language setting

### US-4: Workout Save CRUD
**As a** user creating a custom workout
**I want to** save my workout
**So that** I can use it later

**Acceptance Criteria:**
- Save button triggers save action
- Workout is persisted to storage
- Success feedback shown to user
- Workout appears in saved workouts list

### US-5: PDF Display
**As a** user with a personal trainer
**I want to** view PDF files submitted by my trainer via CMS
**So that** I can follow my personalized program

**Acceptance Criteria:**
- Personal tab fetches PDF from CMS endpoint
- PDF renders correctly in app
- Loading and error states handled
- PDF can be scrolled and zoomed

## Technical Requirements

### Files to Investigate/Modify

1. **Workout Generation Flow:**
   - `HomeView.swift` - generateWorkout() action
   - `HomeViewModel.swift` - generateWorkoutWithCheckIn()
   - Navigation flow after generation

2. **Exercise Reorder:**
   - Custom workout creation views
   - Exercise search/selection sheet
   - State management for exercise list

3. **Localization:**
   - Grep for hardcoded Portuguese strings
   - `Resources/pt-BR.lproj/Localizable.strings`
   - `Resources/en.lproj/Localizable.strings`

4. **Workout Save CRUD:**
   - Custom workout creation ViewModel
   - Repository save methods
   - SwiftData/persistence layer

5. **PDF Display:**
   - Personal tab view
   - CMS API endpoint for PDF
   - PDFKit integration or WebView

## Out of Scope

- New features beyond fixing existing bugs
- Backend/CMS changes
- UI/UX redesign

## Dependencies

- CMS must provide PDF endpoint (verify existing route)
- OpenAI API for workout generation (already implemented)

## Timeline

Priority: **HIGH** - These are blocking issues for user testing
