# Product Requirements Document (PRD)

**Project Name:** Sistema de Ligas Semanais
**Document Version:** 1.0
**Date:** 2026-03-14
**Author:** Vinicius Carvalho
**Status:** Draft
**Linear Issue:** PRO-91

---

## 1. Executive Summary

**Problem Statement:**
Os desafios atuais do FitToday sao avulsos e sem continuidade competitiva. Nao existe ranking dinamico semanal nem progressao entre divisoes. Usuarios Pro/Elite carecem de um diferencial competitivo que justifique a assinatura.

**Proposed Solution:**
Sistema de ligas semanais inspirado no Duolingo: 5 divisoes (Bronze, Silver, Gold, Diamond, Legend) com no maximo 30 usuarios por instancia. Ranking baseado em XP semanal. Top 3 sobem de divisao, bottom 3 descem. Bronze e gratuita; Silver/Gold/Diamond requerem Pro; Legend requer Elite. Reset semanal via Cloud Function (domingo 23:59 BRT) — o app iOS apenas consome os resultados do Firestore.

**Business Value:**
Aumentar retenção de usuarios Pro/Elite via competicao recorrente e criar viral loop atraves de compartilhamento de resultados semanais.

**Success Metrics:**

- 80% dos usuarios Pro/Elite participam de ligas ativamente
- Churn semanal de ligas < 5%
- Compartilhamento de resultados de liga +25%

---

## 2. Goals and Objectives

### Business Goals

1. Aumentar retenção de usuarios Pro/Elite com competicao semanal recorrente
2. Criar diferencial competitivo que justifique assinatura Pro/Elite
3. Aumentar compartilhamento organico via resultados de liga

### User Goals

1. Competir semanalmente contra outros usuarios de nivel similar
2. Progredir entre divisoes como sinal de consistencia
3. Visualizar ranking e historico de desempenho

---

## 3. User Personas

### Persona 1: Fitness Enthusiast (Free)

**Demographics:** 20-35 anos, treina 2-3x/semana, plano Free

**Goals:**
- Experimentar competicao na liga Bronze
- Ser motivado pelo ranking para treinar mais
- Ter incentivo para fazer upgrade ao Pro ao ver divisoes superiores bloqueadas

**Pain Points:**
- Falta de motivacao competitiva continua
- Nao ve razao suficiente para assinar Pro

### Persona 2: Fitness Enthusiast (Pro/Elite)

**Demographics:** 25-40 anos, treina 4-6x/semana, plano Pro ou Elite

**Goals:**
- Competir em divisoes avancadas (Silver-Legend)
- Ver seu progresso semanal comparado com outros
- Compartilhar conquistas (promocao de divisao) nas redes sociais

**Pain Points:**
- Investiu na assinatura mas nao tem diferencial competitivo exclusivo
- Desafios existentes sao isolados e sem continuidade

---

## 4. Functional Requirements

### FR-001: Exibicao da Liga Atual

**Description:** Exibir a liga atual do usuario com ranking, posicao, e XP semanal de cada participante.

**Details:**
- Tela dedicada mostrando: nome da divisao, icone/cor da divisao, lista de ate 30 participantes ordenados por XP semanal
- Posicao do usuario destacada na lista
- Top 3 marcados com indicador de promocao (verde)
- Bottom 3 marcados com indicador de rebaixamento (vermelho)
- XP semanal de cada participante visivel
- Pull-to-refresh para atualizar ranking

**Acceptance Criteria:**
- [ ] UI mostra a liga atual do usuario com ranking completo
- [ ] Posicao do usuario esta destacada
- [ ] Zonas de promocao e rebaixamento estao visualmente distintas

### FR-002: Promocao e Rebaixamento

**Description:** Apos o reset semanal (Cloud Function), exibir resultado de promocao ou rebaixamento.

**Details:**
- Ao abrir o app apos reset semanal, verificar se houve mudanca de divisao
- Se promovido: exibir tela de celebracao com nova divisao
- Se rebaixado: exibir tela informativa com divisao anterior
- Se manteve: exibir resumo da semana
- Dados consumidos do Firestore (campo `lastWeekResult` no documento do usuario)

**Acceptance Criteria:**
- [ ] Top 3 da semana anterior sao promovidos para divisao superior
- [ ] Bottom 3 da semana anterior sao rebaixados para divisao inferior
- [ ] Bronze nao rebaixa (bottom 3 permanece)
- [ ] Legend nao promove (top 3 permanece com badge especial)

