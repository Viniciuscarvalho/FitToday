//
//  CMSWorkoutDetailView.swift
//  FitToday
//
//  Detail view for a CMS personal trainer workout.
//

import SwiftUI
import Swinject
import PDFKit

// MARK: - ViewModel

@Observable
@MainActor
final class CMSWorkoutDetailViewModel {
    private(set) var workout: TrainerWorkout?
    private(set) var progress: CMSWorkoutProgress?
    private(set) var isLoading = false
    private(set) var isCompleting = false
    private(set) var error: String?
    var completedSuccessfully = false

    private let workoutId: String
    private let detailUseCase: FetchCMSWorkoutDetailUseCase?
    private let progressUseCase: FetchWorkoutProgressUseCase?
    private let completeUseCase: CompleteCMSWorkoutUseCase?

    init(
        workoutId: String,
        detailUseCase: FetchCMSWorkoutDetailUseCase?,
        progressUseCase: FetchWorkoutProgressUseCase?,
        completeUseCase: CompleteCMSWorkoutUseCase?
    ) {
        self.workoutId = workoutId
        self.detailUseCase = detailUseCase
        self.progressUseCase = progressUseCase
        self.completeUseCase = completeUseCase
    }

    func loadWorkout() async {
        isLoading = true
        error = nil

        do {
            workout = try await detailUseCase?.execute(id: workoutId)
        } catch {
            self.error = error.localizedDescription
        }

        // Load progress in parallel (non-blocking)
        do {
            progress = try await progressUseCase?.execute(workoutId: workoutId)
        } catch {
            #if DEBUG
            print("[CMSWorkoutDetail] Progress load failed: \(error)")
            #endif
        }

        isLoading = false
    }

    func completeWorkout() async {
        isCompleting = true
        error = nil

        do {
            try await completeUseCase?.execute(id: workoutId)
            completedSuccessfully = true
            // Reload to reflect updated status
            await loadWorkout()
        } catch {
            self.error = error.localizedDescription
        }

        isCompleting = false
    }
}

// MARK: - View

struct CMSWorkoutDetailView: View {
    @Environment(AppRouter.self) private var router

    @State private var viewModel: CMSWorkoutDetailViewModel
    @State private var showPDFSheet = false

    let workoutId: String

    init(workoutId: String, resolver: Resolver) {
        self.workoutId = workoutId
        _viewModel = State(wrappedValue: CMSWorkoutDetailViewModel(
            workoutId: workoutId,
            detailUseCase: resolver.resolve(FetchCMSWorkoutDetailUseCase.self),
            progressUseCase: resolver.resolve(FetchWorkoutProgressUseCase.self),
            completeUseCase: resolver.resolve(CompleteCMSWorkoutUseCase.self)
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.workout == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let workout = viewModel.workout {
                workoutContent(workout)
            } else if let error = viewModel.error {
                errorView(error)
            }
        }
        .background(FitTodayColor.background)
        .navigationTitle("cms_workout.detail.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadWorkout()
        }
        .alert("cms_workout.completion.alert_title".localized, isPresented: $viewModel.completedSuccessfully) {
            Button("Ok") {}
        } message: {
            Text("cms_workout.completion.message".localized)
        }
        .sheet(isPresented: $showPDFSheet) {
            if let pdfUrlString = viewModel.workout?.pdfUrl,
               let pdfUrl = URL(string: pdfUrlString) {
                CMSPDFSheetView(url: pdfUrl, title: viewModel.workout?.title ?? "PDF")
            }
        }
    }

    // MARK: - Content

    private func workoutContent(_ workout: TrainerWorkout) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Header
                headerSection(workout)

                // Progress (if available)
                if let progress = viewModel.progress {
                    progressSection(progress)
                }

                // Phases & Exercises
                ForEach(Array(workout.phases.enumerated()), id: \.offset) { _, phase in
                    phaseSection(phase)
                }

                // Actions
                actionsSection(workout)

                Spacer(minLength: FitTodaySpacing.xxl)
            }
            .padding(FitTodaySpacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private func headerSection(_ workout: TrainerWorkout) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text(workout.title)
                .font(FitTodayFont.display(size: 24, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            if let description = workout.description, !description.isEmpty {
                Text(description)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Info chips
            HStack(spacing: FitTodaySpacing.sm) {
                infoChip(icon: "clock", text: "\(workout.estimatedDurationMinutes) min")
                infoChip(icon: "flame", text: workout.intensity.displayName)
                infoChip(icon: "target", text: workout.focus.displayName)
            }

            if !workout.isActive {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("cms_workout.detail.completed_badge".localized)
                }
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.success)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(FitTodayColor.success.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
        }
        .foregroundStyle(FitTodayColor.textSecondary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, 6)
        .background(FitTodayColor.background)
        .clipShape(Capsule())
    }

    // MARK: - Progress

    private func progressSection(_ progress: CMSWorkoutProgress) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("cms_workout.progress.title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            HStack(spacing: FitTodaySpacing.lg) {
                VStack(spacing: 4) {
                    Text("\(progress.completedSessions)")
                        .font(FitTodayFont.ui(size: 24, weight: .bold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text("cms_workout.progress.of".localized(with: progress.totalSessions))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Text("cms_workout.progress.sessions".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }

                Spacer()

                // Progress bar
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress.overallProgress * 100))%")
                        .font(FitTodayFont.ui(size: 18, weight: .bold))
                        .foregroundStyle(FitTodayColor.brandPrimary)

                    ProgressView(value: progress.overallProgress)
                        .tint(FitTodayColor.brandPrimary)
                        .frame(width: 120)
                }
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Phase Section

    private func phaseSection(_ phase: TrainerWorkoutPhase) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text(phase.name)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.md)

            VStack(spacing: FitTodaySpacing.xs) {
                ForEach(Array(phase.items.enumerated()), id: \.offset) { index, item in
                    exerciseRow(item, index: index + 1)
                }
            }
        }
    }

