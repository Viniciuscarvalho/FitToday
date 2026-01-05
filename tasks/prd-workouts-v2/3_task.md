# [3.0] UX Biblioteca: thumbnails, detalhe do treino, detalhe do exercício (M)

## Objetivo
- Melhorar a Biblioteca para exibir treinos e exercícios com mídia confiável e permitir abrir o detalhe do exercício ao tocar.

## Subtarefas
- [x] 3.1 Adicionar thumbnails de treino/exercício usando `ExerciseMediaResolver`
- [x] 3.2 Garantir navegação: Library -> Workout Detail -> Exercise Detail
- [x] 3.3 Ajustar layout e acessibilidade seguindo Design System

## Critérios de Sucesso
- Ao tocar um exercício no detalhe do treino da biblioteca, abre a tela de detalhe com mídia (GIF/imagem) e instruções.
- UI consistente com tema dark e componentes em `DesignSystem/`.

## Dependências
- 1.0 ExerciseMediaResolver + cache/placeholder
- 2.0 Normalização de IDs e mídia no catálogo

## Observações
- Evitar trabalho pesado em `body`: pré-computar dados no view model quando necessário.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/ui-library</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 3.0: UX Biblioteca: thumbnails, detalhe do treino, detalhe do exercício

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Reforçar a Biblioteca como entrada “free” de alta qualidade: visual, confiável e com detalhe por exercício.

<requirements>
- Exibir thumbnails com placeholder e tamanho fixo
- Permitir abrir detalhe do exercício ao tocar na lista
- Acessibilidade: labels e touch targets
</requirements>

## Subtarefas

- [x] 3.1 Ajustar `LibraryView` para thumbnails e cards consistentes
- [x] 3.2 Ajustar `LibraryDetailView` para navegação de exercício (novo route ou sheet)

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Presentation”, “Performance”, “Abordagem de Testes”).

## Critérios de Sucesso

- Navegação consistente: nenhum “tap” morto
- Placeholder aparece em falhas sem travar scroll

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Library/LibraryView.swift`
- `FitToday/FitToday/Presentation/Features/Library/LibraryDetailView.swift`

