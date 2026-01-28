//
//  GroupStreakDetailView.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import SwiftUI
import Swinject

// MARK: - GroupStreakDetailView

struct GroupStreakDetailView: View {
    @Bindable var viewModel: GroupStreakViewModel
    @State private var showPauseSheet = false
    @State private var selectedPauseDays = 3
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let status = viewModel.streakStatus {
                    // Header with streak days
                    streakHeaderSection(status)

                    // Current week calendar
                    currentWeekSection(status)

                    // Members list
                    membersSection(status)

                    // Week history
                    historySection(status)

                    // Pause button (admin only)
                    if viewModel.canPause {
                        pauseSection
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Group Streak")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPauseSheet) {
            pauseSheetContent
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header Section

    private func streakHeaderSection(_ status: GroupStreakStatus) -> some View {
        VStack(spacing: 8) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    status.hasActiveStreak ?
                    LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                )

            // Days count
            Text("\(status.streakDays)")
                .font(.system(size: 72, weight: .bold, design: .rounded))

            Text(status.streakDays == 1 ? "day streak" : "days streak")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Start date
            if let startDate = status.streakStartDate {
                Text("Started \(startDate, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Next milestone
            if let next = status.nextMilestone, let days = status.daysToNextMilestone {
                HStack {
                    Text(next.emoji)
                    Text("\(days) days to \(next.localizedDescription)")
                }
                .font(.subheadline)
                .foregroundStyle(.orange)
                .padding(.top, 8)
            }

            // Paused indicator
            if status.isPaused, let pausedUntil = status.pausedUntil {
                Label("Paused until \(pausedUntil, style: .date)", systemImage: "pause.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Current Week Section

    private func currentWeekSection(_ status: GroupStreakStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            if let week = status.currentWeek {
                // Week dates
                HStack {
                    Text("\(week.weekStartDate, style: .date) - \(week.weekEndDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(week.totalGroupWorkouts) workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Compliance summary
                HStack(spacing: 16) {
                    complianceStat(
                        count: week.compliantMemberCount,
                        label: "Compliant",
                        color: .green
                    )

                    complianceStat(
                        count: week.atRiskMemberCount,
                        label: "At Risk",
                        color: .orange
                    )

                    complianceStat(
                        count: week.memberCompliance.count - week.compliantMemberCount - week.atRiskMemberCount,
                        label: "Not Started",
                        color: .secondary
                    )
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func complianceStat(count: Int, label: String, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Members Section

    private func membersSection(_ status: GroupStreakStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.headline)

            ForEach(status.membersSortedByWorkouts, id: \.id) { member in
                MemberDetailRow(member: member)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - History Section

    private func historySection(_ status: GroupStreakStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent History")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    // Full history view
                    Text("Full History")
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }

            // Placeholder for history - would be populated from repository
            Text("Week history will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
    }

    // MARK: - Pause Section

    private var pauseSection: some View {
        Button {
            showPauseSheet = true
        } label: {
            Label("Pause Streak", systemImage: "pause.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
    }

    // MARK: - Pause Sheet

    private var pauseSheetContent: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Pause Group Streak")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Pausing the streak will protect it during vacations or breaks. You can only pause once per month.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Picker("Days", selection: $selectedPauseDays) {
                    ForEach(1...PauseGroupStreakUseCase.maxPauseDays, id: \.self) { days in
                        Text("\(days) day\(days > 1 ? "s" : "")").tag(days)
                    }
                }
                .pickerStyle(.wheel)

                if viewModel.isPausingStreak {
                    ProgressView()
                } else {
                    Button {
                        Task {
                            await viewModel.pauseStreak(days: selectedPauseDays)
                            if viewModel.error == nil {
                                showPauseSheet = false
                            }
                        }
                    } label: {
                        Text("Pause for \(selectedPauseDays) days")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPauseSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - MemberDetailRow

struct MemberDetailRow: View {
    let member: MemberWeeklyStatus

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay {
                    if let photoURL = member.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(String(member.displayName.prefix(1)))
                                .font(.headline)
                        }
                        .clipShape(Circle())
                    } else {
                        Text(String(member.displayName.prefix(1)))
                            .font(.headline)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(member.workoutCount)/\(MemberWeeklyStatus.requiredWorkouts) workouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<MemberWeeklyStatus.requiredWorkouts, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < member.workoutCount ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 20, height: 8)
                }
            }

            // Status
            Text(member.complianceStatus(isWeekOver: false).emoji)
                .font(.title3)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupStreakDetailView(
            viewModel: {
                let vm = GroupStreakViewModel(resolver: Container())
                return vm
            }()
        )
    }
}
