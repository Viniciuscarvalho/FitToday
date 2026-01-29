//
//  CheckInFeedView.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import SwiftUI

// MARK: - CheckInFeedView

/// Displays a chronological feed of group check-ins with real-time updates.
struct CheckInFeedView: View {
    @State private var viewModel: CheckInFeedViewModel

    init(viewModel: CheckInFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: FitTodaySpacing.md) {
                ForEach(viewModel.checkIns) { checkIn in
                    CheckInCardView(checkIn: checkIn)
                }

                if viewModel.checkIns.isEmpty && !viewModel.isLoading {
                    EmptyFeedView()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}

// MARK: - CheckInCardView

/// Card displaying a single check-in with user info and photo.
struct CheckInCardView: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header: avatar + name + time
            HStack(spacing: FitTodaySpacing.sm) {
                AsyncImage(url: checkIn.userPhotoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(FitTodayColor.brandPrimary.opacity(0.2))
                        .overlay {
                            Text(String(checkIn.displayName.prefix(1)).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(FitTodayColor.brandPrimary)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(checkIn.displayName)
                        .font(.subheadline.weight(.semibold))

                    Text(checkIn.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                // Duration badge
                Text("feed.duration".localized(with: checkIn.workoutDurationMinutes))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FitTodayColor.brandPrimary.opacity(0.1))
                    .cornerRadius(FitTodayRadius.sm)
            }

            // Photo
            AsyncImage(url: checkIn.checkInPhotoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(FitTodayColor.surface)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                case .empty:
                    Rectangle()
                        .fill(FitTodayColor.surface)
                        .overlay {
                            ProgressView()
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            .cornerRadius(FitTodayRadius.md)
            .clipped()
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.lg)
    }
}

// MARK: - EmptyFeedView

/// Empty state view when no check-ins exist.
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("feed.empty.title".localized)
                .font(.headline)

            Text("feed.empty.subtitle".localized)
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(.vertical, 60)
    }
}
