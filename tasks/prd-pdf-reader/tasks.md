# Tasks

**Feature:** CMS Workout PDF Reader + Localization Cleanup
**Date:** 2026-02-17

---

## Task 1: Add pdfUrl to TrainerWorkout domain model

**File:** `Domain/Entities/PersonalTrainerModels.swift`
**Action:** Add `pdfUrl: String?` property to the `TrainerWorkout` struct.
**Acceptance:** The domain model carries the PDF URL from CMS data through to the presentation layer.

---

## Task 2: Map pdfUrl in CMSWorkoutMapper

**File:** `Data/Mappers/CMSWorkoutMapper.swift`
**Action:** Update `toDomain(_ cms: CMSWorkout) -> TrainerWorkout` to map `cms.pdfUrl` to the new `pdfUrl` property.
**Acceptance:** When a CMS workout has a `pdfUrl`, it appears in the mapped `TrainerWorkout`.

---

## Task 3: Add PDF button to CMSWorkoutDetailView

**File:** `Presentation/Features/PersonalTrainer/CMSWorkoutDetailView.swift`
**Action:** Add a "Ver PDF" button in the actions section that opens the existing `PDFViewerView` via a `.sheet()` when `workout.pdfUrl` is not nil. Use `PDFCacheService` for download/cache.
**Acceptance:** Students can tap "Ver PDF" to view the trainer's attached PDF workout file.

---

## Task 4: Localize PersonalTrainerView.swift

**File:** `Presentation/Features/PersonalTrainer/PersonalTrainerView.swift`
**Action:** Replace all ~18 hardcoded Portuguese strings with `.localized` keys. Add corresponding keys to both `en.lproj/Localizable.strings` and `pt-BR.lproj/Localizable.strings`.
**Key prefix:** `personal_trainer.*`
**Acceptance:** No hardcoded Portuguese strings remain in the file. Both locale files have the new keys.

---

## Task 5: Localize CMSWorkoutDetailView.swift

**File:** `Presentation/Features/PersonalTrainer/CMSWorkoutDetailView.swift`
**Action:** Replace all ~10 hardcoded strings with `.localized` keys. Add keys to both locale files.
**Key prefix:** `cms_workout.*`
**Acceptance:** All user-facing strings use localization.

---

## Task 6: Localize CMSWorkoutFeedbackView.swift

**File:** `Presentation/Features/PersonalTrainer/CMSWorkoutFeedbackView.swift`
**Action:** Replace all ~8 hardcoded strings with `.localized` keys. Add keys to both locale files.
**Key prefix:** `cms_feedback.*`
**Acceptance:** All user-facing strings use localization.

---

## Task 7: Localize TrainerSearchView.swift and ConnectionRequestSheet.swift

**Files:** `Presentation/Features/PersonalTrainer/TrainerSearchView.swift`, `Presentation/Features/PersonalTrainer/Components/ConnectionRequestSheet.swift`
**Action:** Replace hardcoded strings with `.localized` keys. Add keys to both locale files.
**Acceptance:** No hardcoded Portuguese strings remain.

---

## Task 8: Localize PDFCacheService error descriptions

**File:** `Data/Services/PDFCacheService.swift`
**Action:** Replace hardcoded error descriptions in `PDFCacheError` with localized strings using `.localized` or `NSLocalizedString`.
**Key prefix:** `pdf.error.*`
**Acceptance:** Error messages are localized.

---

## Task 9: Build verification and test

**Action:** Build the project. Verify no compilation errors. Run existing tests.
**Acceptance:** Build succeeds. All tests pass.

---

## Task 10: Unit tests for PDF mapping

**Action:** Write unit tests verifying `CMSWorkoutMapper.toDomain()` correctly maps `pdfUrl` from the CMS DTO to the domain model.
**Acceptance:** Tests pass, covering both nil and non-nil pdfUrl cases.
