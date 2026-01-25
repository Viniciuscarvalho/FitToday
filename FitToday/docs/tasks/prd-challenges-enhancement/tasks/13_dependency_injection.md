# Task 13.0: Registrar Dependências no AppContainer

**Status:** ⬜ Não iniciado
**Dependência:** 6.0
**Fase:** 5 - Integração

---

## Objetivo

Registrar todos os novos serviços e use cases no container de DI.

---

## Arquivos a Modificar

| Arquivo | Mudança |
|---------|---------|
| `Presentation/DI/AppContainer.swift` | Adicionar registros |

---

## Registros a Adicionar

### 13.1 Firebase Storage Service

```swift
// Firebase Storage Service
container.register(StorageServicing.self) { _ in
    FirebaseStorageService()
}
.inObjectScope(.container)
```

### 13.2 Image Compressor

```swift
// Image Compressor
container.register(ImageCompressing.self) { _ in
    ImageCompressor()
}
.inObjectScope(.container)
```

### 13.3 Check-In Repository

```swift
// Check-In Repository
container.register(CheckInRepository.self) { resolver in
    FirebaseCheckInRepository(
        storageService: resolver.resolve(StorageServicing.self)!
    )
}
.inObjectScope(.container)
```

### 13.4 Check-In Use Case

```swift
// Check-In Use Case
container.register(CheckInUseCase.self) { resolver in
    CheckInUseCase(
        checkInRepository: resolver.resolve(CheckInRepository.self)!,
        authRepository: resolver.resolve(AuthenticationRepository.self)!,
        leaderboardRepository: resolver.resolve(LeaderboardRepository.self)!,
        imageCompressor: resolver.resolve(ImageCompressing.self)!,
        networkMonitor: resolver.resolve(NetworkMonitor.self)!
    )
}
.inObjectScope(.container)
```

---

## Ordem de Registro

A ordem é importante devido às dependências:

```
1. StorageServicing (sem dependências)
2. ImageCompressing (sem dependências)
3. CheckInRepository (depende de StorageServicing)
4. CheckInUseCase (depende de CheckInRepository + outros)
```

---

## Local no Arquivo

Adicionar após o bloco de `SyncWorkoutCompletionUseCase`:

```swift
// Workout Sync Use Case - syncs workout completion...
container.register(SyncWorkoutCompletionUseCase.self) { ... }

// ========== CHECK-IN SERVICES (NOVO) ==========

// Firebase Storage Service
container.register(StorageServicing.self) { ... }

// Image Compressor
container.register(ImageCompressing.self) { ... }

// Check-In Repository
container.register(CheckInRepository.self) { ... }

// Check-In Use Case
container.register(CheckInUseCase.self) { ... }

// ========== END CHECK-IN SERVICES ==========
```

---

## Critérios de Aceite

- [ ] Todos os 4 registros adicionados
- [ ] Ordem de dependências correta
- [ ] Scope `.container` para todos
- [ ] App compila sem erros
- [ ] Resolver.resolve() funciona para todos

---

## Subtasks

- [ ] 13.1 Adicionar registro StorageServicing
- [ ] 13.2 Adicionar registro ImageCompressing
- [ ] 13.3 Adicionar registro CheckInRepository
- [ ] 13.4 Adicionar registro CheckInUseCase
- [ ] 13.5 Testar resolução de dependências
