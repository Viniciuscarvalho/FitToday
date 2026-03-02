//
//  PersonalTrainerHomeCard.swift
//  FitToday
//
//  Card shown on the Home screen for the personal trainer feature.
//  Two states: discover (no trainer) and connected (has trainer).
//

import SwiftUI

struct PersonalTrainerHomeCard: View {
    let state: PersonalTrainerHomeCardState
    let onDiscoverTap: () -> Void
    let onDashboardTap: () -> Void
    let onChatTap: () -> Void
    let onWorkoutTap: () -> Void

    var body: some View {
        Group {
            switch state {
            case .loading:
                loadingCard
            case .noTrainer:
                discoverCard
            case .hasTrainer(let trainer, let todayWorkout):
                connectedCard(trainer: trainer, todayWorkout: todayWorkout)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Loading

    private var loadingCard: some View {
        HStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("Carregando...")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Discover (No Trainer)

    private var discoverCard: some View {
        Button(action: onDiscoverTap) {
            VStack(spacing: FitTodaySpacing.md) {
                HStack(spacing: FitTodaySpacing.md) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32))
                        .foregroundStyle(FitTodayColor.brandPrimary)

                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text("Encontre seu Personal")
                            .font(FitTodayFont.ui(size: 16, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)

                        Text("Treine com acompanhamento profissional e evolua mais rápido")
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                // CTA
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                    Text("Ver personais disponíveis")
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FitTodaySpacing.sm)
                .background(FitTodayColor.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .padding(FitTodaySpacing.lg)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connected (Has Trainer)

    private func connectedCard(trainer: PersonalTrainer, todayWorkout: TrainerWorkout?) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Trainer info row
            Button(action: onDashboardTap) {
                HStack(spacing: FitTodaySpacing.md) {
                    trainerAvatar(trainer)

                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text(trainer.displayName)
                            .font(FitTodayFont.ui(size: 16, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: FitTodaySpacing.xs) {
                            Text("Personal Trainer")
                                .font(FitTodayFont.ui(size: 13, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .buttonStyle(.plain)

            // Today's workout badge
            if todayWorkout != nil {
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.success)

                    Text("Treino de hoje disponível")
                        .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.success)

                    Spacer()
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
                .background(FitTodayColor.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }

            // Action buttons
            HStack(spacing: FitTodaySpacing.sm) {
                if todayWorkout != nil {
                    Button(action: onWorkoutTap) {
                        HStack(spacing: FitTodaySpacing.xs) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 13))
                            Text("Ver treino")
                                .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FitTodaySpacing.sm)
                        .background(FitTodayColor.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onChatTap) {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 13))
                        Text("Chat")
                            .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    }
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(FitTodayColor.brandPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Helpers

    private func trainerAvatar(_ trainer: PersonalTrainer) -> some View {
        Group {
            if let photoURL = trainer.photoURL {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder(trainer)
                }
            } else {
                avatarPlaceholder(trainer)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private func avatarPlaceholder(_ trainer: PersonalTrainer) -> some View {
        Circle()
            .fill(FitTodayColor.brandPrimary.opacity(0.2))
            .overlay(
                Text(String(trainer.displayName.prefix(1)).uppercased())
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            )
    }
}
