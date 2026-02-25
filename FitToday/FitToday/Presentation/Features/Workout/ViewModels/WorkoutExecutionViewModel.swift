//
//  WorkoutExecutionViewModel.swift
//  FitToday
//
//  Composes existing stores for workout execution with Live Activity support.
//  Key principle: Derive all state from existing stores (single source of truth).
//

import Foundation
import Swinject
import UIKit
import AVFoundation

/// ViewModel for workout execution that composes existing stores.
/// Does NOT duplicate state - all properties are derived from WorkoutSessionStore, RestTimerStore, WorkoutTimerStore.
@MainActor
@Observable final class WorkoutExecutionViewModel {
    // MARK: - Composed Stores (Single Source of Truth)

    let sessionStore: WorkoutSessionStore
    let restTimer: RestTimerStore
    let workoutTimer: WorkoutTimerStore

    // MARK: - Live Activity Manager

    private var liveActivityManager: WorkoutLiveActivityManager?

    // MARK: - Feedback Generators

    private let hapticGenerator = UINotificationFeedbackGenerator()
    private var lastRestTimerSeconds: Int?
    private var liveActivityUpdateTimer: Timer?

    // MARK: - Local State

    private(set) var showExerciseSubstitution: Bool = false
    private(set) var showCompletionScreen: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.sessionStore = resolver.resolve(WorkoutSessionStore.self)!
        self.restTimer = RestTimerStore()
        self.workoutTimer = WorkoutTimerStore()

