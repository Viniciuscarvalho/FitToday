# PRD — AI Workout V3 (Equalização IA + Progresso + HealthKit)

## Overview

O FitToday ganhou um pipeline “híbrido” (local + OpenAI) para gerar treinos, mas hoje a montagem via IA ficou **confusa**: o prompt mistura muitas regras, faltam sinais diários (ex.: energia) e o feedback de segurança/progressão não é claro. Além disso, o histórico ainda não entrega “dopamina” (insights visuais simples) e não há integração com o ecossistema Apple (HealthKit) para enriquecer métricas e exportar treinos.

Este PRD define uma única iniciativa (épica) em 3 fases:
1) **Equalização do treino via IA** com adaptação diária e regras de segurança explícitas.  
2) **Progresso no histórico** com gráficos simples e resumos mensais.  
3) **HealthKit (iPhone, PRO)** para importar métricas de sessões e exportar treinos.

## Objectives

- Tornar a geração via IA **compreensível, consistente e segura**, reduzindo variação “errada” e aumentando qualidade percebida.
- Melhorar retenção com “dopamina”: **streak**, **minutos/semana**, e **mês em números**.
- Entregar integração HealthKit (PRO) com foco em privacidade e confiabilidade.

Métricas sugeridas (instrumentação mínima):
- Taxa de sucesso do pipeline IA (passa `QualityGate` sem fallback).
- Tempo médio de geração do treino (p95).
- Uso do histórico: visualizações/semana e scroll depth.
- Adoção HealthKit (PRO): % que concede permissão + % que exporta ao menos 1 treino.

## User Stories

- Como usuário, quero responder o check-in do dia e receber um treino **completo** alinhado ao meu perfil, para treinar sem “ficar pensando”.
- Como usuário com dor/limitação articular, quero que o treino **evite riscos** e ofereça alternativas seguras.
- Como usuário, quero ver meu progresso com gráficos simples (streak, minutos/semana, mês em números) para me manter motivado.
- Como usuário PRO, quero conectar o HealthKit para **importar duração/calorias** das minhas sessões e **exportar** treinos concluídos.

## Core Features

### 1) Equalização do treino via IA (Fase 1)

**Descrição**: consolidar a montagem do prompt e do fluxo híbrido para que a IA gere um treino “robusto”, usando apenas o catálogo e respeitando blueprint + segurança + histórico recente.

**Requisitos funcionais**
1. O check-in diário deve capturar **energia (0–10)** além de foco e DOMS.  
2. O prompt deve receber um contrato objetivo: **perfil**, **check-in**, **blueprint**, **catálogo compatível**, e **histórico recente** (últimos treinos concluídos).  
3. A IA deve retornar **apenas JSON** dentro de um schema único e validável.  
4. O sistema deve aplicar validação e normalização via quality gate; em falha, deve ocorrer fallback local.  
5. O treino deve respeitar **equipamento** do usuário e **condições de saúde** (ex.: joelho/ombro/lombar), evitando seleções de alto risco.  
6. Quando energia estiver baixa (ex.: 0–3) ou DOMS forte, o treino deve entrar em modo conservador (ex.: reduzir intensidade/volume; sugerir deload).  
7. Deve existir um mecanismo explícito para evitar repetição de exercícios recentes usando histórico persistido.  

### 2) Progresso que dá dopamina (Fase 2)

**Descrição**: melhorar a área de histórico para oferecer insights rápidos e visuais.

**Requisitos funcionais**
8. O topo do histórico deve exibir: **streak atual** e **melhor streak**.  
9. O histórico deve exibir **minutos treinados por semana** (agregado) e **sessões/semana**.  
10. O sistema deve exibir “PRs” sem carga (sem registrar peso por série), como:
   - Maior nº de sessões em 7 dias
   - Maior tempo treinado em uma semana
   - Maior duração de sessão
11. Deve existir um resumo **“Mês em números”** (mínimo): total de sessões, total de minutos e melhor streak do mês.  
12. As agregações devem funcionar com paginação e sem travar UI (cálculo assíncrono/eficiente).  

### 3) Ecossistema Apple — HealthKit (iPhone, PRO) (Fase 3)

**Descrição**: adicionar integração HealthKit (sem app no Watch) para enriquecer histórico e exportar treinos.

**Requisitos funcionais**
13. Somente usuários **PRO** devem acessar a conexão HealthKit.  
14. O app deve solicitar permissões HealthKit (explicando privacidade) e permitir desconectar/revogar.  
15. O sistema deve importar do HealthKit, no mínimo: **duração da sessão** e **calorias** (quando disponível), vinculando a um item de histórico.  
16. Ao concluir um treino no FitToday, o usuário PRO deve poder **exportar** como `HKWorkout` (e dados associados quando aplicável).  
17. Falhas do HealthKit (sem permissão, sem dados, erro do store) devem degradar de forma segura e sem bloquear o fluxo de treino/histórico.  

## User Experience

- **Fase 1**: check-in diário com energia (0–10) + foco + DOMS; retorno do treino com copy simples (“hoje vamos mais leve/normal/forte”) e sem jargões excessivos.  
- **Fase 2**: histórico com um “header” de insights (streak/semana/mês) e lista paginada existente. Gráficos simples, legíveis e rápidos.  
- **Fase 3**: tela de conexão HealthKit (PRO) com:
  - Explicação do que será lido/escrito
  - Botão “Conectar”
  - Estado conectado/desconectado

Acessibilidade:
- Textos de métricas devem ter alternativa textual (sem depender só de gráficos).
- Contraste e tamanho de fonte respeitando Dynamic Type.

## High-Level Technical Constraints

- iOS target moderno (projeto já aponta para targets altos), com foco em Swift Concurrency (async/await) e isolamento correto (`@MainActor` apenas onde fizer sentido).
- Persistência atual via SwiftData para histórico; o plano completo pode ser serializado (JSON) para apoiar anti-repetição.
- HealthKit requer:
  - chaves de `Info.plist` e capability no target
  - tratamento de permissão e privacidade (dados sensíveis)

## Non-Goals (Out of Scope)

- App dedicado no Apple Watch nesta iniciativa.
- Registro de carga (peso) por série/reps reais (PRs serão sem carga por enquanto).
- “Year in review” completo (começar por “Mês em números”; expandir depois).
- Recomendações nutricionais.

## Open Questions

- Qual a política exata de “energia baixa” (thresholds e mensagens) para modo conservador/deload?
- Import HealthKit: a associação com o histórico será automática (por janela de tempo) ou manual (usuário escolhe qual sessão vincular)?
- Export HealthKit: export automático ao concluir ou opção manual por padrão?

