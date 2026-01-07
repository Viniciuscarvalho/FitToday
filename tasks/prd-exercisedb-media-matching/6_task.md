# [6.0] Testes unitários e smoke para ranking/resolução (M)

## Objetivo
- Garantir que a heurística de match e ranking seja determinística e mantenha cobertura alta, com testes unitários para normalização/ranking e smoke tests para fluxo de resolução (via mocks).

## Subtarefas
- [ ] 6.1 Criar testes unitários para normalização/tokenização de nomes
- [ ] 6.2 Criar testes unitários para ranking determinístico (equipamento + tokens)
- [ ] 6.3 Criar smoke tests com mock de `ExerciseDBServicing` para validar fluxo por target e fallback por nome
- [ ] 6.4 Garantir que testes não dependam de rede/chaves reais

## Critérios de Sucesso
- Testes rodam localmente e validam seleção determinística de candidatos.
- Smoke tests validam que `resolveMedia` retorna URL quando o mock fornece candidatos.

## Dependências
- 3.0 (resolver por target + ranking)

## Observações
- Evitar acoplamento a implementações internas; preferir testar funções puras/isoladas (normalização e ranking).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 6.0: Testes unitários e smoke para ranking/resolução

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Heurísticas sem testes tendem a regredir. Precisamos validar: (1) normalização/tokenização, (2) ranking determinístico e (3) fluxo de resolução com mocks, sem depender da rede.

<requirements>
- Unit tests para normalização e ranking.
- Smoke tests para fluxo por target e fallback por nome.
- Nenhuma dependência de rede ou chaves reais.
</requirements>

## Subtarefas

- [ ] 6.1 Adicionar tests em `FitTodayTests` para normalização (casos: Lever Pec Deck Fly etc.)
- [ ] 6.2 Adicionar tests para ranking com candidatos sintéticos
- [ ] 6.3 Criar mock `ExerciseDBServicing` e validar `resolveMedia(for:)`
- [ ] 6.4 Cobrir fallback para placeholder em erro

## Detalhes de Implementação

- Referenciar **Abordagem de Testes** em `techspec.md`.

## Critérios de Sucesso

- Suite de testes passa sem network.
- Cobertura mínima para os métodos de normalização/ranking e caminho target-first.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseMediaResolver.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitTodayTests/FitTodayTests.swift`


