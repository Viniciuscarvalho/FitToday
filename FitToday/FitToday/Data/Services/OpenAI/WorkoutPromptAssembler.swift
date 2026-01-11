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
    previousWorkouts: [WorkoutPlan]
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
      metadata.blueprintVersion.rawValue
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
  let variationSeed: UInt64
  let blueprintVersion: BlueprintVersion
  let contextSource: String // "personal-active/emagrecimento.md" etc.
  let timestamp: Date
  
  var logDescription: String {
    """
    [PromptMetadata] goal=\(goal.rawValue) structure=\(structure.rawValue) \
    level=\(level.rawValue) focus=\(focus.rawValue) \
    seed=\(variationSeed) version=\(blueprintVersion.rawValue) \
    context=\(contextSource)
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
  private static let maxBlocksInCatalog = 30 // Aumentado para máxima variedade (era 20)
  private static let maxExercisesPerBlock = 12 // Aumentado para treinos mais robustos (era 8)
  // = Máximo de 360 exercícios enviados à OpenAI (era 160)
  
  // MARK: - WorkoutPromptAssembling
  
  func assemblePrompt(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan] = []
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
      previousWorkouts: previousWorkouts
    )
    
    let metadata = PromptMetadata(
      goal: profile.mainGoal,
      structure: profile.availableStructure,
      level: profile.level,
      focus: checkIn.focus,
      variationSeed: blueprint.variationSeed,
      blueprintVersion: blueprint.version,
      contextSource: contextSource,
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
  
  // MARK: - System Message
  
  private func buildSystemMessage(
    goal: FitnessGoal,
    guidelines: String,
    blueprint: WorkoutBlueprint
  ) -> String {
    """
    Você é um personal trainer expert em \(goalDescription(goal)).
    
    ## OBJETIVO PRINCIPAL: \(goal.rawValue.uppercased())
    \(guidelines)
    
    ## TAREFA
    Crie um treino COMPLETO e ROBUSTO usando APENAS exercícios do catálogo fornecido.
    
    ## REGRAS OBRIGATÓRIAS
    1. OBJETIVO do usuário é \(goal.rawValue) - adapte intensidade, volume e seleção
    2. Use APENAS equipamentos: \(blueprint.equipmentConstraints.allowedEquipment.map(\.rawValue).joined(separator: ", "))
    3. Cada fase DEVE ter o número EXATO de exercícios do blueprint
    4. Selecione exercícios VARIADOS - evite repetição
    5. NUNCA use exercícios que não estão no catálogo
    
    ## FORMATO JSON (retorne APENAS isso):
    ```json
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
    ```
    """
  }
  
  // MARK: - User Message
  
  private func buildUserMessage(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan]
  ) -> String {
    let blueprintJSON = formatBlueprint(blueprint)
    let catalogJSON = formatCatalog(blocks: blocks, blueprint: blueprint)
    let previousExercisesContext = formatPreviousWorkouts(previousWorkouts)
    
    return """
    ## USUÁRIO
    **OBJETIVO PRINCIPAL: \(profile.mainGoal.rawValue.uppercased())**
    Nível: \(profile.level.rawValue) | Equipamentos: \(profile.availableStructure.rawValue) | Frequência: \(profile.weeklyFrequency)x/sem
    
    ## HOJE
    Foco: \(checkIn.focus.rawValue) | DOMS: \(checkIn.sorenessLevel.rawValue)\(checkIn.sorenessAreas.isEmpty ? "" : " (áreas: \(checkIn.sorenessAreas.map(\.rawValue).joined(separator: ", ")))")
    
    ## ESTRUTURA DO TREINO (OBRIGATÓRIO)
    Título: \(blueprint.title) | Intensidade: \(blueprint.intensity.rawValue) | Duração: ~\(blueprint.estimatedDurationMinutes)min
    \(blueprintJSON)
    
    \(previousExercisesContext)
    
    ## EXERCÍCIOS DISPONÍVEIS (use APENAS estes)
    \(catalogJSON)
    
    **MONTE O TREINO COMPLETO AGORA. Retorne APENAS o JSON.**
    """
  }
  
  // MARK: - Previous Workouts Formatting
  
  private func formatPreviousWorkouts(_ workouts: [WorkoutPlan]) -> String {
    guard !workouts.isEmpty else {
      return ""
    }

    // Pegar apenas os últimos 3 treinos para não estourar contexto
    let recentWorkouts = Array(workouts.prefix(3))

    var lines: [String] = []
    lines.append("## EXERCÍCIOS PROIBIDOS")
    lines.append("")
    lines.append("🚫 REGRA CRÍTICA: NÃO repita estes exercícios.")
    lines.append("Você DEVE selecionar exercícios COMPLETAMENTE DIFERENTES.")
    lines.append("Repetir exercícios desta lista resultará em treino rejeitado.")
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
      lines.append("- ❌ \(name)")
    }
    lines.append("")
    lines.append("⚠️ Selecione exercícios que NÃO estão nesta lista!")
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
  
  // MARK: - Catalog Formatting
  
  private func formatCatalog(blocks: [WorkoutBlock], blueprint: WorkoutBlueprint) -> String {
    // Filtrar blocos compatíveis com equipamento
    let allowedEquipment = Set(blueprint.equipmentConstraints.allowedEquipment)
    
    let compatibleBlocks = blocks.filter { block in
      block.equipmentOptions.contains { allowedEquipment.contains($0) }
    }
    
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
    catalogLines.append("Use APENAS exercícios desta lista. Escolha exercícios VARIADOS para cada fase.")
    catalogLines.append("")
    
    // Ordenar grupos musculares para consistência
    let sortedMuscles = exercisesByMuscle.keys.sorted { $0.rawValue < $1.rawValue }
    
    for muscle in sortedMuscles {
      guard let exercises = exercisesByMuscle[muscle], !exercises.isEmpty else { continue }
      
      catalogLines.append("[\(muscle.rawValue.uppercased())]")
      for exercise in exercises {
        catalogLines.append("• \(exercise.name) (\(exercise.equipment.rawValue))")
      }
      catalogLines.append("")
    }
    
    return catalogLines.joined(separator: "\n")
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
