# [5.0] QA/Polimento e validação end-to-end (M)

## Objective
- Garantir qualidade do rollout (fases 1–3) com validação end-to-end, checklist de privacidade/permissões, e ajustes finais de UX/performance.

## Subtasks
- [ ] 5.1 Rodar checklist de qualidade (pipeline IA, histórico, HealthKit)
- [ ] 5.2 Validar acessibilidade (Dynamic Type, contraste, texto alternativo para gráficos)
- [ ] 5.3 Ajustar mensagens e microcopy (energia baixa/deload, erros de permissão)
- [ ] 5.4 Adicionar/ajustar testes de UI para fluxos críticos (mínimo)
- [ ] 5.5 Revisar regressões de performance (scroll do histórico, cálculo de insights)

## Success Criteria
- Fluxos críticos estáveis:
  - Gerar treino (IA/local)
  - Concluir treino → histórico atualizado
  - Dashboard de progresso renderiza rápido
  - HealthKit conecta/importa/exporta (PRO) e degrada com segurança
- Sem crashes em cenários de permissão negada/sem internet.

## Dependencies
- 1.0, 2.0, 3.0, 4.0 concluídos.

## Notes
- Priorizar device testing para HealthKit.

## markdown

## status: pending # Options: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/qa</domain>
<type>testing</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>external_apis|database</dependencies>
</task_context>

# Task 5.0: QA/Polimento e validação end-to-end

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Consolidar qualidade e UX antes do rollout final.

<requirements>
- Validar fluxo IA e fallback.
- Validar dashboard e paginação.
- Validar HealthKit (PRO) e privacidade.
</requirements>

## Subtasks

- [ ] 5.1 Criar checklist de validação no PR do feature (ou doc interno)
- [ ] 5.2 Ajustar testes e corrigir regressões encontradas

## Implementation Details

Referência: `tasks/prd-ai-workout-v3/techspec.md` (Known Risks + Testing Strategy).

## Success Criteria

- Release candidate estável.

## Relevant Files
- `FitToday/FitToday/Presentation/Features/History/HistoryView.swift`
- `FitToday/FitToday/Data/Services/OpenAI/`
- `FitToday/FitToday/Data/Services/HealthKit/`

