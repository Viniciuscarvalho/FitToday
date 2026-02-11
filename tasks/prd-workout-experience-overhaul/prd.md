# Product Requirements Document (PRD)

**Project Name:** Workout Experience Overhaul
**Document Version:** 1.0
**Date:** 2026-02-09
**Author:** Product Team
**Status:** Draft

---

## Executive Summary

**Problem Statement:**
O FitToday apresenta três problemas críticos que comprometem a experiência do usuário: (1) treinos gerados via OpenAI são repetitivos e não variam conforme os inputs do usuário, (2) a execução de treinos é apenas demonstrativa, sem funcionalidade real de timer, controles ou Live Activities, e (3) exercícios exibem imagens ausentes e descrições inconsistentes (mistura de idiomas).

**Proposed Solution:**
Reescrever completamente o fluxo de geração de treinos OpenAI para garantir variação dinâmica, implementar execução de treinos funcional com Live Activities seguindo o padrão do app Hevy, e melhorar a consistência dos dados de exercícios da API Wger.

**Success Metrics:**
- 100% dos treinos gerados em sequência devem ser diferentes
- Live Activity funcional com controles de pause/play/próximo
- 90%+ dos exercícios com imagem válida ou placeholder adequado

---

## Goals and Objectives

### Business Goals
1. Aumentar retenção de usuários através de treinos personalizados e variados
2. Proporcionar experiência de execução de treino competitiva com apps líderes de mercado
3. Reduzir abandono de treinos por falta de orientação visual/temporal

### User Goals
1. Receber treinos diferentes e adaptados aos meus inputs diários
2. Executar treinos com timer e controles mesmo com o app em background
3. Visualizar exercícios com imagens e descrições claras em português

---

## Functional Requirements

### Epic 1: Geração Dinâmica de Treinos via OpenAI

#### FR-001: Inputs para Geração de Treino [MUST]

**Description:**
O sistema deve coletar e utilizar os seguintes inputs para gerar treinos únicos: equipamentos disponíveis, músculos a treinar, nível do usuário e como está se sentindo.

**Acceptance Criteria:**
- Sistema coleta equipamentos disponíveis do perfil do usuário
- Sistema permite seleção de músculos-alvo antes da geração
- Sistema considera nível (iniciante/intermediário/avançado)
- Sistema captura estado atual (cansado/normal/energizado)
- Todos os inputs são enviados ao prompt da OpenAI

---

#### FR-002: Variação Obrigatória de Treinos [MUST]

**Description:**
Treinos gerados em sequência devem ser obrigatoriamente diferentes, mesmo com inputs idênticos.

**Acceptance Criteria:**
- Seed de variação único por requisição (timestamp + random)
- Histórico dos últimos 5 treinos consultado para evitar repetição
- OpenAI prompt instrui explicitamente a não repetir exercícios recentes
- Validação pós-geração verifica diferença mínima de 60% dos exercícios
- Se validação falhar, nova requisição é feita (máx 2 retries)

---

#### FR-003: Fallback Local [MUST]

**Description:**
Quando a API OpenAI falhar (timeout, rate limit, erro), o sistema deve gerar treino localmente.

**Acceptance Criteria:**
- Fallback ativado em timeout (>10s), erro de rede ou rate limit
- Geração local respeita mesmos inputs do usuário
- Geração local usa catálogo de exercícios embarcado
- Usuário é notificado que treino foi gerado localmente
- Fallback também garante variação (não repetir últimos treinos)

---

#### FR-004: Testes Unitários de Geração [MUST]

**Description:**
Cobertura de testes unitários para todo o fluxo de geração.

**Acceptance Criteria:**
- Testes para parsing de resposta OpenAI
- Testes para validação de variação
- Testes para fallback local
- Testes para tratamento de erros
- Mínimo 80% de cobertura no módulo de geração

---

### Epic 2: Execução de Treinos com Live Activities

#### FR-005: Fluxo de Navegação de Programas [MUST]

**Description:**
Implementar fluxo: Programas → Selecionar Programa → Ver Workouts → Selecionar Workout → Ver Exercícios → Iniciar → Executar.

**Acceptance Criteria:**
- Tela de listagem de programas disponíveis
- Tela de detalhes do programa com lista de workouts
- Tela de preview do workout com lista de exercícios
- Botão "Iniciar Treino" inicia sessão de execução
- Navegação fluida entre todas as telas

---

#### FR-006: Tela de Execução de Treino [MUST]

**Description:**
Tela principal de execução mostrando exercício atual, séries, tempo de descanso e controles.

**Acceptance Criteria:**
- Exibe nome do exercício atual
- Exibe imagem/GIF/vídeo do exercício (prioridade: vídeo > GIF > imagem)
- Exibe descrição do exercício em português
- Exibe número de séries e repetições prescritas
- Checkbox para marcar série como concluída
- Timer de descanso entre séries (valores pré-definidos por tipo de exercício)
- Timer total do treino
- Botão próximo exercício / pular

