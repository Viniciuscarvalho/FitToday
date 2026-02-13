//
//  AIWorkoutGeneratorCard.swift
//  FitToday
//
//  Card for AI-powered workout generation with live inputs for DailyCheckIn.
//  Updated to use DailyFocus, MuscleSorenessLevel, and energyLevel directly.
//

import SwiftUI

/// Card for AI workout generation with inputs that map directly to DailyCheckIn.
/// These inputs are used for OpenAI workout generation.
struct AIWorkoutGeneratorCard: View {
    // MARK: - Bindings for DailyCheckIn fields

    /// Focus area selection (maps directly to DailyFocus)
    @Binding var selectedFocus: DailyFocus

    /// Soreness level (maps directly to MuscleSorenessLevel)
    @Binding var sorenessLevel: MuscleSorenessLevel

    /// Energy level 0-10 (maps directly to DailyCheckIn.energyLevel)
    @Binding var energyLevel: Int

    /// Loading state
    let isGenerating: Bool

    /// Generate button action
    let onGenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
            // Section Label
            Text("home.ai.section_title".localized)
                .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .tracking(1)

            // Focus Selection (replaces body parts)
            focusSection

            // Soreness Level Selection (replaces fatigue slider)
            sorenessSection

            // Energy Level Slider
            energySection

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

    // MARK: - Focus Section

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.ai.focus_question".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            // First row: upper, lower, fullBody
            HStack(spacing: FitTodaySpacing.sm) {
                ForEach([DailyFocus.upper, .lower, .fullBody], id: \.self) { focus in
                    FocusChip(
                        focus: focus,
                        isSelected: selectedFocus == focus
                    ) {
                        selectedFocus = focus
                    }
                }
            }

            // Second row: cardio, core, surprise
            HStack(spacing: FitTodaySpacing.sm) {
                ForEach([DailyFocus.cardio, .core, .surprise], id: \.self) { focus in
                    FocusChip(
                        focus: focus,
                        isSelected: selectedFocus == focus
                    ) {
                        selectedFocus = focus
                    }
                }
            }
        }
    }

    // MARK: - Soreness Section

    private var sorenessSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.ai.soreness_question".localized)
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)

            HStack(spacing: FitTodaySpacing.sm) {
                ForEach(MuscleSorenessLevel.allCases, id: \.self) { level in
                    SorenessChip(
                        level: level,
                        isSelected: sorenessLevel == level
                    ) {
                        sorenessLevel = level
                    }
                }
            }
        }
    }

    // MARK: - Energy Section

    private var energySection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("home.ai.energy_question".localized)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Text("\(energyLevel)/10")
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(energyColor)
            }

            VStack(spacing: FitTodaySpacing.xs) {
                Slider(value: Binding(
                    get: { Double(energyLevel) },
                    set: { energyLevel = Int($0) }
                ), in: 0...10, step: 1)
                    .tint(energyColor)

                HStack {
                    Text("home.ai.energy_low".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    Spacer()

                    Text("home.ai.energy_high".localized)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
    }

    private var energyColor: Color {
        switch energyLevel {
        case 0...3: return FitTodayColor.error
        case 4...6: return FitTodayColor.warning
        default: return FitTodayColor.success
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
                    Image(systemName: "sparkles")
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
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.6 : 1)
    }
}

// MARK: - Focus Chip

private struct FocusChip: View {
    let focus: DailyFocus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.xs) {
                Text(focus.icon)
                Text(focus.displayName)
                    .font(FitTodayFont.ui(size: 13, weight: isSelected ? .bold : .medium))
            }
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

// MARK: - Soreness Chip

private struct SorenessChip: View {
    let level: MuscleSorenessLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(level.displayName)
                .font(FitTodayFont.ui(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : FitTodayColor.textSecondary)
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? level.color : FitTodayColor.background)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? level.color : FitTodayColor.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Display Extensions

extension DailyFocus {
    var displayName: String {
        switch self {
        case .fullBody: return "focus.fullbody".localized
        case .upper: return "focus.upper".localized
        case .lower: return "focus.lower".localized
        case .cardio: return "focus.cardio".localized
        case .core: return "focus.core".localized
        case .surprise: return "focus.surprise".localized
        }
    }

    var icon: String {
        switch self {
        case .fullBody: return "🏋️"
        case .upper: return "💪"
        case .lower: return "🦵"
        case .cardio: return "❤️"
        case .core: return "🎯"
        case .surprise: return "🎲"
        }
    }
}

extension MuscleSorenessLevel {
    var displayName: String {
        switch self {
        case .none: return "soreness.none".localized
        case .light: return "soreness.light".localized
        case .moderate: return "soreness.moderate".localized
        case .strong: return "soreness.strong".localized
        }
    }

    var color: Color {
        switch self {
        case .none: return FitTodayColor.success
        case .light: return FitTodayColor.info
        case .moderate: return FitTodayColor.warning
        case .strong: return FitTodayColor.error
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AIWorkoutGeneratorCard(
            selectedFocus: .constant(.upper),
            sorenessLevel: .constant(.none),
            energyLevel: .constant(7),
            isGenerating: false,
            onGenerate: {}
        )
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
