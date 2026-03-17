//
//  LeagueView.swift
//  FitToday
//

import SwiftUI
import Swinject

/// Main league screen showing the current league tier, countdown, and member rankings.
struct LeagueView: View {
    @State private var viewModel: LeagueViewModel

    init(resolver: Resolver) {
        self._viewModel = State(wrappedValue: LeagueViewModel(resolver: resolver))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if let league = viewModel.league {
                leagueContent(league)
            } else {
                emptyState
            }
        }
        .navigationTitle("league.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.leagueHistory) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }
        }
        .task { await viewModel.loadLeague() }
        .refreshable { await viewModel.loadLeague() }
        .fullScreenCover(isPresented: $viewModel.showPromotionAnimation) {
            if let tier = viewModel.league?.tier {
                LeaguePromotionView(tier: tier) { viewModel.showPromotionAnimation = false }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showDemotionAnimation) {
            if let tier = viewModel.league?.tier {
                LeagueDemotionView(tier: tier) { viewModel.showDemotionAnimation = false }
            }
        }
    }

    // MARK: - League Content

    private func leagueContent(_ league: League) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // Header
                    VStack(spacing: FitTodaySpacing.sm) {
                        LeagueTierBadge(tier: league.tier, size: .large)
                        Text("league.season_week".localized(with: league.seasonWeek))
                            .font(FitTodayFont.ui(size: 14, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                    .padding(.top, FitTodaySpacing.sm)

                    if !viewModel.countdownText.isEmpty {
                        Text(viewModel.countdownText)
                            .font(FitTodayFont.ui(size: 13, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }

                    // Members list with zone indicators
                    LazyVStack(spacing: FitTodaySpacing.xs) {
                        ForEach(league.members.sorted(by: { $0.rank < $1.rank })) { member in
                            LeagueRankingRow(member: member, totalMembers: league.members.count)
                                .id(member.userId)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, FitTodaySpacing.md)
            }
            .onAppear {
                guard let uid = league.members.first(where: { $0.isCurrentUser })?.userId else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { proxy.scrollTo(uid, anchor: .center) }
                }
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("league.loading".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.top, FitTodaySpacing.sm)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)
            Text("league.empty.title".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("league.empty.message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal)
    }
}
