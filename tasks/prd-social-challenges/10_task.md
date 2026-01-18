# [10.0] Leaderboard UI with Real-Time Updates (L)

## status: completed

<task_context>
<domain>presentation/leaderboards</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>swiftui|asyncstream|observable</dependencies>
</task_context>

# Task 10.0: Leaderboard UI with Real-Time Updates

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the leaderboard UI that displays live rankings for check-ins and streaks. Implement real-time updates using AsyncStream subscription in ViewModel. Integrate leaderboard into GroupDashboardView.

<requirements>
- Create LeaderboardView with tabbed interface (Check-Ins, Streak)
- Create LeaderboardViewModel with AsyncStream subscription for real-time updates
- Create LeaderboardRowView for individual entry display
- Highlight current user's position in leaderboard
- Handle empty states (no workouts this week yet)
- Handle loading and error states
- Display rank, name, avatar/initials, and metric value
- Sort entries by rank ascending (1st place at top)
- Follow @Observable pattern and SwiftUI best practices
</requirements>

## Subtasks

- [ ] 10.1 Create LeaderboardViewModel
  - `/Presentation/Features/Groups/LeaderboardViewModel.swift`
  - @MainActor, @Observable
  - Properties: checkInsLeaderboard, streakLeaderboard, isLoading, errorMessage
  - Method: startListening(groupId) - subscribes to AsyncStream
  - Method: stopListening() - cancels Task
  - Use Task to consume AsyncStream in background

