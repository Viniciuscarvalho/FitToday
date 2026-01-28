# Technical Specification: FitToday Pivot - Fase 1

## 1. Architecture Overview

### 1.1 Current Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Views         │  │   ViewModels    │  │   Router        │ │
│  │   (SwiftUI)     │  │   (@Observable) │  │   (Navigation)  │ │
│  └────────┬────────┘  └────────┬────────┘  └─────────────────┘ │
└───────────┼────────────────────┼────────────────────────────────┘
            │                    │
┌───────────┼────────────────────┼────────────────────────────────┐
│           │     Domain Layer   │                                │
│  ┌────────▼────────┐  ┌────────▼────────┐  ┌─────────────────┐ │
│  │   Entities      │  │   Use Cases     │  │   Protocols     │ │
│  │   (Models)      │  │   (Business)    │  │   (Repository)  │ │
│  └─────────────────┘  └────────┬────────┘  └────────┬────────┘ │
└────────────────────────────────┼────────────────────┼──────────┘
                                 │                    │
┌────────────────────────────────┼────────────────────┼──────────┐
│                     Data Layer │                    │          │
│  ┌─────────────────┐  ┌────────▼────────┐  ┌───────▼────────┐ │
│  │   DTOs          │  │   Repositories  │  │   Services     │ │
│  │   (Firebase)    │  │   (Impl)        │  │   (API/DB)     │ │
│  └─────────────────┘  └─────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 New Components (Fase 1)

```
Domain/
├── Entities/
│   └── GroupStreakModels.swift          # NEW: GroupStreakWeek, MemberWeeklyStatus
├── UseCases/
│   ├── UpdateGroupStreakUseCase.swift   # NEW: Streak update logic
│   ├── PauseGroupStreakUseCase.swift    # NEW: Admin pause feature
│   └── SyncWorkoutCompletionUseCase.swift  # MODIFY: Add streak tracking

Data/
├── Repositories/
│   └── FirebaseGroupStreakRepository.swift  # NEW: Streak persistence
├── Services/
│   ├── OpenAI/
│   │   ├── WorkoutPromptAssembler.swift     # MODIFY: Add exercise catalog
│   │   └── HybridWorkoutPlanComposer.swift  # MODIFY: Cache key diversity
│   └── ExerciseDB/
│       ├── ExerciseMediaResolver.swift      # MODIFY: Add timeout
│       └── ExerciseTranslationDictionary.swift  # MODIFY: Add translations

Presentation/
├── Features/
│   └── Groups/
│       ├── GroupStreakCardView.swift        # NEW: Streak card component
│       ├── GroupStreakDetailView.swift      # NEW: Detail view
│       ├── GroupStreakViewModel.swift       # NEW: ViewModel
│       ├── MilestoneOverlayView.swift       # NEW: Celebration overlay
│       └── GroupDashboardView.swift         # MODIFY: Add streak card
```

---

## 2. Data Models

### 2.1 New Models (`Domain/Entities/GroupStreakModels.swift`)

```swift
import Foundation

// MARK: - Group Streak Week

/// Represents a single week's tracking for group streak
struct GroupStreakWeek: Codable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let weekStartDate: Date  // Monday 00:00 UTC
    let weekEndDate: Date    // Sunday 23:59 UTC
    var memberCompliance: [String: MemberWeeklyStatus]
    var allCompliant: Bool
    let createdAt: Date

    var isCurrentWeek: Bool {
        let now = Date()
        return now >= weekStartDate && now <= weekEndDate
    }
}

/// Individual member's weekly workout status
struct MemberWeeklyStatus: Codable, Sendable {
    let userId: String
    var workoutCount: Int
    var lastWorkoutDate: Date?

    var isCompliant: Bool { workoutCount >= 3 }

    var complianceStatus: ComplianceStatus {
        if workoutCount >= 3 { return .compliant }
        if workoutCount >= 2 { return .atRisk }
        if workoutCount >= 1 { return .atRisk }
        return .notStarted
    }
}

/// Compliance status for UI display
enum ComplianceStatus: String, Codable, Sendable {
    case compliant     // 3+ workouts
    case atRisk        // 1-2 workouts
    case notStarted    // 0 workouts
    case failed        // End of week, <3 workouts
}

// MARK: - Group Streak Status

/// Complete streak status for a group
struct GroupStreakStatus: Codable, Sendable {
    let groupId: String
    var streakDays: Int
    var streakStartDate: Date?
    var pausedUntil: Date?
    var lastPauseDate: Date?
    var lastMilestoneReached: StreakMilestone?
    var currentWeek: GroupStreakWeek?
    var weekHistory: [GroupStreakWeek]

    var isPaused: Bool {
        guard let pausedUntil else { return false }
        return Date() < pausedUntil
    }

    var nextMilestone: StreakMilestone? {
        StreakMilestone.allCases.first { $0.days > streakDays }
    }

    var daysToNextMilestone: Int? {
        guard let next = nextMilestone else { return nil }
        return next.days - streakDays
    }
}

/// Milestone thresholds for celebrations
enum StreakMilestone: Int, Codable, Sendable, CaseIterable {
    case week1 = 7
    case week2 = 14
    case month1 = 30
    case month2 = 60
    case day100 = 100

    var days: Int { rawValue }

    var title: String {
        switch self {
        case .week1: return "1 Semana"
        case .week2: return "2 Semanas"
        case .month1: return "1 Mês"
        case .month2: return "2 Meses"
        case .day100: return "100 Dias"
        }
    }

    var emoji: String {
        switch self {
        case .week1: return "🎯"
        case .week2: return "💪"
        case .month1: return "🏆"
        case .month2: return "⭐"
        case .day100: return "🔥"
        }
    }
}
```

