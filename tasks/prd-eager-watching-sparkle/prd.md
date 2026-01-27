# PRD: FitToday Pivot - Fase 1

## Visão Geral

**Feature**: Foundation Phase - Technical Fixes + Group Streaks
**Versão**: 1.0
**Data**: 2026-01-26
**Autor**: Vinícius Carvalho

### Problema

O FitToday enfrenta dois problemas críticos:

1. **Qualidade dos treinos gerados pela IA**: Os exercícios retornados pela OpenAI frequentemente não correspondem ao catálogo interno, resultando em imagens incorretas e experiência confusa.

2. **Diferenciação competitiva**: O app não possui features que o destaquem de concorrentes como SmartGym, Freeletics, Hevy e GymRats.

### Solução

Fase 1 do pivot consiste em:
- **Fixes técnicos P0**: Resolver problemas de matching de exercícios e variação de treinos
- **Group Streaks**: Nova feature de accountability coletiva que diferencia o app

### Métricas de Sucesso

| Métrica | Atual | Meta |
|---------|-------|------|
| Taxa de matching exercício-imagem | ~60% | 90%+ |
| Diversidade de treinos (7 dias) | 40% | 80%+ |
| Retenção D7 em grupos | - | +15% |
| Engajamento diário (usuários em grupos) | - | +25% |

---

## Parte 1: Fixes Técnicos P0

### 1.1 Melhorar Matching de Exercícios no Prompt OpenAI

**Problema**: A normalização de nomes acontece APÓS a resposta da OpenAI, mas o catálogo usa nomes originais em inglês → alta taxa de mismatch.

**Solução**: Incluir lista explícita de exercícios disponíveis no prompt.

**Arquivo**: `Data/Services/OpenAI/WorkoutPromptAssembler.swift`

**Requisitos Funcionais**:
- [ ] RF1.1.1: O prompt deve incluir seção "AVAILABLE EXERCISES" agrupada por muscle group
- [ ] RF1.1.2: Cada exercício deve incluir: nome exato, equipment, muscle group
- [ ] RF1.1.3: Limitar a 150 exercícios no prompt (filtrados por equipment do usuário)
- [ ] RF1.1.4: Instruir explicitamente: "Use ONLY exercise names from this list"
- [ ] RF1.1.5: Adicionar validação pós-resposta que verifica se todos exercícios existem no catálogo

**Formato do Prompt**:
```
AVAILABLE EXERCISES (use EXACT names from this list):

## Chest
- Barbell Bench Press (barbell)
- Incline Dumbbell Press (dumbbell)
- Cable Crossover (cable)
...

## Back
- Lat Pulldown (cable)
- Bent Over Barbell Row (barbell)
...

CRITICAL: Every exercise name in your response MUST match exactly one name from the list above.
```

### 1.2 Diversificar Cache Key

**Problema**: Cache key usa seed de 15 minutos → mesmo treino por longos períodos.

**Solução**: Incluir hash do histórico recente na cache key.

**Arquivo**: `Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`

**Requisitos Funcionais**:
- [ ] RF1.2.1: Cache key deve incluir hash dos últimos 3 workout IDs
- [ ] RF1.2.2: Manter TTL de 15 minutos mas com key diferenciada
- [ ] RF1.2.3: Se usuário pedir "novo treino", invalidar cache manualmente

### 1.3 Timeout na Resolução de Mídia

**Problema**: Resolução de mídia pode travar indefinidamente.

**Arquivo**: `Data/Services/ExerciseDB/ExerciseMediaResolver.swift`

**Requisitos Funcionais**:
- [ ] RF1.3.1: Adicionar timeout de 5 segundos para resolução de mídia
- [ ] RF1.3.2: Em caso de timeout, retornar placeholder
- [ ] RF1.3.3: Log de warning quando timeout ocorre para monitoramento

### 1.4 Expandir Dicionário de Traduções

**Problema**: Apenas ~80 traduções PT→EN, muitos exercícios não são encontrados.

