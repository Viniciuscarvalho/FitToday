//
//  TrainerRatingCard.swift
//  FitToday
//
//  Card displaying a personal trainer with rating, bio, and action button.
//

import SwiftUI

struct TrainerRatingCard: View {
    let trainer: PersonalTrainer
    let onRate: () -> Void
    let onSelect: () -> Void

    @State private var isBioExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header: Avatar + Name + Rating
            HStack(spacing: FitTodaySpacing.md) {
                trainerAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(trainer.displayName)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    starRating
                }

                Spacer()
            }

            // Bio
            if let bio = trainer.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(bio)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .lineLimit(isBioExpanded ? nil : 2)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isBioExpanded.toggle()
                        }
                    } label: {
                        Text(isBioExpanded ? "trainer.card.show_less".localized : "trainer.card.show_more".localized)
                            .font(FitTodayFont.ui(size: 12, weight: .semiBold))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Actions
            HStack(spacing: FitTodaySpacing.sm) {
                Button(action: onSelect) {
                    Text("trainer.card.view_profile".localized)
                        .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(FitTodayColor.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                }
                .buttonStyle(.plain)

                Button(action: onRate) {
                    Text("trainer.card.rate".localized)
                        .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(FitTodayColor.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Avatar

    private var trainerAvatar: some View {
        Group {
            if let photoURL = trainer.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(FitTodayColor.brandPrimary.opacity(0.1))
            Text(trainer.displayName.prefix(1).uppercased())
                .font(FitTodayFont.ui(size: 22, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
    }

    // MARK: - Star Rating

    private var starRating: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < 4 ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(FitTodayColor.warning)
            }
            Text("4.5")
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
            Text("(128)")
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
    }
}
