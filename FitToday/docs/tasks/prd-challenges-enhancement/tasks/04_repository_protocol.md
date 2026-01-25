# Task 4.0: Criar CheckInRepository Protocol + DTO

**Status:** ⬜ Não iniciado
**Dependência:** 1.0
**Fase:** 2 - Data Layer

---

## Objetivo

Definir a interface do repositório de check-ins e criar o DTO Firebase.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Domain/Protocols/SocialRepositories.swift` | Adicionar protocol |
| `Data/Models/FirebaseModels.swift` | Adicionar FBCheckIn |

---

## Implementação

### 4.1 Adicionar Protocol em SocialRepositories.swift

```swift
// MARK: - Check-In Repository

protocol CheckInRepository: Sendable {
    func createCheckIn(_ checkIn: CheckIn) async throws
    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn]
    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]>
    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL
}
```

### 4.2 Adicionar DTO em FirebaseModels.swift

```swift
// MARK: - Check-In DTOs

struct FBCheckIn: Codable {
    @DocumentID var id: String?
    var groupId: String
    var challengeId: String
    var userId: String
    var displayName: String
    var userPhotoURL: String?
    var checkInPhotoURL: String
    var workoutEntryId: String
    var workoutDurationMinutes: Int
    @ServerTimestamp var createdAt: Timestamp?
}

extension FBCheckIn {
    func toDomain() -> CheckIn {
        CheckIn(
            id: id ?? UUID().uuidString,
            groupId: groupId,
            challengeId: challengeId,
            userId: userId,
            displayName: displayName,
            userPhotoURL: userPhotoURL.flatMap(URL.init),
            checkInPhotoURL: URL(string: checkInPhotoURL)!,
            workoutEntryId: UUID(uuidString: workoutEntryId) ?? UUID(),
            workoutDurationMinutes: workoutDurationMinutes,
            createdAt: createdAt?.dateValue() ?? Date()
        )
    }
}
```

---

## Critérios de Aceite

- [ ] Protocol segue padrão Sendable
- [ ] DTO usa @DocumentID e @ServerTimestamp
- [ ] Mapper toDomain() funciona corretamente
- [ ] Código compila sem erros

---

## Subtasks

- [ ] 4.1 Adicionar `CheckInRepository` protocol
- [ ] 4.2 Adicionar `FBCheckIn` DTO
- [ ] 4.3 Implementar extension `toDomain()`
