# [8.0] Testes e QA: unit + UI + checklist manual (M)

## Objetivo
- Cobrir o Workouts v2 com testes mínimos e checklist manual para garantir qualidade (mídia, navegação e geração).

## Subtarefas
- [ ] 8.1 Unit tests: MediaResolver, Validator, composer (local/AI com mocks)
- [ ] 8.2 UI tests: Biblioteca -> detalhe -> exercício; Home -> questionário -> treino -> exercício
- [ ] 8.3 Checklist manual (rede ruim, offline, falha OpenAI)

## Critérios de Sucesso
- Principais fluxos passam em CI/local sem flakiness.
- Erros de mídia/OpenAI não quebram UX.

## Dependências
- 1.0 a 7.0 implementadas (ou parcialmente prontas para testes).

## Observações
- Para UI tests, preferir dados seed estáveis e desabilitar animações quando necessário.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/testing</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>temporal</dependencies>
</task_context>

# Tarefa 8.0: Testes e QA: unit + UI + checklist manual

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Garantir que o Workouts v2 seja confiável com uma base de testes e um checklist manual prático, cobrindo navegação e regressões comuns (mídia e geração).

<requirements>
- Mocks para OpenAI (`OpenAIClienting`) e repositórios quando necessário
- Testes de validação do plano e do resolver
- UI tests para fluxos críticos
</requirements>

## Subtarefas

- [ ] 8.1 Implementar unit tests dos componentes novos
- [ ] 8.2 Implementar UI tests dos fluxos principais

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Abordagem de Testes”, “Riscos Conhecidos”).

## Critérios de Sucesso

- Cobertura mínima dos fluxos principais
- Sem crashes em cenários de erro

## Arquivos relevantes
- `FitToday/FitTodayTests/`
- `FitToday/FitTodayUITests/`