**Arquivo**: `Data/Services/ExerciseDB/ExerciseTranslationDictionary.swift`

**Requisitos Funcionais**:
- [ ] RF1.4.1: Adicionar +100 traduções cobrindo:
  - Exercícios de máquinas (leg press, hack squat, smith machine variations)
  - Exercícios de cabos (cable fly, cable curl, face pull)
  - Variações unilaterais (single arm, single leg)
  - Exercícios compostos com variações (close grip, wide grip, sumo)
- [ ] RF1.4.2: Incluir sinônimos comuns (supino = bench press = chest press)
- [ ] RF1.4.3: Reduzir threshold de token coverage de 80% para 70%

---

## Parte 2: Group Streaks

### 2.1 Conceito

**Group Streaks** é um novo tipo de desafio onde o streak só sobrevive se TODOS os membros ativos do grupo treinarem pelo menos 3x na semana. Cria responsabilidade coletiva e pressão social positiva.

### 2.2 Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN1 | Streak inicia quando grupo é criado ou quando admin ativa |
| RN2 | Cada membro deve completar ≥3 treinos válidos por semana |
| RN3 | Treino válido = duração ≥30 min OU check-in com foto |
| RN4 | Semana = segunda 00:00 UTC até domingo 23:59 UTC |
| RN5 | Se qualquer membro ativo falhar, streak reseta para 0 |
| RN6 | Membros inativos (isActive=false) não contam |
| RN7 | Milestones: 7, 14, 30, 60, 100 dias |
| RN8 | Admin pode "pausar" streak (ex: feriados) - máx 1x/mês |

### 2.3 Modelo de Dados

**Extensão de `SocialModels.swift`**:

```swift
// Novo tipo de Challenge
enum ChallengeType: String, Codable {
    case checkIns = "check-ins"
    case streak = "streak"
    case groupStreak = "group-streak"  // NOVO
}

// Novo modelo para tracking semanal
struct GroupStreakWeek: Codable, Sendable {
    let id: String
    let groupId: String
    let weekStartDate: Date
    let weekEndDate: Date
    var memberCompliance: [String: MemberWeeklyStatus]  // userId -> status
    var allCompliant: Bool
}

struct MemberWeeklyStatus: Codable, Sendable {
    let userId: String
    var workoutCount: Int
    var isCompliant: Bool { workoutCount >= 3 }
    var lastWorkoutDate: Date?
}

// Extensão de SocialGroup
extension SocialGroup {
    var groupStreakDays: Int
    var groupStreakStartDate: Date?
    var groupStreakPausedUntil: Date?
    var lastStreakMilestone: Int?
}
```

**Firestore Structure**:
```
groups/{groupId}
├── groupStreakDays: number
├── groupStreakStartDate: Timestamp
├── groupStreakPausedUntil: Timestamp?
└── streakWeeks/{weekId}
    ├── weekStartDate: Timestamp
    ├── weekEndDate: Timestamp
    ├── memberCompliance: Map<userId, {workoutCount, lastWorkoutDate}>
    └── allCompliant: boolean
```

### 2.4 Fluxos de Usuário

#### Fluxo 1: Visualizar Group Streak (Read)

```
1. Usuário abre GroupDashboardView
2. Sistema exibe card de Group Streak no topo
3. Card mostra:
   - Dias de streak atual (número grande)
   - Barra de progresso da semana (0/3 para cada membro)
   - Lista de membros com status (✓ compliant / ⚠️ at risk / ✗ failed)
   - Próximo milestone
4. Tap no card → expande detalhes
```

#### Fluxo 2: Completar Treino que Conta para Streak (Write)

```
1. Usuário completa treino (≥30 min) ou faz check-in
2. SyncWorkoutCompletionUseCase é chamado
3. Sistema verifica se grupo tem groupStreak ativo
4. Se sim:
   a. Incrementa workoutCount do membro na semana atual
   b. Verifica se membro atingiu 3 treinos
   c. Se todos membros compliant → mantém streak
   d. Dispara notificação de progresso para grupo
```

