# Tasks: Migrar Programas para API Wger

## Fase 1: Core Infrastructure (P0)

### Task 1.1: Criar WorkoutTemplateType enum
**Arquivo:** `Domain/Entities/WorkoutTemplateType.swift`
**Estimativa:** 15min
**Dependências:** Nenhuma

- [ ] Criar enum `WorkoutTemplateType` com cases: push, pull, legs, fullbody, core, hiit, upper, lower, conditioning
- [ ] Implementar propriedade `wgerCategoryIds: [Int]` com mapeamento para IDs de categorias Wger
- [ ] Implementar `static func from(templateId: String) -> WorkoutTemplateType?`
- [ ] Adicionar conformância a `CaseIterable` e `Sendable`

### Task 1.2: Criar ProgramWorkout entity
**Arquivo:** `Domain/Entities/ProgramWorkout.swift`
**Estimativa:** 20min
**Dependências:** Task 1.1

- [ ] Criar struct `ProgramWorkout` com: id, templateId, title, subtitle, estimatedDurationMinutes, exercises
- [ ] Criar nested struct `ProgramExercise` com: id, wgerExercise, sets, repsRange, restSeconds, notes, order
- [ ] Conformância a `Identifiable` e `Sendable`

### Task 1.3: Criar WgerProgramWorkoutRepository protocol
**Arquivo:** `Domain/Repositories/WgerProgramWorkoutRepository.swift`
**Estimativa:** 15min
**Dependências:** Task 1.2

- [ ] Criar protocol `WgerProgramWorkoutRepository`
- [ ] Método `loadWorkoutExercises(templateId:exerciseCount:) async throws -> [WgerExercise]`
- [ ] Método `saveCustomization(programId:workoutId:exerciseIds:order:) async throws`
- [ ] Método `loadCustomization(programId:workoutId:) async throws -> WorkoutCustomization?`
- [ ] Criar struct `WorkoutCustomization` com exerciseIds, order, updatedAt

### Task 1.4: Implementar DefaultWgerProgramWorkoutRepository
**Arquivo:** `Data/Repositories/DefaultWgerProgramWorkoutRepository.swift`
**Estimativa:** 45min
**Dependências:** Task 1.3

- [ ] Criar actor `DefaultWgerProgramWorkoutRepository` conformando ao protocol
- [ ] Injetar `ExerciseServiceProtocol` e `UserDefaults`
- [ ] Implementar cache em memória `exerciseCache: [Int: [WgerExercise]]`
- [ ] Implementar `loadWorkoutExercises` usando `WorkoutTemplateType.from()` e `wgerService.fetchExercises()`
- [ ] Implementar `saveCustomization` e `loadCustomization` com UserDefaults
- [ ] Criar enum `WgerProgramError` para erros específicos

### Task 1.5: Criar LoadProgramWorkoutsUseCase
**Arquivo:** `Domain/UseCases/LoadProgramWorkoutsUseCase.swift`
**Estimativa:** 30min
**Dependências:** Task 1.4

- [ ] Criar struct `LoadProgramWorkoutsUseCase`
- [ ] Injetar `ProgramRepository` e `WgerProgramWorkoutRepository`
- [ ] Implementar `execute(programId:) async throws -> [ProgramWorkout]`
- [ ] Iterar sobre `program.workoutTemplateIds` e carregar exercícios de cada
- [ ] Implementar helpers `workoutTitle(for:index:)` e `workoutSubtitle(for:)`
- [ ] Criar enum `LoadProgramError`

---

## Fase 2: Integração com Views (P1)

### Task 2.1: Atualizar ProgramDetailViewModel
**Arquivo:** `Presentation/Features/Programs/ProgramDetailViewModel.swift`
**Estimativa:** 30min
**Dependências:** Task 1.5

- [ ] Remover dependência de `LibraryWorkoutsRepository`
- [ ] Adicionar dependência de `LoadProgramWorkoutsUseCase`
- [ ] Mudar propriedade `workouts: [LibraryWorkout]` para `workouts: [ProgramWorkout]`
- [ ] Atualizar método `load()` para usar `LoadProgramWorkoutsUseCase.execute()`
- [ ] Adicionar logs de debug para exercícios carregados

### Task 2.2: Atualizar ProgramDetailView
**Arquivo:** `Presentation/Features/Programs/ProgramDetailView.swift`
**Estimativa:** 45min
**Dependências:** Task 2.1

- [ ] Atualizar init para receber `LoadProgramWorkoutsUseCase` em vez de `LibraryWorkoutsRepository`
- [ ] Atualizar `workoutsSection` para usar `[ProgramWorkout]`
- [ ] Atualizar `WorkoutRowCard` para mostrar número de exercícios de `ProgramWorkout`
- [ ] Navegar para `ProgramWorkoutDetailView` ao clicar em treino

### Task 2.3: Criar ProgramWorkoutDetailView
**Arquivo:** `Presentation/Features/Programs/Views/ProgramWorkoutDetailView.swift`
**Estimativa:** 60min
**Dependências:** Task 2.2

- [ ] Criar view para exibir exercícios do treino
- [ ] List com `ForEach` dos exercícios
- [ ] Implementar `.onMove` para reordenação
- [ ] Implementar `.onDelete` para remoção
- [ ] Mostrar imagem do exercício via `AsyncImage` da URL Wger
- [ ] Mostrar sets/reps e notas

### Task 2.4: Criar ExerciseRowView component
**Arquivo:** `Presentation/Features/Programs/Components/ExerciseRowView.swift`
**Estimativa:** 30min
**Dependências:** Task 2.3

- [ ] HStack com imagem, nome, sets/reps
- [ ] AsyncImage com placeholder de ícone SF Symbols
- [ ] Fallback visual quando sem imagem
- [ ] Indicador de loading durante fetch de imagem

