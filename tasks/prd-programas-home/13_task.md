# [13.0] Testes unitários + smoke UI (M)

## Objetivo
- Adicionar testes unitários e smoke tests de UI cobrindo as regras críticas (recomendação, IA only Pro, troca 1x) e integrações (Keychain, RapidAPI) com mocks.

## Subtarefas
- [ ] 13.1 Testes unitários do `ProgramRecommender` (objetivo + treinou ontem)
- [ ] 13.2 Testes unitários do estado do treino diário (troca 1x + CTA pós-treino)
- [ ] 13.3 Testes unitários do `KeychainStore` e do `ExerciseDBService` (construção de request sem vazamento)
- [ ] 13.4 Smoke UI: Home → Programas → Detalhe; Home → Treino → Concluir; Histórico → Evolução

## Critérios de Sucesso
- Regras do PRD cobertas por testes determinísticos.
- Integrações são testadas com mocks (sem chamar rede real).
- Smoke UI garante navegação principal.

## Dependências
- Depende das implementações de 2.0–12.0.

## Observações
- Evitar dependência de rede/Keychain real em CI; usar in-memory/mocks.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>testing/quality</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 13.0: Testes unitários + smoke UI

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Adicionar cobertura para garantir que as regras de recomendação, gating Pro e troca do treino não regredirão.

<requirements>
- Testar recomendação e regras de alternância
- Testar estado do treino diário (troca 1x/CTA)
- Testar integração (Keychain/RapidAPI) com mocks
</requirements>

## Subtarefas

- [ ] 13.1 Criar testes unitários para `ProgramRecommender` e `DailyWorkoutState`
- [ ] 13.2 Criar mocks para `KeychainStoring` e cliente HTTP do ExerciseDB

## Detalhes de Implementação

- Referenciar “Abordagem de Testes” em `techspec.md`.

## Critérios de Sucesso

- Suite de testes passa e cobre regras críticas

## Arquivos relevantes
- `FitTodayTests/`
- `FitToday/FitToday/Domain/`
- `FitToday/FitToday/Data/Services/ExerciseDB/`


