# Tasks: Treinos do Personal (Visual Workouts)

## Task 1: Criar modelo PersonalWorkout
**Prioridade**: Alta
**Estimativa**: 15 min
**Arquivos**:
- `FitToday/Domain/Entities/PersonalWorkout.swift` (criar)

**Descrição**:
Criar o modelo de domínio `PersonalWorkout` com todas as propriedades necessárias.

**Critérios de Aceitação**:
- [ ] Struct PersonalWorkout com Identifiable, Hashable, Sendable, Codable
- [ ] Enum FileType (pdf, image)
- [ ] Computed property isNew
- [ ] Computed property fileURLValue

---

## Task 2: Criar PersonalWorkoutRepository protocol e implementação Firebase
**Prioridade**: Alta
**Estimativa**: 30 min
**Arquivos**:
- `FitToday/Domain/Repositories/PersonalWorkoutRepository.swift` (criar)
- `FitToday/Data/Repositories/FirebasePersonalWorkoutRepository.swift` (criar)

**Descrição**:
Criar o protocolo do repositório e a implementação Firebase com suporte a observação em tempo real.

**Critérios de Aceitação**:
- [ ] Protocol com fetchWorkouts, markAsViewed, observeWorkouts
- [ ] Actor FirebasePersonalWorkoutRepository
- [ ] AsyncStream para observação em tempo real
- [ ] Ordenação por data decrescente

---

## Task 3: Criar PDFCacheService
**Prioridade**: Alta
**Estimativa**: 20 min
**Arquivos**:
- `FitToday/Data/Services/PDFCacheService.swift` (criar)

**Descrição**:
Criar serviço de cache para PDFs com download do Firebase Storage.

**Critérios de Aceitação**:
- [ ] Actor PDFCacheService
- [ ] Método getPDF que retorna URL local
- [ ] Cache em disco no diretório de caches
- [ ] Método clearCache para limpeza

---

## Task 4: Criar PersonalWorkoutsViewModel
**Prioridade**: Alta
**Estimativa**: 25 min
**Arquivos**:
- `FitToday/Presentation/Features/PersonalWorkouts/ViewModels/PersonalWorkoutsViewModel.swift` (criar)

**Descrição**:
Criar ViewModel com @Observable para gerenciar estado da lista de treinos.

**Critérios de Aceitação**:
- [ ] @MainActor @Observable
- [ ] Computed property newWorkoutsCount
- [ ] Método startObserving para real-time
- [ ] Método loadWorkouts
- [ ] Método markAsViewed
- [ ] Método getPDFURL

---

## Task 5: Criar PersonalWorkoutsListView e PersonalWorkoutRow
**Prioridade**: Alta
**Estimativa**: 40 min
**Arquivos**:
- `FitToday/Presentation/Features/PersonalWorkouts/Views/PersonalWorkoutsListView.swift` (criar)
- `FitToday/Presentation/Features/PersonalWorkouts/Views/PersonalWorkoutRow.swift` (criar)

**Descrição**:
Criar a view de lista de treinos e o componente de row.

**Critérios de Aceitação**:
- [ ] Empty state quando não há treinos
- [ ] Loading state durante carregamento
- [ ] Lista com LazyVStack
- [ ] Row com título, data, badge "Novo"
- [ ] Tap para abrir PDF
- [ ] Seguir Design System (FitTodayColor, FitTodayFont, etc.)

---

## Task 6: Criar PDFViewerView com PDFKit
**Prioridade**: Alta
**Estimativa**: 30 min
**Arquivos**:
- `FitToday/Presentation/Features/PersonalWorkouts/Views/PDFViewerView.swift` (criar)

**Descrição**:
Criar visualizador de PDF usando PDFKit nativo do iOS.

**Critérios de Aceitação**:
- [ ] UIViewRepresentable para PDFView
- [ ] Loading state durante download
- [ ] Error state com retry
- [ ] Auto-scale e scroll vertical
- [ ] Marcar como visualizado ao abrir

---