- [ ] 10.2 Create LeaderboardRowView component
  - Display rank (#1, #2, etc.)
  - Display avatar (if photoURL exists) or initials in colored circle
  - Display displayName
  - Display metric value (e.g., "5 workouts" or "12-day streak")
  - Highlight current user (bold text, different background color)

- [ ] 10.3 Create LeaderboardView with tabbed interface
  - `/Presentation/Features/Groups/LeaderboardView.swift`
  - TabView or segmented control for "This Week" and "Best Streak"
  - List of LeaderboardRowView for each entry
  - Empty state: "No workouts this week yet! Be the first to train."
  - Loading state: ProgressView while fetching

- [ ] 10.4 Integrate leaderboard into GroupDashboardView
  - Replace leaderboard placeholder (from Task 7.7) with LeaderboardView
  - Pass groupId to LeaderboardViewModel
  - Handle view lifecycle (start/stop listeners on appear/disappear)

- [ ] 10.5 Implement empty state handling
  - Show encouraging message when no entries exist
  - CTA: "Complete a workout to get on the leaderboard!"

- [ ] 10.6 Implement loading state
  - Show skeleton UI or ProgressView while initial fetch
  - Transition smoothly to content once data loaded

- [ ] 10.7 Implement real-time update animations
  - Animate rank changes (entry moving up/down in list)
  - Use withAnimation for smooth transitions

- [ ] 10.8 Add challenge period display
  - Header: "Week of Jan 15-21" (calculated from challenge.weekStartDate)
  - Update to new week automatically on Monday 00:00

## Implementation Details

Reference **techspec.md** sections:
- "Implementation Design > Repository, UseCase, ViewModel Breakdown"
- "Data Flow Scenarios > View Leaderboard (Real-Time Updates)"

### LeaderboardViewModel AsyncStream Subscription
```swift
@MainActor
@Observable final class LeaderboardViewModel {
  private(set) var checkInsLeaderboard: LeaderboardSnapshot?
  private(set) var streakLeaderboard: LeaderboardSnapshot?
  private(set) var isLoading = false
  private var leaderboardTask: Task<Void, Never>?

  private let resolver: Resolver

  init(resolver: Resolver) {
    self.resolver = resolver
  }

  func startListening(groupId: String) {
    guard let repo = resolver.resolve(LeaderboardRepository.self) else { return }

    leaderboardTask = Task {
      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          for await snapshot in repo.observeLeaderboard(groupId: groupId, type: .checkIns) {
            await MainActor.run { self.checkInsLeaderboard = snapshot }
          }
        }
        group.addTask {
          for await snapshot in repo.observeLeaderboard(groupId: groupId, type: .streak) {
            await MainActor.run { self.streakLeaderboard = snapshot }
          }
        }
      }
    }
  }

  func stopListening() {
    leaderboardTask?.cancel()
  }
}
```

### LeaderboardView Structure
```swift
struct LeaderboardView: View {
  @State private var viewModel: LeaderboardViewModel
  @State private var selectedTab: ChallengeType = .checkIns

  var body: some View {
    VStack {
      // Tab selector
      Picker("Challenge Type", selection: $selectedTab) {
        Text("This Week").tag(ChallengeType.checkIns)
        Text("Best Streak").tag(ChallengeType.streak)
      }
      .pickerStyle(.segmented)
      .padding()

      // Leaderboard list
      if selectedTab == .checkIns {
        leaderboardList(snapshot: viewModel.checkInsLeaderboard)
      } else {
        leaderboardList(snapshot: viewModel.streakLeaderboard)
      }
    }
    .task {
      await viewModel.startListening(groupId: groupId)
    }
    .onDisappear {
      viewModel.stopListening()
    }
  }

  @ViewBuilder
  private func leaderboardList(snapshot: LeaderboardSnapshot?) -> some View {
    if let snapshot = snapshot, !snapshot.entries.isEmpty {
      List(snapshot.entries) { entry in
        LeaderboardRowView(entry: entry, isCurrentUser: entry.id == currentUserId)
      }
    } else {
      emptyStateView()
    }
  }
}
```

### LeaderboardRowView
```swift
struct LeaderboardRowView: View {
  let entry: LeaderboardEntry
  let isCurrentUser: Bool

  var body: some View {
    HStack(spacing: 12) {
      // Rank
      Text("#\(entry.rank)")
        .font(.headline)
        .foregroundStyle(isCurrentUser ? .blue : .secondary)
        .frame(width: 40)

      // Avatar or initials
      if let photoURL = entry.photoURL {
        AsyncImage(url: photoURL) { image in
          image.resizable()
        } placeholder: {
          initialsView
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
      } else {
        initialsView
      }

      // Name and value
      VStack(alignment: .leading) {
        Text(entry.displayName)
          .font(isCurrentUser ? .headline : .body)
        Text("\(entry.value) workouts") // Or "\(entry.value)-day streak"
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.clear)
    .cornerRadius(8)
  }

  private var initialsView: some View {
    Text(String(entry.displayName.prefix(1)))
      .font(.headline)
      .foregroundColor(.white)
      .frame(width: 40, height: 40)
      .background(Color.blue)
      .clipShape(Circle())
  }
}
```

## Success Criteria

- [ ] Leaderboard displays two tabs: "This Week" (check-ins) and "Best Streak"
- [ ] Entries sorted by rank (1st place at top)
- [ ] Current user's entry highlighted (different background, bold text)
- [ ] Avatar displays if photoURL exists, otherwise shows initials
- [ ] Empty state shows when no entries exist
- [ ] Leaderboard updates in real-time (within 5s) when workout completed
- [ ] Smooth animations when entries change position
- [ ] Loading state shows during initial fetch
- [ ] Challenge period displays correctly ("Week of [date]-[date]")
- [ ] Listeners stopped when view disappears (no memory leaks)

## Dependencies

**Before starting this task:**
- Task 9.0 (Firebase Leaderboard Service) must provide AsyncStream
- Task 7.0 (Groups UI) must have GroupDashboardView skeleton
- LeaderboardRepository registered in AppContainer

**Blocks these tasks:**
- Task 11.0 (Workout Sync) - leaderboard must exist to see updates
- Task 16.0 (Integration Testing) - leaderboard is key integration point

## Notes

- **AsyncStream Lifecycle**: CRITICAL to call stopListening() onDisappear to prevent memory leaks. AsyncStream listeners stay active until cancelled.
- **Animations**: Use `withAnimation` when updating leaderboard entries to smooth rank changes.
- **Empty State**: Keep it encouraging, not discouraging. "Be the first to train!" vs. "No one has trained yet."
- **Current User Highlight**: Fetch current userId from AuthenticationRepository, compare with entry.id.
- **Metric Display**: For check-ins: "X workouts". For streak: "X-day streak" or "X days".
- **Accessibility**: Ensure VoiceOver reads "Rank 1, [Name], 5 workouts" for each row.

## Validation Steps

1. Open Groups tab → navigate to group → see leaderboard
2. Verify two tabs: "This Week" and "Best Streak"
3. Verify empty state if no workouts yet
4. Complete workout from another device → verify leaderboard updates within 5s
5. Current user should be highlighted in list
6. Tap between tabs → data persists (no re-fetch needed)
7. Navigate away and back → listeners restart correctly
8. Check Instruments for memory leaks → no leaking listeners

## Relevant Files

### Files to Create
- `/Presentation/Features/Groups/LeaderboardView.swift`
- `/Presentation/Features/Groups/LeaderboardViewModel.swift`
- `/Presentation/Features/Groups/LeaderboardRowView.swift`

### Files to Modify
- `/Presentation/Features/Groups/GroupDashboardView.swift` - Integrate LeaderboardView
- `/Presentation/DI/AppContainer.swift` - Register LeaderboardViewModel (if needed)

### Reference Files
- AsyncStream docs: https://developer.apple.com/documentation/swift/asyncstream
- SwiftUI List animations: https://developer.apple.com/documentation/swiftui/list
