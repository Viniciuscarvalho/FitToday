//
//  CheckInSheet.swift
//  FitToday
//
//  Photo picker sheet for submitting workout check-ins with photo proof.
//

import SwiftUI
import PhotosUI
import Swinject

/// Sheet for submitting a workout check-in with photo proof.
struct CheckInSheet: View {
    let resolver: Resolver
    let challengeId: String
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CheckInSheetViewModel?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: FitTodaySpacing.lg) {
                // Header
                headerSection

                // Photo Picker
                photoPickerSection

                // Selected Photo Preview
                if let selectedImage {
                    photoPreviewSection(selectedImage)
                }

                Spacer()

                // Submit Button
                submitButton

                // Error Message
                if let errorMessage = viewModel?.errorMessage {
                    errorView(errorMessage)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.background)
            .navigationTitle("Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .task {
                viewModel = CheckInSheetViewModel(resolver: resolver, challengeId: challengeId)
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text("Comprove seu treino")
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Tire uma foto ou selecione da galeria para registrar seu check-in")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.lg)
    }

    // MARK: - Photo Picker Section

    private var photoPickerSection: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: FitTodaySpacing.md) {
                if selectedImage == nil {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Text("Toque para selecionar foto")
                        .font(FitTodayFont.ui(size: 15, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                } else {
                    Text("Toque para trocar foto")
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: selectedImage == nil ? 180 : 44)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 2, dash: selectedImage == nil ? [8] : [])
                            )
                            .foregroundStyle(selectedImage == nil ? FitTodayColor.outline : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Preview Section

    private func photoPreviewSection(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(FitTodayColor.brandPrimary, lineWidth: 2)
            )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                await submitCheckIn()
            }
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                if viewModel?.isLoading == true {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Enviar Check-In")
                }
            }
            .font(FitTodayFont.ui(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(canSubmit ? FitTodayColor.brandPrimary : FitTodayColor.textTertiary)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || viewModel?.isLoading == true)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(FitTodayColor.error)
            Text(message)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.error)
        }
        .padding(FitTodaySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(FitTodayColor.error.opacity(0.1))
        )
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        selectedImageData != nil && viewModel?.isLoading != true
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            selectedImage = nil
            selectedImageData = nil
            return
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                }
            }
        } catch {
            #if DEBUG
            print("[CheckInSheet] Error loading image: \(error)")
            #endif
            viewModel?.errorMessage = "Erro ao carregar imagem"
        }
    }

    private func submitCheckIn() async {
        guard let imageData = selectedImageData else { return }

        let success = await viewModel?.submitCheckIn(photoData: imageData) ?? false

        if success {
            onSuccess()
            dismiss()
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class CheckInSheetViewModel {
    private(set) var isLoading = false
    var errorMessage: String?

    private let resolver: Resolver
    private let challengeId: String

    init(resolver: Resolver, challengeId: String) {
        self.resolver = resolver
        self.challengeId = challengeId
    }

    func submitCheckIn(photoData: Data) async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Resolve dependencies
        guard let checkInUseCase = resolver.resolve(CheckInUseCase.self) else {
            errorMessage = "Serviço de check-in indisponível"
            return false
        }

        guard let historyRepo = resolver.resolve(WorkoutHistoryRepository.self) else {
            errorMessage = "Serviço de histórico indisponível"
            return false
        }

        guard let networkMonitor = resolver.resolve(NetworkMonitor.self) else {
            errorMessage = "Monitor de rede indisponível"
            return false
        }

        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorMessage = "Sem conexão com a internet"
            return false
        }

        do {
            // Get most recent workout entry (within last 24 hours)
            let entries = try await historyRepo.listEntries(limit: 1, offset: 0)

            guard let recentEntry = entries.first else {
                errorMessage = "Nenhum treino recente encontrado. Complete um treino primeiro."
                return false
            }

            // Check if workout was within last 24 hours
            let hoursSinceWorkout = Date().timeIntervalSince(recentEntry.date) / 3600
            guard hoursSinceWorkout < 24 else {
                errorMessage = "Treino muito antigo. Complete um treino hoje."
                return false
            }

            // Submit check-in
            _ = try await checkInUseCase.execute(
                workoutEntry: recentEntry,
                photoData: photoData,
                isConnected: true
            )

            #if DEBUG
            print("[CheckInSheet] Check-in submitted successfully")
            #endif

            return true

        } catch let error as CheckInError {
            switch error {
            case .networkUnavailable:
                errorMessage = "Sem conexão com a internet"
            case .notInGroup:
                errorMessage = "Entre em um grupo para fazer check-in"
            case .workoutTooShort(let minutes):
                errorMessage = "Treino muito curto (\(minutes) min). Mínimo: \(CheckIn.minimumWorkoutMinutes) min"
            case .uploadFailed:
                errorMessage = "Erro ao enviar foto. Tente novamente."
            case .noActiveChallenge:
                errorMessage = "Nenhum desafio ativo no momento"
            case .photoRequired:
                errorMessage = "Foto é obrigatória para o check-in"
            }
            return false
        } catch {
            #if DEBUG
            print("[CheckInSheet] Error: \(error)")
            #endif
            errorMessage = "Erro ao enviar check-in: \(error.localizedDescription)"
            return false
        }
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return CheckInSheet(resolver: container, challengeId: "test-challenge") {}
        .preferredColorScheme(.dark)
}
