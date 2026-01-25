# Task 2.0: Criar Firebase Storage Service

**Status:** ⬜ Não iniciado
**Dependência:** Nenhuma
**Fase:** 1 - Infraestrutura

---

## Objetivo

Criar serviço para upload de imagens no Firebase Storage.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Data/Services/Firebase/FirebaseStorageService.swift` | Actor para upload/delete de imagens |

---

## Implementação

### 2.1 Criar Protocol

```swift
protocol StorageServicing: Sendable {
    func uploadImage(data: Data, path: String) async throws -> URL
    func deleteImage(path: String) async throws
}
```

### 2.2 Criar Actor

```swift
actor FirebaseStorageService: StorageServicing {
    private let storage = Storage.storage()

    func uploadImage(data: Data, path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    func deleteImage(path: String) async throws {
        let ref = storage.reference().child(path)
        try await ref.delete()
    }
}
```

---

## Critérios de Aceite

- [ ] Actor é thread-safe (Sendable)
- [ ] Upload retorna URL válida do Firebase Storage
- [ ] Metadata define content-type como image/jpeg
- [ ] Erro de upload é propagado corretamente

---

## Subtasks

- [ ] 2.1 Criar arquivo `FirebaseStorageService.swift`
- [ ] 2.2 Implementar protocol `StorageServicing`
- [ ] 2.3 Implementar actor `FirebaseStorageService`
- [ ] 2.4 Testar upload manualmente
