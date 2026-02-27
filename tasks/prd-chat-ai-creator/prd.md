# Product Requirements Document (PRD)

**Project Name:** FitOrb AI Chat - Integracao Completa
**Document Version:** 1.0
**Date:** 2026-02-27
**Author:** FitToday Team
**Status:** Approved

---

## Executive Summary

**Problem Statement:**
O FitOrb (assistente IA do FitToday) existe como tela no app mas e superficial — system prompt generico sem dados do usuario, sem persistencia de historico, servico HTTP duplicado, sem limite de mensagens para freemium e sem features contextuais. O usuario nao recebe valor real da IA.

**Proposed Solution:**
Transformar FitOrb em um assistente IA completo: personal trainer + nutricionista contextualizado com dados reais do usuario (treinos, streak, perfil, stats), historico persistente, typing effect, gating freemium e quick actions contextuais.

**Business Value:**
- Aumentar retencao via engajamento diario com IA personalizada
- Gerar conversao Free->Pro via limite de mensagens (5/dia free)
- Diferenciar o app no mercado com IA contextualizada

**Success Metrics:**
- 60% dos usuarios Pro usam FitOrb pelo menos 1x/semana
- Taxa de conversao Free->Pro aumenta 15% apos lancamento
- NPS da feature >= 4.0/5.0

---

## Project Overview

### Background
FitToday e um app iOS de fitness com treinos personalizados por IA. A tela FitOrb ja existe com UI funcional (chat bubbles, quick actions, animated orb, input field), mas a integracao com LLM e incompleta.

### Current State
- UI funcional com bolhas de chat, chips de quick action, orb animado
- AIChatService faz chamadas HTTP diretamente (duplica NewOpenAIClient)
- System prompt e uma string estatica generica
- Mensagens sao in-memory (perdidas ao fechar a tela)
- Sem gating de mensagens para usuarios free
- Sem features contextuais (sugestao de treino, motivacao)

### Desired State
- Respostas personalizadas com dados reais do usuario (perfil, stats, treinos)
- Historico de conversa persistente via SwiftData
- Servico refatorado usando NewOpenAIClient (retry, session management)
- Typing effect simulado para UX premium
- Limite de 5 msgs/dia para free, ilimitado para Pro
- Quick actions contextuais baseados no estado do usuario

---

## Goals and Objectives

### Business Goals
1. Aumentar engajamento diario com assistente IA personalizado
2. Criar alavanca de conversao Free->Pro via limite de mensagens
3. Posicionar FitToday como app de fitness com IA de referencia

### User Goals
1. Receber orientacao personalizada de treino e nutricao
2. Ter historico de conversas acessivel entre sessoes
3. Interagir com IA que conhece seu progresso e objetivos

---

## User Personas

### Primary Persona: Usuario Ativo (Pro)
**Demographics:** 25-40 anos, treina 3-5x/semana
**Goals:** Otimizar treinos, receber sugestoes personalizadas, acompanhar progresso
**Pain Points:** Apps de fitness genericos, falta de personalizacao

### Secondary Persona: Usuario Iniciante (Free)
**Demographics:** 18-35 anos, comecando a treinar
**Goals:** Aprender exercicios, receber motivacao, entender nutricao basica
**Pain Points:** Nao sabe por onde comecar, falta de orientacao acessivel

---

## Functional Requirements

### FR-001: Persistencia de Historico de Chat [MUST]
Mensagens devem ser salvas localmente via SwiftData e carregadas ao abrir a tela.

**Acceptance Criteria:**
- Historico carrega ultimas 50 mensagens ao abrir FitOrb
- Mensagens persistem entre fechamentos do app
- Usuario pode limpar historico via botao na toolbar

---

### FR-002: System Prompt Personalizado [MUST]
O prompt do sistema deve incluir dados reais do usuario para respostas contextualizadas.

**Acceptance Criteria:**
- Prompt inclui: objetivo, nivel, equipamento, condicoes de saude
- Prompt inclui: streak atual, treinos da semana, calorias
- Prompt inclui: ultimos 3 treinos realizados
- Fallback para prompt generico se dados indisponiveis

---

