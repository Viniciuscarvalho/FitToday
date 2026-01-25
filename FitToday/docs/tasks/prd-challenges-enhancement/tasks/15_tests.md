# Task 15.0: Escrever Testes Unitários

**Status:** ⬜ Não iniciado
**Dependência:** 6.0, 7.0
**Fase:** 6 - Finalização

---

## Objetivo

Escrever testes unitários para os componentes críticos.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `FitTodayTests/Domain/UseCases/CheckInUseCaseTests.swift` | Testes do use case |
| `FitTodayTests/Data/Services/ImageCompressorTests.swift` | Testes de compressão |
| `FitTodayTests/Mocks/MockCheckInRepository.swift` | Mock do repository |

---

## Cenários de Teste

### 15.1 CheckInUseCase

| Cenário | Comportamento Esperado |
|---------|------------------------|
| Treino < 30 min | Lança `CheckInError.workoutTooShort` |
| Usuário sem grupo | Lança `CheckInError.notInGroup` |
| Sem conexão | Lança `CheckInError.networkUnavailable` |
| Sucesso | Retorna CheckIn válido |
| Upload falha | Lança `CheckInError.uploadFailed` |

### 15.2 ImageCompressor

| Cenário | Comportamento Esperado |
|---------|------------------------|
| Imagem válida | Retorna Data ≤ 500KB |
| Imagem grande | Reduz qualidade até caber |
| Dados inválidos | Lança `CompressionError.invalidImage` |

---

## Implementação

### Mock Repository

```swift
final class MockCheckInRepository: CheckInRepository, @unchecked Sendable {
    var createCheckInCalled = false
    var uploadPhotoCalled = false
    var uploadPhotoResult: Result<URL, Error> = .success(URL(string: "https://example.com/photo.jpg")!)
    var checkInsToReturn: [CheckIn] = []

    func createCheckIn(_ checkIn: CheckIn) async throws {
        createCheckInCalled = true
    }

    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn] {
        return checkInsToReturn
    }

    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]> {
        AsyncStream { continuation in
            continuation.yield(checkInsToReturn)
            continuation.finish()
        }
    }

    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL {
        uploadPhotoCalled = true
        return try uploadPhotoResult.get()
    }
}
```

### CheckInUseCaseTests

```swift
@Suite("CheckInUseCase Tests")
struct CheckInUseCaseTests {

    @Test("Rejects workout under 30 minutes")
    func testRejectsShortWorkout() async throws {
        let useCase = makeUseCase()
        let entry = WorkoutHistoryEntry(
            planId: UUID(),
            title: "Test",
            focus: .fullBody,
            status: .completed,
            durationMinutes: 20  // < 30
        )

        await #expect(throws: CheckInError.workoutTooShort(minutes: 20)) {
            try await useCase.execute(workoutEntry: entry, photoData: testImageData())
        }
    }

    @Test("Rejects when user not in group")
    func testRejectsNotInGroup() async throws {
        let useCase = makeUseCase(userInGroup: false)
        let entry = makeValidEntry()

        await #expect(throws: CheckInError.notInGroup) {
            try await useCase.execute(workoutEntry: entry, photoData: testImageData())
        }
    }

    @Test("Rejects when offline")
    func testRejectsWhenOffline() async throws {
        let useCase = makeUseCase(isConnected: false)
        let entry = makeValidEntry()

        await #expect(throws: CheckInError.networkUnavailable) {
            try await useCase.execute(workoutEntry: entry, photoData: testImageData())
        }
    }

    @Test("Creates check-in successfully")
    func testSuccess() async throws {
        let mockRepo = MockCheckInRepository()
        let useCase = makeUseCase(checkInRepository: mockRepo)
        let entry = makeValidEntry()

        let result = try await useCase.execute(workoutEntry: entry, photoData: testImageData())

        #expect(mockRepo.createCheckInCalled)
        #expect(mockRepo.uploadPhotoCalled)
        #expect(result.workoutDurationMinutes == 45)
    }

    // MARK: - Helpers

    private func makeUseCase(
        checkInRepository: CheckInRepository = MockCheckInRepository(),
        userInGroup: Bool = true,
        isConnected: Bool = true
    ) -> CheckInUseCase {
        // Setup mocks...
    }

    private func makeValidEntry() -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            planId: UUID(),
            title: "Test Workout",
            focus: .fullBody,
            status: .completed,
            durationMinutes: 45
        )
    }

    private func testImageData() -> Data {
        // Return minimal valid JPEG data
    }
}
```

### ImageCompressorTests

```swift
@Suite("ImageCompressor Tests")
struct ImageCompressorTests {

    @Test("Output is under max size")
    func testOutputUnderMaxSize() throws {
        let compressor = ImageCompressor()
        let largeImage = makeLargeTestImage()

        let result = try compressor.compress(
            data: largeImage,
            maxBytes: 500_000,
            quality: 0.7
        )

        #expect(result.count <= 500_000)
    }

    @Test("Invalid data throws error")
    func testInvalidDataThrows() {
        let compressor = ImageCompressor()
        let invalidData = Data([0x00, 0x01, 0x02])

        #expect(throws: ImageCompressor.CompressionError.invalidImage) {
            try compressor.compress(data: invalidData, maxBytes: 500_000, quality: 0.7)
        }
    }
}
```

---

## Critérios de Aceite

- [ ] Cobertura ≥ 80% no CheckInUseCase
- [ ] Todos os cenários de erro testados
- [ ] Mocks implementados
- [ ] Testes passam no CI

---

## Subtasks

- [ ] 15.1 Criar `MockCheckInRepository`
- [ ] 15.2 Implementar `CheckInUseCaseTests`
- [ ] 15.3 Implementar `ImageCompressorTests`
- [ ] 15.4 Rodar testes e verificar cobertura
