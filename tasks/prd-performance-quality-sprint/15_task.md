# [15.0] F8 — Testes e cobertura para composição/caching (M)

## Objetivo
- Aumentar cobertura e confiabilidade da “principal funcionalidade” (montagem do treino) adicionando testes unitários e smoke tests para: blueprint engine, prompt assembly, validação/diversidade e cache de composição. O foco é evitar regressões que gerem treinos “iguais” ou inválidos.

## Subtarefas
- [x] 15.1 Criar fixtures de inputs (profiles/check-ins) por objetivo/local e outputs esperados (blueprints)
- [x] 15.2 Testar determinismo: mesmo input/seed/version → mesmo blueprint/prompt
- [x] 15.3 Testar diversidade: inputs distintos → variação mínima garantida (overlap/ordem)
- [x] 15.4 Testar cache: hit/miss + TTL + inclusão de blueprintVersion no hash
- [x] 15.5 Smoke test do fluxo completo (mocks OpenAI): blueprint → prompt → validate → cache
- [x] 15.6 Relatório/critério mínimo de cobertura (targets) e checklist de QA manual

## Critérios de Sucesso
- Suite em XCTest cobre os cenários críticos e impede regressões de “treino igual”.
- Smoke tests validam o fluxo completo sem rede (mocks).
- Cache e diversidade são observáveis em teste (métricas/thresholds).

## Dependências
- Task 11.0, 12.0, 13.0, 14.0 (componentes a serem testados)
- Infra de testes existente (XCTest)

## Observações
- Manter testes determinísticos (sem aleatoriedade sem seed fixo).
- Evitar dependência de rede; sempre usar mocks.

## markdown

## status: completed # Options: pending, in-progress, completed, excluded

<task_context>
<domain>testing/workout-composition</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Task 15.0: F8 — Testes e cobertura para composição/caching

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Como a geração de treino é o core do FitToday, precisamos de uma suite de testes que garanta consistência, robustez e diversidade. Esta tarefa cria fixtures, testes determinísticos e smoke tests do fluxo completo, com mocks para OpenAI, assegurando que objetivo/local influenciem de fato a composição.

<requirements>
- Fixtures por objetivo/local (inputs)
- Testes determinísticos (seed/versão)
- Testes de diversidade mínima (quality gate)
- Testes do cache (TTL + hash estável)
- Smoke test do fluxo completo com mocks
- Critério mínimo de cobertura e checklist de QA
</requirements>

## Subtasks

- [ ] 15.1 Criar fixtures de profiles/check-ins representativos (objetivo/local)
- [ ] 15.2 Testar blueprint engine (determinismo e aderência)
- [ ] 15.3 Testar prompt assembly (conteúdo por objetivo/local + blueprint)
- [ ] 15.4 Testar validação/diversidade (thresholds e reprovação)
- [ ] 15.5 Testar cache (hit/miss, TTL, blueprintVersion no hash)
- [ ] 15.6 Smoke tests de fluxo (mocks) e definir targets mínimos de cobertura

## Implementation Details

- Referenciar `techspec.md` para padrões de testes, mocks e arquitetura.
- Referenciar `prd.md` seção F8 (Test Coverage) e objetivos de robustez.

## Success Criteria

- Testes falham quando o fluxo volta a gerar treinos “iguais” para entradas diferentes.
- Testes garantem que cache não mascara bugs (ex.: hash errado).
- Testes são estáveis e não flake (seed fixo, mocks).

## Relevant Files
- `tasks/prd-performance-quality-sprint/prd.md`
- `tasks/prd-performance-quality-sprint/techspec.md`
- `FitToday/FitTodayTests/` (novos testes de composição/caching)
- `FitToday/FitToday/Domain/` (blueprint/validator)
- `FitToday/FitToday/Data/` (cache SwiftData)

