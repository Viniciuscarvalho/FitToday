//
//  WorkoutTabView.swift
//  FitToday
//
//  Main Workout tab with segmented control for "My Workouts", "Programs" and "Personal".
//

import SwiftUI
import Swinject

/// Main Workout tab view with three sections: My Workouts, Programs, and Personal.
struct WorkoutTabView: View {
    @Environment(\.dependencyResolver) private var envResolver
    let resolver: Resolver

    @State private var selectedSegment: WorkoutSegment = .programs
    @State private var showCreateWorkout = false
    @State private var personalWorkoutsViewModel: PersonalWorkoutsViewModel?

    enum WorkoutSegment: CaseIterable {
        case myWorkouts
        case programs
        case personal

        var title: String {
            switch self {
            case .myWorkouts: return "workout_tab.segment.my_workouts".localized
            case .programs: return "workout_tab.segment.programs".localized
            case .personal: return "personal.title".localized
            }
        }

        var icon: String {
            switch self {
            case .myWorkouts: return "figure.strengthtraining.traditional"
            case .programs: return "list.bullet.rectangle"
            case .personal: return "person.fill"
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

                    PersonalWorkoutsListView()
                        .tag(WorkoutSegment.personal)
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
                    HStack(spacing: 4) {
                        Text(segment.title)
                            .font(FitTodayFont.ui(size: 14, weight: selectedSegment == segment ? .bold : .medium))

                        // Badge para treinos novos do Personal
                        if segment == .personal, let count = personalWorkoutsViewModel?.newWorkoutsCount, count > 0 {
                            Text("\(count)")
                                .font(FitTodayFont.ui(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(FitTodayColor.error)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(selectedSegment == segment ? FitTodayColor.textPrimary : FitTodayColor.textSecondary)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .padding(.horizontal, FitTodaySpacing.sm)
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
        .task {
            await initializePersonalWorkoutsViewModel()
        }
    }

    // MARK: - Personal Workouts Badge

    private func initializePersonalWorkoutsViewModel() async {
        guard personalWorkoutsViewModel == nil else { return }

        let resolverToUse = envResolver.resolve(Resolver.self) ?? resolver

        guard let repository = resolverToUse.resolve(PersonalWorkoutRepository.self),
              let pdfCache = resolverToUse.resolve(PDFCaching.self),
              let authRepository = resolverToUse.resolve(AuthenticationRepository.self) else {
            return
        }

        let vm = PersonalWorkoutsViewModel(repository: repository, pdfCache: pdfCache)
        personalWorkoutsViewModel = vm

        if let user = try? await authRepository.currentUser() {
            vm.startObserving(userId: user.id)
        }
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
