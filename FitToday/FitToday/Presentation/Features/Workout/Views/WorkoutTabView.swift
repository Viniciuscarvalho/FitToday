//
//  WorkoutTabView.swift
//  FitToday
//
//  Main Workout tab with segmented control for "My Workouts" and "Programs".
//

import SwiftUI
import Swinject

/// Main Workout tab view with two sections: My Workouts and Programs.
struct WorkoutTabView: View {
    let resolver: Resolver

    @State private var selectedSegment: WorkoutSegment = .myWorkouts
    @State private var showCreateWorkout = false

    enum WorkoutSegment: CaseIterable {
        case myWorkouts
        case programs

        var title: String {
            switch self {
            case .myWorkouts: return "workout_tab.segment.my_workouts".localized
            case .programs: return "workout_tab.segment.programs".localized
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Segmented Control
                segmentedControl
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.top, FitTodaySpacing.sm)

                // Content
                TabView(selection: $selectedSegment) {
                    MyWorkoutsView(showCreateWorkout: $showCreateWorkout, resolver: resolver)
                        .tag(WorkoutSegment.myWorkouts)

                    ProgramsListView()
                        .tag(WorkoutSegment.programs)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }

            // Floating Action Button (only on My Workouts)
            if selectedSegment == .myWorkouts {
                createWorkoutButton
                    .padding(.trailing, FitTodaySpacing.lg)
                    .padding(.bottom, FitTodaySpacing.xl)
            }
        }
        .background(FitTodayColor.background)
        .navigationTitle("workout.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateWorkout) {
            CreateWorkoutView(resolver: resolver) {
                showCreateWorkout = false
            }
        }
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            ForEach(WorkoutSegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.title)
                        .font(FitTodayFont.ui(size: 15, weight: selectedSegment == segment ? .bold : .medium))
                        .foregroundStyle(selectedSegment == segment ? FitTodayColor.textPrimary : FitTodayColor.textSecondary)
                        .padding(.vertical, FitTodaySpacing.sm)
                        .padding(.horizontal, FitTodaySpacing.md)
                        .background(
                            Capsule()
                                .fill(selectedSegment == segment ? FitTodayColor.brandPrimary.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedSegment == segment ? FitTodayColor.brandPrimary : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.xs)
        .background(
            Capsule()
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Floating Action Button

    private var createWorkoutButton: some View {
        Button {
            showCreateWorkout = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(FitTodayColor.textInverse)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(FitTodayColor.brandPrimary)
                )
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Criar novo treino")
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    return WorkoutTabView(resolver: container)
        .preferredColorScheme(.dark)
}
