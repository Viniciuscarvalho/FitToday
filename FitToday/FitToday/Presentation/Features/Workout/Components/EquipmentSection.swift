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

// Note: Uses FlowLayout from TrainerCard.swift (shared)

// MARK: - Preview

#Preview {
    EquipmentSection(equipment: ["Barbell", "Bench", "Dumbbells", "Cable Machine", "Pull-up Bar"])
        .padding()
        .background(FitTodayColor.background)
        .preferredColorScheme(.dark)
}
