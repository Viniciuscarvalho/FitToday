//
//  FatigueSlider.swift
//  FitToday
//
//  Reusable slider component for selecting fatigue level.
//

import SwiftUI

/// Fatigue level options.
enum FatigueLevel: Int, CaseIterable, Sendable {
    case rested = 1
    case light = 2
    case moderate = 3
    case tired = 4
    case exhausted = 5

    var label: String {
        switch self {
        case .rested: return "Descansado"
        case .light: return "Leve"
        case .moderate: return "Moderado"
        case .tired: return "Cansado"
        case .exhausted: return "Exausto"
        }
    }

    var emoji: String {
        switch self {
        case .rested: return "💪"
        case .light: return "🙂"
        case .moderate: return "😐"
        case .tired: return "😓"
        case .exhausted: return "😫"
        }
    }

    var color: Color {
        switch self {
        case .rested: return .green
        case .light: return .mint
        case .moderate: return .yellow
        case .tired: return .orange
        case .exhausted: return .red
        }
    }

    var description: String {
        switch self {
        case .rested: return "Pronto para treino intenso"
        case .light: return "Pequena fadiga, treino normal"
        case .moderate: return "Fadiga moderada, ajuste o volume"
        case .tired: return "Cansado, reduza a intensidade"
        case .exhausted: return "Muito cansado, considere descanso"
        }
    }

    static func from(_ value: Int) -> FatigueLevel {
        FatigueLevel(rawValue: max(1, min(5, value))) ?? .moderate
    }
}

// MARK: - Fatigue Slider

/// A visual slider for selecting fatigue level with emoji feedback.
struct FatigueSlider: View {
    @Binding var level: Int
    var showDescription: Bool = true
    var style: FatigueSliderStyle = .dots

    enum FatigueSliderStyle {
        case dots
        case continuous
        case segments
    }

    private var currentLevel: FatigueLevel {
        FatigueLevel.from(level)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Header
            headerSection

            // Slider
            switch style {
            case .dots:
                dotsSlider
            case .continuous:
                continuousSlider
            case .segments:
                segmentsSlider
            }

            // Description
            if showDescription {
                descriptionSection
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("Nível de Fadiga")
                .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)

            Spacer()

            HStack(spacing: FitTodaySpacing.xs) {
                Text(currentLevel.emoji)
                    .font(.system(size: 18))

                Text(currentLevel.label)
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(currentLevel.color)
            }
        }
    }

    // MARK: - Dots Slider

    private var dotsSlider: some View {
        HStack(spacing: FitTodaySpacing.md) {
            ForEach(FatigueLevel.allCases, id: \.rawValue) { fatigueLevel in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        level = fatigueLevel.rawValue
                    }
                } label: {
                    VStack(spacing: FitTodaySpacing.xs) {
                        Circle()
                            .fill(fatigueLevel.rawValue <= level ? fatigueLevel.color : FitTodayColor.outline)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(fatigueLevel.rawValue == level ? fatigueLevel.color : Color.clear, lineWidth: 3)
                                    .padding(-4)
                            )
                            .shadow(color: fatigueLevel.rawValue == level ? fatigueLevel.color.opacity(0.5) : .clear, radius: 4)

                        Text("\(fatigueLevel.rawValue)")
                            .font(FitTodayFont.ui(size: 11, weight: fatigueLevel.rawValue == level ? .bold : .medium))
                            .foregroundStyle(fatigueLevel.rawValue == level ? fatigueLevel.color : FitTodayColor.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Continuous Slider

    private var continuousSlider: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Emoji scale
            HStack {
                Text("😫")
                Spacer()
                Text("💪")
            }
            .font(.system(size: 20))

            // Slider
            Slider(value: Binding(
                get: { Double(level) },
                set: { level = Int($0) }
            ), in: 1...5, step: 1)
            .tint(currentLevel.color)

            // Labels
            HStack {
                Text("Exausto")
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
                Spacer()
                Text("Descansado")
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
        }
    }

    // MARK: - Segments Slider

    private var segmentsSlider: some View {
        GeometryReader { geometry in
            let segmentWidth = (geometry.size.width - CGFloat(4 * 4)) / 5

            HStack(spacing: 4) {
                ForEach(FatigueLevel.allCases, id: \.rawValue) { fatigueLevel in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level = fatigueLevel.rawValue
                        }
                    } label: {
                        VStack(spacing: FitTodaySpacing.xs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(fatigueLevel.rawValue <= level ? fatigueLevel.color : FitTodayColor.outline)
                                .frame(width: segmentWidth, height: fatigueLevel.rawValue == level ? 32 : 24)

                            Text(fatigueLevel.emoji)
                                .font(.system(size: fatigueLevel.rawValue == level ? 16 : 12))
                                .opacity(fatigueLevel.rawValue == level ? 1 : 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 56)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(currentLevel.color)

            Text(currentLevel.description)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(FitTodaySpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(currentLevel.color.opacity(0.1))
        )
    }
}

// MARK: - Compact Fatigue Slider

/// A more compact version of the fatigue slider for inline use.
struct CompactFatigueSlider: View {
    @Binding var level: Int

    private var currentLevel: FatigueLevel {
        FatigueLevel.from(level)
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Text(currentLevel.emoji)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(currentLevel.label)
                    .font(FitTodayFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(currentLevel.color)

                // Mini progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(FitTodayColor.outline)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentLevel.color)
                            .frame(width: geometry.size.width * CGFloat(level) / 5, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Step buttons
            HStack(spacing: FitTodaySpacing.xs) {
                Button {
                    if level > 1 {
                        withAnimation { level -= 1 }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(level > 1 ? FitTodayColor.textSecondary : FitTodayColor.outline)
                }
                .disabled(level <= 1)

                Button {
                    if level < 5 {
                        withAnimation { level += 1 }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(level < 5 ? FitTodayColor.textSecondary : FitTodayColor.outline)
                }
                .disabled(level >= 5)
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }
}

// MARK: - Previews

#Preview("Dots Style") {
    VStack(spacing: 32) {
        FatigueSlider(level: .constant(1), style: .dots)
        FatigueSlider(level: .constant(3), style: .dots)
        FatigueSlider(level: .constant(5), style: .dots)
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}

#Preview("Continuous Style") {
    FatigueSlider(level: .constant(3), style: .continuous)
        .padding()
        .background(FitTodayColor.background)
        .preferredColorScheme(.dark)
}

#Preview("Segments Style") {
    FatigueSlider(level: .constant(4), style: .segments)
        .padding()
        .background(FitTodayColor.background)
        .preferredColorScheme(.dark)
}

#Preview("Compact") {
    CompactFatigueSlider(level: .constant(3))
        .padding()
        .background(FitTodayColor.background)
        .preferredColorScheme(.dark)
}