---

## Fase 3: Adicionar Exercícios (P1)

### Task 3.1: Adicionar botão "Adicionar Exercício" na ProgramWorkoutDetailView
**Arquivo:** `Presentation/Features/Programs/Views/ProgramWorkoutDetailView.swift`
**Estimativa:** 20min
**Dependências:** Task 2.3

- [ ] Botão na toolbar ou no final da lista
- [ ] State `showAddExercise: Bool`
- [ ] Sheet para `ExerciseSearchSheet` existente

### Task 3.2: Conectar ExerciseSearchSheet com ProgramWorkout
**Arquivo:** `Presentation/Features/Programs/Views/ProgramWorkoutDetailView.swift`
**Estimativa:** 30min
**Dependências:** Task 3.1

- [ ] Callback `onSelect: (WgerExercise) -> Void`
- [ ] Adicionar exercício selecionado ao array `exercises`
- [ ] Criar `ProgramWorkout.ProgramExercise` com valores default (4 sets, 8-12 reps)

---

## Fase 4: Persistência de Customizações (P2)

### Task 4.1: Implementar SaveWorkoutCustomizationUseCase
**Arquivo:** `Domain/UseCases/SaveWorkoutCustomizationUseCase.swift`
**Estimativa:** 20min
**Dependências:** Task 1.4

- [ ] Criar struct `SaveWorkoutCustomizationUseCase`
- [ ] Método `execute(programId:workoutId:exercises:) async throws`
- [ ] Extrair IDs e ordem dos exercícios
- [ ] Chamar `workoutRepository.saveCustomization()`

### Task 4.2: Carregar customizações no LoadProgramWorkoutsUseCase
**Arquivo:** `Domain/UseCases/LoadProgramWorkoutsUseCase.swift`
**Estimativa:** 30min
**Dependências:** Task 4.1

- [ ] Antes de retornar workouts, verificar se existe customização
- [ ] Se existe, aplicar ordem e exercícios customizados
- [ ] Buscar exercícios específicos por ID se necessário

### Task 4.3: Salvar automaticamente ao sair da view
**Arquivo:** `Presentation/Features/Programs/Views/ProgramWorkoutDetailView.swift`
**Estimativa:** 20min
**Dependências:** Task 4.2

- [ ] `.onDisappear` salvar customização se houve mudanças
- [ ] Flag `hasChanges: Bool` para tracking
- [ ] Chamar `SaveWorkoutCustomizationUseCase`

---

## Fase 5: Registro de Dependências (P0)

### Task 5.1: Registrar novos componentes no AppContainer
**Arquivo:** `Presentation/DI/AppContainer.swift`
**Estimativa:** 15min
**Dependências:** Tasks 1.4, 1.5, 4.1

- [ ] Registrar `WgerProgramWorkoutRepository` como `DefaultWgerProgramWorkoutRepository`
- [ ] Registrar `LoadProgramWorkoutsUseCase`
- [ ] Registrar `SaveWorkoutCustomizationUseCase`
- [ ] Usar `.inObjectScope(.container)` para singletons

### Task 5.2: Atualizar init de ProgramDetailView para novas dependências
**Arquivo:** `Presentation/Features/Programs/ProgramDetailView.swift`
**Estimativa:** 15min
**Dependências:** Task 5.1

- [ ] Resolver `LoadProgramWorkoutsUseCase` do container
- [ ] Remover resolução de `LibraryWorkoutsRepository`
- [ ] Atualizar criação do ViewModel

---

## Fase 6: Navegação (P1)

### Task 6.1: Adicionar rota para ProgramWorkoutDetailView
**Arquivo:** `Presentation/Navigation/AppRouter.swift`
**Estimativa:** 15min
**Dependências:** Task 2.3

- [ ] Adicionar case `.programWorkoutDetail(ProgramWorkout)` no enum de rotas
- [ ] Implementar navigation destination

### Task 6.2: Atualizar navegação no ProgramDetailView
**Arquivo:** `Presentation/Features/Programs/ProgramDetailView.swift`
**Estimativa:** 10min
**Dependências:** Task 6.1

- [ ] Ao clicar em `WorkoutRowCard`, navegar para `.programWorkoutDetail(workout)`
- [ ] Passar `ProgramWorkout` completo com exercícios

---

## Resumo de Prioridades

| Fase | Tasks | Prioridade | Bloqueadores |
|------|-------|------------|--------------|
| 1 | 1.1-1.5 | P0 | Nenhum |
| 5 | 5.1-5.2 | P0 | Fase 1 |
| 2 | 2.1-2.4 | P1 | Fases 1, 5 |
| 6 | 6.1-6.2 | P1 | Fase 2 |
| 3 | 3.1-3.2 | P1 | Fase 2 |
| 4 | 4.1-4.3 | P2 | Fases 1, 3 |

## Ordem de Execução Recomendada

1. Task 1.1 → Task 1.2 → Task 1.3 → Task 1.4 → Task 1.5
2. Task 5.1 → Task 5.2
3. Task 2.1 → Task 2.2 → Task 2.3 → Task 2.4
4. Task 6.1 → Task 6.2
5. Task 3.1 → Task 3.2
6. Task 4.1 → Task 4.2 → Task 4.3

## Critérios de Done

- [ ] Todos os 26 programas carregam na lista
- [ ] Ao abrir um programa, exercícios são carregados da API Wger
- [ ] Exercícios mostram imagens quando disponíveis
- [ ] Usuário pode reordenar exercícios
- [ ] Usuário pode adicionar exercícios
- [ ] Usuário pode remover exercícios
- [ ] Build sem erros
- [ ] App não crasha ao navegar entre programas
