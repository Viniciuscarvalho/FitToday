//
//  CheckInPhotoView.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import SwiftUI

// MARK: - CheckInPhotoView

/// View for capturing or selecting a photo for workout check-in.
struct CheckInPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CheckInViewModel

    let workoutEntry: WorkoutHistoryEntry
    let onSuccess: (CheckIn) -> Void

    init(
        viewModel: CheckInViewModel,
        workoutEntry: WorkoutHistoryEntry,
        onSuccess: @escaping (CheckIn) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.workoutEntry = workoutEntry
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FitTodaySpacing.lg) {
                // Header info
                WorkoutSummaryHeader(entry: workoutEntry)

                // Photo picker
                PhotoPickerView(selectedImage: $viewModel.selectedImage)

                Spacer()

                // Submit button
                Button("checkin.button.submit".localized) {
                    Task { await viewModel.submitCheckIn() }
                }
                .fitPrimaryStyle()
                .disabled(!viewModel.canSubmit)
            }
            .padding()
            .navigationTitle("checkin.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .alert("common.error".localized, isPresented: $viewModel.showError) {
                Button("common.done".localized) { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "error.generic".localized)
            }
            .onChange(of: viewModel.checkInResult) { _, checkIn in
                if let checkIn {
                    onSuccess(checkIn)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - WorkoutSummaryHeader

/// Displays a summary of the completed workout.
struct WorkoutSummaryHeader: View {
    let entry: WorkoutHistoryEntry

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(FitTodayColor.brandPrimary)

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(entry.title)
                    .font(.headline)

                if let duration = entry.durationMinutes {
                    Text("feed.duration".localized(with: duration))
                        .font(.subheadline)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
    }
}

// MARK: - LoadingOverlay

/// Full-screen loading overlay with progress indicator.
private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: FitTodaySpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)

                Text("checkin.sending".localized)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(FitTodaySpacing.xl)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        }
    }
}