### FR-003: Animacoes de Resultado

**Description:** Animacoes diferenciadas para promocao e rebaixamento.

**Details:**
- Promocao: animacao de confetti + tela de parabens com nova divisao
- Rebaixamento: animacao de shake sutil + tela informativa
- Manutencao: resumo simples sem animacao especial
- Animacoes acionadas na primeira abertura do app apos reset semanal

**Acceptance Criteria:**
- [ ] Confetti exibido ao ser promovido
- [ ] Shake exibido ao ser rebaixado
- [ ] Animacao exibida apenas uma vez por ciclo semanal

### FR-004: Push Notifications

**Description:** Notificacoes push para eventos de liga.

**Details:**
- Notificacao ao final da semana com resultado (promovido/rebaixado/manteve)
- Notificacao mid-week se o usuario esta na zona de rebaixamento
- Textos localizados em pt-BR e en

**Acceptance Criteria:**
- [ ] Push notification recebida apos reset semanal com resultado
- [ ] Notificacao mid-week para usuarios em zona de rebaixamento
- [ ] Textos em pt-BR e en

### FR-005: Consumo do Reset Semanal

**Description:** Consumir resultados do reset semanal processado pela Cloud Function.

**Details:**
- Cloud Function roda domingo 23:59 BRT (fora do escopo iOS)
- iOS escuta mudancas no Firestore via snapshot listener ou fetch no app launch
- Documento do usuario contem: `currentLeagueTier`, `currentLeagueId`, `weeklyXP`, `lastWeekResult` (promoted/demoted/stayed), `lastWeekRank`
- XP semanal resetado no servidor; app exibe valor zerado apos fetch

**Acceptance Criteria:**
- [ ] App consome resultado do reset semanal corretamente
- [ ] XP semanal exibido como 0 apos reset
- [ ] Divisao atualizada apos promocao/rebaixamento

### FR-006: Historico de Ligas

**Description:** Exibir historico de participacao em ligas.

**Details:**
- Lista de semanas anteriores com: divisao, posicao final, XP total, resultado (promovido/rebaixado/manteve)
- Armazenado no Firestore na subcollection `leagueHistory` do usuario
- Exibido em tela acessivel a partir da tela de liga

**Acceptance Criteria:**
- [ ] Historico de semanas anteriores exibido
- [ ] Cada entrada mostra divisao, posicao, XP, e resultado

### FR-007: Feature Flag

**Description:** Toda a feature de ligas gateada por Remote Config.

**Details:**
- Nova flag `leagues_enabled` no `FeatureFlagKey` enum
- Default value: `false` (unreleased)
- Quando desabilitada: tela de liga nao aparece na navegacao
- Usar padrao existente com `FeatureFlagUseCase`

**Acceptance Criteria:**
- [ ] Feature flag `leagues_enabled` adicionada ao `FeatureFlagKey`
- [ ] Liga completamente oculta quando flag esta desabilitada
- [ ] Sem crash ou estado inconsistente ao toggle da flag

### FR-008: Gating por Entitlement

**Description:** Divisoes superiores requerem assinatura Pro ou Elite.

**Details:**
- Bronze: acessivel para todos (Free, Pro, Elite)
- Silver, Gold, Diamond: requerem Pro ou Elite (`SubscriptionTier.pro` ou `.elite`)
- Legend: requer Elite (`SubscriptionTier.elite`)
- Se usuario faz downgrade de Pro para Free estando em Silver+, permanece na liga ate o fim da semana, depois e rebaixado para Bronze (logica no servidor)
- Adicionar `leagueAccess` ao `ProFeature` enum e verificacao no `EntitlementPolicy`

**Acceptance Criteria:**
- [ ] Usuarios Free so acessam Bronze
- [ ] Usuarios Pro acessam ate Diamond
- [ ] Usuarios Elite acessam Legend
- [ ] UI mostra badge de Pro/Elite nas divisoes bloqueadas

---

## 5. Non-Functional Requirements

### Performance

- Tela de ranking deve carregar em < 2 segundos
- Snapshot listener do Firestore para atualizacao em near real-time durante semana ativa
- Cache local dos dados de liga para exibicao offline (ultima versao conhecida)

### Accessibility

