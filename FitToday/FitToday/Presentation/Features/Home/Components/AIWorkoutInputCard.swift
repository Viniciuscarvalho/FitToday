//
//  AIWorkoutInputCard.swift
//  FitToday
//
//  Card for AI-powered workout generation input.
//

import SwiftUI

/// Input data for AI workout generation.
struct AIWorkoutInput: Sendable {
    var selectedMuscles: Set<MuscleGroup> = []
    var fatigueLevel: Int = 3 // 1-5
    var availableTime: Int = 45 // minutes
    var equipment: EquipmentAvailability = .fullGym
}

/// Equipment availability options.
enum EquipmentAvailability: String, CaseIterable, Sendable {
    case fullGym = "Academia"
    case homeGym = "Casa"
    case bodyweight = "Sem Equipamento"

    var icon: String {
        switch self {
        case .fullGym: return "building.2"
        case .homeGym: return "house"
        case .bodyweight: return "figure.stand"
        }
    }
}

/// Card for inputting AI workout generation parameters.
struct AIWorkoutInputCard: View {
    @Binding var input: AIWorkoutInput
    let onGenerate: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header
            headerSection

            if isExpanded {
                // Muscle Selection
                muscleSelectionSection

                // Fatigue Level
                fatigueSection

                // Time Selection
                timeSection

                // Equipment Selection
                equipmentSection

                // Generate Button
                generateButton
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary.opacity(0.5), FitTodayColor.brandSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text("Gerar Treino com IA")
                    .font(FitTodayFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Muscle Selection Section

    private var muscleSelectionSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Músculos Alvo")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            MuscleSelectionGrid(selectedMuscles: $input.selectedMuscles)
        }
    }

    // MARK: - Fatigue Section

    private var fatigueSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("Nível de Fadiga")
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Spacer()

                Text(fatigueLabel)
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(fatigueColor)
            }

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        input.fatigueLevel = level
                    } label: {
                        Circle()
                            .fill(level <= input.fatigueLevel ? fatigueColor : FitTodayColor.outline)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(level == input.fatigueLevel ? fatigueColor : Color.clear, lineWidth: 2)
                                    .padding(-2)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
    }

    private var fatigueLabel: String {
        switch input.fatigueLevel {
        case 1: return "Descansado"
        case 2: return "Leve"
        case 3: return "Moderado"
        case 4: return "Cansado"
        case 5: return "Exausto"
        default: return "Moderado"
        }
    }

    private var fatigueColor: Color {
        switch input.fatigueLevel {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .yellow
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Tempo Disponível")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.sm) {
                    ForEach([20, 30, 45, 60, 90], id: \.self) { time in
                        TimeChip(
                            minutes: time,
                            isSelected: input.availableTime == time
                        ) {
                            input.availableTime = time
                        }
                    }
                }
            }
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Equipamento")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(EquipmentAvailability.allCases, id: \.self) { equipment in
                    EquipmentChip(
                        equipment: equipment,
                        isSelected: input.equipment == equipment
                    ) {
                        input.equipment = equipment
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: onGenerate) {
            HStack {
                Image(systemName: "sparkles")
                Text("Gerar Treino")
            }
            .font(FitTodayFont.ui(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.md)
            .background(
                LinearGradient(
                    colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(input.selectedMuscles.isEmpty)
        .opacity(input.selectedMuscles.isEmpty ? 0.5 : 1)
    }
}

// MARK: - Time Chip

struct TimeChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes) min")
                .font(FitTodayFont.ui(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.background)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equipment Chip

struct EquipmentChip: View {
    let equipment: EquipmentAvailability
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: equipment.icon)
                    .font(.system(size: 12))
                Text(equipment.rawValue)
                    .font(FitTodayFont.ui(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.background)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        AIWorkoutInputCard(
            input: .constant(AIWorkoutInput()),
            onGenerate: {}
        )
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
