//
//  TrainerCard.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import SwiftUI

/// Variants for the TrainerCard display
enum TrainerCardVariant {
    case compact
    case expanded
}

struct TrainerCard: View {
    let trainer: PersonalTrainer
    var variant: TrainerCardVariant = .compact

    var body: some View {
        switch variant {
        case .compact:
            compactCard
        case .expanded:
            expandedCard
        }
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Photo
            trainerPhoto(size: 56)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: FitTodaySpacing.xs) {
                    Text(trainer.displayName)
                        .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    if trainer.isActive {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    }
                }

                if !trainer.specializations.isEmpty {
                    Text(trainer.specializations.prefix(2).joined(separator: " - "))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Expanded Card

    private var expandedCard: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Header with photo and name
            HStack(spacing: FitTodaySpacing.lg) {
                trainerPhoto(size: 80)

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Text(trainer.displayName)
                            .font(FitTodayFont.ui(size: 20, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)

                        if trainer.isActive {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                        }
                    }

                    Text(trainer.email)
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()
            }

            // Bio
            if let bio = trainer.bio, !bio.isEmpty {
                Text(bio)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Specializations
            if !trainer.specializations.isEmpty {
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("Especializacoes")
                        .font(FitTodayFont.ui(size: 12, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    FlowLayout(spacing: FitTodaySpacing.xs) {
                        ForEach(trainer.specializations, id: \.self) { specialization in
                            specializationTag(specialization)
                        }
                    }
                }
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Components

    private func trainerPhoto(size: CGFloat) -> some View {
        Group {
            if let photoURL = trainer.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        photoPlaceholder(size: size)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        photoPlaceholder(size: size)
                    @unknown default:
                        photoPlaceholder(size: size)
                    }
                }
            } else {
                photoPlaceholder(size: size)
            }
        }
    }

    private func photoPlaceholder(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.1))

            Text(trainer.displayName.prefix(1).uppercased())
                .font(FitTodayFont.ui(size: size * 0.4, weight: .bold))
                .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .frame(width: size, height: size)
    }

    private func specializationTag(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 12, weight: .medium))
            .foregroundStyle(FitTodayColor.brandPrimary)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, 4)
            .background(FitTodayColor.brandPrimary.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

/// A simple flow layout for tags that wraps to next line
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        let lastWidth = subviews.last?.sizeThatFits(.unspecified).width ?? 0
        let totalWidth = min(maxWidth, positions.reduce(0) { max($0, $1.x) } + lastWidth)

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Preview

#Preview("Compact") {
    VStack(spacing: 16) {
        TrainerCard(
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
            variant: .compact
        )

        TrainerCard(
            trainer: PersonalTrainer(
                id: "2",
                displayName: "Ana Paula",
                email: "ana@example.com",
                photoURL: nil,
                specializations: ["Pilates", "Yoga"],
                bio: nil,
                isActive: true,
                inviteCode: "XYZ789",
                maxStudents: 15,
                currentStudentCount: 3
            ),
            variant: .compact
        )
    }
    .padding()
    .background(FitTodayColor.background)
}

#Preview("Expanded") {
    TrainerCard(
        trainer: PersonalTrainer(
            id: "1",
            displayName: "Carlos Silva",
            email: "carlos@example.com",
            photoURL: nil,
            specializations: ["Musculacao", "Funcional", "HIIT", "Emagrecimento", "Hipertrofia"],
            bio: "Personal trainer com 10 anos de experiencia em musculacao e treinamento funcional. Especializado em emagrecimento e hipertrofia.",
            isActive: true,
            inviteCode: "ABC123",
            maxStudents: 20,
            currentStudentCount: 5
        ),
        variant: .expanded
    )
    .padding()
    .background(FitTodayColor.background)
}
