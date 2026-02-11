//
//  NewOpenAIWorkoutComposer.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 3.0)
//

import Foundation

/// Simplified OpenAI workout composer with variation validation and fallback.
///
/// Key features:
/// - Uses WorkoutVariationValidator for post-generation validation
/// - Retries up to 2 times if validation fails (60% diversity requirement)
/// - Falls back to EnhancedLocalWorkoutPlanComposer on total failure
/// - Respects user inputs (equipment, muscles, level, feeling)
/// - Seed = timestamp + random for uniqueness
///
/// - Note: Part of FR-002 (OpenAI Generation Enhancement) from PRD
struct NewOpenAIWorkoutComposer: WorkoutPlanComposing, Sendable {

    // MARK: - Dependencies

    private let client: NewOpenAIClient
    private let promptBuilder: NewWorkoutPromptBuilder
    private let blueprintEngine: WorkoutBlueprintEngine
    private let localFallback: EnhancedLocalWorkoutPlanComposer
    private let historyRepository: WorkoutHistoryRepository

    // MARK: - Configuration

    private let maxValidationRetries = 2
    private let minimumDiversityPercent = 0.6

    // MARK: - Initialization

    init(
        client: NewOpenAIClient,
        promptBuilder: NewWorkoutPromptBuilder = NewWorkoutPromptBuilder(),
        blueprintEngine: WorkoutBlueprintEngine = WorkoutBlueprintEngine(),
        localFallback: EnhancedLocalWorkoutPlanComposer,
        historyRepository: WorkoutHistoryRepository
    ) {
        self.client = client
        self.promptBuilder = promptBuilder
        self.blueprintEngine = blueprintEngine
        self.localFallback = localFallback
        self.historyRepository = historyRepository
    }

    // MARK: - WorkoutPlanComposing

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        // 1. Generate blueprint
        let blueprint = blueprintEngine.generateBlueprint(profile: profile, checkIn: checkIn)

        #if DEBUG
        print("[NewOpenAIComposer] Generated blueprint: \(blueprint.title) (seed=\(blueprint.variationSeed))")
        #endif

        // 2. Fetch recent workouts for variation validation
        let previousWorkouts = try await fetchRecentWorkouts(limit: 3)

        #if DEBUG
        if !previousWorkouts.isEmpty {
            print("[NewOpenAIComposer] Fetched \(previousWorkouts.count) previous workouts for variation validation")
        }
        #endif

        // 3. Build prompt
        let prompt = promptBuilder.buildPrompt(
            blueprint: blueprint,
            blocks: blocks,
            profile: profile,
            checkIn: checkIn,
            previousWorkouts: previousWorkouts
        )

        #if DEBUG
        print("[NewOpenAIComposer] Prompt built: \(prompt.count) characters")
        #endif

        // 4. Attempt generation with validation retries
        var attempt = 0

        while attempt < maxValidationRetries {
            do {
                // 4a. Call OpenAI
                let responseData = try await client.generateWorkout(prompt: prompt)

                #if DEBUG
                print("[NewOpenAIComposer] Received response: \(responseData.count) bytes (attempt \(attempt + 1))")
                #endif

                // 4b. Decode and validate response
                let workoutPlan = try decodeAndConvert(
                    responseData: responseData,
                    blueprint: blueprint,
                    blocks: blocks
                )

                // 4c. Validate diversity
                let isValid = WorkoutVariationValidator.validateDiversity(
                    generated: workoutPlan,
                    previousWorkouts: previousWorkouts,
                    minimumDiversityPercent: minimumDiversityPercent
                )

                if isValid {
                    #if DEBUG
                    let diversity = WorkoutVariationValidator.calculateDiversityRatio(
                        generated: workoutPlan,
                        previousWorkouts: previousWorkouts
                    )
                    print("[NewOpenAIComposer] ✅ Workout passed validation (diversity: \(String(format: "%.0f", diversity * 100))%, attempt: \(attempt + 1))")
                    #endif

                    return workoutPlan
                }

                // Validation failed
                attempt += 1

                #if DEBUG
                let diversity = WorkoutVariationValidator.calculateDiversityRatio(
                    generated: workoutPlan,
                    previousWorkouts: previousWorkouts
                )
                print("[NewOpenAIComposer] ⚠️ Workout failed validation (diversity: \(String(format: "%.0f", diversity * 100))%, attempt: \(attempt)/\(maxValidationRetries))")
                #endif

            } catch {
                // OpenAI request failed
                #if DEBUG
                print("[NewOpenAIComposer] ❌ OpenAI request failed: \(error.localizedDescription)")
                #endif

                // Fall back to local immediately on API errors
                return try await localFallback.composePlan(
                    blocks: blocks,
                    profile: profile,
                    checkIn: checkIn
                )
            }
        }