---

#### FR-007: Timer de Descanso [MUST]

**Description:**
Timer countdown entre séries com feedback sonoro e háptico.

**Acceptance Criteria:**
- Timer inicia automaticamente ao completar série
- Valores pré-definidos: 60s (leve), 90s (moderado), 120s (pesado)
- Vibração ao término do descanso
- Som de notificação ao término do descanso
- Possibilidade de pular descanso manualmente

---

#### FR-008: Live Activity para Treino [MUST]

**Description:**
Live Activity no Dynamic Island e Lock Screen mostrando status do treino.

**Acceptance Criteria:**
- Exibe exercício atual
- Exibe série atual (ex: "Série 2/4")
- Exibe tempo de descanso em countdown (quando ativo)
- Exibe tempo total do treino
- Botão de próximo exercício funcional
- Botão de pause/play funcional
- Atualização em tempo real do timer
- Live Activity persiste com app em background

---

#### FR-009: Conclusão de Treino [MUST]

**Description:**
Tela de conclusão com resumo e opção de avaliação.

**Acceptance Criteria:**
- Exibe tempo total do treino
- Exibe exercícios completados
- Opção de avaliar treino (1-5 estrelas)
- Salva treino no histórico
- Finaliza Live Activity

---

### Epic 3: Melhoria de Dados de Exercícios

#### FR-010: Imagens de Exercícios [MUST]

**Description:**
Garantir que exercícios tenham imagem válida ou placeholder adequado.

**Acceptance Criteria:**
- Priorizar GIF/vídeo quando disponível na API Wger
- Fallback para imagem estática
- Placeholder genérico por grupo muscular quando sem imagem
- Cache local de imagens para performance
- Indicador de carregamento enquanto busca imagem

---

#### FR-011: Descrições em Português [MUST]

**Description:**
Descrições de exercícios consistentemente em português brasileiro.

**Acceptance Criteria:**
- Buscar descrição em português da API Wger (language=2)
- Se indisponível, traduzir descrição em inglês via fallback
- Remover qualquer conteúdo em espanhol
- Sanitizar HTML das descrições
- Descrições curtas e focadas na execução do movimento

---

## Non-Functional Requirements

### NFR-001: Performance de Geração [MUST]

**Description:**
Geração de treino deve ser responsiva.

**Acceptance Criteria:**
- Resposta OpenAI em até 10 segundos
- Fallback local em até 2 segundos
- Feedback visual de loading durante geração

---

### NFR-002: Precisão de Timers [MUST]

**Description:**
Timers devem ser precisos mesmo em background.

**Acceptance Criteria:**
- Timer não para quando app vai para background
- Precisão de ±1 segundo
- Live Activity sincronizada com timer interno

---

### NFR-003: Cobertura de Testes [MUST]

**Description:**
Código novo deve ter cobertura adequada.

**Acceptance Criteria:**
- Mínimo 80% de cobertura em ViewModels
- Mínimo 70% de cobertura em UseCases
- Testes para todos os fluxos críticos

---

## Out of Scope

### Explicitly Excluded Features
1. **Apple Watch App** - Será considerado em versão futura
2. **Widget de treino** - Fora do escopo desta versão
3. **macOS** - Apenas iOS nesta fase
4. **Registro detalhado de peso/reps** - Apenas checkbox de conclusão
5. **Sincronização de timer com HealthKit** - Apenas treino finalizado
6. **UITests** - Conforme CLAUDE.md, não escrever durante scaffolding

### Future Considerations
- Apple Watch companion app
- Widgets para próximo treino
- Registro de progressão de cargas
- Integração com equipamentos smart

---

## Assumptions and Dependencies

### Assumptions
1. API OpenAI disponível e com quota suficiente
2. API Wger mantém disponibilidade
3. iOS 17+ como deployment target (requerido para Live Activities)
4. Usuário concede permissão para Live Activities

### Dependencies

| Dependency | Type | Status | Risk |
|------------|------|--------|------|
| OpenAI API | External | Active | Medium - fallback mitiga |
| Wger API | External | Active | Low - cache mitiga |
| ActivityKit | Framework | iOS 17+ | Low |
| AVFoundation | Framework | Built-in | None |

---

## Technical Constraints

- Swift 6.0 com strict concurrency
- SwiftUI apenas (sem UIKit desnecessário)
- MVVM com @Observable
- iOS 17.0 minimum deployment
- Testes com XCTest

---

## Glossary

| Term | Definition |
|------|------------|
| Live Activity | Recurso iOS 16.1+ para mostrar informações em tempo real no Dynamic Island e Lock Screen |
| Dynamic Island | Área interativa na parte superior de iPhones com notch pill |
| Workout | Sessão de treino composta por exercícios |
| Program | Conjunto de workouts organizados |
| Set/Série | Execução de um número de repetições de um exercício |
| Rest Timer | Contador regressivo de descanso entre séries |

---

**Document End**
