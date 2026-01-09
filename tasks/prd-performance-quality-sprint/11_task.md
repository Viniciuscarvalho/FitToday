# [11.0] Motor de Composição (Blueprint) para treinos adaptativos (L)

## Objetivo
- Implementar um motor determinístico que gera um **blueprint de treino** (estrutura + constraints) a partir dos inputs do usuário (objetivo, local/estrutura, nível, duração, frequência, restrições), garantindo **variação controlada** (sem treinos “iguais”) e um contrato claro para a OpenAI preencher.

## Subtarefas
- [ ] 11.1 Definir o modelo de `WorkoutBlueprint` (estrutura da sessão, blocos, constraints, seed de variação)
- [ ] 11.2 Implementar regras por objetivo (emagrecimento / hipertrofia / força / resistência) alinhadas ao PRD + `personal-active/`
- [ ] 11.3 Implementar regras por local/estrutura (fullGym / home / bodyweight) e compatibilidade de equipamento
- [ ] 11.4 Implementar mecanismo de variação determinística (seed) e política anti-repetição (diversidade mínima)
- [ ] 11.5 Versionar blueprint (`blueprintVersion`) para estabilidade e evolução sem quebrar cache
- [ ] 11.6 Testes unitários (XCTest) para casos determinísticos e de diversidade mínima

## Critérios de Sucesso
- Blueprint gerado é **determinístico** para o mesmo input (mesma seed e versão) e **variável** quando inputs/seed mudam.
- Blueprint descreve claramente: blocos (aquecimento/força/metabólico/aeróbio quando aplicável), quantidade de exercícios, sets/reps/tempo, descanso e foco.
- Regras respeitam objetivo + local, evitando prescrições impossíveis (ex.: máquina em ambiente bodyweight).
- Testes em XCTest cobrindo: objetivos, locais e variação/anti-repetição.

## Dependências
- PRD/Spec desta pasta (Fase 3): `tasks/prd-performance-quality-sprint/prd.md`
- TechSpec desta pasta (padrões e arquitetura): `tasks/prd-performance-quality-sprint/techspec.md`
- Conteúdo base por objetivo em `personal-active/` (usado na próxima task como contexto de prompt).

## Observações
- Este motor deve produzir um contrato “machine-readable” (structs) para permitir validação e cache.
- A OpenAI deve receber o blueprint como “contrato”, não como “sugestão”.

## markdown

## status: completed

<task_context>
<domain>domain/workout/composition</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Task 11.0: Motor de Composição (Blueprint) para treinos adaptativos

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Hoje os treinos gerados pela OpenAI estão com baixa variação e pouca aderência a objetivo/local. Esta tarefa cria um motor determinístico que gera um blueprint/estrutura de treino (blocos, volumes, constraints e seed), que servirá como contrato para a geração via IA e base para validação e caching.

<requirements>
- Gerar `WorkoutBlueprint` a partir de profile + check-in + objetivo + local
- Blueprint conter: blocos, contagens, intensidades (ex.: RPE/zona), descansos e constraints de equipamento
- Incluir `variationSeed` e regras anti-repetição (diversidade mínima)
- Incluir `blueprintVersion` para compatibilidade futura e cache
- Testes em XCTest garantindo determinismo e diversidade mínima
</requirements>

## Subtasks

- [ ] 11.1 Definir modelos (Domain): `WorkoutBlueprint`, `WorkoutBlockBlueprint`, constraints e seed
- [ ] 11.2 Implementar gerador por objetivo (emagrecimento/hipertrofia/força/resistência) conforme PRD + base `personal-active/`
- [ ] 11.3 Implementar gerador por local (fullGym/home/bodyweight) com constraints de equipamento
- [ ] 11.4 Implementar política de variação determinística (seed) e diversidade mínima
- [ ] 11.5 Adicionar versionamento do blueprint e estratégia de evolução
- [ ] 11.6 Testes unitários em XCTest (determinismo, diversidade, compatibilidade com local)

## Implementation Details

- Referenciar `techspec.md` para padrões de Clean Architecture, repository pattern, async/await e testes em XCTest.
- Referenciar `prd.md` (Fase 3) para o objetivo do cache de composição e para os inputs mínimos do hash.

## Success Criteria

- Mesmos inputs (incluindo seed e versão) → mesmo blueprint.
- Inputs diferentes (objetivo/local) → blueprint diferente e aderente.
- Blueprint impede “estruturas inválidas” (ex.: força máxima com descanso curto e volume alto).
- Testes em XCTest cobrindo os principais objetivos e locais.

## Relevant Files
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift` (ou arquivo equivalente de modelos de treino)
- `FitToday/FitToday/Domain/UseCases/` (novo use case: gerar blueprint)
- `FitToday/FitToday/Data/` (integração futura com cache e OpenAI)
- `personal-active/*.md`

