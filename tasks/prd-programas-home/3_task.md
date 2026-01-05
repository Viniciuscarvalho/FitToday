# [3.0] Integrar RapidAPI ExerciseDB `/image` (cache/placeholder) com key no Keychain (M)

## Objetivo
- Buscar e exibir mídia (imagem/GIF) dos exercícios via RapidAPI ExerciseDB `/image`, usando `resolution` e `exerciseId`, com `x-rapidapi-key` no Keychain (sem commitar).

## Subtarefas
- [ ] 3.1 Revisar `ExerciseDBService` (GETs existentes) e adicionar endpoint `/image` com parâmetros obrigatórios
- [ ] 3.2 Criar/ajustar resolver de mídia para escolher `resolution` por contexto (card vs detalhe) e aplicar placeholder/cache
- [ ] 3.3 Tratar erros e registrar logs não sensíveis; validar UX em listas e detalhes

## Critérios de Sucesso
- Mídia carrega via RapidAPI quando key presente no Keychain.
- Placeholder aparece de forma estável quando falhar/sem key.
- Nenhum header sensível é logado.

## Dependências
- Depende de 2.0 (Keychain + key RapidAPI).

## Observações
- Endpoint ref: https://exercisedb.p.rapidapi.com/image?resolution=...&exerciseId=...

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>infra/integration</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 3.0: Integrar RapidAPI ExerciseDB `/image`

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Implementar integração de mídia usando o endpoint `/image` da RapidAPI, com chaves no Keychain e parâmetros obrigatórios `resolution` e `exerciseId`.

<requirements>
- Implementar chamada `GET /image` com headers RapidAPI
- Exigir `resolution` e `exerciseId`
- Placeholder/caching e tratamento de erro sem vazamento de segredos
</requirements>

## Subtarefas

- [ ] 3.1 Implementar requisição (URLComponents) e parsing do retorno (se aplicável)
- [ ] 3.2 Integrar com `ExerciseMediaImage`/componentes de UI usando `AsyncImage` + placeholder
- [ ] 3.3 Definir defaults de `resolution` (card/detalhe) e validar performance

## Detalhes de Implementação

- Referenciar “RapidAPI ExerciseDB `/image`” em `techspec.md`.
- Conferir o endpoint no playground: [RapidAPI ExerciseDB endpoint](https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb/playground/apiendpoint_746ab174-9373-496e-9c2d-5a1a0c0954f7)

## Critérios de Sucesso

- Mídia carrega com key válida no Keychain
- Placeholder e fallbacks funcionam sem travar UI

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Presentation/DesignSystem/ExerciseMediaImage.swift`

