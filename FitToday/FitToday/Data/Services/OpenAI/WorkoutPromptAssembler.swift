//
//  WorkoutPromptAssembler.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation

// MARK: - Protocol

/// Protocol para montagem de prompts para geração de treino via OpenAI
protocol WorkoutPromptAssembling: Sendable {
  /// Monta o prompt completo para a OpenAI
  func assemblePrompt(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan],
    intensityAdjustment: IntensityAdjustment
  ) -> WorkoutPrompt
}

// MARK: - Prompt Models

/// Prompt montado para envio à OpenAI
struct WorkoutPrompt: Sendable, Equatable {
  /// System message (instruções gerais e contexto)
  let systemMessage: String
  
  /// User message (dados específicos da requisição)
  let userMessage: String
  
  /// Metadata para logging/cache
  let metadata: PromptMetadata
  
  /// Hash do prompt para cache
  var cacheKey: String {
    // Incluir fatores de variação para garantir que cache respeite mecanismos de diversidade
    let components = [
      String(metadata.variationSeed),  // CRÍTICO: incluir seed para variação horária/minuto
      metadata.goal.rawValue,
      metadata.structure.rawValue,
      metadata.level.rawValue,
      metadata.focus.rawValue,
      String(metadata.energyLevel),
      metadata.sorenessLevel.rawValue,
      metadata.blueprintVersion.rawValue,
      metadata.feedbackHash,  // Hash do feedback para invalidar cache quando ajuste mudar
      metadata.historyHash    // NOVO: hash do histórico para variar com base em treinos recentes
    ]
    return Hashing.sha256(components.joined(separator: "|"))
  }
}

/// Metadata do prompt para logging e diagnóstico
struct PromptMetadata: Sendable, Equatable {
  let goal: FitnessGoal
  let structure: TrainingStructure
  let level: TrainingLevel
  let focus: DailyFocus
  let energyLevel: Int
  let sorenessLevel: MuscleSorenessLevel
  let variationSeed: UInt64
  let blueprintVersion: BlueprintVersion
  let contextSource: String // "personal-active/emagrecimento.md" etc.
  let feedbackHash: String // Hash do ajuste de intensidade baseado em feedback
  let historyHash: String  // Hash dos últimos treinos para diversificar cache
  let timestamp: Date

  var logDescription: String {
    """
    [PromptMetadata] goal=\(goal.rawValue) structure=\(structure.rawValue) \
    level=\(level.rawValue) focus=\(focus.rawValue) \
    energy=\(energyLevel) soreness=\(sorenessLevel.rawValue) \
    seed=\(variationSeed) version=\(blueprintVersion.rawValue) \
    context=\(contextSource) feedback=\(feedbackHash) history=\(historyHash)
    """
  }
}

// MARK: - Response Schema

/// Schema da resposta esperada da OpenAI
struct OpenAIWorkoutResponse: Codable, Sendable {
  let phases: [OpenAIPhaseResponse]
  let title: String?
  let notes: String?
}

struct OpenAIPhaseResponse: Codable, Sendable {
  let kind: String // "warmup", "strength", "accessory", "aerobic"
  let exercises: [OpenAIExerciseResponse]?
  let activity: OpenAIActivityResponse?
}

struct OpenAIExerciseResponse: Codable, Sendable {
  let name: String
  let muscleGroup: String
  let equipment: String
  let sets: Int
  let reps: String // "8-12" ou "10"
  let restSeconds: Int
  let notes: String?
}

struct OpenAIActivityResponse: Codable, Sendable {
  let kind: String // "mobility", "aerobicZone2", "aerobicIntervals", "breathing"
  let title: String
  let durationMinutes: Int
  let notes: String?
}

// MARK: - Response Validator

/// Validador de resposta da OpenAI
struct OpenAIResponseValidator: Sendable {
  
  enum ValidationError: Error, LocalizedError {
    case invalidJSON(String)
    case missingPhases
    case emptyExercises
    case invalidPhaseKind(String)
    case exerciseCountMismatch(expected: Int, got: Int)
    
