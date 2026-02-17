# Product Requirements Document (PRD)

**Project Name:** CMS Workout PDF Reader + Localization Cleanup
**Document Version:** 1.0
**Date:** 2026-02-17
**Author:** FitToday Team
**Status:** Approved

---

## Executive Summary

**Problem Statement:**
Students connected to a personal trainer via the CMS integration cannot view PDF workout attachments sent by their trainer. Additionally, the Personal Trainer feature and CMS workout views contain ~48 hardcoded Portuguese strings, violating the app's established localization pattern and breaking the i18n system for potential future language support.

**Proposed Solution:**
1. Wire the existing `PDFViewerView` and `PDFCacheService` into the CMS workout detail flow, allowing students to open and view PDF workout files attached to trainer workouts.
2. Extract all hardcoded strings in the Personal Trainer feature area into `Localizable.strings` using the existing `.localized` extension pattern.

**Business Value:**
- Complete the trainer-student communication loop (structured workouts + PDF attachments + feedback)
- Maintain i18n readiness for future market expansion
- Improve code quality and consistency

---

## Functional Requirements

### FR-001: CMS Workout PDF Viewer [MUST]

**Description:**
When a CMS workout has an attached PDF (`pdfUrl` field), the student should be able to open and view it from the workout detail view.

**Acceptance Criteria:**
- A "Ver PDF" button appears in `CMSWorkoutDetailView` when `workout.pdfUrl` is not nil
- Tapping the button opens the existing `PDFViewerView` with the PDF URL
- PDF is downloaded and cached using the existing `PDFCacheService`
- Loading, error, and empty states are handled gracefully
- The PDF view supports zooming, scrolling, and sharing

---

### FR-002: Personal Trainer Localization [MUST]

**Description:**
All hardcoded Portuguese strings in the Personal Trainer feature (views, sheets, error messages) must be replaced with localized string keys using the `.localized` pattern.

**Acceptance Criteria:**
- All strings in `PersonalTrainerView.swift`, `TrainerSearchView.swift`, `ConnectionRequestSheet.swift` use Localizable.strings keys
- Keys follow the `personal_trainer.*` naming convention
- Both `en.lproj` and `pt-BR.lproj` files are updated with new keys

---

### FR-003: CMS Workout Views Localization [MUST]

**Description:**
All hardcoded Portuguese strings in `CMSWorkoutDetailView.swift` and `CMSWorkoutFeedbackView.swift` must be replaced with localized string keys.

**Acceptance Criteria:**
- All strings in CMS workout views use Localizable.strings keys
- Keys follow the `cms_workout.*` and `cms_feedback.*` naming conventions
- Both locale files updated

---

### FR-004: PDF Cache Error Localization [SHOULD]

**Description:**
Error descriptions in `PDFCacheService.swift` should use localized strings instead of hardcoded Portuguese.

**Acceptance Criteria:**
- `PDFCacheError` cases use localized error descriptions
- Keys follow the `pdf.error.*` naming convention

---

## Out of Scope

1. PDF annotation or editing capabilities
2. Offline PDF sync from CMS
3. Adding new languages beyond en/pt-BR
4. Refactoring existing localized views (only new/unlocalized views are in scope)

---

## Assumptions and Dependencies

### Assumptions
1. The `CMSWorkout.pdfUrl` field contains a valid HTTPS URL when present
2. The existing `PDFCacheService` can handle CMS PDF URLs (not just Firebase Storage URLs)
3. The `PDFViewerView` component works correctly (already tested with personal workouts)

### Dependencies
- `PDFViewerView.swift` - Existing PDF rendering component
- `PDFCacheService.swift` - Existing PDF download/cache service
- `Localizable.strings` (en, pt-BR) - Existing localization files
- `String+Localized` extension - Existing `.localized` pattern

---

**Document End**
