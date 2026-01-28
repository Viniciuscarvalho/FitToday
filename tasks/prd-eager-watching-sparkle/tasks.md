# Tasks: FitToday Pivot - Fase 1

## Overview

Total de tasks: 18
Estimativa total: ~17.5 dias

---

## Categoria A: Fixes Técnicos (P0)

### Task 1: Incluir Catálogo de Exercícios no Prompt OpenAI

**Arquivo**: `Data/Services/OpenAI/WorkoutPromptAssembler.swift`
**Estimativa**: 2 dias
**Prioridade**: P0

**Descrição**:
Modificar o prompt enviado à OpenAI para incluir lista explícita de exercícios disponíveis, agrupados por muscle group, para garantir que os exercícios retornados existam no catálogo.

**Acceptance Criteria**:
- [ ] Criar método `formatExerciseCatalog(exercises:userEquipment:)` que formata exercícios para o prompt
- [ ] Filtrar exercícios por equipment disponível do usuário
- [ ] Agrupar por muscle group com máximo 20 exercícios por grupo
- [ ] Incluir nome exato e equipment de cada exercício
- [ ] Adicionar instrução "CRITICAL: use EXACT names from this list"
- [ ] Limitar total a ~150 exercícios no prompt
- [ ] Adicionar validação pós-resposta que verifica se exercícios existem no catálogo
- [ ] Testes unitários cobrindo cenários de filtragem

**Dependências**: Nenhuma

---

### Task 2: Diversificar Cache Key do HybridWorkoutPlanComposer

