# [1.0] ExerciseMediaResolver + cache/placeholder (M)

## Objetivo
- Implementar um resolver centralizado de mídia para exercícios (ExerciseDB v2), garantindo GIF/imagem com fallback e cache, para estabilizar a UI e evitar falhas de carregamento.

## Subtarefas
- [x] 1.1 Criar `ExerciseMediaResolver` (`ExerciseMediaResolving`) com regra de prioridade (gif -> image -> placeholder)
- [x] 1.2 Integrar resolver na UI (Biblioteca e Treino) para usar URLs normalizadas
- [x] 1.3 Adicionar cache/fallback e logs de falha de mídia (debug)

## Critérios de Sucesso
- Mídia (GIF/imagem) carrega de forma consistente quando disponível; em falha, placeholder aparece sem travar UI.
- URLs seguem o padrão `https://v2.exercisedb.io/image/{id}` quando não houver URL explícita.
- Não há trabalho pesado em `body` nem layout instável em listas.

## Dependências
- `tasks/prd-workouts-v2/prd.md`
- `tasks/prd-workouts-v2/techspec.md`

## Observações
- `AsyncImage` pode não animar GIF dependendo do formato; se necessário, adotar fallback via `WKWebView`.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/media</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 1.0: ExerciseMediaResolver + cache/placeholder

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Criar um componente único responsável por resolver URLs de mídia (GIF/imagem) a partir do `exerciseId` e padronizar sua utilização em todas as telas que exibem exercícios.

<requirements>
- Resolver URLs para `v2.exercisedb.io` quando `gifURL/imageURL` estiverem ausentes
- Priorizar GIF quando existir; fallback para imagem; fallback final para placeholder
- Adicionar cache/fallback e logs de falha em DEBUG
</requirements>

## Subtarefas

- [x] 1.1 Implementar `ExerciseMediaResolving` e `ExerciseMediaResolver`
- [x] 1.2 Atualizar UI para usar `resolvedMedia(...)`

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Interfaces Principais”, “Endpoints de API”, “Pontos de Integração”).

## Critérios de Sucesso

- Lista de exercícios não “pisca”/recalcula layout por causa de mídia
- Falhas de rede mostram placeholder sem crash

## Arquivos relevantes
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift`
- `FitToday/FitToday/Presentation/Features/Library/LibraryDetailView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutExerciseDetailView.swift`

