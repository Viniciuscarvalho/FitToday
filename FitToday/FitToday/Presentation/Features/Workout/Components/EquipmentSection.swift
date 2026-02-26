//
//  EquipmentSection.swift
//  FitToday
//

import SwiftUI

/// Section displaying required equipment as a horizontal flow of pill-shaped chips.
struct EquipmentSection: View {
    let equipment: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Equipment Needed")
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            FlowLayout(spacing: FitTodaySpacing.sm) {
                ForEach(equipment, id: \.self) { item in
                    equipmentChip(item)
                }
            }
        }
    }

    // MARK: - Chip

    private func equipmentChip(_ name: String) -> some View {
        Text(name)
            .font(FitTodayFont.ui(size: 14, weight: .medium))
            .foregroundStyle(FitTodayColor.textPrimary)
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
            .background(FitTodayColor.surfaceElevated)
            .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

/// Simple horizontal wrapping layout for chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + rowHeight
        }

        return (positions, CGSize(width: totalWidth, height: totalHeight))
    }
}

// MARK: - Preview

#Preview {
    EquipmentSection(equipment: ["Barbell", "Bench", "Dumbbells", "Cable Machine", "Pull-up Bar"])
        .padding()
        .background(FitTodayColor.background)
        .preferredColorScheme(.dark)
}