#### Fluxo 3: Fim de Semana - Avaliação (Scheduled)

```
1. Cloud Function roda domingo 23:59 UTC
2. Para cada grupo com groupStreak ativo:
   a. Verifica memberCompliance de todos membros ativos
   b. Se allCompliant: incrementa groupStreakDays += 7
   c. Se não: reseta groupStreakDays = 0, notifica grupo
   d. Verifica milestones (7, 30, 100) → dispara celebração
   e. Cria novo GroupStreakWeek para próxima semana
```

#### Fluxo 4: Membro em Risco (Notification)

```
1. Sistema monitora quinta-feira
2. Se membro tem <2 treinos:
   a. Envia push notification: "Streak em risco! Complete mais 2 treinos até domingo"
   b. Notifica grupo: "João está com 1/3 treinos esta semana"
3. Se membro tem 2 treinos no sábado:
   a. Envia push: "Falta 1 treino para manter o streak do grupo!"
```

### 2.5 Wireframes UI/UX

#### 2.5.1 Group Streak Card (GroupDashboardView)

```
┌─────────────────────────────────────────────┐
│  🔥 GROUP STREAK                            │
│                                             │
│         42 dias                             │
│         ───────                             │
│    Próximo milestone: 60 dias               │
│                                             │
│  Esta semana:                               │
│  ┌─────────────────────────────────────┐   │
│  │ 👤 Vinícius    ●●●○○  3/3 ✓        │   │
│  │ 👤 Maria       ●●○○○  2/3 ⚠️       │   │
│  │ 👤 João        ●○○○○  1/3 ⚠️       │   │
│  │ 👤 Ana         ●●●○○  3/3 ✓        │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  [ Ver histórico ]                          │
└─────────────────────────────────────────────┘
```

**Estados do indicador**:
- `●` = treino completado
- `○` = treino pendente
- `✓` = membro compliant (verde)
- `⚠️` = at risk, <3 treinos (amarelo)
- `✗` = failed (vermelho, só no fim da semana)

#### 2.5.2 Group Streak Detail View

```
┌─────────────────────────────────────────────┐
│  ← Group Streak                             │
├─────────────────────────────────────────────┤
│                                             │
│         🔥 42                               │
│         dias consecutivos                   │
│                                             │
│  ════════════════════════════════════════   │
│  Iniciado em 15 Dez 2025                    │
│  Próximo milestone: 60 dias (18 dias)       │
│  ════════════════════════════════════════   │
│                                             │
│  📊 ESTA SEMANA                             │
│  ┌─────────────────────────────────────┐   │
│  │ Seg  Ter  Qua  Qui  Sex  Sáb  Dom  │   │
│  │  ●    ●    ●    ○    ○    ○    ○   │   │
│  │ Grupo: 8 treinos / 12 necessários   │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  👥 MEMBROS                                 │
│  ┌─────────────────────────────────────┐   │
│  │ 🥇 Vinícius     3/3  ✓  Seg,Ter,Qua│   │
│  │ 🥈 Ana          3/3  ✓  Seg,Qua,Qui│   │
│  │    Maria        2/3  ⚠️ Ter,Qua    │   │
│  │    João         1/3  ⚠️ Seg        │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  📜 HISTÓRICO                               │
│  ┌─────────────────────────────────────┐   │
│  │ Sem 6 (atual)   8/12   Em andamento│   │
│  │ Sem 5          12/12   ✓ Completa  │   │
│  │ Sem 4          12/12   ✓ Completa  │   │
│  │ Sem 3          12/12   ✓ Completa  │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ⚙️ Opções (apenas admin)                  │
│  [ Pausar streak (1x/mês) ]                │
│                                             │
└─────────────────────────────────────────────┘
```

#### 2.5.3 Milestone Celebration Overlay

