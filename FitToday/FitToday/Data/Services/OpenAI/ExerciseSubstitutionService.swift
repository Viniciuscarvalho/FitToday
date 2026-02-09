//
//  ExerciseSubstitutionService.swift
//  FitToday
//
//  Serviço de substituição de exercícios usando OpenAI.
//

import Foundation

// MARK: - Models

/// Exercício alternativo sugerido pela IA
struct AlternativeExercise: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let targetMuscle: String
    let equipment: String
    let difficulty: String
    let instructions: [String]
    let whyGood: String // Explicação de por que é uma boa alternativa
    
    init(id: String = UUID().uuidString, name: String, targetMuscle: String, equipment: String, difficulty: String, instructions: [String], whyGood: String) {
        self.id = id
        self.name = name
        self.targetMuscle = targetMuscle
        self.equipment = equipment
        self.difficulty = difficulty
        self.instructions = instructions
        self.whyGood = whyGood
    }
}

/// Resposta da OpenAI para substituição
struct SubstitutionResponse: Codable {
    let alternatives: [AlternativeExercise]
    let message: String? // Mensagem opcional da IA
}

// MARK: - Protocol

protocol ExerciseSubstituting: Sendable {
    func suggestAlternatives(
        for exercise: WorkoutExercise,
        userProfile: UserProfile,
        reason: SubstitutionReason?
    ) async throws -> [AlternativeExercise]
}

/// Motivo da substituição
enum SubstitutionReason: String, CaseIterable {
    case equipmentUnavailable = "equipment_unavailable"
    case tooHard = "too_hard"
    case pain = "pain"
    case boring = "boring"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .equipmentUnavailable: return "Equipamento indisponível"
        case .tooHard: return "Muito difícil"
        case .pain: return "Sinto dor"
        case .boring: return "Quero variar"
        case .other: return "Outro motivo"
        }
    }
}

// MARK: - Chat Completion Response (local copy)

private struct SubstitutionChatResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String?
    }
}

// MARK: - Service

actor ExerciseSubstitutionService: ExerciseSubstituting {
    private let client: NewOpenAIClient
    private let logger: (String) -> Void

    init(client: NewOpenAIClient, logger: @escaping (String) -> Void = { print("[Substitution]", $0) }) {
        self.client = client
        self.logger = logger
    }

    func suggestAlternatives(
        for exercise: WorkoutExercise,
        userProfile: UserProfile,
        reason: SubstitutionReason?
    ) async throws -> [AlternativeExercise] {
        let prompt = buildPrompt(for: exercise, profile: userProfile, reason: reason)

        logger("Buscando alternativas para: \(exercise.name)")

        let data = try await client.generateWorkout(prompt: prompt)

        // Decodificar resposta do Chat Completions
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            logger("Resposta vazia do OpenAI")
            throw SubstitutionError.noAlternativesFound
        }

        let response = try JSONDecoder().decode(SubstitutionResponse.self, from: contentData)

        guard !response.alternatives.isEmpty else {
            throw SubstitutionError.noAlternativesFound
        }

        logger("Encontradas \(response.alternatives.count) alternativas")
        return response.alternatives
    }
    
    // MARK: - Prompt Building
    
    private func buildPrompt(for exercise: WorkoutExercise, profile: UserProfile, reason: SubstitutionReason?) -> String {
        let reasonText = reason?.displayName ?? "não especificado"
        let healthConditions = profile.healthConditions.map(\.rawValue).joined(separator: ", ")
        
        return """
        Você é um personal trainer especialista. O usuário precisa de ALTERNATIVAS para um exercício.

        EXERCÍCIO ORIGINAL:
        - Nome: \(exercise.name)
        - Músculo principal: \(exercise.mainMuscle.rawValue)
        - Equipamento: \(exercise.equipment.rawValue)

        PERFIL DO USUÁRIO:
        - Nível: \(profile.level.rawValue)
        - Estrutura disponível: \(profile.availableStructure.rawValue)
        - Condições de saúde: \(healthConditions.isEmpty ? "nenhuma" : healthConditions)
        - Objetivo: \(profile.mainGoal.rawValue)

        MOTIVO DA SUBSTITUIÇÃO: \(reasonText)

        REGRAS OBRIGATÓRIAS:
        1. Sugira 3 exercícios alternativos que trabalhem o MESMO músculo principal (\(exercise.mainMuscle.rawValue))
        2. Considere o equipamento disponível (\(profile.availableStructure.rawValue))
        3. Respeite o nível do usuário (\(profile.level.rawValue))
        4. Se o motivo for "dor", sugira versões mais leves/seguras
        5. Se o motivo for "equipamento indisponível", sugira com outros equipamentos ou peso corporal
        6. Inclua exercícios criativos e variados, não apenas os óbvios

        FORMATO DE RESPOSTA (JSON OBRIGATÓRIO):
        {
            "alternatives": [
                {
                    "id": "unique-id-1",
                    "name": "Nome do Exercício",
                    "targetMuscle": "\(exercise.mainMuscle.rawValue)",
                    "equipment": "tipo de equipamento",
                    "difficulty": "beginner|intermediate|advanced",
                    "instructions": ["Passo 1", "Passo 2", "Passo 3"],
                    "whyGood": "Explicação breve de por que é uma boa alternativa"
                }
            ],
            "message": "Mensagem opcional para o usuário"
        }

        IMPORTANTE:
        - Retorne APENAS JSON válido, sem texto adicional
        - Sempre 3 alternativas, ordenadas da mais recomendada para menos
        - Instruções claras e objetivas (máximo 4 passos)
        - whyGood deve ser persuasivo e curto (máximo 20 palavras)
        """
    }
}

// MARK: - Errors

enum SubstitutionError: Error, LocalizedError {
    case noAlternativesFound
    case apiError(String)
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .noAlternativesFound:
            return "Não encontramos alternativas para este exercício."
        case .apiError(let message):
            return "Erro ao buscar alternativas: \(message)"
        case .notAvailable:
            return "Substituição por IA não disponível. Configure sua chave de API nas configurações."
        }
    }
}

// MARK: - Factory

struct ExerciseSubstitutionServiceFactory {
    /// Cria o serviço de substituição se OpenAI estiver configurado
    static func create() -> ExerciseSubstituting? {
        guard let client = NewOpenAIClient.fromUserKey() else {
            return nil
        }
        return ExerciseSubstitutionService(client: client)
    }
}

