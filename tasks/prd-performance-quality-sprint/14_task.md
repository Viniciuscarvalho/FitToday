# [14.0] F7 — Workout Composition Caching (SwiftData + TTL 24h) (M)

## Objetivo
- Implementar cache inteligente de composição por 24h (TTL) em SwiftData para **reutilizar** o treino quando o usuário “regenerar com os mesmos inputs”, reduzindo custo/latência e garantindo consistência. Deve haver fallback transparente quando cache miss e toggle DEBUG para desabilitar.

## Subtarefas
- [x] 14.1 Definir função de hash dos inputs (profile + checkIn + objetivo + local + blueprintVersion + seed) → chave única
- [x] 14.2 Criar modelo SwiftData `SDCachedWorkout` com expiração (TTL 24h) e payload do treino
- [x] 14.3 Criar `WorkoutCompositionCacheRepository` com `getCachedWorkout(for hash:)` e `saveCachedWorkout(...)`
- [x] 14.4 Implementar lógica de expiração/cleanup (remover expirados, não retornar stale)
- [x] 14.5 Adicionar toggle DEBUG para desabilitar cache e logs de cache hit/miss
- [x] 14.6 Testes em XCTest: hash estável, TTL, hit/miss, cleanup

## Critérios de Sucesso
- Regenerar com mesmos inputs dentro de 24h retorna o mesmo treino sem chamar OpenAI.
- Cache expira corretamente e não retorna treinos stale.
- Hash é estável e inclui `blueprintVersion` (evita incompatibilidades).
- Toggle DEBUG funciona e facilita validação.

## Dependências
- Task 11.0 (blueprint + blueprintVersion/seed)
- Persistência SwiftData existente e infraestrutura de repositories

## Observações
- O cache deve ser por **composição** (entrada → treino), não substitui cache de imagens (Fase 1).
- Guardar também metadados úteis (createdAt, expiresAt, objetivo, local) para auditoria.

## markdown

## status: completed # Options: pending, in-progress, completed, excluded

<task_context>
<domain>data/persistence/swiftdata</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Task 14.0: F7 — Workout Composition Caching (SwiftData + TTL 24h)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

O PRD define um cache por 24h para reduzir chamadas redundantes à OpenAI quando o usuário regenera o treino com os mesmos inputs. Esta tarefa adiciona um modelo SwiftData (`SDCachedWorkout`), repository para acesso e regras de expiração/cleanup. Também inclui um toggle DEBUG para desligar o cache durante validação.

<requirements>
- Hash de inputs (profile + checkIn) como chave única (e incluir objetivo/local/blueprintVersion/seed conforme arquitetura)
- `SDCachedWorkout` em SwiftData com TTL 24h
- Repository com `getCachedWorkout(for hash:)` e save
- Expiração/cleanup dos expirados
- Toggle DEBUG para desabilitar cache
- Testes em XCTest (hash, TTL, hit/miss, cleanup)
</requirements>

## Subtasks

- [ ] 14.1 Implementar hash estável e documentado (inputs e versão)
- [ ] 14.2 Implementar SwiftData model `SDCachedWorkout` e migrations necessárias
- [ ] 14.3 Implementar repository (protocol no Domain + implementação no Data)
- [ ] 14.4 Implementar expiração/cleanup e evitar stale reads
- [ ] 14.5 Implementar toggle DEBUG + logs de cache hit/miss
- [ ] 14.6 Testes em XCTest para comportamento do cache

## Implementation Details

- Referenciar `prd.md` seção F7 (Workout Composition Caching).
- Referenciar `techspec.md` para padrões de SwiftData, repositories e testes.

## Success Criteria

- Cache hit evita chamada OpenAI e reduz tempo de geração em regenerações.
- Cache miss/rebuild é transparente e não quebra UX.
- TTL 24h respeitado, sem retornar stale.

## Relevant Files
- `tasks/prd-performance-quality-sprint/prd.md`
- `tasks/prd-performance-quality-sprint/techspec.md`
- `FitToday/FitToday/Data/` (repositories SwiftData)
- `FitToday/FitToday/Domain/Protocols/` (protocol do repository)
- `FitToday/FitToday/Data/Models/SwiftData/` (ou pasta equivalente para models)

