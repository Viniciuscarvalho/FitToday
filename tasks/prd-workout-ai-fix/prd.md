# PRD: Correção da Geração de Treinos com IA

## Resumo Executivo

A geração de treinos com IA está produzindo treinos repetitivos e não está utilizando corretamente os inputs do usuário. O sistema de histórico não está salvando os planos de treino corretamente, resultando em uma lista vazia de exercícios proibidos, o que permite que a IA repita os mesmos exercícios.

## Problema

### Evidência do Log
```
[NewOpenAIComposer] 📋 History entries fetched: 3
[NewOpenAIComposer]   [0] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer]   [1] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer]   [2] Apple Health Workout - hasWorkoutPlan: false, exercises: 0
[NewOpenAIComposer] 📋 WorkoutPlans with exercises: 0
[PromptBuilder] 🚫 Prohibited exercises count: 0
```

### Problemas Identificados

1. **WorkoutPlan não está sendo salvo no histórico**: Os entries de "Apple Health Workout" têm `hasWorkoutPlan: false`, significando que o `workoutPlan` não foi persistido.

2. **Exercícios proibidos sempre vazios**: Como não há `workoutPlan` no histórico, a lista de exercícios proibidos é sempre vazia, permitindo que a IA repita exercícios.

3. **Foco sempre "fullBody"**: O check-in pode não estar sendo passado corretamente ou o usuário sempre seleciona fullBody.

4. **Limite de 2 gerações/dia não implementado**: Não há controle de quantas vezes o usuário pode gerar treino por dia.

5. **Sistema de cache antigo ainda influenciando**: Embora o `BlueprintInput` tenha sido corrigido para usar seed aleatório, outros componentes podem estar usando versões antigas.

## Objetivos

### P0 (Crítico)
- [ ] Garantir que `workoutPlan` seja salvo no histórico ao completar treino
- [ ] Garantir que exercícios dos últimos 3 treinos sejam enviados como proibidos
- [ ] Validar que cada geração produz exercícios diferentes

### P1 (Importante)
- [ ] Implementar limite de 2 gerações de treino por dia
- [ ] Limpar/remover código de cache antigo não utilizado
- [ ] Adicionar logs claros para debug

### P2 (Desejável)
- [ ] Adicionar testes unitários para validar variação
- [ ] Métricas de diversidade de treinos

## Escopo

### Incluído
- Correção do fluxo de salvamento de `workoutPlan` no histórico
- Correção do fluxo de busca de exercícios proibidos
- Implementação de limite diário de gerações
- Remoção de código legado de cache
- Testes de validação

### Excluído
- Mudanças na UI
- Novos tipos de treino
- Integração com outros serviços

## Arquitetura Atual

```
UserProfile + DailyCheckIn
        ↓
BlueprintInput.from() → variationSeed (random)
        ↓
WorkoutBlueprintEngine.generateBlueprint()
        ↓
NewOpenAIWorkoutComposer.composePlan()
    ├── fetchRecentWorkouts() → [WorkoutPlan] (VAZIO!)
    ├── buildPrompt() → prohibitedExercises (VAZIO!)
    └── client.generateWorkout()
        ↓
WorkoutPlan (gerado pela IA)
        ↓
CompleteWorkoutSessionUseCase.execute()
    └── historyRepository.saveEntry() → workoutPlan: ??? (NÃO SALVO!)
```

## Arquitetura Proposta

```
UserProfile + DailyCheckIn
        ↓
BlueprintInput.from() → variationSeed (random) ✓
        ↓
WorkoutBlueprintEngine.generateBlueprint() ✓
        ↓
NewOpenAIWorkoutComposer.composePlan()
    ├── fetchRecentWorkouts() → [WorkoutPlan] (COM EXERCÍCIOS!)
    ├── buildPrompt() → prohibitedExercises (POPULADO!)
    └── client.generateWorkout()
        ↓
WorkoutPlan (gerado pela IA, sem exercícios repetidos)
        ↓
CompleteWorkoutSessionUseCase.execute()
    └── historyRepository.saveEntry(workoutPlan: plan) ✓ (SALVO!)
```

## Requisitos Funcionais

### FR-001: Persistência do WorkoutPlan
- Ao completar um treino, o `WorkoutPlan` completo DEVE ser salvo no `WorkoutHistoryEntry`
- O `workoutPlan` DEVE incluir todas as fases e exercícios
- A serialização/deserialização JSON DEVE funcionar corretamente

### FR-002: Exercícios Proibidos
- Ao gerar novo treino, DEVE buscar os últimos 3 treinos com `workoutPlan` não-nulo
- DEVE extrair todos os nomes de exercícios desses treinos
- DEVE enviar lista de exercícios proibidos no prompt para OpenAI
- A IA DEVE ser instruída a NÃO usar esses exercícios

### FR-003: Limite Diário de Gerações
- Usuário pode gerar no máximo 2 treinos por dia (reset à meia-noite local)
- Ao atingir limite, exibir mensagem informativa
- Contador deve persistir entre sessões do app

### FR-004: Validação de Diversidade
- Após receber resposta da IA, validar que pelo menos 60% dos exercícios são diferentes dos proibidos
- Se falhar validação, fazer até 2 retries
- Se todos retries falharem, usar fallback local

## Requisitos Não-Funcionais

### Performance
- Geração de treino deve completar em < 10 segundos (incluindo chamada OpenAI)
- Busca de histórico deve completar em < 100ms

### Confiabilidade
- Se OpenAI falhar, fallback local DEVE funcionar
- Se histórico falhar, gerar treino sem proibidos (mas logar warning)

## Métricas de Sucesso

1. **Taxa de Diversidade**: > 60% dos exercícios devem ser diferentes entre treinos consecutivos
2. **Taxa de Salvamento**: 100% dos treinos completados devem ter `workoutPlan` salvo
3. **Taxa de Proibidos**: > 90% das gerações devem enviar lista de proibidos não-vazia (após 3+ treinos)

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| workoutPlan muito grande para persistir | Baixa | Alto | Limitar tamanho, comprimir JSON |
| OpenAI ignora exercícios proibidos | Média | Médio | Validação pós-geração + retry |
| Histórico corrompido | Baixa | Alto | Validação de schema, migração |

## Timeline

- **Fase 1**: Correção do salvamento de workoutPlan (1 task)
- **Fase 2**: Correção da busca de exercícios proibidos (1 task)
- **Fase 3**: Implementação de limite diário (1 task)
- **Fase 4**: Limpeza de código legado (1 task)
- **Fase 5**: Testes e validação (1 task)

## Dependências

- `WorkoutHistoryRepository` - Para salvar/buscar histórico
- `NewOpenAIWorkoutComposer` - Para gerar treinos
- `NewWorkoutPromptBuilder` - Para construir prompts
- `CompleteWorkoutSessionUseCase` - Para completar treinos

## Aprovações

- [ ] Tech Lead
- [ ] Product Owner
- [ ] QA Lead
