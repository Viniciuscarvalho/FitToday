# [9.0] Implementar recomendação (objetivo + treinou ontem) para “Top for You” e “Week’s Workout” (L)

## Objetivo
- Implementar um recomendador que selecione Programas e/ou treinos para as seções “Top for You” e “Week’s Workout”, seguindo regras de objetivo do usuário e evitando repetir tipo se treinou ontem.

## Subtarefas
- [ ] 9.1 Criar `ProgramRecommender` (Domain) com regras determinísticas e testáveis
- [ ] 9.2 Conectar recomendação no `HomeViewModel` usando perfil + histórico
- [ ] 9.3 Ajustar fallback (quando não houver perfil/histórico) e limitar quantidade de itens

## Critérios de Sucesso
- Com objetivo emagrecimento, recomenda metabolic.
- Com objetivo força, recomenda strength.
- Se treinou ontem, evita repetir tipo e alterna quando possível.

## Dependências
- Depende de 4.0/5.0 (Programas).
- Depende de 12.0 parcialmente se o vínculo programa↔histórico for necessário; caso não exista ainda, usar heurística baseada em “tipo do treino de ontem”.

## Observações
- Priorizar previsibilidade: mesma entrada → mesma saída.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/recommendation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 9.0: Recomendação (objetivo + treinou ontem)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Recomendações são essenciais para a Home: sugerir programas coerentes com objetivo e variar estímulo quando o usuário treinou no dia anterior.

<requirements>
- Implementar `ProgramRecommending` no Domain
- Integrar no `HomeViewModel`
- Definir fallbacks (sem perfil/histórico)
</requirements>

## Subtarefas

- [ ] 9.1 Implementar regras básicas e testes unitários
- [ ] 9.2 Conectar com o histórico para detectar “treinou ontem”

## Detalhes de Implementação

- Referenciar “Recomendação de programas/treinos” no `prd.md` e a interface `ProgramRecommending` em `techspec.md`.

## Critérios de Sucesso

- Recomendação consistente e alinhada às regras do PRD

## Arquivos relevantes
- `FitToday/FitToday/Domain/`
- `FitToday/FitToday/Presentation/Features/Home/HomeViewModel.swift`
- `FitToday/FitToday/Domain/UseCases/HistoryUseCases.swift`


