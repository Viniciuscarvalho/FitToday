//
//  GroupStreakCardView.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import SwiftUI

// MARK: - GroupStreakCardView

struct GroupStreakCardView: View {
    let status: GroupStreakStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                headerSection

                // Days count
                daysSection

                // Progress to next milestone
                if let nextMilestone = status.nextMilestone {
                    milestoneProgressSection(nextMilestone)
                }

                Divider()

                // Members compliance
                membersSection
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            Text("streak.header.title".localized)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Spacer()

            if status.isPaused {
                Label("streak.paused".localized, systemImage: "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
    }

    // MARK: - Days Count

    private var daysSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(status.streakDays)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(status.hasActiveStreak ? .primary : .secondary)

            Text(status.streakDays == 1 ? "streak.day.singular".localized : "streak.days.plural".localized)
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            if let milestone = status.lastMilestone {
                VStack(alignment: .trailing) {
                    Text(milestone.emoji)
                        .font(.title)
                    Text(milestone.localizedDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Milestone Progress

    @ViewBuilder
    private func milestoneProgressSection(_ milestone: StreakMilestone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "streak.next.milestone".localized, milestone.localizedDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let daysRemaining = status.daysToNextMilestone {
                    Text(String(format: "streak.days.remaining".localized, daysRemaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.gradient)
                        .frame(width: geometry.size.width * status.progressToNextMilestone, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("streak.this.week".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let week = status.currentWeek {
                    Text(String(format: "streak.compliant.count".localized, week.compliantMemberCount, week.memberCompliance.count))
                        .font(.caption)
                        .foregroundStyle(week.isAllCurrentlyCompliant ? .green : .orange)
                }
            }

            if let members = status.currentWeek?.memberCompliance.prefix(5) {
                ForEach(Array(members), id: \.id) { member in
                    MemberComplianceRow(member: member)
                }

                if let totalMembers = status.currentWeek?.memberCompliance.count, totalMembers > 5 {
                    Text("+\(totalMembers - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color.orange.opacity(0.1),
                Color.red.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - MemberComplianceRow

struct MemberComplianceRow: View {
    let member: MemberWeeklyStatus

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay {
                    if let photoURL = member.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(String(member.displayName.prefix(1)))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .clipShape(Circle())
                    } else {
                        Text(String(member.displayName.prefix(1)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

            Text(member.displayName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Progress dots
            HStack(spacing: 4) {
                ForEach(0..<MemberWeeklyStatus.requiredWorkouts, id: \.self) { index in
                    Circle()
                        .fill(index < member.workoutCount ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Status indicator
            Text(member.complianceStatus(isWeekOver: false).emoji)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    GroupStreakCardView(
        status: GroupStreakStatus(
            groupId: "preview",
            groupName: "Fitness Squad",
            streakDays: 21,
            currentWeek: GroupStreakWeek(
                id: "week1",
                groupId: "preview",
                weekStartDate: Date().startOfWeekUTC,
                weekEndDate: Date().endOfWeekUTC,
                memberCompliance: [
                    MemberWeeklyStatus(id: "1", displayName: "Alice", workoutCount: 3),
                    MemberWeeklyStatus(id: "2", displayName: "Bob", workoutCount: 2),
                    MemberWeeklyStatus(id: "3", displayName: "Charlie", workoutCount: 1)
                ]
            ),
            lastMilestone: .twoWeeks
        ),
        onTap: {}
    )
    .padding()
}