        self.liveActivityManager = WorkoutLiveActivityManager()
        hapticGenerator.prepare()
    }

    // For testing
    init(
        sessionStore: WorkoutSessionStore,
        restTimer: RestTimerStore,
        workoutTimer: WorkoutTimerStore
    ) {
        self.sessionStore = sessionStore
        self.restTimer = restTimer
        self.workoutTimer = workoutTimer
        self.liveActivityManager = WorkoutLiveActivityManager()
        hapticGenerator.prepare()
    }

    // MARK: - Derived State (Computed from Stores)

    /// Current exercise index - derived from sessionStore
    var currentExerciseIndex: Int {
        sessionStore.currentExerciseIndex
    }

    /// Current exercise prescription - derived from sessionStore
    var currentPrescription: ExercisePrescription? {
        sessionStore.currentPrescription
    }

    /// Current exercise name (accounting for substitutions) - derived from sessionStore
    var currentExerciseName: String {
        sessionStore.effectiveCurrentExerciseName
    }

    /// Current exercise progress - derived from sessionStore
    var currentExerciseProgress: ExerciseProgress? {
        sessionStore.currentExerciseProgress
    }

    /// Current set number (1-indexed for display) - derived from sessionStore
    var currentSetNumber: Int {
        (currentExerciseProgress?.completedSetsCount ?? 0) + 1
    }

    /// Total sets for current exercise - derived from sessionStore
    var totalSets: Int {
        currentExerciseProgress?.totalSets ?? 0
    }

    /// Is current exercise complete - derived from sessionStore
    var isCurrentExerciseComplete: Bool {
        sessionStore.isCurrentExerciseComplete
    }

    /// Overall workout progress (0.0 - 1.0) - derived from sessionStore
    var overallProgress: Double {
        sessionStore.overallProgress
    }

    /// Completed exercises count - derived from sessionStore
    var completedExercisesCount: Int {
        sessionStore.completedExercisesCount
    }

    /// Total exercises count - derived from sessionStore
    var totalExercisesCount: Int {
        sessionStore.exerciseCount
    }

    /// Workout elapsed time - derived from workoutTimer
    var workoutElapsedTime: TimeInterval {
        TimeInterval(workoutTimer.elapsedSeconds)
    }

    /// Formatted workout time - derived from workoutTimer
    var formattedWorkoutTime: String {
        workoutTimer.formattedTime
    }

    /// Is workout paused - derived from workoutTimer
    var isPaused: Bool {
        !workoutTimer.isRunning
    }

    /// Is resting - derived from restTimer
    var isResting: Bool {
        restTimer.isActive
    }

    /// Rest time remaining - derived from restTimer
    var restTimeRemaining: TimeInterval {
        TimeInterval(restTimer.remainingSeconds)
    }

    /// Formatted rest time - derived from restTimer
    var formattedRestTime: String {
        restTimer.formattedTime
    }

    /// Rest progress percentage (0.0 - 1.0) - derived from restTimer
    var restProgressPercentage: Double {
        restTimer.progressPercentage
    }

    /// Is rest timer finished - derived from restTimer
    var isRestFinished: Bool {
        restTimer.isFinished
    }

    // MARK: - Workout Lifecycle

    /// Starts a workout with the given plan
    func startWorkout(with plan: WorkoutPlan) {
        sessionStore.start(with: plan)
        workoutTimer.start()

        // Start Live Activity
        Task {
            do {
                let firstExerciseName = currentExerciseName
                let totalExercises = sessionStore.exerciseCount
                try await liveActivityManager?.startActivity(
                    workoutTitle: plan.title,
                    totalExercises: totalExercises,
                    initialExerciseName: firstExerciseName
                )
            } catch {
                // Live Activity start failure is non-critical, just log
                print("Failed to start Live Activity: \(error.localizedDescription)")
            }
        }

        // Schedule periodic Live Activity updates (every second)
        startLiveActivityUpdateTimer()
    }

    /// Pauses the workout
    func pauseWorkout() {
        workoutTimer.pause()
        if restTimer.isActive {
            restTimer.pause()
        }
    }

    /// Resumes the workout
    func resumeWorkout() {
        workoutTimer.start()
        if restTimer.remainingSeconds > 0 {
            restTimer.resume()
        }
    }

    /// Toggles workout pause/resume
    func togglePause() {
        workoutTimer.toggle()
        if restTimer.isActive || restTimer.remainingSeconds > 0 {
            restTimer.toggle()
        }
    }

    // MARK: - Exercise Navigation

    /// Advances to next exercise, returns true if workout is complete
    @discardableResult
    func nextExercise() -> Bool {
        let isComplete = sessionStore.advanceToNextExercise()
        if isComplete {
            showCompletionScreen = true
        }
        return isComplete
    }

    /// Skips current exercise, returns true if workout is complete
    @discardableResult
    func skipExercise() -> Bool {
        let isComplete = sessionStore.skipCurrentExercise()
        if isComplete {
            showCompletionScreen = true
        }
        return isComplete
    }

    /// Navigates to specific exercise
    func selectExercise(at index: Int) {
        sessionStore.selectExercise(at: index)
    }

    // MARK: - Set Completion

    /// Toggles completion state of a set for the current exercise
    func toggleSet(at setIndex: Int) {
        sessionStore.toggleCurrentExerciseSet(at: setIndex)

        // Start rest timer after completing a set (if not the last set)
        if let progress = currentExerciseProgress,
           progress.sets[setIndex].isCompleted,
           setIndex < progress.sets.count - 1 {
            startRestTimer()
        }
    }

    /// Completes all sets for current exercise
    func completeAllSets() {
        sessionStore.completeAllCurrentSets()
    }

    // MARK: - Rest Timer

    /// Starts rest timer with default duration (from exercise prescription)
    func startRestTimer() {
        let duration = currentPrescription?.restInterval ?? 60
        restTimer.start(duration: duration)
    }

    /// Starts rest timer with custom duration
    func startRestTimer(duration: TimeInterval) {
        restTimer.start(duration: duration)
    }

    /// Skips rest timer
    func skipRest() {
        restTimer.skip()
    }

    /// Adds time to rest timer
    func addRestTime(_ seconds: Int) {
        restTimer.addTime(seconds)
    }

    // MARK: - Exercise Substitution

    /// Shows exercise substitution UI
    func showSubstitution() {
        showExerciseSubstitution = true
    }

    /// Hides exercise substitution UI
    func hideSubstitution() {
        showExerciseSubstitution = false
    }

    /// Substitutes current exercise with alternative
    func substituteExercise(with alternative: AlternativeExercise) {
        sessionStore.substituteCurrentExercise(with: alternative)
        showExerciseSubstitution = false
    }

    /// Removes substitution for current exercise
    func removeSubstitution() {
        sessionStore.removeCurrentSubstitution()
    }

    /// Checks if current exercise has substitution
    var hasSubstitution: Bool {
        sessionStore.currentExerciseHasSubstitution
    }

    // MARK: - Live Activity Management

    /// Starts periodic timer to update Live Activity
    private func startLiveActivityUpdateTimer() {
        // Cancel any existing timer
        liveActivityUpdateTimer?.invalidate()

        // Create new timer that fires every second
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.updateLiveActivity()
            }
        }
    }

    /// Stops the Live Activity update timer
    private func stopLiveActivityUpdateTimer() {
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil
    }

    /// Updates Live Activity with current workout state
    private func updateLiveActivity() async {
        guard let manager = liveActivityManager else {
            return
        }

        // Determine workout state
        let workoutState: WorkoutActivityAttributes.ContentState.WorkoutState
        if isPaused {
            workoutState = .paused
        } else if isResting {
            workoutState = .resting
        } else {
            workoutState = .active
        }

        // Format series information
        let seriesInfo = "\(currentSetNumber)/\(totalSets)"

        // Get rest timer seconds if active
        let restSeconds = isResting ? Int(restTimeRemaining) : nil

        // Check if rest timer just completed (FR-007 - Haptic + Sound)
        if let lastSeconds = lastRestTimerSeconds,
           lastSeconds > 0,
           restSeconds == 0 {
            // Play haptic feedback
            hapticGenerator.notificationOccurred(.success)

            // Play system sound (notification sound)
            AudioServicesPlaySystemSound(1026)
        }
        lastRestTimerSeconds = restSeconds

        // Calculate completion percentage
        let completionPercentage = Int(overallProgress * 100)

        // Update Live Activity
        await manager.updateActivity(
            exerciseName: currentExerciseName,
            series: seriesInfo,
            restSeconds: restSeconds,
            totalTime: formattedWorkoutTime,
            canGoNext: isCurrentExerciseComplete && !isResting,
            completionPercentage: completionPercentage,
            workoutState: workoutState
        )
    }

    // MARK: - Workout Completion

    /// Finishes workout with given status
    func finishWorkout(status: WorkoutStatus) async {
        do {
            workoutTimer.pause()
            restTimer.stop()
            stopLiveActivityUpdateTimer()

            await liveActivityManager?.endActivity()

            try await sessionStore.finish(status: status)
            showCompletionScreen = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Dismisses completion screen and resets workout
    func dismissCompletion() {
        showCompletionScreen = false
        sessionStore.reset()
        workoutTimer.reset()
        restTimer.stop()
        stopLiveActivityUpdateTimer()

        // Ensure Live Activity is ended
        Task {
            await liveActivityManager?.endActivity()
        }
    }

    // MARK: - Error Handling

    /// Clears error message
    func clearError() {
        errorMessage = nil
    }
}