### 2.2 Extensions to Existing Models

```swift
// Extension to SocialModels.swift

extension ChallengeType {
    case groupStreak = "group-streak"
}

extension SocialGroup {
    var groupStreakDays: Int { get set }
    var groupStreakStartDate: Date? { get set }
    var groupStreakPausedUntil: Date? { get set }
    var groupStreakLastMilestone: Int? { get set }
}
```

### 2.3 Firebase DTOs (`Data/Models/FirebaseModels.swift`)

```swift
// Add to FirebaseModels.swift

struct FBGroupStreakWeek: Codable {
    @DocumentID var id: String?
    var groupId: String
    @ServerTimestamp var weekStartDate: Timestamp?
    @ServerTimestamp var weekEndDate: Timestamp?
    var memberCompliance: [String: FBMemberWeeklyStatus]
    var allCompliant: Bool
    @ServerTimestamp var createdAt: Timestamp?
}

struct FBMemberWeeklyStatus: Codable {
    var userId: String
    var workoutCount: Int
    @ServerTimestamp var lastWorkoutDate: Timestamp?
}

// Extension to FBGroup
extension FBGroup {
    var groupStreakDays: Int?
    @ServerTimestamp var groupStreakStartDate: Timestamp?
    @ServerTimestamp var groupStreakPausedUntil: Timestamp?
    var groupStreakLastMilestone: Int?
}
```

---

## 3. Repository Protocols

### 3.1 New Protocol (`Domain/Protocols/GroupStreakRepository.swift`)

```swift
import Foundation

protocol GroupStreakRepository: Sendable {
    /// Get current streak status for a group
    func getStreakStatus(groupId: String) async throws -> GroupStreakStatus

    /// Observe real-time streak updates
    func observeStreakStatus(groupId: String) -> AsyncStream<GroupStreakStatus>

    /// Increment workout count for member in current week
    func incrementWorkoutCount(groupId: String, userId: String) async throws

    /// Create new week tracking record
    func createWeekRecord(groupId: String, members: [GroupMember]) async throws -> GroupStreakWeek

    /// Update streak days (called by Cloud Function)
    func updateStreakDays(groupId: String, days: Int, milestone: StreakMilestone?) async throws

    /// Reset streak to zero
    func resetStreak(groupId: String) async throws

    /// Pause streak (admin only)
    func pauseStreak(groupId: String, until: Date) async throws

    /// Resume streak from pause
    func resumeStreak(groupId: String) async throws

    /// Get week history
    func getWeekHistory(groupId: String, limit: Int) async throws -> [GroupStreakWeek]
}
```

### 3.2 Implementation (`Data/Repositories/FirebaseGroupStreakRepository.swift`)

