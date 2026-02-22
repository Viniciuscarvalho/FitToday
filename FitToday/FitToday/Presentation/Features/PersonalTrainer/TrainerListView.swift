//
//  TrainerListView.swift
//  FitToday
//
//  List of personal trainers with search functionality.
//

import SwiftUI

struct TrainerListView: View {
    @Bindable var viewModel: PersonalTrainerViewModel
    let onTrainerSelected: (PersonalTrainer) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)

            ScrollView {
                LazyVStack(spacing: FitTodaySpacing.md) {
                    if viewModel.isSearching {
                        ProgressView()
                            .tint(FitTodayColor.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, FitTodaySpacing.xl)
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        emptyResultsView
                    } else {
                        ForEach(viewModel.searchResults) { trainer in
                            TrainerRatingCard(
                                trainer: trainer,
                                onRate: { onTrainerSelected(trainer) },
                                onSelect: { onTrainerSelected(trainer) }
                            )
                        }
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.bottom, FitTodaySpacing.xl)
            }
            .scrollIndicators(.hidden)
        }
        .background(FitTodayColor.background)
        .onAppear {
            if viewModel.searchResults.isEmpty {
                Task { await viewModel.searchTrainers() }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(FitTodayColor.textSecondary)

            TextField("trainer.list.search_placeholder".localized, text: $viewModel.searchQuery)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, 10)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .onChange(of: viewModel.searchQuery) {
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                await viewModel.searchTrainers()
            }
        }
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("trainer.list.no_results".localized)
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("trainer.list.no_results_message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.xxl)
    }
}