        // 5. All validation retries exhausted - fall back to local
        #if DEBUG
        print("[NewOpenAIComposer] ⚠️ Validation retries exhausted, falling back to local composer")
        #endif

        return try await localFallback.composePlan(
            blocks: blocks,
            profile: profile,
            checkIn: checkIn
        )
    }

    // MARK: - Private Helpers

    /// Fetches recent workouts from history repository
    private func fetchRecentWorkouts(limit: Int = 3) async throws -> [WorkoutPlan] {
        do {
            let entries = try await historyRepository.listEntries(limit: limit, offset: 0)

            #if DEBUG
            print("[NewOpenAIComposer] 📋 History entries fetched: \(entries.count)")
            for (index, entry) in entries.enumerated() {
                let hasWorkoutPlan = entry.workoutPlan != nil
                let exerciseCount = entry.workoutPlan?.phases.flatMap(\.items).count ?? 0
                print("[NewOpenAIComposer]   [\(index)] \(entry.title) - hasWorkoutPlan: \(hasWorkoutPlan), exercises: \(exerciseCount)")
            }
            #endif

            let workoutPlans = entries.compactMap { $0.workoutPlan }

            #if DEBUG
            print("[NewOpenAIComposer] 📋 WorkoutPlans with exercises: \(workoutPlans.count)")
            #endif

            return workoutPlans
        } catch {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Failed to fetch history: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Decodes OpenAI response and converts to WorkoutPlan
    private func decodeAndConvert(
        responseData: Data,
        blueprint: WorkoutBlueprint,
        blocks: [WorkoutBlock]
    ) throws -> WorkoutPlan {
        let decoder = JSONDecoder()

        // 1. Decode ChatCompletionResponse with debug logging
        let chatResponse: ChatCompletionResponse
        do {
            chatResponse = try decoder.decode(ChatCompletionResponse.self, from: responseData)
        } catch {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Failed to decode ChatCompletionResponse: \(error)")
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("[NewOpenAIComposer] Raw response (first 500 chars): \(String(jsonString.prefix(500)))")
            }
            #endif
            throw NewOpenAIClient.ClientError.decodingError("ChatCompletionResponse: \(error.localizedDescription)")
        }

        guard let content = chatResponse.choices.first?.message.content else {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Empty choices or content in response")
            #endif
            throw NewOpenAIClient.ClientError.invalidResponse
        }

        // 2. Extract JSON from content (may be wrapped in markdown)
        guard let workoutJSON = extractJSON(from: content) else {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Failed to extract JSON from content (first 200 chars): \(String(content.prefix(200)))")
            #endif
            throw NewOpenAIClient.ClientError.decodingError("Failed to extract JSON from response")
        }

        // 3. Decode OpenAIWorkoutResponse with debug logging
        let workoutResponse: OpenAIWorkoutResponse
        do {
            workoutResponse = try decoder.decode(OpenAIWorkoutResponse.self, from: workoutJSON)
        } catch {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Failed to decode OpenAIWorkoutResponse: \(error)")
            if let jsonString = String(data: workoutJSON, encoding: .utf8) {
                print("[NewOpenAIComposer] Workout JSON (first 1000 chars): \(String(jsonString.prefix(1000)))")
            }
            #endif
            throw NewOpenAIClient.ClientError.decodingError("OpenAIWorkoutResponse: \(error.localizedDescription)")
        }

        // 4. Validate response has content
        guard !workoutResponse.phases.isEmpty else {
            #if DEBUG
            print("[NewOpenAIComposer] ❌ Decoded response has empty phases array")
            #endif
            throw NewOpenAIClient.ClientError.emptyWorkoutResponse
        }

        #if DEBUG
        print("[NewOpenAIComposer] ✅ Decoded \(workoutResponse.phases.count) phases successfully")
        #endif

        // 5. Convert to WorkoutPlan
        let workoutPlan = convertToWorkoutPlan(
            response: workoutResponse,
            blueprint: blueprint,
            blocks: blocks
        )

        return workoutPlan
    }

    /// Extracts JSON from response content (handles markdown wrapping)
    private func extractJSON(from text: String) -> Data? {
        // Try to find JSON between ```json and ```
        if let jsonMatch = text.range(of: "```json\\s*\\n([\\s\\S]*?)\\n```", options: .regularExpression) {
            let jsonString = text[jsonMatch]
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return jsonString.data(using: .utf8)
        }

        // Try to find JSON between { and }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            let jsonString = String(text[start...end])
            return jsonString.data(using: .utf8)
        }

        // Try direct
        return text.data(using: .utf8)
    }

    /// Converts OpenAI response to WorkoutPlan domain model
    private func convertToWorkoutPlan(
        response: OpenAIWorkoutResponse,
        blueprint: WorkoutBlueprint,
        blocks: [WorkoutBlock]
    ) -> WorkoutPlan {
        var phases: [WorkoutPlanPhase] = []

        // Map exercises by name for lookup
        let allExercises = blocks.flatMap { $0.exercises }
        let exercisesByName = Dictionary(
            allExercises.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for openAIPhase in response.phases {
            // Determine phase kind
            guard let phaseKind = WorkoutPlanPhase.Kind(rawValue: openAIPhase.kind) else {
                #if DEBUG
                print("[NewOpenAIComposer] ⚠️ Unknown phase kind: \(openAIPhase.kind)")
                #endif
                continue
            }

            var items: [WorkoutPlanItem] = []

            // Add guided activity if present
            if let activity = openAIPhase.activity {
                if let activityKind = ActivityPrescription.Kind(rawValue: activity.kind) {
                    items.append(.activity(ActivityPrescription(
                        kind: activityKind,
                        title: activity.title,
                        durationMinutes: activity.durationMinutes,
                        notes: activity.notes
                    )))
                }
            }

            // Add exercises
            if let exercises = openAIPhase.exercises {
                for ex in exercises {
                    // Try to find exercise in catalog
                    var exercise = exercisesByName[ex.name.lowercased()]

                    // If not found, try partial match
                    if exercise == nil {
                        let searchName = ex.name.lowercased()
                        exercise = allExercises.first { catalogExercise in
                            catalogExercise.name.lowercased().contains(searchName) ||
                            searchName.contains(catalogExercise.name.lowercased())
                        }
                    }

                    // If still not found, try substitute from same muscle group
                    if exercise == nil {
                        if let muscleGroup = MuscleGroup(rawValue: ex.muscleGroup.lowercased()) {
                            let usedExerciseNames = Set(items.compactMap { item -> String? in
                                if case .exercise(let prescription) = item {
                                    return prescription.exercise.name.lowercased()
                                }
                                return nil
                            })

                            exercise = allExercises.first { catalogExercise in
                                catalogExercise.mainMuscle == muscleGroup &&
                                !usedExerciseNames.contains(catalogExercise.name.lowercased())
                            }

                            #if DEBUG
                            if let foundExercise = exercise {
                                print("[NewOpenAIComposer] ⚠️ Substituted '\(ex.name)' with '\(foundExercise.name)' (same muscle: \(muscleGroup.rawValue))")
                            }
                            #endif
                        }
                    }

                    guard let foundExercise = exercise else {
                        #if DEBUG
                        print("[NewOpenAIComposer] ❌ Skipping hallucinated exercise: '\(ex.name)'")
                        #endif
                        continue
                    }

                    // Parse reps
                    let repsComponents = ex.reps.components(separatedBy: "-")
                    let minReps = Int(repsComponents.first ?? "10") ?? 10
                    let maxReps = Int(repsComponents.last ?? "12") ?? 12

                    items.append(.exercise(ExercisePrescription(
                        exercise: foundExercise,
                        sets: ex.sets,
                        reps: IntRange(minReps, maxReps),
                        restInterval: TimeInterval(ex.restSeconds),
                        tip: ex.notes
                    )))
                }
            }

            // Create phase if has items
            if !items.isEmpty {
                let blueprintBlock = blueprint.blocks.first { $0.phaseKind == phaseKind }
                let rpeTarget = blueprintBlock?.rpeTarget ?? 7

                let title: String
                if let blueprintTitle = blueprintBlock?.title {
                    title = blueprintTitle
                } else if let activityTitle = openAIPhase.activity?.title {
                    title = activityTitle
                } else {
                    title = phaseKind.rawValue.capitalized
                }

                phases.append(WorkoutPlanPhase(
                    kind: phaseKind,
                    title: title,
                    rpeTarget: rpeTarget,
                    items: items
                ))
            }
        }

        // Create WorkoutPlan
        let title = response.title ?? blueprint.title
        let duration = blueprint.estimatedDurationMinutes

        return WorkoutPlan(
            title: title,
            focus: blueprint.focus,
            estimatedDurationMinutes: duration,
            intensity: blueprint.intensity,
            phases: phases,
            createdAt: Date()
        )
    }
}