### FR-003: Refatoracao do Servico HTTP [MUST]
AIChatService deve delegar ao NewOpenAIClient ao inves de duplicar logica HTTP.

**Acceptance Criteria:**
- AIChatService nao chama URLSession.shared diretamente
- Retry logic do NewOpenAIClient e reaproveitada
- Comportamento externo mantido (mesma API publica)

---

### FR-004: Typing Effect Simulado [SHOULD]
Respostas devem ser exibidas com efeito de digitacao para UX premium.

**Acceptance Criteria:**
- Texto aparece progressivamente (~5 chars a cada ~15ms)
- Indicador de "digitando" visivel durante animacao
- Mensagem salva no repositorio apenas apos animacao completa

---

### FR-005: Limite de Mensagens Freemium [MUST]
Usuarios free devem ter limite de 5 mensagens por dia.

**Acceptance Criteria:**
- Free: 5 msgs/dia, Pro: ilimitado
- Mensagem de limite atingido com CTA para Pro
- Contador reseta a meia-noite
- Tracking separado do tracking de workout generation

---

### FR-006: Quick Actions Contextuais [SHOULD]
Chips de sugestao devem variar conforme estado do usuario.

**Acceptance Criteria:**
- Se nao treinou hoje: "Sugerir treino de hoje"
- Se treinou: "Dicas de recuperacao"
- Baseado no objetivo: sugestoes especificas
- Localizado em PT-BR e EN

---

### FR-007: Adocao de ErrorPresenting [MUST]
ViewModel deve usar o padrao ErrorPresenting do projeto.

**Acceptance Criteria:**
- AIChatViewModel conforma com ErrorPresenting
- Erros mapeados via ErrorMapper
- Alertas usam ErrorMessage (titulo + mensagem amigavel)

---

## Non-Functional Requirements

### NFR-001: Performance [MUST]
Historico de 50 mensagens carrega em < 200ms.

### NFR-002: Seguranca [MUST]
API key nunca exposta em logs, analytics ou bundle.

### NFR-003: Testabilidade [MUST]
70%+ coverage no ViewModel, 80%+ no ChatSystemPromptBuilder.

### NFR-004: Localizacao [MUST]
Todas as strings via Localizable.strings (EN + PT-BR).

---

## Out of Scope

1. Streaming SSE real (token-by-token via server) — substituido por typing effect simulado
2. Suporte a Anthropic/Claude — manter OpenAI BYOK
3. Analise de refeicoes com foto — complexidade excessiva para MVP
4. Push notifications de motivacao diaria — requer backend
5. Testes de UI (UITests) — fase de scaffolding

---

## Release Planning

### Phase 1: Infrastructure (Tasks 1-8)
- ChatRepository + SwiftData model + mapper
- Refatoracao AIChatService -> NewOpenAIClient
- DI wiring

### Phase 2: Personalizacao (Tasks 9-11)
- ChatSystemPromptBuilder
- Integracao no AIChatService
- Update DI

### Phase 3: ViewModel + Persistence (Tasks 12-14)
- ErrorPresenting
- ChatRepository no ViewModel
- View updates

### Phase 4: UX Polish (Tasks 15-16)
- Typing effect simulado
- UI do typing indicator

### Phase 5: Freemium (Tasks 17-19)
- ProFeature.aiChat
- Usage tracking
- Enforcement no ViewModel

### Phase 6: Extras (Tasks 20-21)
- Quick actions contextuais
- Localizacao completa

### Phase 7: Quality (Tasks 22-24)
- Error mapping
- Test suite completo
- Security audit

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Token window excedida no prompt | Alto | Limitar contexto a 3 treinos + stats resumidos |
| API key exposta em logs | Alto | Audit de seguranca + review de codigo |
| Migracao SwiftData schema | Medio | SDChatMessage e modelo novo, sem migracao |
| Custo de API para usuarios Free | Medio | Limite de 5 msgs/dia reduz custo |

---

## References

- GitHub Issue #26: https://github.com/Viniciuscarvalho/FitToday/issues/26
- Issue #24: Strings FitPal em ingles
- OpenAI API Docs: https://platform.openai.com/docs