- VoiceOver: todos os elementos de ranking com labels descritivos (posicao, nome, XP)
- Dynamic Type: suporte a tamanhos de fonte acessiveis
- Contraste: cores das divisoes atendem WCAG 2.1 AA
- Animacoes respeitam `UIAccessibility.isReduceMotionEnabled`

### Localization

- Todas as strings em `Localizable.strings` para pt-BR e en
- Nomes das divisoes localizados: Bronze/Bronze, Prata/Silver, Ouro/Gold, Diamante/Diamond, Lenda/Legend

---

## 6. Epics and User Stories

### Epic 1: Infraestrutura de Ligas

**US-001:** Como desenvolvedor, quero adicionar a feature flag `leagues_enabled` ao `FeatureFlagKey` para gatear toda a funcionalidade de ligas.

**US-002:** Como desenvolvedor, quero adicionar `leagueAccess` ao `ProFeature` e atualizar `EntitlementPolicy` para verificar acesso por tier de assinatura.

**US-003:** Como desenvolvedor, quero criar as entidades de dominio (`LeagueTier`, `LeagueStanding`, `LeagueWeekResult`, `LeagueHistory`) para modelar os dados de liga.

**US-004:** Como desenvolvedor, quero criar o `LeagueRepository` protocol e `FirestoreLeagueRepository` para ler dados de liga do Firestore.

### Epic 2: Tela de Liga e Ranking

**US-005:** Como usuario, quero ver minha liga atual com ranking de todos os participantes para acompanhar minha posicao.

**US-006:** Como usuario, quero ver meu XP semanal e dos outros participantes para entender como estou comparado.

**US-007:** Como usuario, quero ver indicadores visuais de zona de promocao (top 3) e rebaixamento (bottom 3) para saber minha situacao.

**US-008:** Como usuario, quero fazer pull-to-refresh no ranking para ver dados atualizados.

### Epic 3: Resultado Semanal e Animacoes

**US-009:** Como usuario, quero ver uma tela de celebracao com confetti quando sou promovido para sentir a conquista.

**US-010:** Como usuario, quero ver uma tela informativa com shake quando sou rebaixado para entender o resultado.

**US-011:** Como usuario, quero que a animacao de resultado apareca apenas uma vez por semana para nao ser repetitiva.

### Epic 4: Notificacoes e Historico

**US-012:** Como usuario, quero receber push notification com meu resultado semanal para saber mesmo sem abrir o app.

**US-013:** Como usuario, quero receber alerta mid-week se estou na zona de rebaixamento para ter chance de reagir.

**US-014:** Como usuario, quero ver meu historico de ligas (semanas anteriores) para acompanhar minha evolucao.

---

## 7. User Experience Requirements

### User Flows

**Flow 1: Primeiro Acesso a Liga**
1. Usuario abre aba/secao de Liga (visivel apenas se `leagues_enabled` = true)
2. Se Free: alocado automaticamente em instancia Bronze (via servidor)
3. Se Pro: alocado em Bronze (promocao organica)
4. Se Elite: alocado em Bronze (promocao organica, acesso a Legend quando promovido)
5. Ve ranking com 30 participantes, posicao zerada

**Flow 2: Semana Ativa**
1. Usuario treina e ganha XP (sistema existente PRO-90)
2. XP semanal e contabilizado automaticamente no Firestore
3. Usuario abre tela de Liga e ve ranking atualizado
4. Se estiver em zona de rebaixamento, recebe push mid-week

**Flow 3: Resultado Semanal**
1. Cloud Function processa reset domingo 23:59 BRT
2. Usuario abre app na segunda-feira
3. App detecta `lastWeekResult` no Firestore
4. Exibe tela de resultado: confetti (promocao), shake (rebaixamento), ou resumo (manutencao)
5. Marca resultado como visualizado localmente
6. Redireciona para ranking da nova semana

**Flow 4: Usuario Free Vendo Divisoes Bloqueadas**
1. Na tela de liga, usuario Free ve divisoes Silver+ com badge Pro/Elite
2. Ao tocar em divisao bloqueada, exibe paywall/upgrade prompt
3. Apos upgrade, na proxima semana pode ser promovido para Silver

### UI Requirements

