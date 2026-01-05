# [1.0] Corrigir topo/header global (S)

## Objetivo
- Remover o “topo com uma linha”/header indesejado em toda a aplicação, garantindo consistência visual entre tabs e telas.

## Subtarefas
- [ ] 1.1 Identificar origem do header/linha (NavigationStack/toolbar/safeAreaInset) e reproduzir em 2–3 telas (Home, Programas, Histórico)
- [ ] 1.2 Ajustar estilo de navegação/toolbar para remover linha/título indesejado e manter comportamento de navegação correto
- [ ] 1.3 Validar em todas as tabs (incluindo telas empilhadas) e checar dark mode/contraste

## Critérios de Sucesso
- O topo/linha indesejada não aparece em nenhuma tab/tela.
- Navegação e titles/toolbar (quando intencionais) continuam corretos.
- Nenhuma regressão visual óbvia (safe areas, scroll, status bar).

## Dependências
- Nenhuma (pode ser feito primeiro).

## Observações
- Preferir solução centralizada (ex.: estilos globais do NavigationStack/toolbar) para evitar “gambiarras” por tela.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/navigation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 1.0: Corrigir topo/header global

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Hoje a app exibe uma “linha” no topo como se fosse um header permanente. A tarefa é remover isso de forma consistente e sem quebrar a navegação entre tabs.

<requirements>
- Remover a linha/topo indesejado globalmente
- Manter navegação e toolbar/titles intencionais
- Validar em Home/Programas/Histórico
</requirements>

## Subtarefas

- [ ] 1.1 Investigar origem do topo/linha em `TabRootView`/`AppRouter`/telas principais
- [ ] 1.2 Aplicar ajuste de estilo central (toolbar/navigationBar) e remover overrides redundantes

## Detalhes de Implementação

- Referenciar a seção “Ajuste global do topo/header” em `techspec.md`.

## Critérios de Sucesso

- Linha/topo removido em toda a app
- Navegação e layout preservados

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Root/TabRootView.swift`
- `FitToday/FitToday/Presentation/Router/AppRouter.swift`
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`