## Task 7: Integrar aba Personal no WorkoutTabView
**Prioridade**: Alta
**Estimativa**: 20 min
**Arquivos**:
- `FitToday/Presentation/Features/Workout/Views/WorkoutTabView.swift` (modificar)

**Descrição**:
Adicionar a terceira aba "Personal" ao WorkoutTabView existente.

**Critérios de Aceitação**:
- [ ] Enum WorkoutTab com caso .personal
- [ ] Ícone person.fill
- [ ] Badge com contador de novos treinos
- [ ] Navegação para PersonalWorkoutsListView

---

## Task 8: Registrar dependências no Container
**Prioridade**: Alta
**Estimativa**: 10 min
**Arquivos**:
- `FitToday/Application/DependencyContainer.swift` (modificar)

**Descrição**:
Registrar o repositório, cache service e ViewModel no Swinject.

**Critérios de Aceitação**:
- [ ] Registrar PersonalWorkoutRepository
- [ ] Registrar PDFCacheService
- [ ] Registrar PersonalWorkoutsViewModel

---

## Task 9: Atualizar regras Firebase (Firestore e Storage)
**Prioridade**: Alta
**Estimativa**: 15 min
**Arquivos**:
- `firestore.rules` (modificar)
- `storage.rules` (modificar)

**Descrição**:
Adicionar regras para a coleção personalWorkouts e path de storage.

**Critérios de Aceitação**:
- [ ] Regra Firestore: usuário lê seus treinos, pode atualizar viewedAt
- [ ] Regra Storage: usuário lê seus arquivos
- [ ] Deploy das regras via CLI

---

## Task 10: Adicionar strings de localização
**Prioridade**: Média
**Estimativa**: 10 min
**Arquivos**:
- `FitToday/Resources/pt-BR.lproj/Localizable.strings` (modificar)
- `FitToday/Resources/en.lproj/Localizable.strings` (modificar)

**Descrição**:
Adicionar todas as strings de localização para a feature.

**Critérios de Aceitação**:
- [ ] Strings em pt-BR
- [ ] Strings em en
- [ ] Usar .localized nas views

---

## Task 11: Criar testes unitários
**Prioridade**: Alta
**Estimativa**: 45 min
**Arquivos**:
- `FitTodayTests/Presentation/Features/PersonalWorkoutsViewModelTests.swift` (criar)
- `FitTodayTests/Data/Repositories/MockPersonalWorkoutRepository.swift` (criar)

**Descrição**:
Criar testes unitários para o ViewModel e mock do repository.

**Critérios de Aceitação**:
- [ ] Mock repository
- [ ] Teste loadWorkouts success
- [ ] Teste loadWorkouts error
- [ ] Teste newWorkoutsCount
- [ ] Teste markAsViewed

---

## Task 12: Build e validação final
**Prioridade**: Alta
**Estimativa**: 15 min

**Descrição**:
Compilar o projeto, rodar testes e validar a feature no simulador.

**Critérios de Aceitação**:
- [ ] Build sem erros
- [ ] Testes passando
- [ ] Feature funcional no simulador
- [ ] Empty state visível
- [ ] Navegação funcionando

---

## Resumo

| Task | Descrição | Prioridade | Status |
|------|-----------|------------|--------|
| 1 | Modelo PersonalWorkout | Alta | Pendente |
| 2 | Repository protocol + Firebase | Alta | Pendente |
| 3 | PDFCacheService | Alta | Pendente |
| 4 | PersonalWorkoutsViewModel | Alta | Pendente |
| 5 | ListView e Row | Alta | Pendente |
| 6 | PDFViewerView | Alta | Pendente |
| 7 | Integrar aba no WorkoutTabView | Alta | Pendente |
| 8 | Registrar dependências | Alta | Pendente |
| 9 | Regras Firebase | Alta | Pendente |
| 10 | Localização | Média | Pendente |
| 11 | Testes unitários | Alta | Pendente |
| 12 | Build e validação | Alta | Pendente |

**Total estimado**: ~4-5 horas
