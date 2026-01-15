# [1.0] Firebase SDK Setup & Configuration (M)

## status: pending

<task_context>
<domain>infrastructure/firebase</domain>
<type>configuration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>firebase_sdk|spm|xcode</dependencies>
</task_context>

# Task 1.0: Firebase SDK Setup & Configuration

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Set up Firebase SDK integration in FitToday using Swift Package Manager. This task establishes the foundation for all Firebase features (Authentication, Firestore) required for the Social Challenges feature.

<requirements>
- Add Firebase iOS SDK via Swift Package Manager (SPM)
- Configure Firebase project in Firebase Console
- Download and integrate GoogleService-Info.plist
- Initialize Firebase in app lifecycle
- Update .gitignore to prevent committing sensitive Firebase credentials
- Configure Firestore database with initial security rules
- Create required Firestore indexes
</requirements>

## Subtasks

- [ ] 1.1 Create Firebase project in Firebase Console
  - Project name: "FitToday" or appropriate name
  - Enable Google Analytics (optional but recommended)
  - Register iOS app with bundle identifier

- [ ] 1.2 Add Firebase SDK via Swift Package Manager
  - Add package: `https://github.com/firebase/firebase-ios-sdk.git`
  - Version: 10.20.0 or later (Swift 6 compatible)
  - Products to add: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift

- [ ] 1.3 Download and integrate GoogleService-Info.plist
  - Download from Firebase Console
  - Add to FitToday target (not FitTodayTests)
  - Ensure "Copy Bundle Resources" includes the file

- [ ] 1.4 Initialize Firebase in FitTodayApp.swift
  - Import FirebaseCore
  - Call FirebaseApp.configure() in app init()

- [ ] 1.5 Update .gitignore
  - Add GoogleService-Info.plist to prevent committing
  - Document setup steps in README or SETUP.md

- [ ] 1.6 Configure Firestore database
  - Enable Firestore in Firebase Console
  - Set region (prefer US-based for lower latency)
  - Start in test mode initially (will update security rules in Task 5.0)

- [ ] 1.7 Create Firestore composite indexes
  - Index 1: `challenges` collection: (groupId, weekStartDate, type, isActive)
  - Index 2: `notifications` collection: (userId, createdAt DESC)
  - These can be created via Firebase Console or auto-created on first query

## Implementation Details

Reference **techspec.md** section: "Integration Points > Firebase SDK Integration"

### Firebase Initialization Code
```swift
import SwiftUI
import FirebaseCore

@main
struct FitTodayApp: App {
  init() {
    FirebaseApp.configure()
    // ... existing setup
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

### Package.swift / SPM Configuration
Add via Xcode:
- File > Add Package Dependencies
- Enter URL: `https://github.com/firebase/firebase-ios-sdk.git`
- Dependency Rule: Up to Next Major Version (10.20.0 < 11.0.0)
- Products: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift

### .gitignore Entry
```
# Firebase
GoogleService-Info.plist
```

## Success Criteria

- [ ] Firebase SDK successfully added to project without build errors
- [ ] GoogleService-Info.plist present in project but NOT committed to Git
- [ ] App launches without crashes after Firebase initialization
- [ ] Firebase Console shows iOS app registered and connected
- [ ] Firestore database created and accessible via Console
- [ ] No compiler warnings related to Firebase imports
- [ ] Documentation exists for other developers to setup Firebase locally

## Dependencies

**Before starting this task:**
- Xcode project must be using Swift Package Manager
- Firebase project must be created (done in subtask 1.1)
- Apple Developer account required for bundle identifier

**Blocks these tasks:**
- Task 2.0 (Firebase Authentication) - requires SDK
- Task 5.0 (Firebase Group Service) - requires SDK
- All Firebase-dependent tasks

## Notes

- **Security**: NEVER commit GoogleService-Info.plist to version control. This file contains API keys.
- **Team Setup**: Document Firebase setup process for other developers (e.g., in CONTRIBUTING.md or SETUP.md)
- **Firebase Plan**: Start with free Spark plan. Monitor usage during development.
- **Firestore Region**: Choose region closest to primary user base (e.g., us-central1 for US users)
- **Testing**: Use Firebase Emulator Suite for local testing (optional, can be added in Task 19.0)

## Validation Steps

1. Build project: `⌘ + B` - should succeed without errors
2. Run app on simulator - should launch without crashes
3. Check Xcode console for Firebase initialization log: `[FirebaseApp] Configured`
4. Open Firebase Console → Project Settings → Your Apps → verify iOS app shows "Latest SDK Version"
5. Git status: `GoogleService-Info.plist` should NOT appear in untracked/staged files

## Relevant Files

### Files to Create
- `/FitToday/GoogleService-Info.plist` (downloaded from Firebase Console)
- `/.gitignore` (update existing file)
- `/SETUP.md` (optional - Firebase setup documentation)

### Files to Modify
- `/FitToday/FitTodayApp.swift` - Add Firebase initialization
- `/FitToday.xcodeproj/project.pbxproj` - SPM will auto-modify when adding packages

### Firebase Console Configuration
- Firestore Database → Rules (will be updated in Task 5.0)
- Firestore Database → Indexes (create composite indexes)
