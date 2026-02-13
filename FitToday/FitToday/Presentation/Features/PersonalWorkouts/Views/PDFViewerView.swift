//
//  PDFViewerView.swift
//  FitToday
//
//  Visualizador de PDF para treinos do Personal.
//

import SwiftUI
import PDFKit

/// View para visualizar PDFs de treinos do Personal.
struct PDFViewerView: View {
    let workout: PersonalWorkout
    let viewModel: PersonalWorkoutsViewModel

    @State private var pdfURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let url = pdfURL {
                    pdfContentView(url: url)
                }
            }
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }

                if let url = pdfURL {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: url) {
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

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("personal.loading".localized)
                .font(FitTodayFont.ui(size: 16))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(FitTodayColor.warning)

            VStack(spacing: FitTodaySpacing.sm) {
                Text("personal.error.load".localized)
                    .font(FitTodayFont.ui(size: 18, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(message)
                    .font(FitTodayFont.ui(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadPDF() }
            } label: {
                Label("common.retry".localized, systemImage: "arrow.clockwise")
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
            }
            .buttonStyle(.borderedProminent)
            .tint(FitTodayColor.brandPrimary)
        }
        .padding(FitTodaySpacing.xl)
    }

    @ViewBuilder
    private func pdfContentView(url: URL) -> some View {
        if workout.fileType == .pdf {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
        } else {
            // Para imagens
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    errorView(message: "error.image.load_failed.title".localized)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Methods

    private func loadPDF() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            pdfURL = try await viewModel.getPDFURL(for: workout)
            await viewModel.markAsViewed(workout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - PDFKit Wrapper

/// UIViewRepresentable para PDFView do PDFKit.
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(FitTodayColor.background)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document == nil {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PDFViewerView(
        workout: .fixture(),
        viewModel: PersonalWorkoutsViewModel(
            repository: PreviewPersonalWorkoutRepository(),
            pdfCache: PreviewPDFCache()
        )
    )
}

// MARK: - Mocks for Preview

#if DEBUG
final class PreviewPersonalWorkoutRepository: PersonalWorkoutRepository, @unchecked Sendable {
    var workoutsToReturn: [PersonalWorkout] = []

    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout] {
        workoutsToReturn
    }

    func markAsViewed(_ workoutId: String) async throws {}

    func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]> {
        AsyncStream { continuation in
            continuation.yield(workoutsToReturn)
        }
    }
}

actor PreviewPDFCache: PDFCaching {
    func getPDF(for workout: PersonalWorkout) async throws -> URL {
        URL(fileURLWithPath: "/tmp/preview.pdf")
    }

    func isCached(workoutId: String, fileType: PersonalWorkout.FileType) async -> Bool {
        false
    }
}
#endif
