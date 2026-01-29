//
//  MilestoneOverlayView.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import SwiftUI

// MARK: - MilestoneOverlayView

struct MilestoneOverlayView: View {
    let milestone: StreakMilestone
    let groupName: String
    let topPerformers: [MemberWeeklyStatus]
    let onShare: () -> Void
    let onDismiss: () -> Void

    @State private var isPresented = false

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Content card
            VStack(spacing: 24) {
                // Celebration header
                celebrationHeader

                // Milestone badge
                milestoneBadge

                // Message
                Text(milestone.celebrationMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("\(groupName) maintained their streak for \(milestone.rawValue) days!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Top performers
                if !topPerformers.isEmpty {
                    topPerformersSection
                }

                // Action buttons
                actionButtons
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isPresented = true
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 8) {
            // Confetti-like decoration
            HStack(spacing: 12) {
                Text("\u{1F389}") // Party popper
                Text("\u{2B50}") // Star
                Text("\u{1F389}") // Party popper
            }
            .font(.system(size: 32))

            Text("INCREDIBLE!")
                .font(.caption)
                .fontWeight(.black)
                .tracking(4)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Milestone Badge

    private var milestoneBadge: some View {
        VStack(spacing: 8) {
            Text(milestone.emoji)
                .font(.system(size: 80))

            Text("\(milestone.rawValue)")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("DAYS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Top Performers

    private var topPerformersSection: some View {
        VStack(spacing: 12) {
            Text("TOP PERFORMERS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Array(topPerformers.enumerated()), id: \.element.id) { index, performer in
                    topPerformerBadge(performer: performer, rank: index + 1)
                }
            }
        }
    }

    private func topPerformerBadge(performer: MemberWeeklyStatus, rank: Int) -> some View {
        VStack(spacing: 4) {
            // Rank medal
            Text(rankMedal(rank))
                .font(.title2)

            // Avatar
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    if let photoURL = performer.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(String(performer.displayName.prefix(1)))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .clipShape(Circle())
                    } else {
                        Text(String(performer.displayName.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }

            // Name
            Text(performer.displayName.split(separator: " ").first.map(String.init) ?? performer.displayName)
                .font(.caption)
                .lineLimit(1)

            // Workouts
            Text("\(performer.workoutCount) workouts")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func rankMedal(_ rank: Int) -> String {
        switch rank {
        case 1: return "\u{1F947}" // Gold medal
        case 2: return "\u{1F948}" // Silver medal
        case 3: return "\u{1F949}" // Bronze medal
        default: return "\u{2B50}" // Star
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onShare()
            } label: {
                Label("Share Achievement", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Button {
                onDismiss()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Preview

#Preview {
    MilestoneOverlayView(
        milestone: .oneMonth,
        groupName: "Fitness Squad",
        topPerformers: [
            MemberWeeklyStatus(id: "1", displayName: "Alice Johnson", workoutCount: 5),
            MemberWeeklyStatus(id: "2", displayName: "Bob Smith", workoutCount: 4),
            MemberWeeklyStatus(id: "3", displayName: "Charlie Brown", workoutCount: 4)
        ],
        onShare: {},
        onDismiss: {}
    )
}
