//
//  CreatePostView.swift
//  FitToday
//
//  Created by Claude on 12/03/26.
//

import PhotosUI
import SwiftUI

// MARK: - Create Post View

struct CreatePostView: View {
    @State private var viewModel: CreatePostViewModel
    @State private var selectedPhotosItem: PhotosPickerItem?
    @State private var showCamera = false
    @Environment(\.dismiss) private var dismiss

    let onSuccess: () -> Void

    init(viewModel: CreatePostViewModel, onSuccess: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    // MARK: - Workout Summary
                    workoutSummaryCard

                    // MARK: - Photo Section
                    photoSection

                    // MARK: - Caption
                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text("Legenda (opcional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(FitTodayColor.textSecondary)

                        TextField("Como foi o treino?", text: $viewModel.caption, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Submit
                    Button {
                        Task {
                            await viewModel.submitPost()
                            if viewModel.createdPost != nil {
                                onSuccess()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Publicar")
                        }
                    }
                    .fitPrimaryStyle()
                    .disabled(!viewModel.canSubmit)
                }
                .padding()
            }
            .navigationTitle("Postar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("Erro", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
            }
        }
    }

    // MARK: - Workout Summary Card

    private var workoutSummaryCard: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Treino Concluído")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            HStack(spacing: FitTodaySpacing.lg) {
                VStack {
                    Text("\(viewModel.workoutDurationMinutes)")
                        .font(.title3.weight(.bold))
                    Text("min")
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text("\(viewModel.exerciseCount)")
                        .font(.title3.weight(.bold))
                    Text("exercícios")
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                if let volume = viewModel.totalVolume, volume > 0 {
                    Divider().frame(height: 30)
                    VStack {
                        Text(String(format: "%.0f", volume))
                            .font(.title3.weight(.bold))
                        Text("kg total")
                            .font(.caption)
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.brandPrimary.opacity(0.08))
        )
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            viewModel.selectedImage = nil
                            selectedPhotosItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
            } else {
                HStack(spacing: FitTodaySpacing.md) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: FitTodaySpacing.xs) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Câmera")
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(FitTodayColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhotosItem, matching: .images) {
                        VStack(spacing: FitTodaySpacing.xs) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Galeria")
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(FitTodayColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    }
                }
            }
        }
        .onChange(of: selectedPhotosItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.selectedImage = uiImage
                }
            }
        }
    }
}
