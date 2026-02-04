# PRD: Fix Workout Generation Flow & Related Issues

## Overview

**Feature Name:** Fix Flow Generate
**Priority:** High
**Status:** Draft
**Created:** 2026-02-04
**Author:** Auto-generated via feature-marker

## Problem Statement

O aplicativo FitToday apresenta 4 problemas críticos que afetam a experiência do usuário:

1. **Geração de Treinos Repetitivos**: O mesmo treino está sendo gerado independentemente do grupo muscular selecionado (ombro, perna, etc.), causando frustração e tornando o recurso de personalização inútil.

2. **Interface de Treinos Quebrada**: O título do header desapareceu na aba de treinos, e não existe funcionalidade para salvar programas como "Minhas Rotinas".

3. **Descrições de Exercícios Multilíngues**: Descrições de exercícios estão mescladas com inglês e espanhol, criando inconsistência visual e dificultando a compreensão.

4. **Inconsistência nos Desafios**: O número de dias ativos não sincroniza com o número de streaks, e o upload de fotos para check-in não está funcionando corretamente.

## Goals

### Primary Goals

1. **Corrigir geração de treinos**: Garantir que cada grupo muscular selecionado gere um treino único e apropriado
2. **Restaurar UI de treinos**: Corrigir o header e implementar a seção "Minhas Rotinas"
3. **Traduzir descrições**: Implementar tradução automática para o idioma do sistema
4. **Sincronizar desafios**: Corrigir inconsistências entre dias ativos e streaks, e restaurar upload de fotos

### Success Metrics

- Taxa de treinos únicos por grupo muscular: 100%
- Zero descrições em idiomas não suportados
- Paridade entre dias ativos e streaks calculados
- Taxa de sucesso no upload de fotos: 100%

## User Stories

### US1: Geração de Treinos por Grupo Muscular
**Como** usuário do FitToday
**Quero** selecionar um grupo muscular (ombro, perna, etc.)
**Para que** eu receba um treino específico e variado para aquele grupo

**Critérios de Aceite:**
- Ao selecionar "Ombro", o treino gerado deve conter exercícios focados em ombros
- Treinos consecutivos para o mesmo grupo devem ter variação de exercícios
- O cache deve ser invalidado quando o grupo muscular mudar

### US2: Salvar Programas como Rotinas
**Como** usuário do FitToday
**Quero** salvar até 5 programas na seção "Minhas Rotinas"
**Para que** eu possa acessá-los rapidamente na aba "Meus Treinos"

**Critérios de Aceite:**
- Botão "Salvar como Rotina" nos detalhes do programa
- Limite de 5 rotinas salvas
- Seção "Minhas Rotinas" visível em "Meus Treinos"
- Possibilidade de remover rotinas salvas

### US3: Descrições em Português
**Como** usuário brasileiro
**Quero** ver todas as descrições de exercícios em português
**Para que** eu entenda as instruções sem confusão de idiomas

**Critérios de Aceite:**
- Todas as descrições traduzidas para o idioma do sistema
- Fallback para português quando tradução não disponível
- Sem mistura de idiomas em uma mesma descrição

### US4: Consistência de Streaks
**Como** usuário participando de desafios
**Quero** que meus dias ativos correspondam aos meus streaks
**Para que** eu confie nos dados exibidos

**Critérios de Aceite:**
- Dias ativos = Streaks calculados com mesma lógica
- Timezone consistente (local do usuário)
- Sincronização em tempo real com Firebase

### US5: Upload de Foto no Check-in
**Como** usuário que completou um treino
**Quero** enviar uma foto comprovando meu treino
**Para que** meu check-in seja registrado no desafio do grupo

**Critérios de Aceite:**
- Captura ou seleção de foto funcional
- Upload para Firebase Storage com sucesso
- Confirmação visual de check-in realizado
- Foto visível no feed do grupo

## Technical Analysis

### Issue 1: Workout Generation Cache

**Root Cause Identificado:**
- O cache key inclui `focus.rawValue`, mas o `variationSeed` é calculado com base em buckets de 15 minutos
- Se o usuário muda o grupo muscular dentro do mesmo bucket de 15 minutos, o seed pode colidir
- O OpenAI pode retornar respostas cacheadas incorretas

**Arquivos Afetados:**
- `FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `FitToday/Data/Services/OpenAI/OpenAIResponseCache.swift`
- `FitToday/Domain/Entities/WorkoutBlueprint.swift`

**Solução Proposta:**
1. Incluir `focus` explicitamente no `variationSeed`
2. Invalidar cache quando `focus` mudar
3. Remover dependência de time bucket para variedade de exercícios

### Issue 2: Missing Title Header & Routines

**Root Cause Identificado:**
- `WorkoutTabView` não está exibindo o navigation title corretamente
- Não existe estrutura para salvar programas como rotinas

**Arquivos Afetados:**
- `FitToday/Presentation/Features/Workout/Views/WorkoutTabView.swift`
- `FitToday/Presentation/Features/Workout/Views/MyWorkoutsView.swift`
- `FitToday/Domain/Entities/ProgramModels.swift`

**Solução Proposta:**
1. Restaurar `.navigationTitle()` com display mode correto
2. Criar modelo `SavedRoutine` para rotinas salvas
3. Adicionar seção "Minhas Rotinas" em `MyWorkoutsView`
4. Implementar persistência via SwiftData

### Issue 3: Exercise Description Translations

**Root Cause Identificado:**
- API Wger retorna descrições em múltiplos idiomas
- Filtro atual não exclui espanhol explicitamente
- Fallback inadequado quando português não disponível

**Arquivos Afetados:**
- `FitToday/Domain/Entities/WgerModels.swift`
- `FitToday/Data/Services/Wger/WgerAPIService.swift`
- `FitToday/Data/Services/Wger/WgerExerciseAdapter.swift`

**Solução Proposta:**
1. Implementar tradução local usando `String.localizedStandard`
2. Criar fallback chain: Português → Inglês → Tradução automática
3. Filtrar explicitamente idiomas não desejados (espanhol)

### Issue 4: Streaks/Active Days Inconsistency

**Root Cause Identificado:**
- Dois sistemas de streak independentes (personal vs group)
- Timezones diferentes: local para personal, UTC para group
- Sync delay entre local e Firebase

**Arquivos Afetados:**
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`
- `FitToday/Domain/UseCases/SyncWorkoutCompletionUseCase.swift`
- `FitToday/Domain/Entities/GroupStreakModels.swift`