```
┌─────────────────────────────────────────────┐
│                                             │
│              🎉 🔥 🎉                        │
│                                             │
│         INCRÍVEL!                           │
│                                             │
│    Vocês alcançaram 30 DIAS                 │
│    de streak em grupo!                      │
│                                             │
│    🏆 Top performers:                       │
│    1. Vinícius - 15 treinos                 │
│    2. Ana - 14 treinos                      │
│    3. Maria - 12 treinos                    │
│                                             │
│         [ Compartilhar 📤 ]                 │
│                                             │
│              [ Fechar ]                     │
│                                             │
└─────────────────────────────────────────────┘
```

#### 2.5.4 At Risk Notification Card (In-App)

```
┌─────────────────────────────────────────────┐
│  ⚠️ STREAK EM RISCO                         │
│                                             │
│  João e Maria ainda não completaram         │
│  os 3 treinos desta semana.                 │
│                                             │
│  Restam 2 dias para salvar o streak!        │
│                                             │
│  [ Enviar lembrete 📲 ]    [ Ignorar ]      │
└─────────────────────────────────────────────┘
```

#### 2.5.5 Streak Broken Screen

```
┌─────────────────────────────────────────────┐
│                                             │
│              💔                              │
│                                             │
│    Streak perdido                           │
│                                             │
│    O grupo não conseguiu manter             │
│    os 3 treinos por membro esta semana.     │
│                                             │
│    Streak anterior: 42 dias                 │
│    Novo streak: 0 dias                      │
│                                             │
│    Membros que não completaram:             │
│    • João (1/3)                             │
│                                             │
│    Não desista! Comece um novo              │
│    streak hoje mesmo.                       │
│                                             │
│         [ Começar novo streak ]             │
│                                             │
└─────────────────────────────────────────────┘
```

### 2.6 Requisitos Funcionais - Group Streaks

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF2.1 | Sistema deve criar GroupStreakWeek automaticamente toda segunda-feira 00:00 UTC | P0 |
| RF2.2 | Sistema deve incrementar workoutCount quando membro completa treino válido | P0 |
| RF2.3 | Sistema deve verificar compliance de todos membros domingo 23:59 UTC | P0 |
| RF2.4 | Sistema deve resetar streak se qualquer membro não completar 3 treinos | P0 |
| RF2.5 | Sistema deve enviar push notification quando membro está "at risk" (quinta-feira, <2 treinos) | P1 |
| RF2.6 | Sistema deve exibir Group Streak card na GroupDashboardView | P0 |
| RF2.7 | Sistema deve exibir milestone celebration ao atingir 7, 14, 30, 60, 100 dias | P1 |
| RF2.8 | Admin deve poder pausar streak por até 7 dias (máx 1x/mês) | P2 |
| RF2.9 | Sistema deve ignorar membros com isActive=false na avaliação | P0 |
| RF2.10 | Sistema deve permitir compartilhamento de milestone achievements | P2 |

### 2.7 Requisitos Não-Funcionais

| ID | Requisito |
|----|-----------|
| RNF1 | Atualização de streak deve ocorrer em <2s após completar treino |
| RNF2 | Push notifications devem ser entregues em <30s após trigger |
| RNF3 | UI de Group Streak deve carregar em <500ms |
| RNF4 | Sistema deve suportar grupos com até 50 membros |
| RNF5 | Histórico de semanas deve ser mantido por 12 meses |

---

## Parte 3: Critérios de Aceite

### 3.1 Fixes Técnicos

- [ ] CA1.1: Gerar 10 treinos consecutivos → ≥90% dos exercícios devem ter imagem correta
- [ ] CA1.2: Gerar 5 treinos no mesmo dia → todos devem ser diferentes
- [ ] CA1.3: Resolução de mídia nunca deve demorar >5s por exercício
- [ ] CA1.4: Log de erros deve mostrar <10% de exercícios não encontrados

### 3.2 Group Streaks

