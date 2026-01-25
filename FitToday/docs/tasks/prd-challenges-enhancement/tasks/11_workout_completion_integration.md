# Task 11.0: Integrar Check-in na WorkoutCompletionView

**Status:** ⬜ Não iniciado
**Dependência:** 8.0
**Fase:** 5 - Integração

---

## Objetivo

Adicionar botão de check-in no fluxo de conclusão de treino.

---

## Arquivos a Modificar

| Arquivo | Mudança |
|---------|---------|
| `Presentation/Features/Workout/WorkoutCompletionView.swift` | Adicionar botão e sheet |

---

## Fluxo

```
1. Usuário conclui treino
2. Vê tela de conclusão
3. Avalia treino (rating)
4. Se está em grupo: vê botão "Fazer Check-in"
5. Abre sheet com CheckInPhotoView
6. Após sucesso: mostra CelebrationOverlay
```

---

## Implementação

### 11.1 Adicionar State

```swift
// Adicionar ao WorkoutCompletionView
@State private var showCheckInSheet = false
@State private var showCelebration = false
@State private var isInGroup = false
@State private var currentEntry: WorkoutHistoryEntry?
```

### 11.2 Verificar se está em grupo

```swift
private func checkGroupMembership() async {
    guard let authRepo = resolver.resolve(AuthenticationRepository.self) else { return }

    do {
        if let user = try await authRepo.currentUser() {
            isInGroup = user.currentGroupId != nil
        }
    } catch {
        isInGroup = false
    }
}
```

### 11.3 Adicionar Botão

```swift
// Após o bloco de rating
if status == .completed && hasRated && isInGroup {
    Button("Fazer Check-in com Foto") {
        showCheckInSheet = true
    }
    .fitPrimaryStyle()
    .padding(.top, FitTodaySpacing.md)
}
```

### 11.4 Adicionar Sheet e Overlay

```swift
.sheet(isPresented: $showCheckInSheet) {
    if let entry = currentEntry,
       let useCase = resolver.resolve(CheckInUseCase.self) {
        CheckInPhotoView(
            viewModel: CheckInViewModel(
                checkInUseCase: useCase,
                workoutEntry: entry
            ),
            workoutEntry: entry,
            onSuccess: { _ in
                showCelebration = true
            }
        )
    }
}
.overlay {
    if showCelebration {
        CelebrationOverlay(type: .checkInComplete)
            .onTapGesture {
                showCelebration = false
            }
            .task {
                try? await Task.sleep(for: .seconds(3))
                showCelebration = false
            }
    }
}
```

### 11.5 Chamar checkGroupMembership no task

```swift
.task {
    await checkProfileCompletion()
    await loadHealthKitAvailability()
    await checkGroupMembership()  // ADICIONAR
    loadCurrentEntry()            // ADICIONAR
}
```

---

## Critérios de Aceite

- [ ] Botão só aparece se usuário está em grupo
- [ ] Botão só aparece após rating
- [ ] Sheet abre com CheckInPhotoView
- [ ] Celebração aparece após sucesso
- [ ] Celebração fecha após 3s ou tap

---

## Subtasks

- [ ] 11.1 Adicionar states
- [ ] 11.2 Implementar `checkGroupMembership()`
- [ ] 11.3 Adicionar botão condicional
- [ ] 11.4 Adicionar sheet
- [ ] 11.5 Adicionar overlay de celebração
- [ ] 11.6 Testar fluxo completo
