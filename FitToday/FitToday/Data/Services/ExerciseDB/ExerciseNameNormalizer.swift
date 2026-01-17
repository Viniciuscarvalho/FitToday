//
//  ExerciseNameNormalizer.swift
//  FitToday
//
//  Created by AI on 16/01/26.
//

import Foundation

// MARK: - Protocol

/// 💡 Learn: Protocol para normalização de nomes de exercícios
/// Usado para encontrar nomes padronizados do ExerciseDB para exercícios gerados pela OpenAI
protocol ExerciseNameNormalizing: Sendable {
    /// Normaliza nome de exercício para usar nome do ExerciseDB quando possível
    /// - Parameters:
    ///   - exerciseName: Nome original (pode estar em português ou inglês)
    ///   - equipment: Equipamento usado (para validação de compatibilidade)
    ///   - muscleGroup: Grupo muscular alvo (para filtrar candidatos)
    /// - Returns: Nome normalizado (ExerciseDB name ou original se não houver match)
    func normalize(
        exerciseName: String,
        equipment: String?,
        muscleGroup: String?
    ) async throws -> String
}

// MARK: - Implementation

/// 💡 Learn: Implementação actor-based para normalização thread-safe de nomes de exercícios
///
/// Algoritmo de normalização em 4 passos:
/// 1. **Tradução PT→EN**: Usa dicionário centralizado para traduzir nomes em português
/// 2. **Normalização de Texto**: Lowercase, remove acentos, tokeniza
/// 3. **Matching Fuzzy**: Busca no ExerciseDB com scoring baseado em tokens
/// 4. **Validação**: Verifica compatibilidade de equipamento e score mínimo (80%)
///
/// Exemplo de fluxo:
/// ```
/// "Supino reto com barra"
///   → Step 1: "barbell bench press" (tradução)
///   → Step 2: {"barbell", "bench", "press"} (tokens)
///   → Step 3: Busca candidatos no ExerciseDB por target "pectorals"
///   → Step 4: Seleciona melhor match com score ≥ 0.80
///   → Resultado: "barbell bench press" (nome padronizado do ExerciseDB)
/// ```
actor ExerciseNameNormalizer: ExerciseNameNormalizing {

    // MARK: - Properties

    private let exerciseDBService: ExerciseDBServicing
    private let translationDictionary: [String: String]
    private var cache: [String: String] = [:]

    // 💡 Learn: Score mínimo para considerar um match válido (Jaccard similarity + equipment)
    // Score = (token overlap / token union) * 0.7 + equipment match * 0.3
    // Exemplo: 80% = pelo menos 70% dos tokens em comum + equipamento correto
    private let minimumMatchScore: Double = 0.80

    // MARK: - Initialization

    init(exerciseDBService: ExerciseDBServicing) {
        self.exerciseDBService = exerciseDBService
        self.translationDictionary = ExerciseTranslationDictionary.portugueseToEnglish
    }

    // MARK: - Public Methods

    func normalize(
        exerciseName: String,
        equipment: String?,
        muscleGroup: String?
    ) async throws -> String {
        // Cache lookup
        let cacheKey = "\(exerciseName)|\(equipment ?? "")|\(muscleGroup ?? "")"
        if let cached = cache[cacheKey] {
            return cached
        }

        // Step 1: Tradução PT → EN
        let translatedName = translate(exerciseName)

        // Step 2: Normalização de texto
        let normalizedTokens = tokenize(translatedName)

        // Step 3: Buscar candidatos no ExerciseDB
        let candidates: [ExerciseDBExercise]
        if let target = muscleGroup {
            // Busca por grupo muscular para filtrar candidatos (mais eficiente)
            candidates = try await exerciseDBService.fetchExercises(
                target: target.lowercased(),
                limit: 50
            )
        } else {
            // Busca por nome (menos eficiente mas necessário quando não temos target)
            candidates = try await exerciseDBService.searchExercises(
                query: translatedName,
                limit: 20
            )
        }

        // Step 4: Scoring e ranking
        let scoredCandidates = candidates.map { candidate in
            (
                exercise: candidate,
                score: calculateMatchScore(
                    candidateName: candidate.name,
                    normalizedTokens: normalizedTokens,
                    candidateEquipment: candidate.equipment,
                    targetEquipment: equipment
                )
            )
        }
        .sorted { $0.score > $1.score }

        // Step 5: Selecionar melhor candidato
        if let best = scoredCandidates.first,
           best.score >= minimumMatchScore {
            // Match válido encontrado
            #if DEBUG
            print("[ExerciseNameNormalizer] ✅ Match encontrado: '\(exerciseName)' → '\(best.exercise.name)' (score: \(String(format: "%.2f", best.score)))")
            #endif
            cache[cacheKey] = best.exercise.name
            return best.exercise.name
        } else {
            // Sem match suficiente - usar nome original
            #if DEBUG
            if let best = scoredCandidates.first {
                print("[ExerciseNameNormalizer] ⚠️ Score insuficiente (\(String(format: "%.2f", best.score)) < \(minimumMatchScore)) - usando nome original '\(exerciseName)'")
            } else {
                print("[ExerciseNameNormalizer] ⚠️ Nenhum candidato encontrado - usando nome original '\(exerciseName)'")
            }
            #endif
            cache[cacheKey] = exerciseName
            return exerciseName
        }
    }

    // MARK: - Private Helpers

    /// Traduz o nome do exercício de português para inglês
    /// - Parameter name: Nome do exercício em português ou inglês
    /// - Returns: Nome traduzido ou original se não houver tradução
    private func translate(_ name: String) -> String {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)
        return translationDictionary[normalized] ?? name
    }

    /// Tokeniza um nome removendo acentos, convertendo para lowercase e separando por palavras
    /// - Parameter text: Texto a ser tokenizado
    /// - Returns: Set de tokens (palavras únicas)
    private func tokenize(_ text: String) -> Set<String> {
        // Normalização: lowercase, remover acentos, split em palavras
        let normalized = text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return Set(normalized.split(separator: " ").map(String.init))
    }

    /// Calcula score de match entre nome normalizado e candidato do ExerciseDB
    ///
    /// Score = (Jaccard similarity * 0.7) + (Equipment match * 0.3)
    /// - Jaccard similarity: intersection(tokens) / union(tokens)
    /// - Equipment match: 1.0 se igual, 0.0 caso contrário
    ///
    /// - Parameters:
    ///   - candidateName: Nome do exercício candidato (ExerciseDB)
    ///   - normalizedTokens: Tokens do nome normalizado (local)
    ///   - candidateEquipment: Equipamento do candidato
    ///   - targetEquipment: Equipamento esperado
    /// - Returns: Score entre 0.0 e 1.0
    private func calculateMatchScore(
        candidateName: String,
        normalizedTokens: Set<String>,
        candidateEquipment: String?,
        targetEquipment: String?
    ) -> Double {
        var score = 0.0

        // 1. Token overlap (peso: 70%) - Jaccard similarity
        let candidateTokens = tokenize(candidateName)
        let intersection = normalizedTokens.intersection(candidateTokens)
        let union = normalizedTokens.union(candidateTokens)

        if !union.isEmpty {
            let jaccardSimilarity = Double(intersection.count) / Double(union.count)
            score += jaccardSimilarity * 0.7
        }

        // 2. Equipment match (peso: 30%)
        if let target = targetEquipment?.lowercased(),
           let candidate = candidateEquipment?.lowercased(),
           target == candidate {
            score += 0.3
        }

        return score
    }
}

// MARK: - No-Op Normalizer

/// 💡 Learn: Normalizer fallback que retorna o nome original sem modificação
/// Usado quando ExerciseDB não está disponível
struct NoOpExerciseNameNormalizer: ExerciseNameNormalizing {
    func normalize(
        exerciseName: String,
        equipment: String?,
        muscleGroup: String?
    ) async throws -> String {
        // Simplesmente retorna o nome original sem normalização
        return exerciseName
    }
}