**Arquivo**: `Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
**Estimativa**: 0.5 dia
**Prioridade**: P0

**Descrição**:
Incluir hash do histórico de treinos recentes na cache key para evitar repetição de treinos.

**Acceptance Criteria**:
- [ ] Criar método `generateCacheKey(prompt:previousWorkouts:)`
- [ ] Incluir hash dos últimos 3 workout IDs na cache key
- [ ] Manter TTL de 15 minutos
- [ ] Adicionar teste que verifica cache keys diferentes para históricos diferentes
- [ ] Adicionar teste que verifica mesmo cache key para mesmo histórico

**Dependências**: Nenhuma

---

### Task 3: Adicionar Timeout na Resolução de Mídia

**Arquivo**: `Data/Services/ExerciseDB/ExerciseMediaResolver.swift`
**Estimativa**: 0.5 dia
**Prioridade**: P1

**Descrição**:
Adicionar timeout de 5 segundos na resolução de mídia para evitar travamentos.

**Acceptance Criteria**:
- [ ] Criar método `resolveMediaWithTimeout(for:context:timeout:)`
- [ ] Usar `withThrowingTaskGroup` com task de timeout
- [ ] Retornar placeholder em caso de timeout
- [ ] Adicionar log de warning quando timeout ocorre
- [ ] Manter método original para compatibilidade
- [ ] Testes com mock que simula delay

**Dependências**: Nenhuma

---

### Task 4: Expandir Dicionário de Traduções PT→EN

**Arquivo**: `Data/Services/ExerciseDB/ExerciseTranslationDictionary.swift`
**Estimativa**: 1 dia
**Prioridade**: P1

**Descrição**:
Adicionar +100 traduções para melhorar cobertura de exercícios.

**Acceptance Criteria**:
- [ ] Adicionar traduções para exercícios de máquinas (leg press, hack squat, etc.)
- [ ] Adicionar traduções para exercícios de cabos (cable fly, face pull, etc.)
- [ ] Adicionar traduções para variações unilaterais
- [ ] Adicionar traduções para variações de pegada (close grip, wide grip, sumo)
- [ ] Adicionar sinônimos comuns (supino = bench press = chest press)
- [ ] Reduzir threshold de token coverage de 80% para 70%
- [ ] Documentar lista de traduções adicionadas

**Dependências**: Nenhuma

---

## Categoria B: Group Streaks - Backend

### Task 5: Criar Modelos de Domínio para Group Streaks

**Arquivo**: `Domain/Entities/GroupStreakModels.swift` (NEW)
**Estimativa**: 0.5 dia
**Prioridade**: P0

**Descrição**:
Criar structs e enums para o sistema de Group Streaks.

**Acceptance Criteria**:
- [ ] Criar `GroupStreakWeek` struct com memberCompliance, allCompliant
- [ ] Criar `MemberWeeklyStatus` struct com workoutCount, isCompliant computed
- [ ] Criar `ComplianceStatus` enum (compliant, atRisk, notStarted, failed)
- [ ] Criar `GroupStreakStatus` struct para status completo
- [ ] Criar `StreakMilestone` enum (7, 14, 30, 60, 100 dias)
- [ ] Adicionar computed properties (isPaused, nextMilestone, daysToNextMilestone)
- [ ] Todos models devem ser Codable e Sendable

**Dependências**: Nenhuma

---

### Task 6: Criar DTOs Firebase para Group Streaks

**Arquivo**: `Data/Models/FirebaseModels.swift`
**Estimativa**: 0.25 dia
**Prioridade**: P0

**Descrição**:
Criar DTOs para persistência no Firestore.

**Acceptance Criteria**:
- [ ] Criar `FBGroupStreakWeek` struct
- [ ] Criar `FBMemberWeeklyStatus` struct
- [ ] Estender `FBGroup` com campos de streak (groupStreakDays, etc.)
- [ ] Usar @DocumentID e @ServerTimestamp apropriadamente

**Dependências**: Task 5

---

### Task 7: Criar GroupStreakRepository Protocol e Implementação

**Arquivo**: `Domain/Protocols/GroupStreakRepository.swift` (NEW)
**Arquivo**: `Data/Repositories/FirebaseGroupStreakRepository.swift` (NEW)
**Estimativa**: 2 dias
**Prioridade**: P0

**Descrição**:
Criar protocolo e implementação Firebase para persistência de streaks.

**Acceptance Criteria**:
- [ ] Criar protocol `GroupStreakRepository` com métodos:
  - `getStreakStatus(groupId:)`
  - `observeStreakStatus(groupId:)` -> AsyncStream
  - `incrementWorkoutCount(groupId:userId:)`
  - `createWeekRecord(groupId:members:)`
  - `updateStreakDays(groupId:days:milestone:)`
  - `resetStreak(groupId:)`
  - `pauseStreak(groupId:until:)`
  - `resumeStreak(groupId:)`
  - `getWeekHistory(groupId:limit:)`
- [ ] Implementar `FirebaseGroupStreakRepository` com todas as operações
- [ ] Usar transactions para incrementWorkoutCount
- [ ] Implementar observeStreakStatus com snapshot listener
- [ ] Registrar no DI container (AppContainer.swift)
- [ ] Testes com mocks

**Dependências**: Task 5, Task 6

---

### Task 8: Criar UpdateGroupStreakUseCase

**Arquivo**: `Domain/UseCases/UpdateGroupStreakUseCase.swift` (NEW)
**Estimativa**: 1 dia
**Prioridade**: P0

**Descrição**:
Use case para atualizar streak quando usuário completa treino.

**Acceptance Criteria**:
- [ ] Criar protocol `UpdateGroupStreakUseCaseProtocol`
- [ ] Implementar `UpdateGroupStreakUseCase`
- [ ] Incrementar workoutCount no repositório
- [ ] Verificar se usuário atingiu 3 treinos (tornou-se compliant)
- [ ] Enviar notificação para grupo quando membro fica compliant
- [ ] Verificar se todos membros ficaram compliant
- [ ] Registrar no DI container
- [ ] Testes unitários com mocks

**Dependências**: Task 7

---

### Task 9: Modificar SyncWorkoutCompletionUseCase para incluir Streak

**Arquivo**: `Domain/UseCases/SyncWorkoutCompletionUseCase.swift`
**Estimativa**: 0.5 dia
**Prioridade**: P0

**Descrição**:
Integrar atualização de streak quando treino é completado.

**Acceptance Criteria**:
- [ ] Injetar `UpdateGroupStreakUseCase` como dependência
- [ ] Após atualizar check-ins existentes, chamar `updateGroupStreakUseCase.execute()`
- [ ] Só contar treino se duração >= 30 min OU tem check-in com foto
- [ ] Iterar por todos os grupos do usuário
- [ ] Manter comportamento existente intacto
- [ ] Testes de integração

**Dependências**: Task 8

---

### Task 10: Criar PauseGroupStreakUseCase

**Arquivo**: `Domain/UseCases/PauseGroupStreakUseCase.swift` (NEW)
**Estimativa**: 0.5 dia
**Prioridade**: P2

**Descrição**:
Use case para admin pausar streak do grupo.

**Acceptance Criteria**:
- [ ] Criar protocol `PauseGroupStreakUseCaseProtocol`
- [ ] Implementar `PauseGroupStreakUseCase`
- [ ] Verificar se usuário é admin do grupo
- [ ] Verificar se pause já foi usado neste mês
- [ ] Validar duração (max 7 dias)
- [ ] Chamar repositório para definir pausedUntil
- [ ] Registrar no DI container
- [ ] Testes unitários

**Dependências**: Task 7

---

## Categoria C: Group Streaks - Cloud Functions

### Task 11: Criar Cloud Function para Avaliação Semanal

**Arquivo**: `functions/src/groupStreak.ts` (NEW)
**Estimativa**: 1.5 dias
**Prioridade**: P0

**Descrição**:
Função que roda domingo 23:59 UTC para avaliar compliance de todos os grupos.

**Acceptance Criteria**:
- [ ] Criar função `evaluateGroupStreaks` com schedule `59 23 * * 0`
- [ ] Buscar todos grupos ativos com groupStreakDays > 0
- [ ] Pular grupos pausados
- [ ] Para cada grupo:
  - Se allCompliant: incrementar streakDays += 7, verificar milestone
  - Se não: resetar para 0, notificar grupo
- [ ] Usar batch writes para performance
- [ ] Enviar notificações de milestone ou streak broken
- [ ] Logging para monitoramento
- [ ] Testes com emulador Firebase

**Dependências**: Task 7

---

### Task 12: Criar Cloud Function para Criação Semanal de Records

**Arquivo**: `functions/src/groupStreak.ts`
**Estimativa**: 0.5 dia
**Prioridade**: P0

**Descrição**:
Função que roda segunda 00:00 UTC para criar novos registros de semana.

**Acceptance Criteria**:
- [ ] Criar função `createWeeklyStreakWeek` com schedule `0 0 * * 1`
- [ ] Buscar todos grupos ativos
- [ ] Criar novo `streakWeeks` document para cada grupo
- [ ] Inicializar memberCompliance com todos membros ativos (workoutCount: 0)
- [ ] Calcular weekStartDate (segunda 00:00 UTC) e weekEndDate (domingo 23:59 UTC)
- [ ] Logging para monitoramento

**Dependências**: Task 11

---

### Task 13: Criar Cloud Function para Notificações At-Risk

**Arquivo**: `functions/src/groupStreak.ts`
**Estimativa**: 1 dia
**Prioridade**: P1

**Descrição**:
Função que roda quinta 18:00 UTC para enviar notificações a membros em risco.

**Acceptance Criteria**:
- [ ] Criar função `sendAtRiskNotifications` com schedule `0 18 * * 4`
- [ ] Buscar grupos com streaks ativos
- [ ] Identificar membros com < 2 treinos
- [ ] Enviar push notification individual: "Streak em risco! Complete mais X treinos até domingo"
- [ ] Enviar notificação para grupo: "João está com 1/3 treinos esta semana"
- [ ] Respeitar preferências de notificação do usuário
- [ ] Testes com emulador

**Dependências**: Task 11, Task 12

---

## Categoria D: Group Streaks - UI

### Task 14: Criar GroupStreakViewModel

**Arquivo**: `Presentation/Features/Groups/GroupStreakViewModel.swift` (NEW)
**Estimativa**: 1 dia
**Prioridade**: P0

**Descrição**:
ViewModel para gerenciar estado e ações do Group Streak.

**Acceptance Criteria**:
- [ ] Criar classe `GroupStreakViewModel` com @Observable
- [ ] Estado: streakStatus, isLoading, error, showMilestoneOverlay, reachedMilestone
- [ ] Injetar groupStreakRepository e pauseStreakUseCase
- [ ] Implementar `startObserving()` com AsyncStream
- [ ] Implementar `pauseStreak(days:)` async
- [ ] Implementar `dismissMilestoneOverlay()`
- [ ] Computed: currentUserStatus, membersAtRisk, isAdmin
- [ ] Detectar milestone recém-alcançado para mostrar overlay
- [ ] Registrar no DI com factory
- [ ] Testes unitários

**Dependências**: Task 7, Task 8, Task 10

---

### Task 15: Criar GroupStreakCardView

**Arquivo**: `Presentation/Features/Groups/GroupStreakCardView.swift` (NEW)
**Estimativa**: 1 dia
**Prioridade**: P0

**Descrição**:
Componente de card para exibir streak no dashboard do grupo.

**Acceptance Criteria**:
- [ ] Criar `GroupStreakCardView` com:
  - Header com ícone de fogo e "GROUP STREAK"
  - Número grande de dias
  - Indicador de próximo milestone
  - Lista de membros com dots de progresso (●○○)
  - Indicador de compliance (✓ ⚠️ ✗)
  - Link "Ver histórico"
- [ ] Criar `MemberComplianceRow` componente auxiliar
- [ ] Suportar estado pausado
- [ ] Tap para navegar para detail view
- [ ] Animações suaves

**Dependências**: Task 5

---

### Task 16: Criar GroupStreakDetailView

**Arquivo**: `Presentation/Features/Groups/GroupStreakDetailView.swift` (NEW)
**Estimativa**: 1.5 dias
**Prioridade**: P0

**Descrição**:
Tela de detalhes do Group Streak.

**Acceptance Criteria**:
- [ ] Criar `GroupStreakDetailView` com:
  - Header com dias de streak
  - Data de início e próximo milestone
  - Calendário da semana atual com dias marcados
  - Total de treinos do grupo
  - Lista de membros ordenada por treinos
  - Histórico de semanas (scrollable)
  - Opção de pausar (apenas admin)
- [ ] Integrar com GroupStreakViewModel
- [ ] Binding com sheet para pausar
- [ ] Animações de transição

**Dependências**: Task 14, Task 15

---

### Task 17: Criar MilestoneOverlayView

**Arquivo**: `Presentation/Features/Groups/MilestoneOverlayView.swift` (NEW)
**Estimativa**: 0.5 dia
**Prioridade**: P1

**Descrição**:
Overlay de celebração quando grupo atinge milestone.

**Acceptance Criteria**:
- [ ] Criar `MilestoneOverlayView` com:
  - Background escuro semi-transparente
  - Emoji grande do milestone
  - Texto "INCRÍVEL!" e descrição
  - Lista de top performers (3)
  - Botão "Compartilhar"
  - Botão "Fechar"
- [ ] Animação de entrada (scale + fade)
- [ ] Callback para share sheet
- [ ] Suportar todos milestones (7, 14, 30, 60, 100)

**Dependências**: Task 5

---

### Task 18: Integrar Group Streak no GroupDashboardView

**Arquivo**: `Presentation/Features/Groups/GroupDashboardView.swift`
**Estimativa**: 0.5 dia
**Prioridade**: P0

**Descrição**:
Adicionar card de Group Streak ao dashboard existente.

**Acceptance Criteria**:
- [ ] Adicionar GroupStreakCardView abaixo do header
- [ ] Criar instância de GroupStreakViewModel
- [ ] Iniciar observação quando view aparecer
- [ ] Navegar para GroupStreakDetailView no tap
- [ ] Exibir MilestoneOverlayView quando showMilestoneOverlay
- [ ] Manter layout existente intacto
- [ ] Testar em diferentes tamanhos de tela

**Dependências**: Task 14, Task 15, Task 16, Task 17

---

## Categoria E: Testes e Validação

### Task 19: Testes de Integração e Cobertura

**Estimativa**: 2 dias
**Prioridade**: P0

**Descrição**:
Garantir cobertura de testes adequada para novas funcionalidades.

**Acceptance Criteria**:
- [ ] Criar fixtures em `FitTodayTests/Fixtures/GroupStreakFixtures.swift`
- [ ] Testes unitários para todos use cases (>80% coverage)
- [ ] Testes para repositório com mocks
- [ ] Testes de snapshot para views (opcional)
- [ ] Rodar `swift test` sem falhas
- [ ] Build sem warnings de concurrency

**Dependências**: Todas as tasks anteriores

---

## Ordem de Execução Recomendada

### Sprint 1 (Dias 1-4): Fixes Técnicos
1. Task 1 - Catálogo no Prompt (2 dias)
2. Task 2 - Cache Key (0.5 dia)
3. Task 3 - Timeout (0.5 dia)
4. Task 4 - Traduções (1 dia)

### Sprint 2 (Dias 5-9): Backend Group Streaks
5. Task 5 - Modelos (0.5 dia)
6. Task 6 - DTOs (0.25 dia)
7. Task 7 - Repository (2 dias)
8. Task 8 - UpdateUseCase (1 dia)
9. Task 9 - Sync Integration (0.5 dia)

### Sprint 3 (Dias 10-13): Cloud Functions
10. Task 11 - Avaliação Semanal (1.5 dias)
11. Task 12 - Criação Semanal (0.5 dia)
12. Task 13 - Notificações At-Risk (1 dia)

### Sprint 4 (Dias 14-17): UI
13. Task 14 - ViewModel (1 dia)
14. Task 15 - CardView (1 dia)
15. Task 16 - DetailView (1.5 dias)
16. Task 17 - MilestoneOverlay (0.5 dia)
17. Task 18 - Dashboard Integration (0.5 dia)
18. Task 10 - PauseUseCase (0.5 dia)

### Sprint 5 (Dias 17.5): Finalização
19. Task 19 - Testes (2 dias)

---

## Verificação Final

Ao concluir todas as tasks:

1. [ ] Gerar 10 treinos consecutivos → ≥90% dos exercícios devem ter imagem correta
2. [ ] Gerar 5 treinos no mesmo dia → todos devem ser diferentes
3. [ ] Resolução de mídia nunca deve demorar >5s por exercício
4. [ ] Criar grupo e completar 3 treinos → streak deve mostrar 1-7 dias
5. [ ] Membro com 2 treinos na quinta → deve receber push notification
6. [ ] Um membro com 2/3 treinos no domingo → streak deve resetar para 0
7. [ ] Atingir milestone 7 dias → celebration overlay deve aparecer
8. [ ] `swift test` passa sem falhas
9. [ ] Build sem warnings de Swift 6 concurrency