```swift
import FirebaseFirestore
import Foundation

final class FirebaseGroupStreakRepository: GroupStreakRepository, @unchecked Sendable {
    private let db = Firestore.firestore()

    func getStreakStatus(groupId: String) async throws -> GroupStreakStatus {
        // 1. Fetch group document for streak metadata
        let groupRef = db.collection("groups").document(groupId)
        let groupDoc = try await groupRef.getDocument()
        let fbGroup = try groupDoc.data(as: FBGroup.self)

        // 2. Fetch current week
        let currentWeek = try await getCurrentWeek(groupId: groupId)

        // 3. Fetch week history (last 12 weeks)
        let history = try await getWeekHistory(groupId: groupId, limit: 12)

        return GroupStreakStatus(
            groupId: groupId,
            streakDays: fbGroup.groupStreakDays ?? 0,
            streakStartDate: fbGroup.groupStreakStartDate?.dateValue(),
            pausedUntil: fbGroup.groupStreakPausedUntil?.dateValue(),
            lastPauseDate: nil,
            lastMilestoneReached: fbGroup.groupStreakLastMilestone.flatMap { StreakMilestone(rawValue: $0) },
            currentWeek: currentWeek,
            weekHistory: history
        )
    }

    func observeStreakStatus(groupId: String) -> AsyncStream<GroupStreakStatus> {
        AsyncStream { continuation in
            let groupRef = db.collection("groups").document(groupId)

            let listener = groupRef.addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot, error == nil else { return }

                Task {
                    do {
                        let status = try await self.getStreakStatus(groupId: groupId)
                        continuation.yield(status)
                    } catch {
                        // Log error but don't terminate stream
                    }
                }
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    func incrementWorkoutCount(groupId: String, userId: String) async throws {
        let weekRef = try await getCurrentWeekRef(groupId: groupId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                let weekDoc = try transaction.getDocument(weekRef)
                var fbWeek = try weekDoc.data(as: FBGroupStreakWeek.self)

                if var memberStatus = fbWeek.memberCompliance[userId] {
                    memberStatus.workoutCount += 1
                    memberStatus.lastWorkoutDate = Timestamp(date: Date())
                    fbWeek.memberCompliance[userId] = memberStatus
                }

                // Check if all members are now compliant
                fbWeek.allCompliant = fbWeek.memberCompliance.values.allSatisfy { $0.workoutCount >= 3 }

                try transaction.setData(from: fbWeek, forDocument: weekRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func createWeekRecord(groupId: String, members: [GroupMember]) async throws -> GroupStreakWeek {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()

        // Get Monday 00:00 UTC
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")

        guard let weekStart = calendar.date(from: components),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            throw DomainError.invalidDate
        }

        let weekEndFinal = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd)!

        // Create compliance map for active members
        var memberCompliance: [String: FBMemberWeeklyStatus] = [:]
        for member in members where member.isActive {
            memberCompliance[member.id] = FBMemberWeeklyStatus(
                userId: member.id,
                workoutCount: 0,
                lastWorkoutDate: nil
            )
        }

        let fbWeek = FBGroupStreakWeek(
            id: nil,
            groupId: groupId,
            weekStartDate: Timestamp(date: weekStart),
            weekEndDate: Timestamp(date: weekEndFinal),
            memberCompliance: memberCompliance,
            allCompliant: false,
            createdAt: Timestamp(date: now)
        )

        let docRef = db.collection("groups").document(groupId)
            .collection("streakWeeks").document()

        try docRef.setData(from: fbWeek)

        return GroupStreakWeek(
            id: docRef.documentID,
            groupId: groupId,
            weekStartDate: weekStart,
            weekEndDate: weekEndFinal,
            memberCompliance: memberCompliance.mapValues { status in
                MemberWeeklyStatus(
                    userId: status.userId,
                    workoutCount: status.workoutCount,
                    lastWorkoutDate: status.lastWorkoutDate?.dateValue()
                )
            },
            allCompliant: false,
            createdAt: now
        )
    }

    // ... Additional methods implementation

    private func getCurrentWeekRef(groupId: String) async throws -> DocumentReference {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()

        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")

        guard let weekStart = calendar.date(from: components) else {
            throw DomainError.invalidDate
        }

        let query = db.collection("groups").document(groupId)
            .collection("streakWeeks")
            .whereField("weekStartDate", isEqualTo: Timestamp(date: weekStart))
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        if let doc = snapshot.documents.first {
            return doc.reference
        }

        // Create new week if doesn't exist
        throw DomainError.weekNotFound
    }
}
```

---

## 4. Use Cases

### 4.1 UpdateGroupStreakUseCase (`Domain/UseCases/UpdateGroupStreakUseCase.swift`)

