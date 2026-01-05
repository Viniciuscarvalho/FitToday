# [10.0] IA apenas no Pro (capacidades definidas) + fallback Free (M)

## Objetivo
- Garantir que a utilização de IA (OpenAI) ocorra **apenas** quando o usuário for Pro, e apenas para as capacidades previstas: ajuste fino, personalização diária, reordenação de blocos e linguagem/explicações. Usuários Free devem usar sempre a composição local.

## Subtarefas
- [ ] 10.1 Revisar fluxo atual de composição (local/híbrido/OpenAI) e inserir gating central por entitlement
- [ ] 10.2 Garantir que a IA só refine dentro de limites (não inventar exercícios fora do catálogo)
- [ ] 10.3 Definir comportamento em falha/ausência de key: fallback local

## Critérios de Sucesso
- Free nunca chama OpenAI.
- Pro chama OpenAI apenas quando keys estão presentes e regras permitem.
- Falhas de OpenAI não quebram geração: fallback local.

## Dependências
- Depende de 2.0 (Keychain/OpenAI key) e do fluxo de entitlement (já existente).

## Observações
- Não logar prompt contendo dados sensíveis.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/entitlement</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 10.0: IA apenas no Pro

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

A IA é um benefício do plano Pro. Precisamos aplicar o gating corretamente e preservar fallback local.

<requirements>
- IA apenas no Pro
- Capacidades: ajuste fino, personalização diária, reordenação, linguagem/explicações
- Fallback local em erro/ausência de key
</requirements>

## Subtarefas

- [ ] 10.1 Ajustar `GenerateWorkoutPlanUseCase`/composer para consultar `EntitlementRepository`
- [ ] 10.2 Ajustar `OpenAIWorkoutPlanComposer` para schema limitado (IDs do catálogo) e validação

## Detalhes de Implementação

- Referenciar “IA apenas no Pro” em `prd.md` e “IA apenas no Pro” em `techspec.md`.

## Critérios de Sucesso

- Free não chama OpenAI; Pro chama sob condições e com fallback

## Arquivos relevantes
- `FitToday/FitToday/Domain/UseCases/WorkoutPlanUseCases.swift`
- `FitToday/FitToday/Domain/UseCases/EntitlementUseCases.swift`
- `FitToday/FitToday/Data/Services/OpenAI/`