    var errorDescription: String? {
      switch self {
      case .invalidJSON(let detail):
        return "JSON inválido: \(detail)"
      case .missingPhases:
        return "Resposta não contém 'phases'"
      case .emptyExercises:
        return "Resposta não contém exercícios"
      case .invalidPhaseKind(let kind):
        return "Tipo de fase inválido: \(kind)"
      case .exerciseCountMismatch(let expected, let got):
        return "Número de exercícios diferente do esperado: esperado \(expected), recebido \(got)"
      }
    }
  }
  
  /// Valida e decodifica a resposta da OpenAI
  static func validate(
    jsonData: Data,
    expectedBlueprint: WorkoutBlueprint
  ) throws -> OpenAIWorkoutResponse {
    let decoder = JSONDecoder()
    
    do {
      let response = try decoder.decode(OpenAIWorkoutResponse.self, from: jsonData)
      
      // Validar estrutura básica
      guard !response.phases.isEmpty else {
        throw ValidationError.missingPhases
      }
      
      // Validar que há exercícios nas fases de força
      let strengthPhases = response.phases.filter { $0.kind == "strength" || $0.kind == "accessory" }
      let totalExercises = strengthPhases.compactMap(\.exercises).flatMap { $0 }.count
      
      if totalExercises == 0 && strengthPhases.contains(where: { $0.activity == nil }) {
        throw ValidationError.emptyExercises
      }
      
      // Validar tipos de fase
      let validKinds = Set(["warmup", "strength", "accessory", "conditioning", "aerobic", "finisher", "cooldown"])
      for phase in response.phases {
        if !validKinds.contains(phase.kind) {
          throw ValidationError.invalidPhaseKind(phase.kind)
        }
      }
      
      return response
      
    } catch let decodingError as DecodingError {
      throw ValidationError.invalidJSON(decodingError.localizedDescription)
    }
  }
  
  /// Tenta extrair JSON de uma resposta que pode conter texto adicional
  static func extractJSON(from text: String) -> Data? {
    // Tentar encontrar JSON entre ```json e ```
    if let jsonMatch = text.range(of: "```json\\s*\\n([\\s\\S]*?)\\n```", options: .regularExpression) {
      let jsonString = text[jsonMatch]
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      return jsonString.data(using: .utf8)
    }
    
    // Tentar encontrar JSON entre { e }
    if let start = text.firstIndex(of: "{"),
       let end = text.lastIndex(of: "}") {
      let jsonString = String(text[start...end])
      return jsonString.data(using: .utf8)
    }
    
    // Tentar direto
    return text.data(using: .utf8)
  }
}

// MARK: - Prompt Assembler Implementation

/// Assembler de prompts para geração de treino via OpenAI
struct WorkoutPromptAssembler: WorkoutPromptAssembling, Sendable {
  
  // MARK: - Constants

  private static let maxContextLength = 2000 // Aumentado para prompts mais completos
  private static let maxBlocksInCatalog = 20 // Reduzido para conter tamanho do prompt
  private static let maxExercisesPerBlock = 8 // Reduzido para conter tamanho do prompt
  // = Máximo de 360 exercícios enviados à OpenAI (era 160)
  
  // MARK: - WorkoutPromptAssembling
  