```swift
import Foundation

protocol UpdateGroupStreakUseCaseProtocol: Sendable {
    func execute(groupId: String, userId: String) async throws
}

final class UpdateGroupStreakUseCase: UpdateGroupStreakUseCaseProtocol, @unchecked Sendable {
    private let groupStreakRepository: GroupStreakRepository
    private let groupRepository: GroupRepository
    private let notificationService: NotificationService

    init(
        groupStreakRepository: GroupStreakRepository,
        groupRepository: GroupRepository,
        notificationService: NotificationService
    ) {
        self.groupStreakRepository = groupStreakRepository
        self.groupRepository = groupRepository
        self.notificationService = notificationService
    }

    func execute(groupId: String, userId: String) async throws {
        // 1. Increment workout count
        try await groupStreakRepository.incrementWorkoutCount(groupId: groupId, userId: userId)

        // 2. Get updated status
        let status = try await groupStreakRepository.getStreakStatus(groupId: groupId)

        // 3. Check if user just became compliant (3rd workout)
        if let currentWeek = status.currentWeek,
           let memberStatus = currentWeek.memberCompliance[userId],
           memberStatus.workoutCount == 3 {
            // Notify group of progress
            try await notificationService.sendGroupNotification(
                groupId: groupId,
                type: .memberCompliant,
                data: ["userId": userId, "workoutCount": 3]
            )
        }

        // 4. Check if all members just became compliant
        if let currentWeek = status.currentWeek, currentWeek.allCompliant {
            try await notificationService.sendGroupNotification(
                groupId: groupId,
                type: .allMembersCompliant,
                data: [:]
            )
        }
    }
}
```

### 4.2 Modify SyncWorkoutCompletionUseCase

```swift
// Add to existing SyncWorkoutCompletionUseCase.swift

// In execute() method, after existing challenge updates:

// Update group streak if applicable
if let groupId = user.groupId {
    let groups = try await groupRepository.getGroups(userId: user.id)
    for group in groups {
        // Only count if workout is valid (>=30 min or has check-in)
        if workoutDurationMinutes >= 30 || hasCheckIn {
            try await updateGroupStreakUseCase.execute(groupId: group.id, userId: user.id)
        }
    }
}
```

### 4.3 PauseGroupStreakUseCase (`Domain/UseCases/PauseGroupStreakUseCase.swift`)

```swift
import Foundation

protocol PauseGroupStreakUseCaseProtocol: Sendable {
    func execute(groupId: String, adminId: String, pauseDays: Int) async throws
}

final class PauseGroupStreakUseCase: PauseGroupStreakUseCaseProtocol, @unchecked Sendable {
    private let groupStreakRepository: GroupStreakRepository
    private let groupRepository: GroupRepository

    init(groupStreakRepository: GroupStreakRepository, groupRepository: GroupRepository) {
        self.groupStreakRepository = groupStreakRepository
        self.groupRepository = groupRepository
    }

    func execute(groupId: String, adminId: String, pauseDays: Int) async throws {
        // 1. Verify user is admin
        let members = try await groupRepository.getMembers(groupId: groupId)
        guard let admin = members.first(where: { $0.id == adminId }),
              admin.role == .admin else {
            throw DomainError.unauthorized
        }

        // 2. Check if pause was used this month
        let status = try await groupStreakRepository.getStreakStatus(groupId: groupId)
        if let lastPause = status.lastPauseDate {
            let calendar = Calendar.current
            if calendar.isDate(lastPause, equalTo: Date(), toGranularity: .month) {
                throw DomainError.pauseAlreadyUsedThisMonth
            }
        }

        // 3. Validate pause duration (max 7 days)
        guard pauseDays > 0 && pauseDays <= 7 else {
            throw DomainError.invalidPauseDuration
        }

        // 4. Set pause
        let pauseUntil = Calendar.current.date(byAdding: .day, value: pauseDays, to: Date())!
        try await groupStreakRepository.pauseStreak(groupId: groupId, until: pauseUntil)
    }
}
```

---

## 5. View/ViewModel Structure

### 5.1 GroupStreakViewModel (`Presentation/Features/Groups/GroupStreakViewModel.swift`)

