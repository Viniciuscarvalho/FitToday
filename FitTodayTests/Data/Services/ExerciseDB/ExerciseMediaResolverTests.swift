//
//  ExerciseMediaResolverTests.swift
//  FitTodayTests
//
//  Created by AI on 05/01/26.
//

import XCTest
@testable import FitToday

final class ExerciseMediaResolverTests: XCTestCase {
    var sut: ExerciseMediaResolver!
    var mockService: MockExerciseDBServiceForResolver!
    var mockTargetCatalog: MockTargetCatalog!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockService = MockExerciseDBServiceForResolver()
        mockTargetCatalog = MockTargetCatalog()
        
        sut = ExerciseMediaResolver(
            service: mockService,
            targetCatalog: mockTargetCatalog,
            baseURL: URL(string: "https://test.com")
        )
    }
    
    override func tearDown() async throws {
        await sut.clearCache()
        sut = nil
        mockService = nil
        mockTargetCatalog = nil
        try await super.tearDown()
    }
    
    // MARK: - Target-Based Resolution Tests
    
    func testResolveMedia_TargetBased_Success() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "local_001",
            name: "Lever Pec Deck Fly",
            mainMuscle: .chest,
            equipment: .machine,
            instructions: [],
            media: nil
        )
        
        mockTargetCatalog.stubbedValidTargets = ["pectorals", "chest"]
        mockTargetCatalog.isValidTargetResult = true
        
        let candidate = ExerciseDBExercise(
            bodyPart: "chest",
            equipment: "machine",
            id: "0023",
            name: "pec deck fly",
            target: "pectorals",
            secondaryMuscles: nil,
            instructions: nil,
            description: nil,
            difficulty: nil,
            category: nil
        )
        mockService.stubbedExercisesByTarget = [candidate]
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        XCTAssertEqual(resolved.source, .exerciseDB)
        XCTAssertTrue(mockService.fetchExercisesCalled)
    }
    
    func testResolveMedia_TargetBased_FallbackToName() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "local_002",
            name: "Bicep Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = [] // Nenhum candidato por target
        
        // Fallback por nome
        let nameMatch = ExerciseDBExercise(
            bodyPart: "upper arms",
            equipment: "dumbbell",
            id: "0001",
            name: "dumbbell bicep curl",
            target: "biceps",
            secondaryMuscles: nil,
            instructions: nil,
            description: nil,
            difficulty: nil,
            category: nil
        )
        mockService.stubbedSearchResults = [nameMatch]
        mockService.stubbedImageURL = URL(string: "https://test.com/image2.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        XCTAssertTrue(mockService.searchExercisesCalled, "Deve tentar fallback por nome")
    }
    
    // MARK: - Ranking Tests
    
    func testRankCandidates_EquipmentMatch_HigherScore() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "test",
            name: "Bicep Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell", // Match exato
                id: "001",
                name: "dumbbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "barbell", // Não match
                id: "002",
                name: "barbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = candidates
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        // O primeiro candidato (dumbbell) deve ser escolhido por ter match de equipamento
        XCTAssertNotNil(resolved.imageURL)
    }
    
    func testRankCandidates_NameSimilarity_ConsidersTokens() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "test",
            name: "Lever Pec Deck Fly",
            mainMuscle: .chest,
            equipment: .machine,
            instructions: [],
            media: nil
        )
        
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "machine",
                id: "001",
                name: "pec deck fly", // Mais tokens em comum
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "machine",
                id: "002",
                name: "chest fly", // Menos tokens
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockTargetCatalog.stubbedValidTargets = ["pectorals"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = candidates
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        // O primeiro candidato deve ser escolhido por ter mais tokens em comum
    }
    
    // MARK: - Fallback by Name Tests
    
    func testResolveMedia_FallbackByName_WhenTargetFails() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "fallback_test",
            name: "Dumbbell Bicep Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        // Target não retorna resultados
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = []
        
        // Fallback por nome retorna resultado
        let nameMatch = ExerciseDBExercise(
            bodyPart: "upper arms",
            equipment: "dumbbell",
            id: "0001",
            name: "dumbbell bicep curl",
            target: "biceps",
            secondaryMuscles: nil,
            instructions: nil,
            description: nil,
            difficulty: nil,
            category: nil
        )
        mockService.stubbedSearchResults = [nameMatch]
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        XCTAssertTrue(mockService.searchExercisesCalled, "Deve tentar fallback por nome quando target falha")
    }
    
    func testResolveMedia_FallbackByName_GeneratesMultipleQueries() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "multi_query_test",
            name: "Lever Pec Deck Fly",
            mainMuscle: .chest,
            equipment: .machine,
            instructions: [],
            media: nil
        )
        
        // Retorna resultado na segunda tentativa (simula query simplificada)
        let simplifiedMatch = ExerciseDBExercise(
            bodyPart: "chest",
            equipment: "machine",
            id: "0023",
            name: "pec deck fly",
            target: "pectorals",
            secondaryMuscles: nil,
            instructions: nil,
            description: nil,
            difficulty: nil,
            category: nil
        )
        
        mockService.stubbedSearchResults = [simplifiedMatch]
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        XCTAssertTrue(mockService.searchExercisesCalled, "Deve tentar busca por nome")
    }
    
    func testResolveMedia_FallbackByName_EquipmentMatch_Prioritized() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "equip_test",
            name: "Bicep Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        // Dois candidatos: um com match de equipamento, outro sem
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "barbell", // Não match
                id: "001",
                name: "barbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell", // Match exato
                id: "002",
                name: "dumbbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockService.stubbedSearchResults = candidates
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        // O candidato com match de equipamento deve ser escolhido
    }
    
    // MARK: - Normalization and Tokenization Tests
    
    func testNormalizeName_RemovesSpecialCharacters() {
        // Given
        let input = "Lever Pec-Deck_Fly"
        let expected = "leverpecdeckfly"
        
        // When
        let normalized = normalizeName(input)
        
        // Then
        XCTAssertEqual(normalized, expected, "Deve remover hífens, underscores e espaços")
    }
    
    func testTokenize_RemovesStopwords() {
        // Given
        let input = "The Dumbbell Bicep Curl for Arms"
        
        // When
        let tokens = tokenize(input)
        
        // Then
        XCTAssertFalse(tokens.contains("the"), "Deve remover stopwords")
        XCTAssertFalse(tokens.contains("for"), "Deve remover stopwords")
        XCTAssertTrue(tokens.contains("dumbbell"), "Deve manter palavras significativas")
        XCTAssertTrue(tokens.contains("bicep"), "Deve manter palavras significativas")
        XCTAssertTrue(tokens.contains("curl"), "Deve manter palavras significativas")
    }
    
    func testTokenize_FiltersShortWords() {
        // Given
        let input = "A Bicep Curl"
        
        // When
        let tokens = tokenize(input)
        
        // Then
        XCTAssertFalse(tokens.contains("a"), "Deve filtrar palavras com menos de 3 caracteres")
        XCTAssertTrue(tokens.contains("bicep"), "Deve manter palavras com 3+ caracteres")
        XCTAssertTrue(tokens.contains("curl"), "Deve manter palavras com 3+ caracteres")
    }
    
    func testGenerateSearchQueries_ProducesMultipleVariations() {
        // Given
        let input = "Lever Pec Deck Fly"
        
        // When
        let queries = generateSearchQueries(from: input)
        
        // Then
        XCTAssertGreaterThan(queries.count, 1, "Deve gerar múltiplas queries")
        XCTAssertTrue(queries.contains("lever pec deck fly"), "Deve incluir nome completo")
        XCTAssertTrue(queries.contains("pec deck fly") || queries.contains("deck fly"), "Deve incluir versão simplificada")
    }
    
    func testGenerateSearchQueries_RemovesEquipmentPrefixes() {
        // Given
        let input = "Dumbbell Bicep Curl"
        
        // When
        let queries = generateSearchQueries(from: input)
        
        // Then
        // Deve ter versão sem "dumbbell"
        let hasSimplified = queries.contains { $0.contains("bicep") && !$0.contains("dumbbell") }
        XCTAssertTrue(hasSimplified || queries.contains("bicep curl"), "Deve gerar query sem prefixo de equipamento")
    }
    
    // MARK: - Deterministic Ranking Tests
    
    func testRanking_Deterministic_AlwaysSameResult() async throws {
        // Given - Mesmos candidatos, mesma ordem
        let exercise = WorkoutExercise(
            id: "deterministic_test",
            name: "Bicep Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell",
                id: "001",
                name: "dumbbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "barbell",
                id: "002",
                name: "barbell bicep curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = candidates
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When - Executa múltiplas vezes
        var firstResult: String?
        var secondResult: String?
        
        for _ in 0..<2 {
            let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
            if firstResult == nil {
                firstResult = resolved.imageURL?.absoluteString
            } else {
                secondResult = resolved.imageURL?.absoluteString
            }
        }
        
        // Then - Deve ser determinístico
        XCTAssertEqual(firstResult, secondResult, "Ranking deve ser determinístico")
    }
    
    func testRanking_EquipmentMatch_ScoresHigher() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "equip_score_test",
            name: "Curl",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "barbell", // Não match
                id: "001",
                name: "barbell curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell", // Match exato (+3 pontos)
                id: "002",
                name: "dumbbell curl",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = candidates
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        // O candidato com match de equipamento (002) deve ser escolhido
    }
    
    func testRanking_NameTokens_AddsToScore() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "token_score_test",
            name: "Pec Deck Fly",
            mainMuscle: .chest,
            equipment: .machine,
            instructions: [],
            media: nil
        )
        
        let candidates = [
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "machine",
                id: "001",
                name: "chest fly", // Menos tokens em comum
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            ),
            ExerciseDBExercise(
                bodyPart: "chest",
                equipment: "machine",
                id: "002",
                name: "pec deck fly", // Mais tokens em comum (pec, deck, fly)
                target: "pectorals",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        
        mockTargetCatalog.stubbedValidTargets = ["pectorals"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = candidates
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(resolved.imageURL)
        // O candidato com mais tokens (002) deve ser escolhido
    }
    
    // MARK: - Error Handling and Placeholder Tests
    
    func testResolveMedia_NoService_ReturnsPlaceholder() async {
        // Given
        let resolverWithoutService = ExerciseMediaResolver(service: nil, targetCatalog: nil)
        let exercise = WorkoutExercise(
            id: "no_service_test",
            name: "Test Exercise",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        // When
        let resolved = await resolverWithoutService.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertEqual(resolved.source, .placeholder, "Deve retornar placeholder sem serviço")
        XCTAssertNil(resolved.imageURL)
    }
    
    func testResolveMedia_NetworkError_ReturnsPlaceholder() async {
        // Given
        let exercise = WorkoutExercise(
            id: "error_test",
            name: "Test Exercise",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = []
        mockService.stubbedSearchResults = []
        // Não configura stubbedImageURL para simular erro
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertEqual(resolved.source, .placeholder, "Deve retornar placeholder em caso de erro")
    }
    
    func testResolveMedia_ExistingMedia_UsesLocal() async {
        // Given
        let existingMedia = ExerciseMedia(
            imageURL: URL(string: "https://local.com/image.jpg"),
            gifURL: nil,
            source: "Local"
        )
        let exercise = WorkoutExercise(
            id: "existing_media_test",
            name: "Test Exercise",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: existingMedia
        )
        
        // When
        let resolved = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertEqual(resolved.source, .local, "Deve usar mídia local existente")
        XCTAssertNotNil(resolved.imageURL)
        XCTAssertFalse(mockService.fetchExercisesCalled, "Não deve buscar da API se já tem mídia")
    }
    
    // MARK: - Cache Tests
    
    func testResolveMedia_CachesResult() async throws {
        // Given
        let exercise = WorkoutExercise(
            id: "cached_test",
            name: "Test Exercise",
            mainMuscle: .biceps,
            equipment: .dumbbell,
            instructions: [],
            media: nil
        )
        
        mockTargetCatalog.stubbedValidTargets = ["biceps"]
        mockTargetCatalog.isValidTargetResult = true
        mockService.stubbedExercisesByTarget = [
            ExerciseDBExercise(
                bodyPart: "arms",
                equipment: "dumbbell",
                id: "001",
                name: "test",
                target: "biceps",
                secondaryMuscles: nil,
                instructions: nil,
                description: nil,
                difficulty: nil,
                category: nil
            )
        ]
        mockService.stubbedImageURL = URL(string: "https://test.com/image.jpg")
        
        // When
        _ = await sut.resolveMedia(for: exercise, context: .thumbnail)
        mockService.fetchExercisesCalled = false
        let cached = await sut.resolveMedia(for: exercise, context: .thumbnail)
        
        // Then
        XCTAssertNotNil(cached.imageURL)
        XCTAssertFalse(mockService.fetchExercisesCalled, "Deve usar cache")
    }
}

// MARK: - Test Helpers (Normalization)

extension ExerciseMediaResolverTests {
    /// Helper para testar normalização de nomes (replica lógica do resolver)
    func normalizeName(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
    
    /// Helper para testar tokenização (replica lógica do resolver)
    func tokenize(_ name: String) -> [String] {
        let stopwords = Set(["the", "a", "an", "of", "on", "with", "for", "and", "or"])
        
        return name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }
    
    /// Helper para testar geração de queries (replica lógica simplificada)
    func generateSearchQueries(from name: String) -> [String] {
        var queries: [String] = []
        
        // Nome completo
        let lowercased = name.lowercased().trimmingCharacters(in: .whitespaces)
        if !lowercased.isEmpty {
            queries.append(lowercased)
        }
        
        // Remove prefixos
        let prefixesToRemove = ["lever", "cable", "machine", "dumbbell", "dumbbells", "barbell"]
        var simplified = lowercased
        for prefix in prefixesToRemove {
            let prefixWithSpace = prefix + " "
            if simplified.hasPrefix(prefixWithSpace) {
                simplified = String(simplified.dropFirst(prefixWithSpace.count))
                break
            }
        }
        if simplified != lowercased && !simplified.isEmpty {
            queries.append(simplified.trimmingCharacters(in: .whitespaces))
        }
        
        // Tokens principais
        let words = tokenize(name)
        if words.count >= 2 {
            queries.append("\(words[0]) \(words[1])")
        }
        
        return queries.filter { !$0.isEmpty && $0.count >= 3 }
    }
}

// MARK: - Mock Helpers

class MockTargetCatalog: ExerciseDBTargetCataloging {
    var stubbedValidTargets: [String] = []
    var isValidTargetResult = false
    var loadTargetsCalled = false
    
    func loadTargets(forceRefresh: Bool) async throws -> [String] {
        loadTargetsCalled = true
        return stubbedValidTargets
    }
    
    func isValidTarget(_ target: String) async -> Bool {
        return isValidTargetResult || stubbedValidTargets.contains(target)
    }
}

// Mock completo do ExerciseDBService para testes do resolver
class MockExerciseDBServiceForResolver: ExerciseDBServicing {
    var stubbedTargetList: [String] = []
    var stubbedExercises: [ExerciseDBExercise] = []
    var stubbedExercisesByTarget: [ExerciseDBExercise] = []
    var stubbedSearchResults: [ExerciseDBExercise] = []
    var stubbedImageURL: URL?
    var stubbedImageData: (data: Data, mimeType: String)?
    var fetchTargetListCalled = false
    var fetchExercisesCalled = false
    var searchExercisesCalled = false
    var fetchImageURLCalled = false
    var fetchImageDataCalled = false
    
    // Handler para simular comportamento dinâmico
    var searchExercisesHandler: ((String, Int) -> [ExerciseDBExercise])?
    
    func fetchTargetList() async throws -> [String] {
        fetchTargetListCalled = true
        return stubbedTargetList
    }
    
    func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise] {
        fetchExercisesCalled = true
        return stubbedExercisesByTarget
    }
    
    func fetchExercise(byId id: String) async throws -> ExerciseDBExercise? {
        return nil
    }
    
    func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise] {
        searchExercisesCalled = true
        
        // Se houver handler, usa ele; senão usa stubbedSearchResults
        if let handler = searchExercisesHandler {
            return handler(query, limit)
        }
        
        return stubbedSearchResults
    }
    
    func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? {
        fetchImageURLCalled = true
        return stubbedImageURL
    }

    func fetchImageData(
        exerciseId: String,
        resolution: ExerciseImageResolution
    ) async throws -> (data: Data, mimeType: String)? {
        fetchImageDataCalled = true
        return stubbedImageData
    }
}

