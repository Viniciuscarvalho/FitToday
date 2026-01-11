# [7.0] Performance/Observabilidade: imagens, invalidations e logs (M)

## Objetivo
- Garantir que a experiência com mídia e listas seja performática e observável (diagnóstico de falhas), seguindo boas práticas SwiftUI.

## Subtarefas
- [ ] 7.1 Revisar listas e evitar invalidation storms (IDs estáveis, pré-cálculos fora do `body`)
- [ ] 7.2 Ajustar cache de imagens e tamanhos fixos (evitar decode pesado na main)
- [ ] 7.3 Adicionar logs/contadores em DEBUG (cache hit/miss, falhas de mídia)

## Critérios de Sucesso
- Scroll suave em listas com thumbnails.
- Sem alocações pesadas de formatters/imagens dentro de `body`.
- Logs úteis em DEBUG para falhas de mídia e OpenAI.

## Dependências
- 1.0 ExerciseMediaResolver + cache/placeholder
- 3.0 UX Biblioteca
- 4.0 UX Treino Gerado

## Observações
- Seguir `swiftui-performance-audit` para smells comuns.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/performance</domain>
<type>testing</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>temporal</dependencies>
</task_context>

# Tarefa 7.0: Performance/Observabilidade: imagens, invalidations e logs

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O Workouts v2 adiciona mídia e mais navegação. Precisamos garantir performance (listas) e observabilidade (logs) para diagnosticar falhas de mídia/IA.

<requirements>
- IDs estáveis em ForEach e listas
- Evitar computação pesada em `body`
- Logs de falha de mídia e métricas básicas (cache hit/miss) em DEBUG
</requirements>

## Subtarefas

- [ ] 7.1 Rodar revisão de performance nos views principais (Biblioteca/Treino)
- [ ] 7.2 Implementar logs/telemetria local (DEBUG)

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Requisitos Especiais”, “Riscos Conhecidos”, “Abordagem de Testes”).

## Critérios de Sucesso

- Sem travamentos perceptíveis em navegação e scroll
- Logs facilitam reproduzir e corrigir falhas

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Library/LibraryView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutPlanView.swift`



