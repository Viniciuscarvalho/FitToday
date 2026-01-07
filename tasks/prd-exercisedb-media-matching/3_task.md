# [3.0] Resolver exerciseId por target + ranking determinístico no ExerciseMediaResolver (M)

## Objetivo
- Atualizar o `ExerciseMediaResolver` para resolver `exerciseDBId` preferindo fluxo por `target` (músculo-alvo), ranquear candidatos e persistir o mapeamento `localExerciseId -> exerciseDBId` para maximizar cobertura e estabilidade.

## Subtarefas
- [ ] 3.1 Derivar target a partir de `WorkoutExercise.mainMuscle` e validar com `targetList`
- [ ] 3.2 Buscar candidatos via `GET /exercises/target/{target}` quando válido
- [ ] 3.3 Implementar ranking determinístico (equipamento + tokens do nome)
- [ ] 3.4 Persistir mapping e garantir cache por resolução (já existente)

## Critérios de Sucesso
- Exercícios como “Lever Pec Deck Fly” passam a resolver um `exerciseDBId` com maior frequência (cobertura).
- O mesmo exercício local resolve o mesmo `exerciseDBId` enquanto o mapping persistido existir.

## Dependências
- 1.0 endpoints no `ExerciseDBService`
- 2.0 catálogo de targets com TTL

## Observações
- Manter fallback por nome (não remover); apenas ajustar ordem de tentativa.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 3.0: Resolver exerciseId por target + ranking determinístico no ExerciseMediaResolver

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O problema principal de mídia é a divergência de nomes entre o catálogo local e o ExerciseDB. Ao usar o target (músculo-alvo) como chave de busca, conseguimos candidatos mais relevantes e aumentar cobertura. Esta tarefa adapta o resolver para usar `targetList` + `target/{target}` antes de tentar match por nome.

<requirements>
- Derivar target a partir de `MuscleGroup`.
- Validar target com `ExerciseDBTargetCatalog`.
- Buscar candidatos por target.
- Ranquear candidatos e escolher determinísticamente.
- Persistir mapping `localExerciseId -> exerciseDBId`.
</requirements>

## Subtarefas

- [ ] 3.1 Criar tabela `MuscleGroup -> target` guiada por `targetList` (fallback quando inexistente)
- [ ] 3.2 Implementar fluxo por target no `resolveExerciseDBId(...)`
- [ ] 3.3 Implementar ranking (equipamento + similaridade de nome) com logs DEBUG de score
- [ ] 3.4 Persistir mapping e manter cache por resolução (`resolvedCache`)

## Detalhes de Implementação

- Referenciar as seções **Heurística de Resolução** e **Cache** de `techspec.md`.

## Critérios de Sucesso

- Para uma amostra de exercícios, pelo menos 80–90% resolvem alguma mídia (objetivo de cobertura).
- O resolver não realiza chamadas redundantes quando já há mapping cacheado.
- Em erro de rede/HTTP, retorna placeholder e segue o app normalmente.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseMediaResolver.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Domain/Entities/DailyCheckIn.swift` (MuscleGroup)
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift` (EquipmentType, WorkoutExercise)


