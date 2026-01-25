# Task 5.0: Implementar FirebaseCheckInRepository

**Status:** ⬜ Não iniciado
**Dependência:** 2.0, 4.0
**Fase:** 2 - Data Layer

---

## Objetivo

Implementar o repositório concreto para check-ins usando Firestore e Storage.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Data/Repositories/FirebaseCheckInRepository.swift` | Implementação do repository |

---

## Firestore Structure

```
/groups/{groupId}/checkIns/{checkInId}
  ├── userId: string
  ├── displayName: string
  ├── userPhotoURL: string?
  ├── checkInPhotoURL: string
  ├── challengeId: string
  ├── workoutEntryId: string
  ├── workoutDurationMinutes: int
  └── createdAt: timestamp

/storage/checkIns/{groupId}/{userId}/{timestamp}.jpg
```

---

## Implementação

```swift
actor FirebaseCheckInRepository: CheckInRepository {
    private let db = Firestore.firestore()
    private let storageService: StorageServicing

    init(storageService: StorageServicing) {
        self.storageService = storageService
    }

    func createCheckIn(_ checkIn: CheckIn) async throws {
        let ref = db.collection("groups")
            .document(checkIn.groupId)
            .collection("checkIns")
            .document(checkIn.id)

        let fbCheckIn = FBCheckIn(from: checkIn)
        try await ref.setData(from: fbCheckIn)
    }

    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn] {
        var query = db.collection("groups")
            .document(groupId)
            .collection("checkIns")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after = after {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: after))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap {
            try? $0.data(as: FBCheckIn.self).toDomain()
        }
    }

    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]> {
        AsyncStream { continuation in
            let listener = db.collection("groups")
                .document(groupId)
                .collection("checkIns")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, _ in
                    guard let docs = snapshot?.documents else { return }
                    let checkIns = docs.compactMap {
                        try? $0.data(as: FBCheckIn.self).toDomain()
                    }
                    continuation.yield(checkIns)
                }

            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "checkIns/\(groupId)/\(userId)/\(timestamp).jpg"
        return try await storageService.uploadImage(data: imageData, path: path)
    }
}
```

---

## Critérios de Aceite

- [ ] Actor é thread-safe
- [ ] Upload gera path único por timestamp
- [ ] Observe usa real-time listener
- [ ] Paginação funciona com `after` date
- [ ] Limite de 50 check-ins no observe

---

## Subtasks

- [ ] 5.1 Criar arquivo `FirebaseCheckInRepository.swift`
- [ ] 5.2 Implementar `createCheckIn`
- [ ] 5.3 Implementar `getCheckIns` com paginação
- [ ] 5.4 Implementar `observeCheckIns` com real-time
- [ ] 5.5 Implementar `uploadPhoto`
