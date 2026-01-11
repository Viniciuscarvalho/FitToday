# [7.0] Hardening de performance: limites, timeouts e prefetch controlado (S)

## Objetivo
- Garantir que a resolução por target não degrade performance: aplicar limites de candidatos, ajustar timeouts e (se necessário) prefetch controlado por tela/contexto.

## Subtarefas
- [ ] 7.1 Definir limites de candidatos por target (ex.: top 20–50) e limitar ranking local
- [ ] 7.2 Revisar timeouts para `targetList`, `target/{target}` e `/image`
- [ ] 7.3 Ajustar prefetch (se aplicável) para evitar burst de requests
- [ ] 7.4 Validar comportamento em redes lentas e offline (fallback/placeholder)

## Critérios de Sucesso
- UI continua responsiva e não há “explosão” de requests ao abrir listas.
- Em rede lenta/offline, o app exibe placeholder e conteúdo textual sem travar.

## Dependências
- 3.0 (resolver por target)

## Observações
- Prefetch deve respeitar o contexto de exibição (`MediaDisplayContext`) e não buscar imagens grandes desnecessariamente.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>implementation</type>
<scope>performance</scope>
<complexity>low</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 7.0: Hardening de performance: limites, timeouts e prefetch controlado

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Buscar candidatos por target pode retornar listas grandes e induzir muitas resoluções de imagem. Precisamos limitar e controlar para manter boa UX e evitar rate limiting.

<requirements>
- Limitar número de candidatos usados no ranking.
- Ajustar timeouts adequados por endpoint.
- Prefetch controlado (se necessário) e sempre com resoluções apropriadas.
</requirements>

## Subtarefas

- [ ] 7.1 Implementar `limit` no fetch por target e limitar ranking local
- [ ] 7.2 Ajustar timeouts e handling de erro por endpoint
- [ ] 7.3 Revisar pontos de prefetch existentes e ajustar para evitar bursts
- [ ] 7.4 Validar offline/timeout com fallback para placeholder

## Detalhes de Implementação

- Referenciar **Pontos de Integração**, **Cache** e **Requisitos Especiais** em `techspec.md`.

## Critérios de Sucesso

- Abertura de listas não dispara requests excessivos.
- A resolução de mídia respeita `MediaDisplayContext` e cache.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseMediaResolver.swift`


