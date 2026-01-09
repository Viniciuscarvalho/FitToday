# [13.0] Pós-validação, normalização e diversidade (quality gate) (M)

## Objetivo
- Implementar uma camada pós-OpenAI que **valida**, **normaliza** e garante **diversidade mínima** do treino gerado, reduzindo treinos “iguais” e evitando saídas inválidas para objetivo/local. Em caso de falha, aplicar retry com feedback ou fallback local.

## Subtarefas
- [ ] 13.1 Definir regras de validação por objetivo/local (estrutura, volume, descansos, presença de cardio quando aplicável)
- [ ] 13.2 Implementar `WorkoutPlanValidator` (Domain) e normalizações (ex.: clamp de sets/reps, ordem de blocos)
- [ ] 13.3 Implementar “diversity gate” (anti-repetição): medir overlap/ordem e aplicar penalidades
- [ ] 13.4 Implementar estratégia de retry/re-prompt com feedback de erro (sem mensagens técnicas ao usuário)
- [ ] 13.5 Instrumentação/logs (DEBUG) com motivos de reprovação e métricas de diversidade
- [ ] 13.6 Testes em XCTest (validação, normalização e diversidade)

## Critérios de Sucesso
- Treinos inválidos são detectados e corrigidos (normalização) ou re-gerados (retry) de forma transparente.
- Métrica de diversidade mínima evita “mesmo treino” quando objetivo/local pedem variação.
- Testes em XCTest cobrem cenários de falha e de correção.

## Dependências
- Task 11.0 (blueprint)
- Task 12.0 (schema JSON + prompt)
- Modelos de plano/execução existentes (Domain)

## Observações
- A validação deve ser **determinística** e independente da UI.
- Em produção, a mensagem ao usuário deve ser amigável; logs técnicos ficam em DEBUG.

## markdown

## status: completed

<task_context>
<domain>domain/workout/validation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Task 13.0: Pós-validação, normalização e diversidade (quality gate)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Mesmo com blueprint e prompt mais robustos, saídas de IA podem variar e, às vezes, violar constraints (objetivo/local) ou gerar treinos repetitivos. Esta tarefa adiciona uma camada pós-processamento que valida e normaliza o plano e aplica um “quality gate” de diversidade. Falhas disparam retry/re-prompt com feedback.

<requirements>
- Validador de plano por objetivo/local (estrutura e compatibilidade)
- Normalização determinística (clamps e ajustes não-destrutivos)
- Diversity gate (anti-repetição) com métricas de overlap/ordem
- Retry/re-prompt com feedback quando necessário
- Logs DEBUG estruturados com motivos e métricas
- Testes em XCTest
</requirements>

## Subtasks

- [ ] 13.1 Mapear regras (PRD + `personal-active/`) para validação por objetivo/local
- [ ] 13.2 Implementar `WorkoutPlanValidator` e `WorkoutPlanNormalizer`
- [ ] 13.3 Implementar `WorkoutDiversityGate` (métrica + thresholds configuráveis)
- [ ] 13.4 Implementar fluxo de retry com feedback (sem mensagens técnicas ao usuário)
- [ ] 13.5 Adicionar logs DEBUG e contadores para auditoria
- [ ] 13.6 Testes em XCTest (plan inválido, normalização, diversidade, retry)

## Implementation Details

- Referenciar `techspec.md` para padrões de error handling e arquitetura.
- Referenciar `prd.md` para objetivos de robustez e consistência (“principal funcionalidade”).

## Success Criteria

- Planos fora do contrato são detectados e não seguem para execução.
- Normalizações resolvem inconsistências comuns sem exigir re-prompt em 100% dos casos.
- Diversity gate reduz taxa de “treinos iguais” de forma observável em testes/fixtures.

## Relevant Files
- `tasks/prd-performance-quality-sprint/prd.md`
- `tasks/prd-performance-quality-sprint/techspec.md`
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift` (ou equivalente)
- `FitToday/FitToday/Domain/UseCases/` (geração de treino)
- `FitToday/FitToday/Data/Services/OpenAI/` (retry/re-prompt)

