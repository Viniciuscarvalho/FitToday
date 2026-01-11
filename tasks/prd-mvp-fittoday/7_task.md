# [7.0] Questionário diário (2 passos) + roteamento (M)

## Objetivo
- Implementar o fluxo diário com 2 perguntas rápidas e garantir o roteamento correto para paywall (Free) ou geração do treino (Pro).

## Subtarefas
- [ ] 7.1 Implementar tela 1: seleção do foco do treino (cards grandes).
- [ ] 7.2 Implementar tela 2: nível de dor (categorias ou slider 1–10; se alto, capturar região opcional).
- [ ] 7.3 Persistir `DailyCheckIn` (se aplicável) e acionar fluxo “Gerar treino”.
- [ ] 7.4 Implementar decisão de gating:
  - Free → Router abre Paywall
  - Pro → Router segue para “Treino gerado”
- [ ] 7.5 Validar UX (< 10s) e estados (loading/erro/fallback).

## Critérios de Sucesso
- Usuário completa o questionário diário rapidamente e sempre chega ao próximo passo correto (paywall ou treino).
- Dados do check-in alimentam o motor de treino.

## Dependências
- 1.0 Fundação.
- 2.0 Design System.
- 3.0 Domain.
- 6.0 Home (ponto de entrada).
- 12.0 Pro (para gating real). Pode iniciar com stub de entitlement até 12.0.

## Observações
- Mesmo antes da StoreKit estar pronta, implementar o contrato `EntitlementRepository` para permitir stub/fake em dev.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/daily-questionnaire</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 7.0: Questionário diário

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Implementar o core loop do MVP: duas telas, dois toques, e a partir daí o usuário ou vê o paywall (Free) ou recebe o treino (Pro).

<requirements>
- Pergunta 1: foco do treino (cards).
- Pergunta 2: dor muscular.
- Gating Free vs Pro após “Gerar treino”.
</requirements>

## Subtarefas

- [ ] 7.1 Implementar Views + ViewModel do questionário diário.
- [ ] 7.2 Integrar com Router e com `EntitlementRepository`.
- [ ] 7.3 Produzir `DailyCheckIn` e encaminhar para geração do treino.

## Detalhes de Implementação

Referenciar:
- “Questionário Diário” e “Paywall” em `prd.md`.
- “EntitlementRepository” e “Router” em `techspec.md`.

## Critérios de Sucesso

- Fluxo completo do questionário diário funciona sem dependência circular.
- A navegação preserva o stack do tab atual.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





