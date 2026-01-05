# [4.0] Data: SwiftData + loader JSON de blocos + mappers e repos concretos (L)

## Objetivo
- Implementar a camada Data com persistência local via SwiftData (perfil, histórico, snapshot Pro) e carregamento de blocos curados via JSON no bundle, expondo repositórios concretos que atendem aos protocolos do Domain.

## Subtarefas
- [ ] 4.1 Definir modelos SwiftData: perfil, histórico, snapshot de entitlement Pro.
- [ ] 4.2 Implementar mappers (SwiftData ↔ Domain) e DTOs se necessário.
- [ ] 4.3 Criar schema JSON de blocos de treino e um loader robusto (validação e fallback).
- [ ] 4.4 Implementar `BundleWorkoutBlocksRepository` (carrega blocos do bundle).
- [ ] 4.5 Implementar `SwiftDataUserProfileRepository` e `SwiftDataWorkoutHistoryRepository`.
- [ ] 4.6 Implementar `EntitlementRepository` (cache local + integração StoreKit em tarefa 12).

## Critérios de Sucesso
- Perfil e histórico persistem entre aberturas do app.
- Loader de JSON lida com erros sem crash (fallback seguro).
- Repositórios são async, thread-safe e aderentes aos protocolos do Domain.

## Dependências
- 1.0 Fundação (estrutura e DI).
- 3.0 Domain (protocolos e modelos).

## Observações
- SwiftData já existe no template; reutilizar a infra (`ModelContainer`) em `FitTodayApp`.
- Evitar fazer parsing pesado no `body`; loader deve ser async e cacheado.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>data/persistence</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 4.0: Data (SwiftData + JSON + Repos)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Construir a base de dados local do MVP. O perfil e histórico precisam existir offline. Os blocos curados devem ser carregados do bundle via JSON para alimentar o motor de treino com segurança e consistência.

<requirements>
- SwiftData para persistir perfil/histórico/pro snapshot.
- Loader JSON robusto para blocos (sem crash).
- Repositórios concretos aderentes aos protocolos do Domain.
</requirements>

## Subtarefas

- [ ] 4.1 Criar modelos SwiftData e atualizar schema/configuração do container.
- [ ] 4.2 Implementar mappers Domain↔SwiftData.
- [ ] 4.3 Definir e adicionar JSON de blocos ao bundle + loader.
- [ ] 4.4 Implementar repositórios concretos (perfil/histórico/blocos).
- [ ] 4.5 Garantir concorrência segura (async/await e `@MainActor` apenas na UI).

## Detalhes de Implementação

Referenciar:
- “Data / Persistência” e “Modelos de Dados (SwiftData)” em `techspec.md`.
- “Banco de blocos” e “Motor de treino” em `prd.md`.

## Critérios de Sucesso

- Persistência local funcional em device/simulator (não in-memory).
- Repositórios retornam dados consistentes e não bloqueiam a UI.

## Arquivos relevantes
- `FitToday/FitToday/FitTodayApp.swift`
- `FitToday/FitToday/Item.swift`
- `tasks/prd-mvp-fittoday/techspec.md`