- **Cores por divisao:** Bronze (#CD7F32), Silver (#C0C0C0), Gold (#FFD700), Diamond (#B9F2FF), Legend (#9B59B6)
- **Icones:** Icone tematico por divisao (shield/crown/gem variants)
- **Ranking list:** Avatar, nome, XP semanal, posicao (#1, #2, #3...)
- **Zonas destacadas:** Top 3 com fundo verde sutil, Bottom 3 com fundo vermelho sutil
- **Tela de resultado:** Full-screen modal com animacao + botao de continuar/compartilhar
- **Navegacao:** Acessivel via tab bar ou secao dedicada no home

---

## 8. Success Metrics

| KPI | Target | Medicao |
|-----|--------|---------|
| Participacao Pro/Elite | 80% ativos em ligas | % usuarios Pro/Elite com `currentLeagueId` != nil |
| Churn semanal | < 5% | % usuarios que param de treinar apos rebaixamento |
| Compartilhamento | +25% vs baseline | Eventos de share na tela de resultado |
| Retencao d7 Pro | +15% | Cohort Pre/Pos ligas |
| DAU durante semana de liga | +10% | Sessoes diarias de usuarios em liga ativa |

---

## 9. Assumptions and Dependencies

### Assumptions

- O sistema de XP (PRO-90) estara completo e funcional antes do inicio do desenvolvimento de ligas
- Usuarios serao alocados automaticamente em instancias de liga pelo backend
- O XP semanal para ranking usa o mesmo XP computado pelo `AwardXPUseCase`
- A Cloud Function de reset semanal sera desenvolvida em paralelo pela equipe de backend

### Dependencies

| Dependencia | Tipo | Status |
|-------------|------|--------|
| Sistema de XP (PRO-90) | Feature interna | Em desenvolvimento |
| Cloud Function de reset semanal | Backend | Pendente |
| Firebase Remote Config (`leagues_enabled`) | Infraestrutura | Existente (adicionar flag) |
| Firestore collections (`leagues`, `leagueHistory`) | Backend | Pendente |
| Push Notifications (FCM) | Infraestrutura | Existente |
| `EntitlementPolicy` / `ProEntitlement` | Feature interna | Existente |
| `FeatureFlagKey` enum | Feature interna | Existente |

---

## 10. Out of Scope

Os seguintes itens estao fora do escopo desta PRD (escopo iOS client apenas):

- **Cloud Function de reset semanal** — implementacao da funcao que roda domingo 23:59 BRT
- **Backend API de alocacao** — logica de alocacao de usuarios em instancias de liga (max 30)
- **Firestore schema design** — definicao detalhada das collections e documents (responsabilidade do backend)
- **Logica de rebaixamento por downgrade de assinatura** — processada pelo servidor
- **Sistema de recompensas/badges por liga** — futura iteracao
- **Chat ou interacao entre membros da liga** — fora do MVP
- **Liga entre amigos/grupos customizados** — futura iteracao

---

## 11. Release Planning

### Phase 1: MVP (Single Release)

**Objetivo:** Entregar o sistema completo de ligas no cliente iOS, pronto para consumir dados do backend.

| Sprint | Entregas |
|--------|----------|
| Sprint 1 | FR-007 (feature flag), FR-008 (entitlement gating), entidades de dominio, repository protocol |
| Sprint 2 | FR-001 (tela de ranking), FR-005 (consumo reset semanal), Firestore integration |
| Sprint 3 | FR-002 (promocao/rebaixamento UI), FR-003 (animacoes), FR-006 (historico) |
| Sprint 4 | FR-004 (push notifications), localizacao pt-BR/en, testes, polish |

**Criterio de launch:** Feature flag `leagues_enabled` = false em producao ate backend estar pronto. QA com flag habilitada em staging.

---

## 12. Risks and Mitigations

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|---------------|---------|-----------|
| Backend de ligas atrasa | Media | Alto | Feature flag permite deploy independente; app funciona sem ligas |
| XP system (PRO-90) nao esta pronto | Media | Alto | Ligas dependem de XP; priorizar PRO-90 primeiro |
| Usuarios Free nao entendem bloqueio de divisoes | Baixa | Medio | UI clara com badge Pro/Elite e messaging de upgrade |
| Instancias com poucos usuarios (< 10) | Media | Medio | Backend deve garantir merge de instancias pequenas |
| Animacoes pesadas em devices antigos | Baixa | Baixo | Respeitar `isReduceMotionEnabled`; testar em iPhone SE |
| Timezone issues no reset semanal | Media | Alto | Servidor usa BRT fixo; app exibe horarios localizados |
| Firestore reads excessivos no ranking | Media | Medio | Cache local + throttle de refresh (min 30s entre fetches) |