  func assemblePrompt(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan] = [],
    intensityAdjustment: IntensityAdjustment = .noChange
  ) -> WorkoutPrompt {
    let contextSource = contextFileName(for: profile.mainGoal)
    let guidelines = loadPersonalActiveGuidelines(for: profile.mainGoal)

    let systemMessage = buildSystemMessage(
      goal: profile.mainGoal,
      guidelines: guidelines,
      blueprint: blueprint
    )

    let userMessage = buildUserMessage(
      blueprint: blueprint,
      blocks: blocks,
      profile: profile,
      checkIn: checkIn,
      previousWorkouts: previousWorkouts,
      intensityAdjustment: intensityAdjustment
    )

    // Generate feedback hash from adjustment values
    let feedbackHash = generateFeedbackHash(intensityAdjustment)

    // Generate history hash from recent workouts for cache diversity
    let historyHash = generateHistoryHash(previousWorkouts)

    let metadata = PromptMetadata(
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      level: profile.level,
      focus: checkIn.focus,
      energyLevel: checkIn.energyLevel,
      sorenessLevel: checkIn.sorenessLevel,
      variationSeed: blueprint.variationSeed,
      blueprintVersion: blueprint.version,
      contextSource: contextSource,
      feedbackHash: feedbackHash,
      historyHash: historyHash,
      timestamp: Date()
    )

    #if DEBUG
    print("[PromptAssembler] \(metadata.logDescription)")
    print("[PromptAssembler] systemMessage length: \(systemMessage.count)")
    print("[PromptAssembler] userMessage length: \(userMessage.count)")
    #endif

    return WorkoutPrompt(
      systemMessage: systemMessage,
      userMessage: userMessage,
      metadata: metadata
    )
  }

  private func generateFeedbackHash(_ adjustment: IntensityAdjustment) -> String {
    let components = [
      String(adjustment.volumeMultiplier),
      String(adjustment.rpeAdjustment),
      String(adjustment.restAdjustment)
    ]
    return components.joined(separator: "-")
  }

  /// Gera hash dos últimos treinos para diversificar a cache key
  /// Isso garante que mesmo com seed similar, históricos diferentes gerem cache keys diferentes
  private func generateHistoryHash(_ workouts: [WorkoutPlan]) -> String {
    guard !workouts.isEmpty else { return "no-history" }

    // Usar IDs dos últimos 3 treinos para gerar hash
    let recentIds = workouts.prefix(3)
      .map { $0.id.uuidString }
      .joined(separator: "-")

    // Usar hash simples para não ter strings muito longas
    return String(abs(recentIds.hashValue))
  }
  
  // MARK: - System Message
  
  private func buildSystemMessage(
    goal: FitnessGoal,
    guidelines: String,
    blueprint: WorkoutBlueprint
  ) -> String {
    """
    Você é um personal trainer especialista em \(goalDescription(goal)).
    
    ## OBJETIVO PRINCIPAL
    \(goal.rawValue.uppercased())
    \(guidelines)
    
    ## TAREFA
    Gerar um treino completo usando APENAS exercícios do catálogo fornecido.
    
    ## REGRAS OBRIGATÓRIAS
    1. Use SOMENTE exercícios do catálogo (não invente nomes).
    2. Use SOMENTE equipamentos permitidos: \(blueprint.equipmentConstraints.allowedEquipment.map(\.rawValue).joined(separator: ", ")).
    3. Respeite o blueprint: cada fase deve ter o número EXATO de exercícios e o kind correto.
    4. Priorize segurança: evite exercícios que agravem limitações articulares/dor informadas pelo usuário.
    5. Evite repetição com base no histórico fornecido (quando existir).
    6. CADA EXERCÍCIO DEVE APARECER APENAS UMA VEZ no treino inteiro. Nunca repita o mesmo exercício em fases diferentes.
    7. Use os nomes EXATOS dos exercícios em inglês conforme fornecido no catálogo.
    
    ## FORMATO (responda APENAS com JSON válido)
    {
      "phases": [
        {
          "kind": "warmup|strength|accessory|conditioning|aerobic",
          "exercises": [{"name":"...", "muscleGroup":"...", "equipment":"...", "sets":3, "reps":"8-12", "restSeconds":60, "notes":"..."}],
          "activity": {"kind":"mobility|aerobicZone2|aerobicIntervals|breathing", "title":"...", "durationMinutes":10}
        }
      ],
      "title": "Título do treino",
      "notes": "Notas opcionais"
    }
    """
  }
  
  // MARK: - User Message
  
  private func buildUserMessage(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan],
    intensityAdjustment: IntensityAdjustment
  ) -> String {
    let blueprintJSON = formatBlueprint(blueprint)
    let catalogJSON = formatCatalog(blocks: blocks, blueprint: blueprint)
    let previousExercisesContext = formatPreviousWorkouts(previousWorkouts)
    let feedbackContext = formatFeedbackHistory(intensityAdjustment)
    let exerciseLimits = formatExerciseLimits()
    let diversityRules = formatDiversityRules()

    return """
    ## USUÁRIO
    **OBJETIVO PRINCIPAL: \(profile.mainGoal.rawValue.uppercased())**
    Nível: \(profile.level.rawValue) | Equipamentos: \(profile.availableStructure.rawValue) | Frequência: \(profile.weeklyFrequency)x/sem
    Condições de saúde: \(formatHealthConditions(profile.healthConditions))\(formatHealthSafetyRules(profile.healthConditions))

    ## HOJE
    Foco: \(checkIn.focus.rawValue) | DOMS: \(checkIn.sorenessLevel.rawValue)\(checkIn.sorenessAreas.isEmpty ? "" : " (áreas: \(checkIn.sorenessAreas.map(\.rawValue).joined(separator: ", ")))") | Energia: \(checkIn.energyLevel)/10

    Regras de adaptação:
    - Se energia <= 3 OU DOMS == strong: mantenha o treino conservador (menos "agressivo"), priorize técnica e segurança.

    ## ESTRUTURA DO TREINO (OBRIGATÓRIO)
    Título: \(blueprint.title) | Intensidade: \(blueprint.intensity.rawValue) | Duração: ~\(blueprint.estimatedDurationMinutes)min
    \(blueprintJSON)

    \(exerciseLimits)

    \(previousExercisesContext)

    \(feedbackContext)

    \(diversityRules)

    ## EXERCÍCIOS DISPONÍVEIS (use APENAS estes)
    \(catalogJSON)

    Retorne APENAS o JSON final.
    """
  }

  // MARK: - Feedback History Formatting

  private func formatFeedbackHistory(_ adjustment: IntensityAdjustment) -> String {
    // Only include feedback section if there's an actual adjustment
    guard adjustment != .noChange else { return "" }

    return """
    ## HISTÓRICO DE FEEDBACK DO USUÁRIO
    \(adjustment.recommendation)
    """
  }

  // MARK: - Exercise Limits Formatting

  private func formatExerciseLimits() -> String {
    """
    ## LIMITES POR FASE (RESPEITAR)
    - Warmup: 2-3 exercícios
    - Strength: 4-6 exercícios
    - Accessory: 2-4 exercícios
    - Conditioning: 2-3 exercícios
    - Cooldown: 2-3 exercícios
    """
  }

  // MARK: - Movement Pattern Diversity

  private func formatDiversityRules() -> String {
    """
    ## REGRA DE DIVERSIDADE
    - Variar padrões de movimento: incluir PUSH, PULL, HINGE, SQUAT
    - ≥80% dos exercícios devem ser DIFERENTES dos últimos 3 treinos
    - Equilibrar grupos musculares: não repetir o mesmo padrão em sequência
    - PROIBIDO: repetir qualquer exercício dentro do mesmo treino (cada exercício aparece UMA vez)
    """
  }
  
  // MARK: - Previous Workouts Formatting
  
  private func formatPreviousWorkouts(_ workouts: [WorkoutPlan]) -> String {
    guard !workouts.isEmpty else {
      return ""
    }

    // Expandido para 7 dias de histórico para melhor diversidade (era 3)
    let recentWorkouts = Array(workouts.prefix(7))

    var lines: [String] = []
    lines.append("## EXERCÍCIOS PROIBIDOS (últimos 7 treinos)")
    lines.append("")
    lines.append("Regra crítica: NÃO repita estes exercícios. Selecione exercícios diferentes.")
    lines.append("")

    // Coletar todos os exercícios recentes em lista flat
    var prohibitedExercises: [String] = []
    for workout in recentWorkouts {
      let exerciseNames = workout.phases
        .flatMap { phase in
          phase.items.compactMap { item in
            if case .exercise(let prescription) = item {
              return prescription.exercise.name
            }
            return nil
          }
        }
      prohibitedExercises.append(contentsOf: exerciseNames)
    }

    // Remover duplicatas e ordenar
    let uniqueProhibited = Array(Set(prohibitedExercises)).sorted()

    lines.append("EXERCÍCIOS PROIBIDOS (\(uniqueProhibited.count) total):")
    for name in uniqueProhibited {
      lines.append("- \(name)")
    }
    lines.append("")

    return lines.joined(separator: "\n")
  }
  
  // MARK: - Blueprint Formatting
  
  private func formatBlueprint(_ blueprint: WorkoutBlueprint) -> String {
    var lines: [String] = []
    
    lines.append("**OBJETIVO: \(blueprint.goal.rawValue.uppercased())**")
    lines.append("Recovery: \(blueprint.isRecoveryMode ? "SIM (reduzir intensidade)" : "NÃO")")
    lines.append("")
    lines.append("### FASES (crie EXATAMENTE \(blueprint.blocks.count) fases):")
    
    for (index, block) in blueprint.blocks.enumerated() {
      lines.append("")
      lines.append("**Fase \(index + 1): \(block.title)** (kind: \(block.phaseKind.rawValue))")
      lines.append("- EXERCÍCIOS: \(block.exerciseCount) (obrigatório)")
      lines.append("- Séries: \(block.setsRange.lowerBound)-\(block.setsRange.upperBound) | Reps: \(block.repsRange.lowerBound)-\(block.repsRange.upperBound) | Descanso: \(block.restSeconds)s | RPE: \(block.rpeTarget)")
      lines.append("- Músculos: \(block.targetMuscles.map(\.rawValue).joined(separator: ", "))")
      
      if !block.avoidMuscles.isEmpty {
        lines.append("- ⚠️ EVITAR: \(block.avoidMuscles.map(\.rawValue).joined(separator: ", "))")
      }
      
      if block.includesGuidedActivity, let activityKind = block.guidedActivityKind {
        lines.append("- Incluir atividade: \(activityKind.rawValue) (\(block.guidedActivityMinutes ?? 0) min)")
      }
    }
    
    return lines.joined(separator: "\n")
  }
  
  // MARK: - Focus to Muscle Mapping

  /// Returns the primary muscle groups for a given workout focus.
  /// Used to prioritize relevant exercises in the catalog.
  private func getMusclesForFocus(_ focus: DailyFocus) -> Set<MuscleGroup> {
    switch focus {
    case .upper:
      return [.chest, .back, .shoulders, .biceps, .triceps, .forearms]
    case .lower:
      return [.quads, .hamstrings, .glutes, .calves]
    case .fullBody:
      return [] // No filtering for full body
    case .core:
      return [.core, .lowerBack]
    case .cardio:
      return [.cardioSystem]
    case .surprise:
      return [] // Surprise can be any muscle group
    }
  }

  // MARK: - Catalog Formatting

  private func formatCatalog(blocks: [WorkoutBlock], blueprint: WorkoutBlueprint) -> String {
    // Filtrar blocos compatíveis com equipamento
    let allowedEquipment = Set(blueprint.equipmentConstraints.allowedEquipment)

    let compatibleBlocks = blocks.filter { block in
      block.equipmentOptions.contains { allowedEquipment.contains($0) }
    }

    // Get muscles relevant to the focus type
    let focusMuscles = getMusclesForFocus(blueprint.focus)

    // USAR A SEED PARA VARIAR A SELEÇÃO E ORDEM DOS BLOCOS
    var generator = SeededRandomGenerator(seed: blueprint.variationSeed)

    // Embaralhar blocos de forma determinística
    var shuffledBlocks = compatibleBlocks
    for i in (1..<shuffledBlocks.count).reversed() {
      let j = generator.nextInt(in: 0...i)
      shuffledBlocks.swapAt(i, j)
    }

    // Selecionar blocos variados baseados na seed
    let selectedBlocks = generator.selectElements(
      from: shuffledBlocks,
      count: min(Self.maxBlocksInCatalog, shuffledBlocks.count)
    )

    // Agrupar exercícios por grupo muscular para facilitar seleção
    var exercisesByMuscle: [MuscleGroup: [WorkoutExercise]] = [:]

    for block in selectedBlocks {
      // EMBARALHAR EXERCÍCIOS DENTRO DO BLOCO USANDO A SEED
      var shuffledExercises = block.exercises
      for i in (1..<shuffledExercises.count).reversed() {
        let j = generator.nextInt(in: 0...i)
        shuffledExercises.swapAt(i, j)
      }

      for exercise in shuffledExercises.prefix(Self.maxExercisesPerBlock) {
        exercisesByMuscle[exercise.mainMuscle, default: []].append(exercise)
      }
    }

    var catalogLines: [String] = []

    // CRITICAL INSTRUCTION - Reforçar uso de nomes exatos
    catalogLines.append("⚠️ CRITICAL: You MUST use EXACTLY these exercise names in your response.")
    catalogLines.append("Any exercise name not in this list will be REJECTED.")
    catalogLines.append("Copy the exercise names EXACTLY as written below (including capitalization).")
    catalogLines.append("")
    catalogLines.append("## AVAILABLE EXERCISES (use EXACT names)")
    catalogLines.append("")

    // Prioritize muscles matching the focus type
    let prioritizedMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]

    if focusMuscles.isEmpty {
      // No filtering - use all muscles sorted
      prioritizedMuscles = exercisesByMuscle.keys.sorted { $0.rawValue < $1.rawValue }
      secondaryMuscles = []
    } else {
      // Separate primary (matching focus) and secondary muscles
      prioritizedMuscles = exercisesByMuscle.keys
        .filter { focusMuscles.contains($0) }
        .sorted { $0.rawValue < $1.rawValue }
      secondaryMuscles = exercisesByMuscle.keys
        .filter { !focusMuscles.contains($0) }
        .sorted { $0.rawValue < $1.rawValue }
    }

    // Reduced limit to 80 exercises for better focus
    var totalExercises = 0
    let maxTotalExercises = 80
    let maxPrimaryExercises = 60  // Reserve most slots for focus-relevant muscles

    // First pass: prioritized muscles (up to 60)
    for muscle in prioritizedMuscles {
      guard let exercises = exercisesByMuscle[muscle], !exercises.isEmpty else { continue }
      guard totalExercises < maxPrimaryExercises else { break }

      catalogLines.append("### \(muscle.rawValue.capitalized) (PRIMARY)")

      let remainingSlots = maxPrimaryExercises - totalExercises
      let exercisesToInclude = exercises.prefix(min(15, remainingSlots))

      for exercise in exercisesToInclude {
        catalogLines.append("- \(exercise.name) (\(exercise.equipment.rawValue))")
        totalExercises += 1
      }
      catalogLines.append("")
    }

    // Second pass: secondary muscles (up to remaining 20)
    for muscle in secondaryMuscles {
      guard let exercises = exercisesByMuscle[muscle], !exercises.isEmpty else { continue }
      guard totalExercises < maxTotalExercises else { break }

      catalogLines.append("### \(muscle.rawValue.capitalized)")

      let remainingSlots = maxTotalExercises - totalExercises
      let exercisesToInclude = exercises.prefix(min(5, remainingSlots))

      for exercise in exercisesToInclude {
        catalogLines.append("- \(exercise.name) (\(exercise.equipment.rawValue))")
        totalExercises += 1
      }
      catalogLines.append("")
    }

    catalogLines.append("---")
    catalogLines.append("Total: \(totalExercises) exercises available")
    catalogLines.append("Focus: \(blueprint.focus.rawValue) - prioritize exercises from PRIMARY muscle groups")
    catalogLines.append("REMINDER: Use ONLY names from this list. Do NOT invent or modify exercise names.")

    return catalogLines.joined(separator: "\n")
  }

  // MARK: - Exercise Name Validation

  /// Valida se todos os exercícios da resposta existem no catálogo
  /// Retorna lista de exercícios não encontrados (para logging/debug)
  static func validateExerciseNames(
    response: OpenAIWorkoutResponse,
    availableExercises: [WorkoutExercise]
  ) -> [String] {
    let availableNames = Set(availableExercises.map { $0.name.lowercased() })
    var notFound: [String] = []

    for phase in response.phases {
      guard let exercises = phase.exercises else { continue }
      for exercise in exercises {
        let nameLower = exercise.name.lowercased()
        // Verificar match exato ou parcial
        let hasMatch = availableNames.contains(nameLower) ||
          availableNames.contains { available in
            available.contains(nameLower) || nameLower.contains(available)
          }
        if !hasMatch {
          notFound.append(exercise.name)
        }
      }
    }

    return notFound
  }
  
  // MARK: - Guidelines Loading
  
  private func loadPersonalActiveGuidelines(for goal: FitnessGoal) -> String {
    let resourceName = resourceFileName(for: goal)
    
    // Tentar carregar do bundle
    if let url = Bundle.main.url(forResource: resourceName, withExtension: "md"),
       let data = try? Data(contentsOf: url),
       let text = String(data: data, encoding: .utf8) {
      return extractEssentialGuidelines(from: text)
    }
    
    // Fallback: guidelines inline por objetivo
    return fallbackGuidelines(for: goal)
  }
  
  private func extractEssentialGuidelines(from text: String) -> String {
    // Extrair seções essenciais (até o limite de caracteres)
    var essentials: [String] = []
    var currentSection = ""
    var inRelevantSection = false
    
    let relevantHeaders = [
      "## Objetivo Principal",
      "## Princípios",
      "## Tipos de Exercícios",
      "## Estrutura do Treino",
      "## Variáveis de Controle"
    ]
    
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
      let trimmedLine = String(line)
      
      // Detectar início de seção relevante
      if relevantHeaders.contains(where: { trimmedLine.hasPrefix($0) }) {
        if !currentSection.isEmpty {
          essentials.append(currentSection)
        }
        currentSection = trimmedLine + "\n"
        inRelevantSection = true
        continue
      }
      
      // Detectar fim de seção (nova seção de cabeçalho)
      if trimmedLine.hasPrefix("## ") && inRelevantSection {
        if !currentSection.isEmpty {
          essentials.append(currentSection)
        }
        currentSection = ""
        inRelevantSection = false
        continue
      }
      
      // Adicionar linha à seção atual
      if inRelevantSection {
        currentSection += trimmedLine + "\n"
      }
    }
    
    // Adicionar última seção
    if !currentSection.isEmpty {
      essentials.append(currentSection)
    }
    
    // Juntar e limitar tamanho
    let result = essentials.joined(separator: "\n")
    return String(result.prefix(Self.maxContextLength))
  }
  
  private func fallbackGuidelines(for goal: FitnessGoal) -> String {
    switch goal {
    case .hypertrophy:
      return """
      ## Objetivo: Hipertrofia Muscular
      - Exercícios multiarticulares prioritários
      - Alta intensidade, baixo-médio volume
      - Descanso longo (2-5min) para recuperação neural
      - Sets: 3-5, Reps: 4-10, RPE: 7-9
      - Progressão por sobrecarga progressiva
      """
      
    case .weightLoss:
      return """
      ## Objetivo: Emagrecimento
      - Circuitos full body de alta densidade
      - Intervalos curtos (30-60s)
      - Volume moderado, intensidade percebida 6-8
      - Sets: 3-4, Reps: 10-18
      - Ênfase em gasto energético total
      - Incluir aeróbio leve ao final
      """
      
    case .performance:
      return """
      ## Objetivo: Performance Atlética
      - Movimentos explosivos e funcionais
      - Qualidade > quantidade
      - Recuperação adequada entre séries
      - Sets: 3-4, Reps: 5-8, RPE: 7
      - Alternância de estímulos
      """
      
    case .conditioning:
      return """
      ## Objetivo: Condicionamento
      - Força + resistência equilibrados
      - Intensidade moderada, RPE 6-7
      - Full body preferencial
      - Sets: 3-4, Reps: 10-15
      - Descanso: 45-90s
      """
      
    case .endurance:
      return """
      ## Objetivo: Resistência Cardiorrespiratória
      - Volume alto, intensidade controlada
      - Descanso curto (20-45s)
      - Ênfase em aeróbio e técnica
      - Sets: 2-4, Reps: 15-25
      - Zona 2 prioritária para aeróbio
      """
    }
  }
  
  // MARK: - Helpers
  
  private func formatHealthConditions(_ conditions: [HealthCondition]) -> String {
    guard !conditions.isEmpty else { return "nenhuma" }
    
    // Remover ".none" caso venha junto
    let filtered = conditions.filter { $0 != .none }
    guard !filtered.isEmpty else { return "nenhuma" }
    
    return filtered.map { condition in
      switch condition {
      case .none:
        return "nenhuma"
      case .lowerBackPain:
        return "dor lombar"
      case .knee:
        return "joelho"
      case .shoulder:
        return "ombro"
      case .other:
        return "outra"
      }
    }
    .joined(separator: ", ")
  }
  
  private func formatHealthSafetyRules(_ conditions: [HealthCondition]) -> String {
    let filtered = conditions.filter { $0 != .none }
    guard !filtered.isEmpty else { return "" }
    
    var rules: [String] = []
    rules.append("")
    rules.append("Regras de segurança (obrigatórias):")
    
    for condition in filtered {
      switch condition {
      case .lowerBackPain:
        rules.append("- Evitar exercícios que sobrecarreguem a lombar; prefira estabilidade e amplitude controlada.")
      case .knee:
        rules.append("- Evitar impacto e dor no joelho; prefira controle, amplitude tolerável e variações estáveis.")
      case .shoulder:
        rules.append("- Evitar elevação/dor no ombro; prefira pegadas neutras e amplitude confortável.")
      case .other:
        rules.append("- Priorizar segurança e selecionar opções de baixo risco quando houver dúvida.")
      case .none:
        break
      }
    }
    
    return rules.joined(separator: "\n")
  }
  
  private func contextFileName(for goal: FitnessGoal) -> String {
    switch goal {
    case .weightLoss:
      return "personal-active/emagrecimento.md"
    case .hypertrophy:
      return "personal-active/hipertrofia.md"
    case .performance:
      return "personal-active/força.md"
    case .conditioning, .endurance:
      return "personal-active/resistencia.md"
    }
  }
  
  private func resourceFileName(for goal: FitnessGoal) -> String {
    switch goal {
    case .weightLoss:
      return "personal_active_emagrecimento"
    case .hypertrophy:
      return "personal_active_hipertrofia"
    case .performance:
      return "personal_active_forca"
    case .conditioning, .endurance:
      return "personal_active_resistencia"
    }
  }
  
  private func goalDescription(_ goal: FitnessGoal) -> String {
    switch goal {
    case .hypertrophy:
      return "hipertrofia muscular e desenvolvimento de força"
    case .weightLoss:
      return "emagrecimento e redução de gordura corporal"
    case .performance:
      return "performance atlética e desenvolvimento funcional"
    case .conditioning:
      return "condicionamento físico geral"
    case .endurance:
      return "resistência cardiorrespiratória"
    }
  }
}
