//
//  PhotoPickerView.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import SwiftUI

// MARK: - PhotoPickerView

/// A view that allows users to select or capture a photo.
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            if let image = selectedImage {
                // Photo preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fill)
                    .frame(height: 250)
                    .cornerRadius(FitTodayRadius.lg)
                    .clipped()

                Button("checkin.photo.change".localized) {
                    showImagePicker = true
                    sourceType = .photoLibrary
                }
                .fitSecondaryStyle()
            } else {
                // Empty state with camera/gallery buttons
                VStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text("checkin.photo.placeholder".localized)
                        .font(.subheadline)
                        .foregroundStyle(FitTodayColor.textSecondary)

                    HStack(spacing: FitTodaySpacing.md) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                sourceType = .camera
                                showImagePicker = true
                            } label: {
                                Label("checkin.button.camera".localized, systemImage: "camera")
                            }
                            .fitSecondaryStyle()
                        }

                        Button {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        } label: {
                            Label("checkin.button.gallery".localized, systemImage: "photo")
                        }
                        .fitSecondaryStyle()
                    }
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(FitTodayColor.surface)
                .cornerRadius(FitTodayRadius.lg)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: sourceType)
                .ignoresSafeArea()
        }
    }
}