    private func exerciseRow(_ item: TrainerWorkoutItem, index: Int) -> some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Index
            Text("\(index)")
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(FitTodayColor.brandPrimary.opacity(0.15))
                )

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.exerciseName)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: FitTodaySpacing.sm) {
                    Text("\(item.sets) x \(item.reps.display)")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text("cms_workout.exercise.rest_label".localized(with: item.restSeconds))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
    }

    // MARK: - Actions

    private func actionsSection(_ workout: TrainerWorkout) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            // PDF button (only if pdfUrl is available)
            if workout.pdfUrl != nil {
                Button {
                    showPDFSheet = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("cms_workout.detail.view_pdf".localized)
                    }
                }
                .fitPrimaryStyle()
            }

            // Feedback button
            Button {
                router.push(.cmsWorkoutFeedback(workout.id), on: .workout)
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                    Text("cms_workout.feedback.send_button".localized)
                }
            }
            .fitSecondaryStyle()

            // Complete button (only if active)
            if workout.isActive {
                Button {
                    Task {
                        await viewModel.completeWorkout()
                    }
                } label: {
                    HStack {
                        if viewModel.isCompleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle")
                            Text("cms_workout.completion.button".localized)
                        }
                    }
                }
                .fitPrimaryStyle()
                .disabled(viewModel.isCompleting)
            }
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.error)

            Text(message)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button("cms_workout.detail.retry".localized) {
                Task { await viewModel.loadWorkout() }
            }
            .fitSecondaryStyle()
        }
        .padding()
    }
}

// MARK: - CMS PDF Sheet View

struct CMSPDFSheetView: View {
    let url: URL
    let title: String

    @State private var localURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: FitTodaySpacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("pdf.loading".localized)
                            .font(FitTodayFont.ui(size: 16))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: FitTodaySpacing.lg) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(FitTodayColor.warning)
                        Text(error)
                            .font(FitTodayFont.ui(size: 15, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("common.retry".localized) {
                            Task { await loadPDF() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(FitTodayColor.brandPrimary)
                    }
                    .padding(FitTodaySpacing.xl)
                } else if let pdfURL = localURL {
                    PDFKitView(url: pdfURL)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
                if let pdfURL = localURL {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .task {
            await loadPDF()
        }
    }

    private func loadPDF() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).pdf")
            try data.write(to: fileURL)
            localURL = fileURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