```swift
import Foundation
import Observation

@Observable
final class GroupStreakViewModel: @unchecked Sendable {
    // MARK: - State

    private(set) var streakStatus: GroupStreakStatus?
    private(set) var isLoading = false
    private(set) var error: DomainError?
    private(set) var showMilestoneOverlay = false
    private(set) var reachedMilestone: StreakMilestone?

    // MARK: - Dependencies

    private let groupId: String
    private let userId: String
    private let groupStreakRepository: GroupStreakRepository
    private let pauseStreakUseCase: PauseGroupStreakUseCaseProtocol

    private var observationTask: Task<Void, Never>?

    // MARK: - Init

    init(
        groupId: String,
        userId: String,
        groupStreakRepository: GroupStreakRepository,
        pauseStreakUseCase: PauseGroupStreakUseCaseProtocol
    ) {
        self.groupId = groupId
        self.userId = userId
        self.groupStreakRepository = groupStreakRepository
        self.pauseStreakUseCase = pauseStreakUseCase
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Actions

    func startObserving() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for await status in groupStreakRepository.observeStreakStatus(groupId: groupId) {
                self.streakStatus = status
                self.checkForNewMilestone(status)
            }
        }
    }

    func pauseStreak(days: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await pauseStreakUseCase.execute(groupId: groupId, adminId: userId, pauseDays: days)
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown(error)
        }
    }

    func dismissMilestoneOverlay() {
        showMilestoneOverlay = false
        reachedMilestone = nil
    }

    // MARK: - Computed

    var currentUserStatus: MemberWeeklyStatus? {
        streakStatus?.currentWeek?.memberCompliance[userId]
    }

    var membersAtRisk: [MemberWeeklyStatus] {
        guard let week = streakStatus?.currentWeek else { return [] }
        return week.memberCompliance.values
            .filter { $0.complianceStatus == .atRisk }
            .sorted { $0.workoutCount > $1.workoutCount }
    }

    var isAdmin: Bool {
        // Check from group members
        true // TODO: Inject from parent
    }

    // MARK: - Private

    private func checkForNewMilestone(_ status: GroupStreakStatus) {
        guard let lastMilestone = status.lastMilestoneReached else { return }

        // Check if this is a newly reached milestone
        if reachedMilestone != lastMilestone {
            reachedMilestone = lastMilestone
            showMilestoneOverlay = true
        }
    }
}
```

### 5.2 GroupStreakCardView (`Presentation/Features/Groups/GroupStreakCardView.swift`)

```swift
import SwiftUI

struct GroupStreakCardView: View {
    let streakStatus: GroupStreakStatus
    let members: [GroupMember]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("GROUP STREAK")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if streakStatus.isPaused {
                        Label("Pausado", systemImage: "pause.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                // Streak count
                HStack(alignment: .firstTextBaseline) {
                    Text("\(streakStatus.streakDays)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("dias")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let next = streakStatus.nextMilestone,
                       let daysTo = streakStatus.daysToNextMilestone {
                        VStack(alignment: .trailing) {
                            Text("Próximo: \(next.title)")
                                .font(.caption)
                            Text("\(daysTo) dias")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Member compliance
                Text("Esta semana:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let currentWeek = streakStatus.currentWeek {
                    ForEach(members.filter { $0.isActive }, id: \.id) { member in
                        if let status = currentWeek.memberCompliance[member.id] {
                            MemberComplianceRow(member: member, status: status)
                        }
                    }
                }

                // View history link
                HStack {
                    Spacer()
                    Text("Ver histórico")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct MemberComplianceRow: View {
    let member: GroupMember
    let status: MemberWeeklyStatus

    var body: some View {
        HStack(spacing: 8) {
            // Avatar
            AsyncImage(url: member.photoURL) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            // Name
            Text(member.displayName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Progress dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < status.workoutCount ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Status indicator
            Text("\(status.workoutCount)/3")
                .font(.caption)
                .foregroundStyle(.secondary)

            complianceIndicator
        }
    }

    @ViewBuilder
    private var complianceIndicator: some View {
        switch status.complianceStatus {
        case .compliant:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .atRisk:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        case .notStarted:
            Image(systemName: "circle")
                .foregroundStyle(.gray)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
```

### 5.3 MilestoneOverlayView (`Presentation/Features/Groups/MilestoneOverlayView.swift`)

```swift
import SwiftUI

struct MilestoneOverlayView: View {
    let milestone: StreakMilestone
    let topPerformers: [(member: GroupMember, workoutCount: Int)]
    let onDismiss: () -> Void
    let onShare: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Celebration emoji
                Text("\(milestone.emoji)")
                    .font(.system(size: 80))

                // Title
                Text("INCRÍVEL!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Milestone description
                VStack(spacing: 4) {
                    Text("Vocês alcançaram")
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(milestone.days) DIAS")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("de streak em grupo!")
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Top performers
                if !topPerformers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top performers:")
                            .font(.headline)
                            .foregroundStyle(.white)

                        ForEach(Array(topPerformers.enumerated()), id: \.1.member.id) { index, performer in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundStyle(.yellow)
                                Text(performer.member.displayName)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(performer.workoutCount) treinos")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: onShare) {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    Button(action: onDismiss) {
                        Text("Fechar")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(32)
        }
    }
}
```

