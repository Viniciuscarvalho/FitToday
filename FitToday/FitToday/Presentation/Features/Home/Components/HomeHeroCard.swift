//
//  HomeHeroCard.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//  Redesigned on 23/01/26 - New purple AI-focused design
//

import SwiftUI

struct HomeHeroCard: View {
    let journeyState: HomeJourneyState
    let isGeneratingPlan: Bool
    let heroErrorMessage: String?
    let onCreateProfile: () -> Void
    let onViewTodayWorkout: () -> Void
    let onGeneratePlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            heroContent
        }
        .padding(FitTodaySpacing.lg)
        .background(heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Hero Content

    @ViewBuilder
    private var heroContent: some View {
        switch journeyState {
        case .loading:
            loadingContent
        case .noProfile:
            noProfileContent
        case .workoutReady:
            workoutReadyContent
        case .workoutCompleted:
            workoutCompletedContent
        case .error(let message):
            errorContent(message: message)
        }
    }

    // MARK: - AI Powered Badge

    private var aiPoweredBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
            Text("AI Powered")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.white.opacity(0.2))
        .clipShape(Capsule())
    }

    // MARK: - Loading State

    private var loadingContent: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(.white)
            Text("common.loading".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: - No Profile State

    private var noProfileContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                aiPoweredBadge
                Spacer()
                iconContainer(systemName: "person.badge.plus")
            }

            Text("home.hero.welcome.title".localized)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("home.hero.welcome.subtitle".localized)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            primaryButton(title: "home.hero.create_profile".localized, icon: "arrow.right", action: onCreateProfile)
        }
    }

    // MARK: - AI Workout Content (Reusable)

    private func aiWorkoutContent(
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                aiPoweredBadge
                Spacer()
                iconContainer(systemName: "brain.head.profile")
            }

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            primaryButton(title: buttonTitle, icon: buttonIcon, action: action)
        }
    }

    // MARK: - Workout Ready State

    private var workoutReadyContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                readyBadge
                Spacer()
                if let errorMsg = heroErrorMessage {
                    Text(errorMsg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                iconContainer(systemName: "figure.run")
            }

            Text("home.hero.ready.title".localized)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("home.hero.ready.subtitle".localized)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if isGeneratingPlan {
                generatingIndicator
            } else {
                primaryButton(title: "home.hero.start_workout".localized, icon: "play.fill", action: onViewTodayWorkout)
            }
        }
    }

    private var readyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("home.hero.badge.ready".localized)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(FitTodayColor.success.opacity(0.3))
        .clipShape(Capsule())
    }

    private var generatingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text("home.hero.generating".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Workout Completed State

    private var workoutCompletedContent: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                completedBadge
                Spacer()
                iconContainer(systemName: "trophy.fill", iconColor: .yellow)
            }

            Text("home.hero.completed.title".localized)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("home.hero.completed.subtitle".localized)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var completedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("home.hero.badge.completed".localized)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(FitTodayColor.success.opacity(0.4))
        .clipShape(Capsule())
    }

    // MARK: - Error State

    private func errorContent(message: String) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                errorBadge
                Spacer()
                iconContainer(systemName: "exclamationmark.triangle.fill", iconColor: .red)
            }

            Text("home.hero.error.title".localized)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            secondaryButton(title: "common.retry".localized, icon: "arrow.clockwise", action: onGeneratePlan)
        }
    }

    private var errorBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("common.error".localized)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(FitTodayColor.error.opacity(0.4))
        .clipShape(Capsule())
    }

    // MARK: - Reusable Components

    private func iconContainer(systemName: String, iconColor: Color = .white) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 26, weight: .medium))
            .foregroundStyle(iconColor)
            .frame(width: 48, height: 48)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(FitTodayColor.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gradient

    private var heroGradient: LinearGradient {
        switch journeyState {
        case .loading:
            return LinearGradient(
                colors: [FitTodayColor.surface, FitTodayColor.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noProfile:
            return FitTodayColor.gradientPrimary
        case .workoutReady:
            return FitTodayColor.gradientPrimary
        case .workoutCompleted:
            return LinearGradient(
                colors: [FitTodayColor.success, FitTodayColor.success.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [FitTodayColor.error.opacity(0.8), FitTodayColor.error.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