**Solução Proposta:**
1. Unificar lógica de cálculo de streak
2. Usar timezone consistente (local do usuário)
3. Sincronizar imediatamente após workout completion

### Issue 5: Photo Check-in Not Working

**Root Cause Identificado:**
- Possível falha na compressão de imagem
- Erro no path do Firebase Storage
- Falta de tratamento de erro adequado

**Arquivos Afetados:**
- `FitToday/Domain/UseCases/CheckInUseCase.swift`
- `FitToday/Data/Repositories/FirebaseCheckInRepository.swift`
- `FitToday/Presentation/Features/Activity/Views/CheckInSheet.swift`

**Solução Proposta:**
1. Adicionar logs detalhados no fluxo de upload
2. Validar permissões do Firebase Storage
3. Implementar retry automático em falhas

## Scope

### In Scope

- Correção do cache de geração de treinos
- Restauração do header de navegação
- Implementação de "Minhas Rotinas" (limite de 5)
- Tradução de descrições de exercícios
- Sincronização de streaks/dias ativos
- Correção do upload de fotos para check-in

### Out of Scope

- Novos tipos de desafios
- Redesign completo da UI
- Integração com novas APIs de exercícios
- Sistema de gamificação avançado

## Dependencies

- Firebase SDK (Storage, Firestore)
- OpenAI API
- Wger API
- SwiftData
- LocalizationManager

## Risks & Mitigations

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| API Wger indisponível | Alto | Cache local de exercícios |
| Limite de tokens OpenAI | Médio | Rate limiting e cache agressivo |
| Falhas de rede no upload | Médio | Queue de retry offline |
| Breaking changes em models | Alto | Testes unitários extensivos |

## Timeline

| Fase | Descrição | Estimativa |
|------|-----------|------------|
| Fase 1 | Fix workout generation cache | - |
| Fase 2 | Restore header + Minhas Rotinas | - |
| Fase 3 | Translation implementation | - |
| Fase 4 | Streaks sync + photo upload | - |
| Fase 5 | Testing & validation | - |

## Appendix

### Relevant Files Map

```
FitToday/
├── Data/
│   ├── Services/
│   │   ├── OpenAI/
│   │   │   ├── OpenAIClient.swift
│   │   │   ├── OpenAIResponseCache.swift
│   │   │   ├── WorkoutPromptAssembler.swift
│   │   │   └── HybridWorkoutPlanComposer.swift
│   │   ├── Wger/
│   │   │   ├── WgerAPIService.swift
│   │   │   └── WgerExerciseAdapter.swift
│   │   └── Firebase/
│   │       ├── FirebaseGroupStreakService.swift
│   │       └── FirebaseLeaderboardService.swift
│   └── Repositories/
│       ├── FirebaseCheckInRepository.swift
│       └── SwiftDataCustomWorkoutRepository.swift
├── Domain/
│   ├── Entities/
│   │   ├── WorkoutBlueprint.swift
│   │   ├── WgerModels.swift
│   │   ├── ProgramModels.swift
│   │   ├── GroupStreakModels.swift
│   │   └── CheckInModels.swift
│   └── UseCases/
│       ├── SyncWorkoutCompletionUseCase.swift
│       └── CheckInUseCase.swift
└── Presentation/
    └── Features/
        ├── Workout/Views/
        │   ├── WorkoutTabView.swift
        │   └── MyWorkoutsView.swift
        ├── Home/
        │   └── HomeViewModel.swift
        └── Activity/
            └── Views/CheckInSheet.swift
```

### Cache Key Components (Current)

```swift
var cacheKey: String {
    let components = [
        String(metadata.variationSeed),
        metadata.goal.rawValue,
        metadata.structure.rawValue,
        metadata.level.rawValue,
        metadata.focus.rawValue,        // ← Included but seed collision possible
        String(metadata.energyLevel),
        metadata.sorenessLevel.rawValue,
        metadata.blueprintVersion.rawValue,
        metadata.feedbackHash,
        metadata.historyHash
    ]
    return Hashing.sha256(components.joined(separator: "|"))
}
```

### Proposed Cache Key Fix

```swift
var cacheKey: String {
    let components = [
        metadata.goal.rawValue,
        metadata.structure.rawValue,
        metadata.level.rawValue,
        metadata.focus.rawValue,
        String(metadata.energyLevel),
        metadata.sorenessLevel.rawValue,
        metadata.blueprintVersion.rawValue,
        metadata.feedbackHash,
        metadata.historyHash,
        UUID().uuidString  // Force uniqueness per request
    ]
    return Hashing.sha256(components.joined(separator: "|"))
}
```

**Nota:** A solução final deve balancear entre economia de tokens (cache) e variedade de treinos.