---

## 6. Firebase/Firestore Schema Changes

### 6.1 Updated Firestore Structure

```
groups/{groupId}
├── name: string
├── createdBy: string
├── memberCount: number
├── isActive: boolean
├── groupStreakDays: number              # NEW
├── groupStreakStartDate: Timestamp      # NEW
├── groupStreakPausedUntil: Timestamp?   # NEW
├── groupStreakLastMilestone: number?    # NEW
├── groupStreakLastPauseDate: Timestamp? # NEW
│
├── members/{userId}
│   └── ... (existing)
│
├── checkIns/{checkInId}
│   └── ... (existing)
│
└── streakWeeks/{weekId}                 # NEW COLLECTION
    ├── groupId: string
    ├── weekStartDate: Timestamp
    ├── weekEndDate: Timestamp
    ├── memberCompliance: Map<userId, {
    │     workoutCount: number,
    │     lastWorkoutDate: Timestamp?
    │   }>
    ├── allCompliant: boolean
    └── createdAt: Timestamp
```

### 6.2 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Existing rules...

    match /groups/{groupId} {
      // Existing group rules...

      // New: streakWeeks subcollection
      match /streakWeeks/{weekId} {
        // Read: Any group member
        allow read: if isGroupMember(groupId);

        // Create: Only Cloud Function (service account)
        allow create: if false;

        // Update: Only for incrementing own workoutCount
        allow update: if isGroupMember(groupId)
          && onlyUpdatingOwnWorkoutCount(groupId);

        // Delete: Never
        allow delete: if false;
      }
    }

    // Helper functions
    function isGroupMember(groupId) {
      return exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
    }

    function onlyUpdatingOwnWorkoutCount(groupId) {
      let userId = request.auth.uid;
      let before = resource.data.memberCompliance[userId];
      let after = request.resource.data.memberCompliance[userId];

      // Only workoutCount can change, and only increment by 1
      return after.workoutCount == before.workoutCount + 1
        && request.resource.data.allCompliant == computeAllCompliant(request.resource.data.memberCompliance);
    }
  }
}
```

---

## 7. Cloud Functions

### 7.1 Weekly Evaluation Function

```typescript
// functions/src/groupStreak.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Runs every Sunday at 23:59 UTC to evaluate group streaks
 */
export const evaluateGroupStreaks = functions.pubsub
  .schedule('59 23 * * 0')  // Every Sunday at 23:59 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const groupsSnapshot = await db.collection('groups')
      .where('isActive', '==', true)
      .where('groupStreakDays', '>', 0)
      .get();

    const batch = db.batch();
    const notifications: Promise<void>[] = [];

    for (const groupDoc of groupsSnapshot.docs) {
      const group = groupDoc.data();

      // Skip paused groups
      if (group.groupStreakPausedUntil &&
          group.groupStreakPausedUntil.toDate() > new Date()) {
        continue;
      }

      // Get current week
      const currentWeekQuery = await db.collection('groups')
        .doc(groupDoc.id)
        .collection('streakWeeks')
        .orderBy('weekStartDate', 'desc')
        .limit(1)
        .get();

      if (currentWeekQuery.empty) continue;

      const weekDoc = currentWeekQuery.docs[0];
      const week = weekDoc.data();

      if (week.allCompliant) {
        // Increment streak
        const newStreakDays = (group.groupStreakDays || 0) + 7;

        // Check for milestone
        const milestone = checkMilestone(newStreakDays);

        batch.update(groupDoc.ref, {
          groupStreakDays: newStreakDays,
          ...(milestone && { groupStreakLastMilestone: milestone })
        });

        if (milestone) {
          notifications.push(
            sendMilestoneNotification(groupDoc.id, milestone, newStreakDays)
          );
        }
      } else {
        // Reset streak
        batch.update(groupDoc.ref, {
          groupStreakDays: 0,
          groupStreakStartDate: null
        });

        // Find who failed
        const failedMembers = Object.entries(week.memberCompliance)
          .filter(([_, status]: [string, any]) => status.workoutCount < 3)
          .map(([userId, _]) => userId);

        notifications.push(
          sendStreakBrokenNotification(groupDoc.id, failedMembers, group.groupStreakDays)
        );
      }
    }

    await batch.commit();
    await Promise.all(notifications);

    console.log(`Evaluated ${groupsSnapshot.size} groups`);
  });

