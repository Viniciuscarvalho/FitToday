# [7.0] Remover atalhos da Home + reestruturar Home (Hero / Top for You / Week’s Workout) (L)

## Objetivo
- Simplificar a Home removendo atalhos confusos e reestruturar a tela em 3 seções: **Hero**, **Top for You**, **Week’s Workout**.

## Subtarefas
- [ ] 7.1 Remover atalhos atuais e consolidar fluxo principal de “iniciar treino”
- [ ] 7.2 Implementar seções e layout (hierarquia, espaçamentos, sticky header se necessário)
- [ ] 7.3 Conectar dados às seções (Programas recomendados e treino da semana)

## Critérios de Sucesso
- Atalhos removidos e navegação fica mais clara.
- Home renderiza 3 seções consistentemente em dark mode.
- Conteúdo é carregado com estados de loading/empty claros.

## Dependências
- Depende de 4.0/5.0 (Programas) e 9.0 (recomendação) para conteúdo final, mas layout pode começar antes.

## Observações
- Manter performance: evitar recomputar arrays pesados no `body`.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/home</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 7.0: Reestruturar Home (Hero / Top for You / Week’s Workout)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

A Home atual tem atalhos que confundem a navegação. Vamos removê-los e implementar uma Home mais visual e orientada à recomendação.

<requirements>
- Remover atalhos atuais da Home
- Criar seções: Hero, Top for You, Week’s Workout
- Definir estados de loading/empty e navegação
</requirements>

## Subtarefas

- [ ] 7.1 Refatorar `HomeView` em subviews (Hero/Top/Week) e remover atalhos
- [ ] 7.2 Ajustar `HomeViewModel` para expor estado estável e alimentar as seções

## Detalhes de Implementação

- Referenciar “Home reestruturada” em `prd.md` e “Presentation/HomeView” em `techspec.md`.

## Critérios de Sucesso

- Home clara, sem atalhos, com 3 seções e navegação funcional

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/FitToday/Presentation/Features/Home/HomeViewModel.swift`


