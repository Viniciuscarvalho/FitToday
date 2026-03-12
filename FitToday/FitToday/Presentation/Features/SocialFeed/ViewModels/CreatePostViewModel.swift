//
//  CreatePostViewModel.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import Foundation
import UIKit

@MainActor
@Observable
final class CreatePostViewModel {
    // MARK: - State

    var selectedImage: UIImage?
    var caption: String = ""
    private(set) var isSubmitting = false
    var errorMessage: String?
    private(set) var createdPost: FeedPost?

    var canSubmit: Bool { selectedImage != nil && !isSubmitting }

    // MARK: - Workout Data (auto-pulled)

    let workoutTitle: String
    let workoutDurationMinutes: Int
    let exerciseCount: Int
    let totalVolume: Double?

    // MARK: - Dependencies

    private let createPostUseCase: CreateFeedPostUseCase

    // MARK: - Init

    init(
        createPostUseCase: CreateFeedPostUseCase,
        workoutTitle: String,
        workoutDurationMinutes: Int,
        exerciseCount: Int,
        totalVolume: Double?
    ) {
        self.createPostUseCase = createPostUseCase
        self.workoutTitle = workoutTitle
        self.workoutDurationMinutes = workoutDurationMinutes
        self.exerciseCount = exerciseCount
        self.totalVolume = totalVolume
    }

    // MARK: - Actions

    func submitPost() async {
        guard let image = selectedImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            errorMessage = FeedError.mediaCompressionFailed.localizedDescription
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            createdPost = try await createPostUseCase.execute(
                mediaData: imageData,
                mediaType: .photo,
                caption: caption.isEmpty ? nil : caption,
                workoutTitle: workoutTitle,
                workoutDurationMinutes: workoutDurationMinutes,
                exerciseCount: exerciseCount,
                totalVolume: totalVolume
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
