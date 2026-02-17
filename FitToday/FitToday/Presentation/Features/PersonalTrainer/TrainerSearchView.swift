//
//  TrainerSearchView.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import SwiftUI

struct TrainerSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PersonalTrainerViewModel

    @State private var searchDebounceTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Header
                searchHeader

                Divider()
                    .background(FitTodayColor.outline)

                // Content
                ScrollView {
                    VStack(spacing: FitTodaySpacing.lg) {
                        // Invite Code Section
                        inviteCodeSection

                        // Search Results
                        if viewModel.isSearching {
                            searchingView
                        } else if !viewModel.searchResults.isEmpty {
                            searchResultsSection
                        } else if !viewModel.searchQuery.isEmpty {
                            noResultsView
                        } else {
                            searchPromptView
                        }
                    }
                    .padding()
                }
            }
            .background(FitTodayColor.background.ignoresSafeArea())
            .navigationTitle("personal_trainer.search.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: FitTodaySpacing.md) {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FitTodayColor.textSecondary)

                TextField("personal_trainer.search.placeholder".localized, text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .onChange(of: viewModel.searchQuery) { _, newValue in
                        debounceSearch(query: newValue)
                    }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
            .padding()
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .padding()
    }

    // MARK: - Invite Code Section

    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("personal_trainer.search.invite_code".localized)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            HStack(spacing: FitTodaySpacing.sm) {
                TextField("personal_trainer.search.invite_input".localized, text: $viewModel.inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                    .autocorrectionDisabled()

                Button {
                    Task {
                        await viewModel.findByInviteCode()
                    }
                } label: {
                    if viewModel.isSearching && !viewModel.inviteCode.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 60)
                    } else {
                        Text("personal_trainer.search.find_button".localized)
                            .frame(width: 60)
                    }
                }
                .fitPrimaryStyle()
                .disabled(!viewModel.canUseInviteCode || viewModel.isSearching)
            }

            Text("personal_trainer.search.invite_hint".localized)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("personal_trainer.search.results".localized)
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            ForEach(viewModel.searchResults) { trainer in
                TrainerCard(trainer: trainer, variant: .compact)
                    .onTapGesture {
                        viewModel.selectTrainer(trainer)
                    }
            }
        }
    }

    // MARK: - Searching View

    private var searchingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("personal_trainer.search.searching".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FitTodaySpacing.xl)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("personal_trainer.search.no_results".localized)
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("personal_trainer.search.no_results_hint".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, FitTodaySpacing.xl)
    }

    // MARK: - Search Prompt View

    private var searchPromptView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.5))

            Text("personal_trainer.search.prompt".localized)
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("personal_trainer.search.prompt_hint".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.7))
        }
        .padding(.vertical, FitTodaySpacing.xl)
    }

    // MARK: - Debounce Search

    private func debounceSearch(query: String) {
        searchDebounceTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            guard !Task.isCancelled else { return }
            await viewModel.searchTrainers()
        }
    }
}

// MARK: - Preview

#Preview {
    TrainerSearchView(viewModel: PersonalTrainerViewModel(
        discoverTrainersUseCase: nil,
        requestConnectionUseCase: nil,
        cancelConnectionUseCase: nil,
        getCurrentTrainerUseCase: nil,
        fetchAssignedWorkoutsUseCase: nil,
        featureFlagChecker: nil
    ))
}