/**
 * Runs every Monday at 00:00 UTC to create new week records
 */
export const createWeeklyStreakWeek = functions.pubsub
  .schedule('0 0 * * 1')  // Every Monday at 00:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const groupsSnapshot = await db.collection('groups')
      .where('isActive', '==', true)
      .get();

    const now = new Date();
    const weekStart = getMonday(now);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    for (const groupDoc of groupsSnapshot.docs) {
      const membersSnapshot = await db.collection('groups')
        .doc(groupDoc.id)
        .collection('members')
        .where('isActive', '==', true)
        .get();

      const memberCompliance: Record<string, any> = {};
      membersSnapshot.docs.forEach(memberDoc => {
        memberCompliance[memberDoc.id] = {
          userId: memberDoc.id,
          workoutCount: 0,
          lastWorkoutDate: null
        };
      });

      await db.collection('groups')
        .doc(groupDoc.id)
        .collection('streakWeeks')
        .add({
          groupId: groupDoc.id,
          weekStartDate: admin.firestore.Timestamp.fromDate(weekStart),
          weekEndDate: admin.firestore.Timestamp.fromDate(weekEnd),
          memberCompliance,
          allCompliant: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    console.log(`Created week records for ${groupsSnapshot.size} groups`);
  });

/**
 * Runs every Thursday at 18:00 UTC to send at-risk notifications
 */
export const sendAtRiskNotifications = functions.pubsub
  .schedule('0 18 * * 4')  // Every Thursday at 18:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    // ... Implementation for at-risk notifications
  });

// Helper functions
function checkMilestone(days: number): number | null {
  const milestones = [100, 60, 30, 14, 7];
  for (const m of milestones) {
    if (days >= m && days < m + 7) return m;
  }
  return null;
}

function getMonday(date: Date): Date {
  const d = new Date(date);
  const day = d.getUTCDay();
  const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
  d.setUTCDate(diff);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}
```

---

## 8. Error Handling

### 8.1 Extended DomainError

```swift
// Add to existing DomainError enum

