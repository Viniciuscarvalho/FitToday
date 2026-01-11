# [6.0] Trocar Tab “Biblioteca” → “Programas” + rotas/navegação (M)

## Objetivo
- Renomear e reorientar a área “Biblioteca” para “Programas”, ajustando navegação, rotas e labels sem quebrar o stack de navegação por tab.

## Subtarefas
- [ ] 6.1 Renomear labels/títulos e ícones na TabBar
- [ ] 6.2 Ajustar rotas do Router (e/ou destinos) para apontar para `ProgramsView`/`ProgramDetailView`
- [ ] 6.3 Verificar deep links/paths e regressões de navegação entre tabs

## Critérios de Sucesso
- Tab exibe “Programas” e abre listagem em collection.
- Detalhe do programa abre corretamente.
- Navegação entre tabs mantém stacks independentes.

## Dependências
- Depende de 4.0/5.0 (Program model + seed) para ter conteúdo real.

## Observações
- Evitar breaking change em rotas persistidas; se necessário, criar compatibilidade (alias).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/navigation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 6.0: Trocar Tab “Biblioteca” → “Programas”

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O app deve apresentar “Programas” como principal área de descoberta (substituindo a Biblioteca).

<requirements>
- Renomear “Biblioteca” para “Programas”
- Ajustar navegação e destinos
- Manter stacks por tab funcionando
</requirements>

## Subtarefas

- [ ] 6.1 Atualizar `TabRootView`/labels/ícones
- [ ] 6.2 Ajustar `AppRouter`/destinos para abrir Programas e detalhe

## Detalhes de Implementação

- Referenciar “Programas (substitui Biblioteca)” em `prd.md` e o item de UI/Router em `techspec.md`.

## Critérios de Sucesso

- A tab e navegação para Programas funcionam sem regressões

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Root/TabRootView.swift`
- `FitToday/FitToday/Presentation/Router/AppRouter.swift`
- `FitToday/FitToday/Presentation/Features/Library/` (será reorientado/renomeado)



