//
//  CheckInViewModel.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import Foundation
import UIKit

// MARK: - CheckInViewModel

/// ViewModel for managing the check-in flow with photo capture.
@MainActor
@Observable
final class CheckInViewModel {
    // MARK: - State

    var selectedImage: UIImage?
    private(set) var isLoading = false
    var showError = false
    var errorMessage: String?
    private(set) var checkInResult: CheckIn?

    // MARK: - Computed Properties

    var canSubmit: Bool {
        selectedImage != nil && !isLoading
    }

    var hasPhoto: Bool {
        selectedImage != nil
    }

    // MARK: - Dependencies

    private let checkInUseCase: CheckInUseCase
    private let workoutEntry: WorkoutHistoryEntry
    private let networkMonitor: NetworkMonitor

    // MARK: - Init

    init(
        checkInUseCase: CheckInUseCase,
        workoutEntry: WorkoutHistoryEntry,
        networkMonitor: NetworkMonitor
    ) {
        self.checkInUseCase = checkInUseCase
        self.workoutEntry = workoutEntry
        self.networkMonitor = networkMonitor
    }

    // MARK: - Actions

    func submitCheckIn() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 1.0) else {
            errorMessage = CheckInError.photoRequired.errorDescription
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let checkIn = try await checkInUseCase.execute(
                workoutEntry: workoutEntry,
                photoData: imageData,
                isConnected: networkMonitor.isConnected
            )
            checkInResult = checkIn
        } catch let error as CheckInError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func clearError() {
        showError = false
        errorMessage = nil
    }

    func clearImage() {
        selectedImage = nil
    }
}
