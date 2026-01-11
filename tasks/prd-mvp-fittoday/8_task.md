# [8.0] Motor de treino: combinação de blocos + ajuste por dor + geração local (L)

## Objetivo
- Implementar a geração do treino do dia usando **apenas blocos curados**, respeitando perfil + foco + dor, e produzindo um `WorkoutPlan` consistente para a UI.

## Subtarefas
- [ ] 8.1 Definir regras de seleção de blocos (compatibilidade com objetivo/nível/estrutura/equipamento).
- [ ] 8.2 Implementar ajuste por dor (reduz séries/reps, aumenta descanso, remove padrões mais agressivos).
- [ ] 8.3 Implementar ordenação de exercícios e montagem do `WorkoutPlan` (título, duração estimada, intensidade).
- [ ] 8.4 Implementar fallback seguro (sem blocos compatíveis → plano básico “full body leve” a partir de blocos mais genéricos).
- [ ] 8.5 (Opcional) Definir interface `WorkoutPlanComposer` para futura integração OpenAI sem mudar a UI.

## Critérios de Sucesso
- Plano gerado nunca contém exercícios fora do catálogo/blocos.
- Geração é rápida e não bloqueia a UI (async).
- Regras são testadas (unit tests do UseCase).

## Dependências
- 3.0 Domain (modelos/usecases).
- 4.0 Data (blocos carregados do JSON).
- 7.0 Questionário diário (inputs do check-in).

## Observações
- Manter algoritmo determinístico inicialmente (bom para testes e previsibilidade).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>domain/workout-engine</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 8.0: Motor de treino (blocos curados)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O coração do app: montar treino seguro sem “inventar”. A IA (se existir) não cria exercícios — apenas ajuda a combinar blocos. No MVP, começamos com combinação local robusta e deixamos interface pronta para evoluir.

<requirements>
- Usar somente blocos/exercícios curados.
- Ajustar volume/intensidade conforme dor.
- Produzir `WorkoutPlan` para UI.
</requirements>

## Subtarefas

- [ ] 8.1 Implementar `GenerateWorkoutPlanUseCase` com regras.
- [ ] 8.2 Implementar ajuste por dor e cálculo de duração.
- [ ] 8.3 Implementar fallback seguro e casos extremos.
- [ ] 8.4 Adicionar testes unitários do motor.

## Detalhes de Implementação

Referenciar:
- “Motor de Treino” em `prd.md`.
- “UseCases / GenerateWorkoutPlanUseCase” em `techspec.md`.

## Critérios de Sucesso

- Todos os exercícios do plano existem no catálogo.
- Testes cobrem dor leve/moderada/forte e diferentes estruturas/níveis.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





