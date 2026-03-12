//
//  TrainerReviewSheet.swift
//  FitToday
//
//  Sheet for submitting a review for a personal trainer.
//

import SwiftUI
import Swinject

struct TrainerReviewSheet: View {
    let trainerId: String
    let trainerName: String
    let currentUserId: String
    let onDismiss: () -> Void
    let onSuccess: () -> Void

    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var submitted = false

    @Environment(\.dependencyResolver) private var resolver

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    if submitted {
                        successView
                    } else {
                        reviewForm
                    }
                }
                .padding(FitTodaySpacing.lg)
            }
            .background(FitTodayColor.background)
            .navigationTitle("trainer.review.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("trainer.review.cancel".localized) {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Review Form

    private var reviewForm: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Trainer name
            Text(trainerName)
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Star rating
            VStack(spacing: FitTodaySpacing.sm) {
                Text("trainer.review.rating_prompt".localized)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                HStack(spacing: FitTodaySpacing.md) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                rating = star
                            }
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= rating ? FitTodayColor.warning : FitTodayColor.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Comment
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text("trainer.review.comment_label".localized)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                TextEditor(text: $comment)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(FitTodaySpacing.sm)
                    .background(FitTodayColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }

            // Error
            if let error {
                Text(error)
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.error)
            }

            // Submit button
            Button {
                Task { await submitReview() }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("trainer.review.submit".localized)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(rating > 0 ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(rating == 0 || isSubmitting)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(FitTodayColor.success)

            Text("trainer.review.success".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("trainer.review.thanks".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                onSuccess()
            } label: {
                Text("trainer.review.done".localized)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, FitTodaySpacing.xl)
    }

    // MARK: - Submit

    private func submitReview() async {
        guard rating > 0 else { return }
        isSubmitting = true
        error = nil

        guard let service = resolver.resolve(CMSTrainerService.self) else {
            error = "trainer.review.error_generic".localized
            isSubmitting = false
            return
        }

        let userName = UserDefaults.standard.string(forKey: "socialUserDisplayName") ?? "Athlete"

        let request = CMSCreateReviewRequest(
            studentId: currentUserId,
            studentName: userName,
            rating: rating,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            _ = try await service.submitReview(trainerId: trainerId, review: request)
            withAnimation { submitted = true }
        } catch {
            self.error = "trainer.review.error_generic".localized
            #if DEBUG
            print("[TrainerReviewSheet] Submit error: \(error)")
            #endif
        }

        isSubmitting = false
    }
}
