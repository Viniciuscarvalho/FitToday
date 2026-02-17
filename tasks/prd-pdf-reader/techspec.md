# Technical Specification

**Feature:** CMS Workout PDF Reader + Localization Cleanup
**Date:** 2026-02-17
**Status:** Approved

---

## Architecture Overview

This feature adds PDF viewing capability to CMS workout detail views and extracts hardcoded strings to Localizable.strings. Both changes are additive and follow existing patterns.

### PDF Integration

**Existing Components (no modification needed):**
- `PDFViewerView` - SwiftUI wrapper for PDFKit (already handles PDF + image display)
- `PDFCacheService` - Actor-based download + cache service

**Integration Point:**
- `CMSWorkoutDetailView` - Add a "Ver PDF" button when `pdfUrl` is available
- The `CMSWorkout` DTO already has a `pdfUrl: String?` field
- The `TrainerWorkout` domain model needs to expose the PDF URL (currently not mapped)

**Data Flow:**
```
CMSWorkout.pdfUrl (DTO) → CMSWorkoutMapper → TrainerWorkout.pdfUrl (Domain)
→ CMSWorkoutDetailView → PDFViewerView (via .sheet or navigation)
```

### Changes Required

#### 1. Domain Layer
- **PersonalTrainerModels.swift** - Add `pdfUrl: String?` to `TrainerWorkout`

#### 2. Data Layer
- **CMSWorkoutMapper.swift** - Map `cms.pdfUrl` to `TrainerWorkout.pdfUrl`

#### 3. Presentation Layer
- **CMSWorkoutDetailView.swift** - Add PDF button + sheet presentation
- **PersonalTrainerView.swift** - Replace hardcoded strings with `.localized`
- **CMSWorkoutFeedbackView.swift** - Replace hardcoded strings with `.localized`
- **TrainerSearchView.swift** - Replace hardcoded strings with `.localized`
- **ConnectionRequestSheet.swift** - Replace hardcoded strings with `.localized`

#### 4. Resources
- **en.lproj/Localizable.strings** - Add ~50 new keys
- **pt-BR.lproj/Localizable.strings** - Add ~50 new keys

### Localization Key Naming Convention

```
personal_trainer.find.title
personal_trainer.find.subtitle
personal_trainer.search.button
personal_trainer.status.active
personal_trainer.workouts.title
personal_trainer.workouts.empty
cms_workout.detail.title
cms_workout.progress.title
cms_workout.completion.button
cms_feedback.empty.title
cms_feedback.type.general
cms_feedback.input.placeholder
pdf.error.invalid_url
```

### Testing Strategy

- Unit tests for `CMSWorkoutMapper` to verify `pdfUrl` mapping
- Verify all localization keys exist in both locale files
- Build verification (no hardcoded string warnings)

---

**Document End**
