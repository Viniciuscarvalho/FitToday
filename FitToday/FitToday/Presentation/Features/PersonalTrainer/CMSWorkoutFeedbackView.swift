//
//  CMSWorkoutFeedbackView.swift
//  FitToday
//
//  View for viewing and posting workout feedback to the personal trainer.
//

import SwiftUI
import Swinject

// MARK: - ViewModel

@Observable
@MainActor
final class CMSWorkoutFeedbackViewModel {
    private(set) var feedbackList: [CMSWorkoutFeedback] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var error: String?

    var newMessage: String = ""
    var selectedType: CMSFeedbackType = .general
    var selectedRating: Int?

    private let workoutId: String
    private let fetchUseCase: FetchWorkoutFeedbackUseCase?
    private let postUseCase: PostWorkoutFeedbackUseCase?

    var canSend: Bool {
        !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    init(
        workoutId: String,
        fetchUseCase: FetchWorkoutFeedbackUseCase?,
        postUseCase: PostWorkoutFeedbackUseCase?
    ) {
        self.workoutId = workoutId
        self.fetchUseCase = fetchUseCase
        self.postUseCase = postUseCase
    }

    func loadFeedback() async {
        isLoading = true
        error = nil

        do {
            feedbackList = try await fetchUseCase?.execute(workoutId: workoutId) ?? []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func sendFeedback() async {
        guard canSend else { return }

        isSending = true
        error = nil

        do {
            let feedback = try await postUseCase?.execute(
                workoutId: workoutId,
                type: selectedType,
                message: newMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                rating: selectedRating
            )

            if let feedback {
                feedbackList.insert(feedback, at: 0)
            }

            // Reset form
            newMessage = ""
            selectedType = .general
            selectedRating = nil
        } catch {
            self.error = error.localizedDescription
        }

        isSending = false
    }
}

// MARK: - View

struct CMSWorkoutFeedbackView: View {
    @State private var viewModel: CMSWorkoutFeedbackViewModel

    init(workoutId: String, resolver: Resolver) {
        _viewModel = State(wrappedValue: CMSWorkoutFeedbackViewModel(
            workoutId: workoutId,
            fetchUseCase: resolver.resolve(FetchWorkoutFeedbackUseCase.self),
            postUseCase: resolver.resolve(PostWorkoutFeedbackUseCase.self)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Feedback list
            ScrollView {
                VStack(spacing: FitTodaySpacing.md) {
                    if viewModel.isLoading && viewModel.feedbackList.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, FitTodaySpacing.xxl)
                    } else if viewModel.feedbackList.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.feedbackList) { feedback in
                            feedbackRow(feedback)
                        }
                    }
                }
                .padding(FitTodaySpacing.md)
            }
            .scrollIndicators(.hidden)

            Divider()
                .foregroundStyle(FitTodayColor.outline)

            // Input form
            inputSection
        }
        .background(FitTodayColor.background)
        .navigationTitle("cms_feedback.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFeedback()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "message.badge.circle")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("cms_feedback.empty.title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("cms_feedback.empty.message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.xxl)
    }

    // MARK: - Feedback Row

    private func feedbackRow(_ feedback: CMSWorkoutFeedback) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            HStack {
                typeBadge(feedback.type)

                Spacer()

                Text(feedback.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Message
            Text(feedback.message)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Rating
            if let rating = feedback.rating {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(star <= rating ? FitTodayColor.warning : FitTodayColor.textTertiary)
                    }
                }
            }

            // Trainer reply
            if let reply = feedback.replyMessage, !reply.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("cms_feedback.trainer_reply.label".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .bold))
                        .foregroundStyle(FitTodayColor.brandPrimary)

                    Text(reply)
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
                .padding(FitTodaySpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FitTodayColor.brandPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    private func typeBadge(_ type: CMSFeedbackType) -> some View {
        Text(typeLabel(type))
            .font(FitTodayFont.ui(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, 4)
            .background(typeColor(type))
            .clipShape(Capsule())
    }

    private func typeLabel(_ type: CMSFeedbackType) -> String {
        switch type {
        case .general: return "cms_feedback.type.general".localized
        case .difficulty: return "cms_feedback.type.difficulty".localized
        case .exercise: return "cms_feedback.type.exercise".localized
        case .completion: return "cms_feedback.type.completion".localized
        case .question: return "cms_feedback.type.question".localized
        }
    }

    private func typeColor(_ type: CMSFeedbackType) -> Color {
        switch type {
        case .general: return FitTodayColor.info
        case .difficulty: return FitTodayColor.warning
        case .exercise: return FitTodayColor.brandPrimary
        case .completion: return FitTodayColor.success
        case .question: return .purple
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.xs) {
                    ForEach([CMSFeedbackType.general, .difficulty, .exercise, .question], id: \.self) { type in
                        Button {
                            viewModel.selectedType = type
                        } label: {
                            Text(typeLabel(type))
                                .font(FitTodayFont.ui(size: 12, weight: .medium))
                                .foregroundStyle(viewModel.selectedType == type ? .white : FitTodayColor.textSecondary)
                                .padding(.horizontal, FitTodaySpacing.sm)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedType == type ? typeColor(type) : FitTodayColor.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.selectedType == type ? Color.clear : FitTodayColor.outline, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Rating selector
            HStack(spacing: 4) {
                Text("cms_feedback.rating.label".localized)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                ForEach(1...5, id: \.self) { star in
                    Button {
                        viewModel.selectedRating = viewModel.selectedRating == star ? nil : star
                    } label: {
                        Image(systemName: star <= (viewModel.selectedRating ?? 0) ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundStyle(star <= (viewModel.selectedRating ?? 0) ? FitTodayColor.warning : FitTodayColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Message input + send
            HStack(spacing: FitTodaySpacing.sm) {
                TextField("cms_feedback.input.placeholder".localized, text: $viewModel.newMessage)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .padding(FitTodaySpacing.sm)
                    .background(FitTodayColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))

                Button {
                    Task { await viewModel.sendFeedback() }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .tint(FitTodayColor.brandPrimary)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(viewModel.canSend ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSend)
            }

            if let error = viewModel.error {
                Text(error)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.error)
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.background)
    }
}
