//
//  AIWorkoutGeneratorCard.swift
//  FitToday
//
//  Card for AI-powered workout generation with simplified design.
//

import SwiftUI

/// Simplified body part options for workout generation.
enum BodyPart: String, CaseIterable, Sendable {
    case chest = "Peito"
    case back = "Costas"
    case legs = "Pernas"
    case shoulders = "Ombros"

    var muscleGroups: [MuscleGroup] {
        switch self {
        case .chest: return [.chest, .triceps]
        case .back: return [.back, .biceps, .lats]
        case .legs: return [.quads, .hamstrings, .glutes, .calves]
        case .shoulders: return [.shoulders]
        }
    }
}

/// Card for AI workout generation matching the design reference.
struct AIWorkoutGeneratorCard: View {
    @Binding var selectedBodyParts: Set<BodyPart>
    @Binding var fatigueValue: Double
    @Binding var selectedTime: Int
    let isGenerating: Bool
    let onGenerate: () -> Void

    private let timeOptions = [30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
            // Section Label
            Text("home.ai.section_title".localized)
                .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .tracking(1)

            // Body Parts Selection
            bodyPartsSection

            // Fatigue Slider
            fatigueSection

            // Time Selection
            timeSection

            // Generate Button
            generateButton
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Body Parts Section

    private var bodyPartsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.ai.body_parts_question".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(BodyPart.allCases, id: \.self) { part in
                    BodyPartChip(
                        title: part.rawValue,
                        isSelected: selectedBodyParts.contains(part)
                    ) {
                        toggleBodyPart(part)
                    }
                }
            }
        }
    }

    private func toggleBodyPart(_ part: BodyPart) {
        if selectedBodyParts.contains(part) {
            selectedBodyParts.remove(part)
        } else {
            selectedBodyParts.insert(part)
        }
    }

    // MARK: - Fatigue Section

    private var fatigueSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.ai.fatigue_question".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            VStack(spacing: FitTodaySpacing.xs) {
                Slider(value: $fatigueValue, in: 0...1)
                    .tint(FitTodayColor.brandPrimary)

                HStack {
                    Text("home.ai.fatigue_tired".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Spacer()

                    Text("home.ai.fatigue_rested".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.ai.time_question".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(timeOptions, id: \.self) { time in
                    TimeOptionChip(
                        minutes: time,
                        isSelected: selectedTime == time
                    ) {
                        selectedTime = time
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: onGenerate) {
            HStack(spacing: FitTodaySpacing.sm) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("home.ai.generate_button".localized)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(FitTodayColor.brandPrimary.opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedBodyParts.isEmpty || isGenerating)
        .opacity(selectedBodyParts.isEmpty ? 0.6 : 1)
    }
}

// MARK: - Body Part Chip

private struct BodyPartChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FitTodayFont.ui(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.background)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Option Chip

private struct TimeOptionChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes)min")
                .font(FitTodayFont.ui(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.background)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AIWorkoutGeneratorCard(
            selectedBodyParts: .constant([.legs]),
            fatigueValue: .constant(0.5),
            selectedTime: .constant(45),
            isGenerating: false,
            onGenerate: {}
        )
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
