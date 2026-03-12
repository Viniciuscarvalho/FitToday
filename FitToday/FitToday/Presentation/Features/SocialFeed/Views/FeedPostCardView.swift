//
//  FeedPostCardView.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import SwiftUI

// MARK: - Feed Post Card

struct FeedPostCardView: View {
    let post: FeedPost
    let isLiked: Bool
    let isOwnPost: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // MARK: - Header
            HStack(spacing: FitTodaySpacing.sm) {
                AsyncImage(url: post.authorPhotoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(FitTodayColor.brandPrimary.opacity(0.2))
                        .overlay {
                            Text(String(post.authorName.prefix(1)).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(FitTodayColor.brandPrimary)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                if isOwnPost {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }

            // MARK: - Workout Data Badge
            workoutDataBadge

            // MARK: - Media
            if let mediaURL = post.mediaURL {
                AsyncImage(url: mediaURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(4/3, contentMode: .fill)
                    case .failure:
                        mediaPlaceholder(icon: "photo")
                    case .empty:
                        mediaPlaceholder(icon: nil)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }

            // MARK: - Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(FitTodayColor.textPrimary)
            }

            // MARK: - Actions
            HStack(spacing: FitTodaySpacing.lg) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : FitTodayColor.textSecondary)
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(FitTodayColor.textSecondary)
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .font(.body)
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .fitCardShadow()
        .confirmationDialog(
            "Deletar post?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deletar", role: .destructive) {
                onDelete()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }

    // MARK: - Workout Data Badge

    private var workoutDataBadge: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Label("\(post.workoutDurationMinutes)min", systemImage: "clock")
            Text("·")
            Label("\(post.exerciseCount) exercícios", systemImage: "figure.strengthtraining.traditional")
            if let volume = post.totalVolume, volume > 0 {
                Text("·")
                Label(String(format: "%.0fkg", volume), systemImage: "scalemass")
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(FitTodayColor.brandPrimary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, 6)
        .background(FitTodayColor.brandPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
    }

    private func mediaPlaceholder(icon: String?) -> some View {
        Rectangle()
            .fill(FitTodayColor.surface)
            .overlay {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(FitTodayColor.textSecondary)
                } else {
                    ProgressView()
                }
            }
    }
}
