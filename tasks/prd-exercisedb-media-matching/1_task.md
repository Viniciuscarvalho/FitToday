# [1.0] Implementar endpoints TargetList e Target no ExerciseDBService (M)

## Objetivo
- Adicionar suporte no cliente HTTP do ExerciseDB para obter `targetList` e listar exercícios por `target`, mantendo padrão de autenticação RapidAPI e tratamento de erros.

## Subtarefas
- [ ] 1.1 Atualizar `ExerciseDBServicing` com novos métodos (`fetchTargetList`, `fetchExercises(target:)`)
- [ ] 1.2 Implementar `GET /exercises/targetList` no `ExerciseDBService`
- [ ] 1.3 Implementar `GET /exercises/target/{target}` no `ExerciseDBService` com `limit` e cache em memória
- [ ] 1.4 Adicionar logs DEBUG e handling de status code/timeout consistentes

## Critérios de Sucesso
- `ExerciseDBService` consegue buscar `targetList` e exercícios por target, retornando arrays decodificados.
- Erros (timeout/HTTP inválido) são propagados como `ExerciseDBError` e não travam a UI.

## Dependências
- PRD e Tech Spec da pasta `tasks/prd-exercisedb-media-matching/`.

## Observações
- Usar `ExerciseDBConfiguration` para headers RapidAPI (`x-rapidapi-key`, `x-rapidapi-host`).
- Garantir que o `baseURL` continue sendo `https://exercisedb.p.rapidapi.com`.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 1.0: Implementar endpoints TargetList e Target no ExerciseDBService

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O app atualmente resolve mídia via busca por nome e endpoint `/image`, mas falta suporte a endpoints que permitem uma estratégia baseada em `target` (músculo-alvo). Esta tarefa adiciona os endpoints necessários no `ExerciseDBService` para que o resolver possa usar `targetList` e `target/{target}`.

<requirements>
- Adicionar métodos novos ao protocolo `ExerciseDBServicing`.
- Implementar `GET /exercises/targetList`.
- Implementar `GET /exercises/target/{target}` com suporte a `limit`.
- Manter autenticação RapidAPI e tratamento de erros/timeout consistente.
</requirements>

## Subtarefas

- [ ] 1.1 Atualizar `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift` (protocolo e implementação) com os novos métodos
- [ ] 1.2 Implementar request/parse de `targetList` (lista de strings)
- [ ] 1.3 Implementar request/parse de `target/{target}` (lista de `ExerciseDBExercise`)
- [ ] 1.4 Garantir caching em memória e logs DEBUG úteis

## Detalhes de Implementação

- Referenciar a seção **Endpoints de API** e **Pontos de Integração** em `techspec.md` desta pasta.

## Critérios de Sucesso

- `fetchTargetList()` retorna uma lista de targets válida quando a chave está configurada.
- `fetchExercises(target:limit:)` retorna candidatos para targets conhecidos.
- Em falhas (HTTP != 2xx, timeout), o erro é tratável e não quebra o fluxo de UI.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBConfiguration.swift`


