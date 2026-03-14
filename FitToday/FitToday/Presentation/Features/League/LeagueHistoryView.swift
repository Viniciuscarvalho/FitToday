//
//  LeagueHistoryView.swift
//  FitToday
//

import SwiftUI

/// Displays past league seasons with tier, rank, and promotion/demotion indicators.
struct LeagueHistoryView: View {
    @Bindable var viewModel: LeagueViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(FitTodayColor.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("league.history.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory()
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List(viewModel.history.sorted(by: { $0.seasonWeek > $1.seasonWeek })) { result in
            HStack(spacing: FitTodaySpacing.sm) {
                LeagueTierBadge(tier: result.tier, size: .small)

                VStack(alignment: .leading, spacing: 2) {
                    Text("league.history.season_week".localized(with: result.seasonWeek))
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("league.history.xp_earned".localized(with: result.xpEarned))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                // Rank
                Text("#\(result.finalRank)")
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                // Promotion/Demotion arrow
                if result.promoted {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FitTodayColor.success)
                } else if result.demoted {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FitTodayColor.error)
                }
            }
            .listRowBackground(FitTodayColor.surface)
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textSecondary)
            Text("league.history.empty.title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("league.history.empty.message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal)
    }
}
