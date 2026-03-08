import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutLiveActivityWidget: Widget {
    private let workoutDeepLink = URL(string: "fittoday://workout/execution")!

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            lockScreenView(context: context)
                .widgetURL(workoutDeepLink)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.currentExerciseName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .foregroundStyle(.white)

                        Text(context.attributes.workoutTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.totalWorkoutTime)
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        Text(context.state.currentSeries)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        // Progress bar
                        ProgressView(value: Double(context.state.completionPercentage), total: 100)
                            .tint(brandPrimary)
                            .scaleEffect(y: 2)

                        // Percentage
                        Text("\(context.state.completionPercentage)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(brandPrimary)
                            .monospacedDigit()
                    }
                    .padding(.top, 4)

                    // Rest timer if active
                    if let restSeconds = context.state.restTimerSeconds, restSeconds > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text("Descanso: \(restSeconds)s")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                    }
                }

                DynamicIslandExpandedRegion(.center) {}
            } compactLeading: {
                // Compact leading — exercise icon with state color
                ZStack {
                    Circle()
                        .fill(stateColor(context.state.workoutState).opacity(0.3))
                        .frame(width: 24, height: 24)

                    Image(systemName: stateIcon(context.state.workoutState))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(stateColor(context.state.workoutState))
                }
            } compactTrailing: {
                // Compact trailing — timer
                Text(context.state.totalWorkoutTime)
                    .font(.caption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(brandPrimary)
            } minimal: {
                // Minimal — just the state icon
                Image(systemName: stateIcon(context.state.workoutState))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stateColor(context.state.workoutState))
            }
            .widgetURL(workoutDeepLink)
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Top row: workout title + timer
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(brandPrimary)
                    Text(context.attributes.workoutTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                Spacer()

                Text(context.state.totalWorkoutTime)
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            // Current exercise
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.currentExerciseName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(context.state.currentSeries, systemImage: "repeat")
                            .font(.caption)

                        Label(stateLabel(context.state.workoutState), systemImage: stateIcon(context.state.workoutState))
                            .font(.caption)
                            .foregroundStyle(stateColor(context.state.workoutState))
                    }
                }

                Spacer()

                // Rest timer badge
                if let restSeconds = context.state.restTimerSeconds, restSeconds > 0 {
                    VStack(spacing: 2) {
                        Text("\(restSeconds)s")
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                        Text("rest")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }

            // Progress bar
            ProgressView(value: Double(context.state.completionPercentage), total: 100)
                .tint(brandPrimary)
                .scaleEffect(y: 1.5)
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.8))
    }

    // MARK: - Helpers

    private var brandPrimary: Color {
        Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6
    }

    private func stateColor(_ state: WorkoutActivityAttributes.ContentState.WorkoutState) -> Color {
        switch state {
        case .active: brandPrimary
        case .resting: .orange
        case .paused: .secondary
        }
    }

    private func stateIcon(_ state: WorkoutActivityAttributes.ContentState.WorkoutState) -> String {
        switch state {
        case .active: "figure.strengthtraining.traditional"
        case .resting: "timer"
        case .paused: "pause.fill"
        }
    }

    private func stateLabel(_ state: WorkoutActivityAttributes.ContentState.WorkoutState) -> String {
        switch state {
        case .active: "Ativo"
        case .resting: "Descansando"
        case .paused: "Pausado"
        }
    }
}
