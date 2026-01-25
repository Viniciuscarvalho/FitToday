# Task 7.0: Criar CheckInViewModel

**Status:** ⬜ Não iniciado
**Dependência:** 6.0
**Fase:** 4 - Presentation Layer

---

## Objetivo

Criar ViewModel para gerenciar estado do check-in com foto.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Presentation/Features/Groups/CheckInViewModel.swift` | ViewModel do check-in |

---

## Implementação

```swift
@MainActor
@Observable
final class CheckInViewModel {
    // MARK: - State
    var selectedImage: UIImage?
    var isLoading = false
    var showError = false
    var errorMessage: String?
    var checkInResult: CheckIn?

    // MARK: - Computed
    var canSubmit: Bool {
        selectedImage != nil && !isLoading
    }

    var hasPhoto: Bool {
        selectedImage != nil
    }

    // MARK: - Dependencies
    private let checkInUseCase: CheckInUseCase
    private let workoutEntry: WorkoutHistoryEntry

    init(
        checkInUseCase: CheckInUseCase,
        workoutEntry: WorkoutHistoryEntry
    ) {
        self.checkInUseCase = checkInUseCase
        self.workoutEntry = workoutEntry
    }

    // MARK: - Actions

    func submitCheckIn() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 1.0) else {
            errorMessage = CheckInError.photoRequired.localizedDescription
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let checkIn = try await checkInUseCase.execute(
                workoutEntry: workoutEntry,
                photoData: imageData
            )
            checkInResult = checkIn
        } catch let error as CheckInError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func clearError() {
        showError = false
        errorMessage = nil
    }

    func clearImage() {
        selectedImage = nil
    }
}
```

---

## Estados

| Estado | Descrição |
|--------|-----------|
| Initial | Sem foto selecionada |
| PhotoSelected | Foto escolhida, pronto para submit |
| Loading | Upload em progresso |
| Success | Check-in criado |
| Error | Erro com mensagem |

---

## Critérios de Aceite

- [ ] Usa @Observable (Swift 6)
- [ ] @MainActor para thread safety
- [ ] Gerencia estados loading/error/success
- [ ] Valida foto antes de submit
- [ ] Propaga erros localizados

---

## Subtasks

- [ ] 7.1 Criar arquivo `CheckInViewModel.swift`
- [ ] 7.2 Implementar state properties
- [ ] 7.3 Implementar `submitCheckIn()`
- [ ] 7.4 Implementar computed properties
- [ ] 7.5 Testar transições de estado
