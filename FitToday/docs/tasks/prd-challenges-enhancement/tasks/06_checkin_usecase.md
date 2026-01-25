# Task 6.0: Implementar CheckInUseCase

**Status:** ⬜ Não iniciado
**Dependência:** 3.0, 5.0
**Fase:** 3 - Domain Layer

---

## Objetivo

Implementar a lógica de negócio do check-in com validações.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Domain/UseCases/CheckInUseCase.swift` | Use case principal |

---

## Regras de Negócio

| Regra | Validação |
|-------|-----------|
| Duração mínima | ≥ 30 minutos |
| Foto | Obrigatória |
| Conexão | Requer internet |
| Grupo | Usuário deve estar em grupo |
| Tamanho foto | ≤ 500KB após compressão |

---

## Implementação

```swift
struct CheckInUseCase: Sendable {
    private let checkInRepository: CheckInRepository
    private let authRepository: AuthenticationRepository
    private let leaderboardRepository: LeaderboardRepository
    private let imageCompressor: ImageCompressing
    private let networkMonitor: NetworkMonitor

    private static let minimumWorkoutMinutes = 30
    private static let maxImageSizeBytes = 500_000

    func execute(
        workoutEntry: WorkoutHistoryEntry,
        photoData: Data
    ) async throws -> CheckIn {
        // 1. Validate network
        guard networkMonitor.isConnected else {
            throw CheckInError.networkUnavailable
        }

        // 2. Validate user is in group
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else {
            throw CheckInError.notInGroup
        }

        // 3. Validate workout duration
        let duration = workoutEntry.durationMinutes ?? 0
        guard duration >= Self.minimumWorkoutMinutes else {
            throw CheckInError.workoutTooShort(minutes: duration)
        }

        // 4. Compress image
        let compressed = try imageCompressor.compress(
            data: photoData,
            maxBytes: Self.maxImageSizeBytes,
            quality: 0.7
        )

        // 5. Upload photo
        let photoURL = try await checkInRepository.uploadPhoto(
            imageData: compressed,
            groupId: groupId,
            userId: user.id
        )

        // 6. Get current challenge
        let challenges = try await leaderboardRepository.getCurrentWeekChallenges(groupId: groupId)
        let challengeId = challenges.first(where: { $0.type == .checkIns })?.id ?? ""

        // 7. Create check-in record
        let checkIn = CheckIn(
            id: UUID().uuidString,
            groupId: groupId,
            challengeId: challengeId,
            userId: user.id,
            displayName: user.displayName,
            userPhotoURL: user.photoURL,
            checkInPhotoURL: photoURL,
            workoutEntryId: workoutEntry.id,
            workoutDurationMinutes: duration,
            createdAt: Date()
        )

        try await checkInRepository.createCheckIn(checkIn)

        // 8. Increment challenge counter
        if !challengeId.isEmpty {
            try await leaderboardRepository.incrementCheckIn(
                challengeId: challengeId,
                userId: user.id
            )
        }

        return checkIn
    }
}
```

---

## Critérios de Aceite

- [ ] Rejeita treino < 30 minutos
- [ ] Rejeita se offline
- [ ] Rejeita se não está em grupo
- [ ] Comprime foto antes do upload
- [ ] Incrementa contador do challenge
- [ ] Retorna CheckIn criado

---

## Subtasks

- [ ] 6.1 Criar arquivo `CheckInUseCase.swift`
- [ ] 6.2 Implementar validações
- [ ] 6.3 Implementar fluxo de upload
- [ ] 6.4 Integrar com LeaderboardRepository
- [ ] 6.5 Escrever testes unitários