- [ ] CA2.1: Criar grupo e completar 3 treinos → streak deve mostrar 1-7 dias
- [ ] CA2.2: Membro com 2 treinos na quinta → deve receber push notification
- [ ] CA2.3: Um membro com 2/3 treinos no domingo → streak deve resetar para 0
- [ ] CA2.4: Todos membros com 3+ treinos → streak deve incrementar
- [ ] CA2.5: Atingir milestone 7 dias → celebration overlay deve aparecer
- [ ] CA2.6: Admin pausar streak → contador não deve mudar durante pausa

---

## Parte 4: Apple Health Sync para Histórico e Desafios

### 4.1 Conceito

Sincronizar treinos do Apple Health automaticamente para:
1. Registrar no histórico de treinos do app
2. Contar para desafios do grupo (check-ins, streaks) se duração ≥30 min

### 4.2 Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| RN4.1 | Sincronizar apenas workouts do tipo HKWorkoutActivityType (exercício) |
| RN4.2 | Duração mínima de 30 minutos para contar em desafios |
| RN4.3 | Não duplicar: se já existe entry com mesmo startDate, ignorar |
| RN4.4 | Sincronizar retroativamente últimos 7 dias na primeira abertura |
| RN4.5 | Escutar novos workouts em tempo real (HKObserverQuery) |
| RN4.6 | Marcar entry com `source: "apple_health"` para diferenciar |

### 4.3 Requisitos Funcionais - Apple Health Sync

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF4.1 | Sistema deve solicitar permissão de leitura para HKWorkoutType | P0 |
| RF4.2 | Sistema deve sincronizar workouts ≥30 min dos últimos 7 dias | P0 |
| RF4.3 | Sistema deve criar WorkoutHistoryEntry para cada workout sincronizado | P0 |
| RF4.4 | Sistema deve incrementar check-in/streak se workout ≥30 min | P0 |
| RF4.5 | Sistema deve evitar duplicatas comparando startDate | P0 |
| RF4.6 | Sistema deve escutar novos workouts em background | P1 |
| RF4.7 | Sistema deve mostrar badge "Via Apple Health" em entries sincronizadas | P1 |

### 4.4 Critérios de Aceite - Apple Health Sync

- [ ] CA4.1: Treino de 45 min no Apple Watch → aparece no histórico do app
- [ ] CA4.2: Treino de 45 min → conta como 1 treino para streak do grupo
- [ ] CA4.3: Treino de 20 min → aparece no histórico mas NÃO conta para desafio
- [ ] CA4.4: Mesmo treino não duplica se sincronizado novamente
- [ ] CA4.5: Entry mostra badge "Apple Health" na lista de histórico

---

## Parte 5: Fora de Escopo (Fase 1)

- Workout Battles (1v1) - Fase 2
- Workout DNA analysis - Fase 2
- Progress Photos - Fase 2
- Smart Rest Timer - Fase 2 (sem Apple Watch)
- Coach Mode - Fase 4
- Apple Watch companion app - Removido

---

## Parte 5: Dependências

| Dependência | Status | Responsável |
|-------------|--------|-------------|
| Firebase Cloud Functions para avaliação semanal | Necessário | Dev |
| Push Notifications configuradas | Existente | - |
| Firestore Rules para streakWeeks | Necessário | Dev |

---

## Parte 6: Timeline Estimada

| Fase | Entrega | Duração |
|------|---------|---------|
| Fix 1.1 (Prompt) | Exercícios matching corretamente | 2 dias |
| Fix 1.2 (Cache) | Treinos diversificados | 1 dia |
| Fix 1.3 (Timeout) | Sem travamentos | 0.5 dia |
| Fix 1.4 (Traduções) | Melhor cobertura | 1 dia |
| Group Streaks - Backend | Models + Repository | 3 dias |
| Group Streaks - Cloud Function | Avaliação semanal | 2 dias |
| Group Streaks - UI | Views completas | 4 dias |
| Group Streaks - Notifications | Push integrado | 2 dias |
| Testes | Cobertura ≥70% | 2 dias |
| **Total** | | **~17.5 dias** |