extension DomainError {
    case weekNotFound
    case invalidDate
    case pauseAlreadyUsedThisMonth
    case invalidPauseDuration
    case streakNotActive
    case memberNotInGroup
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

```swift
// Tests/Domain/UseCases/UpdateGroupStreakUseCaseTests.swift

final class UpdateGroupStreakUseCaseTests: XCTestCase {
    var sut: UpdateGroupStreakUseCase!
    var mockStreakRepository: MockGroupStreakRepository!
    var mockGroupRepository: MockGroupRepository!
    var mockNotificationService: MockNotificationService!

    override func setUp() {
        super.setUp()
        mockStreakRepository = MockGroupStreakRepository()
        mockGroupRepository = MockGroupRepository()
        mockNotificationService = MockNotificationService()

        sut = UpdateGroupStreakUseCase(
            groupStreakRepository: mockStreakRepository,
            groupRepository: mockGroupRepository,
            notificationService: mockNotificationService
        )
    }

    func test_execute_incrementsWorkoutCount() async throws {
        // Given
        let groupId = "group123"
        let userId = "user456"

        // When
        try await sut.execute(groupId: groupId, userId: userId)

        // Then
        XCTAssertTrue(mockStreakRepository.incrementWorkoutCountCalled)
        XCTAssertEqual(mockStreakRepository.lastGroupId, groupId)
        XCTAssertEqual(mockStreakRepository.lastUserId, userId)
    }

    func test_execute_sendsNotification_whenUserBecomes Compliant() async throws {
        // Given
        let groupId = "group123"
        let userId = "user456"
        mockStreakRepository.stubbedStatus = GroupStreakStatus.fixture(
            currentWeek: .fixture(memberCompliance: [
                userId: .fixture(workoutCount: 3)
            ])
        )

        // When
        try await sut.execute(groupId: groupId, userId: userId)

        // Then
        XCTAssertTrue(mockNotificationService.sendGroupNotificationCalled)
        XCTAssertEqual(mockNotificationService.lastNotificationType, .memberCompliant)
    }
}
```

### 9.2 Test Fixtures

```swift
// Tests/Fixtures/GroupStreakFixtures.swift

extension GroupStreakStatus {
    static func fixture(
        groupId: String = "group123",
        streakDays: Int = 14,
        currentWeek: GroupStreakWeek? = .fixture()
    ) -> GroupStreakStatus {
        GroupStreakStatus(
            groupId: groupId,
            streakDays: streakDays,
            streakStartDate: Date().addingTimeInterval(-14 * 24 * 60 * 60),
            pausedUntil: nil,
            lastPauseDate: nil,
            lastMilestoneReached: .week2,
            currentWeek: currentWeek,
            weekHistory: []
        )
    }
}

extension GroupStreakWeek {
    static func fixture(
        memberCompliance: [String: MemberWeeklyStatus] = ["user1": .fixture()]
    ) -> GroupStreakWeek {
        GroupStreakWeek(
            id: UUID().uuidString,
            groupId: "group123",
            weekStartDate: getMonday(from: Date()),
            weekEndDate: getSunday(from: Date()),
            memberCompliance: memberCompliance,
            allCompliant: memberCompliance.values.allSatisfy { $0.isCompliant },
            createdAt: Date()
        )
    }
}

extension MemberWeeklyStatus {
    static func fixture(
        userId: String = "user1",
        workoutCount: Int = 2
    ) -> MemberWeeklyStatus {
        MemberWeeklyStatus(
            userId: userId,
            workoutCount: workoutCount,
            lastWorkoutDate: Date()
        )
    }
}
```

---

## 10. Appendix A: Technical Fixes Implementation

### A.1 Fix RF1.1 - Exercise Catalog in Prompt

**File**: `Data/Services/OpenAI/WorkoutPromptAssembler.swift`

```swift
// Add method to format exercise catalog for prompt
private func formatExerciseCatalog(exercises: [LibraryExercise], userEquipment: Set<EquipmentType>) -> String {
    // Filter by user's available equipment
    let availableExercises = exercises.filter { exercise in
        userEquipment.contains(exercise.equipment) || exercise.equipment == .bodyweight
    }

    // Group by muscle group
    let grouped = Dictionary(grouping: availableExercises) { $0.mainMuscle }

    var result = "AVAILABLE EXERCISES (use EXACT names from this list):\n\n"

    for (muscle, exercises) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
        result += "## \(muscle.displayName)\n"
        for exercise in exercises.prefix(20) {  // Max 20 per muscle
            result += "- \(exercise.name) (\(exercise.equipment.rawValue))\n"
        }
        result += "\n"
    }

    result += "\nCRITICAL: Every exercise name in your response MUST match exactly one name from the list above.\n"

    return result
}
```

### A.2 Fix RF1.2 - Cache Key Diversity

**File**: `Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`

```swift
// Modify cache key generation
private func generateCacheKey(
    prompt: WorkoutPrompt,
    previousWorkouts: [WorkoutHistoryEntry]
) -> String {
    let historyHash = previousWorkouts.prefix(3)
        .map { $0.id.uuidString }
        .joined()
        .hashValue

    return "\(prompt.cacheKey)_h\(abs(historyHash))"
}
```

### A.3 Fix RF1.3 - Media Resolution Timeout

**File**: `Data/Services/ExerciseDB/ExerciseMediaResolver.swift`

```swift
// Add timeout wrapper for media resolution
func resolveMediaWithTimeout(
    for exercise: WorkoutExercise,
    context: MediaDisplayContext,
    timeout: TimeInterval = 5.0
) async -> ResolvedExerciseMedia {
    do {
        return try await withThrowingTaskGroup(of: ResolvedExerciseMedia.self) { group in
            group.addTask {
                await self.resolveMedia(for: exercise, context: context)
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw CancellationError()
            }

            guard let result = try await group.next() else {
                return .placeholder(exerciseName: exercise.name)
            }

            group.cancelAll()
            return result
        }
    } catch {
        Logger.warning("Media resolution timeout for \(exercise.name)")
        return .placeholder(exerciseName: exercise.name)
    }
}
```

### A.4 Fix RF1.4 - Translation Dictionary Expansion

**File**: `Data/Services/ExerciseDB/ExerciseTranslationDictionary.swift`

Add 100+ new translations covering:
- Machine exercises (leg press, hack squat, smith machine)
- Cable exercises (cable fly, cable curl, face pull)
- Unilateral variations (single arm, single leg)
- Compound variations (close grip, wide grip, sumo)
- Synonyms (supino = bench press = chest press)
