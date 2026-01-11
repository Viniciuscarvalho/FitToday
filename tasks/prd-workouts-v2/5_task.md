# [5.0] Motor Local “especialista”: estrutura completa por objetivo + validação (L)

## Objetivo
- Elevar a geração local para produzir treinos completos e coerentes, guiados pelos perfis de `personal-active/`, com validação mínima de qualidade.

## Subtarefas
- [ ] 5.1 Definir regras de completude (mínimo de exercícios, distribuição, prescrição coerente)
- [ ] 5.2 Implementar `WorkoutPlanValidator` e aplicá-lo na geração local
- [ ] 5.3 Ajustar composição local por objetivo (força pura, emagrecimento, performance, condicionamento)

## Critérios de Sucesso
- Todo treino gerado localmente contém estrutura (aquecimento/principais/acessórios) conforme objetivo.
- DOMS alto reduz volume/intensidade e evita falha/impacto conforme guias.
- Planos inválidos são rejeitados e regenerados com fallback interno.

## Dependências
- 1.0 ExerciseMediaResolver + cache/placeholder (para consistência final)

## Observações
- Esta tarefa é base do fallback quando OpenAI falhar; deve funcionar bem sozinha.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/workout-engine</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>temporal</dependencies>
</task_context>

# Tarefa 5.0: Motor Local “especialista”: estrutura completa por objetivo + validação

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Implementar um conjunto de regras/heurísticas que transforme o gerador local em um gerador “de especialista”, usando como referência os arquivos em `personal-active/`. O resultado deve ser um treino completo e seguro, mesmo sem OpenAI.

<requirements>
- Estrutura da sessão alinhada ao objetivo (força, emagrecimento, performance, condicionamento)
- Ajuste por DOMS e motivação conforme guias (redução 10–35% com DOMS alto)
- Validação pós-geração: plano mínimo e prescrição coerente
</requirements>

## Subtarefas

- [ ] 5.1 Criar `WorkoutPlanValidating` + implementação `WorkoutPlanValidator`
- [ ] 5.2 Atualizar `LocalWorkoutPlanComposer` para seguir regras por objetivo

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Modelos de Dados”, “Decisões Principais”, “Riscos Conhecidos”).

## Critérios de Sucesso

- Treino gerado é consistente e completo para cada objetivo
- Fallback local cobre 100% dos casos em erro de OpenAI

## Arquivos relevantes
- `FitToday/FitToday/Domain/UseCases/LocalWorkoutPlanComposer.swift`
- `personal-active/performance.md`
- `personal-active/força-pura.md`
- `personal-active/emagrecimento.md`
- `personal-active/condicionamento-fisico.md`



