# [4.0] UX Treino Gerado: lista clicável + detalhe do exercício com execução (M)

## Objetivo
- Garantir que a lista de exercícios do treino gerado permita abrir detalhe com execução (GIF/imagem) e prescrição completa.

## Subtarefas
- [ ] 4.1 Tornar exercícios do `WorkoutPlanView` clicáveis e navegar para detalhe
- [ ] 4.2 Exibir GIF prioritário e prescrição (sets/reps/rest) no detalhe
- [ ] 4.3 Garantir consistência visual com Design System (dark)

## Critérios de Sucesso
- Tocar em qualquer exercício do treino abre detalhe com mídia e instruções.
- Prescrição exibida corretamente e com boa legibilidade.

## Dependências
- 1.0 ExerciseMediaResolver + cache/placeholder

## Observações
- Se a tela atual de detalhe estiver “presa” ao `currentExerciseIndex`, avaliar introduzir um “exerciseId” explícito para navegação.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/ui-workout</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 4.0: UX Treino Gerado: lista clicável + detalhe do exercício com execução

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Melhorar a execução do treino gerado, garantindo que cada exercício tenha uma experiência de detalhe rica e confiável (mídia + prescrição).

<requirements>
- Navegação consistente para detalhe do exercício
- GIF prioritário quando disponível; fallback para imagem
- Prescrição: sets/reps/rest e instruções em bullets
</requirements>

## Subtarefas

- [ ] 4.1 Ajustar `WorkoutPlanView` para suportar tap-to-detail
- [ ] 4.2 Ajustar `WorkoutExerciseDetailView` para consumir mídia resolvida

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Presentation”, “Endpoints de API”, “Riscos Conhecidos”).

## Critérios de Sucesso

- Sem crashes em ausência de mídia
- Sem regressão de navegação (Router/Tab stacks)

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutPlanView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutExerciseDetailView.swift`


