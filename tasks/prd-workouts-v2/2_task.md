# [2.0] Normalização de IDs e mídia no catálogo (Seed/Repository) (M)

## Objetivo
- Garantir que os IDs de exercícios usados no catálogo local sejam compatíveis com a CDN `v2.exercisedb.io` e que o app tenha fallback quando não houver match.

## Subtarefas
- [x] 2.1 Mapear estratégia de ID (normalização) a partir do catálogo atual
- [x] 2.2 Ajustar loader/repositório para preencher mídia ausente via resolver
- [x] 2.3 Criar checklist/validação de catálogo (IDs inválidos)

## Critérios de Sucesso
- Exercícios do seed exibem mídia quando ID existe; quando não, UI mantém placeholder com mensagem neutra.
- Não há crashes por URL inválida.

## Dependências
- 1.0 ExerciseMediaResolver + cache/placeholder

## Observações
- Essa tarefa reduz inconsistência entre “seed com URLs” e “seed sem URLs” ao centralizar a fonte de verdade no resolver.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/catalog</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 2.0: Normalização de IDs e mídia no catálogo (Seed/Repository)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Padronizar o uso de IDs de exercícios (chave de mídia) e aplicar o `ExerciseMediaResolver` no carregamento do catálogo para garantir consistência.

<requirements>
- Definir regra de normalização/validação de `exerciseId` usado para `v2.exercisedb.io`
- Evitar URLs hardcoded inconsistentes; preferir resolver
- Garantir fallback e logs para IDs sem mídia disponível
</requirements>

## Subtarefas

- [x] 2.1 Revisar `LibraryWorkoutsSeed.json` e identificar padrão dos IDs atuais
- [x] 2.2 Integrar resolver no `BundleLibraryWorkoutsRepository` (ou ponto equivalente)

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “Modelos de Dados”, “Endpoints de API”, “Decisões Principais”).

## Critérios de Sucesso

- Catálogo carrega sem falhas; mídia é resolvida de forma previsível
- IDs inválidos não quebram a navegação nem impedem o treino

## Arquivos relevantes
- `FitToday/FitToday/Data/Resources/LibraryWorkoutsSeed.json`
- `FitToday/FitToday/Data/Repositories/BundleLibraryWorkoutsRepository.swift`

