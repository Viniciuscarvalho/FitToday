//
//  ConnectionRequestSheet.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import SwiftUI

struct ConnectionRequestSheet: View {
    let trainer: PersonalTrainer
    let isRequesting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.xl) {
            // Header
            VStack(spacing: FitTodaySpacing.md) {
                // Trainer Photo
                trainerPhoto

                // Trainer Name
                HStack(spacing: FitTodaySpacing.xs) {
                    Text(trainer.displayName)
                        .font(FitTodayFont.ui(size: 24, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    if trainer.isActive {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    }
                }

                // Specializations
                if !trainer.specializations.isEmpty {
                    Text(trainer.specializations.joined(separator: " - "))
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Info Box
            infoBox

            Spacer()

            // Actions
            VStack(spacing: FitTodaySpacing.md) {
                Button {
                    onConfirm()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("connection_request.send_button".localized)
                        }
                    }
                }
                .fitPrimaryStyle()
                .disabled(isRequesting)

                Button {
                    onCancel()
                } label: {
                    Text("common.cancel".localized)
                }
                .fitSecondaryStyle()
                .disabled(isRequesting)
            }
        }
        .padding()
        .background(FitTodayColor.background.ignoresSafeArea())
    }

    // MARK: - Trainer Photo

    private var trainerPhoto: some View {
        Group {
            if let photoURL = trainer.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        photoPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        photoPlaceholder
                    @unknown default:
                        photoPlaceholder
                    }
                }
            } else {
                photoPlaceholder
            }
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.1))

            Text(trainer.displayName.prefix(1).uppercased())
                .font(FitTodayFont.ui(size: 40, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .frame(width: 100, height: 100)
    }

    // MARK: - Info Box

    private var infoBox: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("connection_request.info_title".localized)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            infoRow(
                icon: "envelope.fill",
                text: "connection_request.info_notification".localized
            )

            infoRow(
                icon: "clock.fill",
                text: "connection_request.info_wait".localized
            )

            infoRow(
                icon: "checkmark.circle.fill",
                text: "connection_request.info_approved".localized
            )

            infoRow(
                icon: "xmark.circle",
                text: "connection_request.info_cancel".localized
            )
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 20)

            Text(text)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ConnectionRequestSheet(
        trainer: PersonalTrainer(
            id: "1",
            displayName: "Carlos Silva",
            email: "carlos@example.com",
            photoURL: nil,
            specializations: ["Musculacao", "Funcional", "HIIT"],
            bio: "Personal trainer com 10 anos de experiencia",
            isActive: true,
            inviteCode: "ABC123",
            maxStudents: 20,
            currentStudentCount: 5
        ),
        isRequesting: false,
        onConfirm: {},
        onCancel: {}
    )
}
