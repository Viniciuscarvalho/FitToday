# [2.0] Criar catálogo de targets com cache/TTL (M)

## Objetivo
- Criar um componente responsável por carregar e cachear a lista de `target`s válidos do ExerciseDB, com TTL, evitando chamadas repetidas e permitindo validação rápida durante resolução de mídia.

## Subtarefas
- [ ] 2.1 Criar `ExerciseDBTargetCatalog` (actor) com persistência em `UserDefaults`
- [ ] 2.2 Implementar política de TTL (ex.: 7 dias) e refresh forçado
- [ ] 2.3 Expor API `isValidTarget(_:)` para o resolver
- [ ] 2.4 Integrar o catálogo via DI (`AppContainer`)

## Critérios de Sucesso
- `targetList` é carregado uma vez e reaproveitado até expirar (TTL) ou refresh forçado.
- `isValidTarget` responde rápido usando cache (memória/persistido).

## Dependências
- 1.0 (endpoints `targetList` e `target/{target}` disponíveis no `ExerciseDBService`).

## Observações
- A chave de persistência deve ser versionada (ex.: `exercisedb_target_list_v1`) para facilitar migração.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 2.0: Criar catálogo de targets com cache/TTL

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Para maximizar cobertura e reduzir dependência de match por nome, o resolver vai preferir busca por target. Para isso, precisamos saber quais targets são válidos no ExerciseDB. Esta tarefa cria um catálogo cacheado com TTL usando `GET /exercises/targetList`.

<requirements>
- Criar componente de cache com TTL para `targetList`.
- Persistir em `UserDefaults` para funcionar offline/sem chamadas repetidas.
- Integrar via DI para consumo no `ExerciseMediaResolver`.
</requirements>

## Subtarefas

- [ ] 2.1 Criar arquivo `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBTargetCatalog.swift`
- [ ] 2.2 Implementar persistência `UserDefaults` + TTL
- [ ] 2.3 Implementar `loadTargets(forceRefresh:)` e `isValidTarget(_:)`
- [ ] 2.4 Registrar no DI (`FitToday/FitToday/Presentation/DI/AppContainer.swift`)

## Detalhes de Implementação

- Referenciar **Cache** e **Pontos de Integração** em `techspec.md`.

## Critérios de Sucesso

- Em execução normal, `targetList` é baixado uma vez por TTL.
- Em DEBUG, refresh forçado deve atualizar imediatamente.
- `ExerciseMediaResolver` consegue consultar validade do target sem bloquear UI.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`

