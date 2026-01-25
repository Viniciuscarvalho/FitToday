# Task 1.0: Criar Modelos de Domínio CheckIn

**Status:** ⬜ Não iniciado
**Dependência:** Nenhuma
**Fase:** 1 - Infraestrutura

---

## Objetivo

Criar os modelos de domínio para o sistema de check-in com foto.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Domain/Entities/CheckInModels.swift` | Structs e enums do check-in |

---

## Implementação

### 1.1 Criar CheckIn struct

```swift
struct CheckIn: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let challengeId: String
    let userId: String
    var displayName: String
    var userPhotoURL: URL?
    var checkInPhotoURL: URL          // Obrigatória
    let workoutEntryId: UUID
    var workoutDurationMinutes: Int
    let createdAt: Date
}
```

### 1.2 Criar CheckInError enum

```swift
enum CheckInError: Error, LocalizedError {
    case workoutTooShort(minutes: Int)
    case photoRequired
    case uploadFailed(underlying: Error)
    case networkUnavailable
    case notInGroup

    var errorDescription: String? { ... }
}
```

---

## Critérios de Aceite

- [ ] `CheckIn` conforma a `Codable`, `Hashable`, `Sendable`, `Identifiable`
- [ ] `CheckInError` tem mensagens localizadas
- [ ] Código compila sem warnings
- [ ] Segue padrão Swift 6

---

## Subtasks

- [ ] 1.1 Criar arquivo `CheckInModels.swift`
- [ ] 1.2 Implementar struct `CheckIn`
- [ ] 1.3 Implementar enum `CheckInError`
- [ ] 1.4 Adicionar documentação de código
