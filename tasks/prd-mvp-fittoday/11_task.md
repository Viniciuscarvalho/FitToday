# [11.0] Biblioteca Free: treinos fixos por objetivo/estrutura (M)

## Objetivo
- Implementar a Biblioteca (Free) com treinos fixos e navegação para iniciar um treino básico sem adaptação diária.

## Subtarefas
- [ ] 11.1 Definir catálogo Free (treinos básicos) usando os blocos curados (ou uma camada “Workouts” em cima de blocos).
- [ ] 11.2 Implementar tela de Biblioteca com filtros simples (objetivo/estrutura).
- [ ] 11.3 Implementar detalhe do treino básico e “Iniciar treino”.
- [ ] 11.4 Reutilizar a UI do treino/exercício (tarefa 9) quando possível.
- [ ] 11.5 Garantir que Biblioteca funciona offline.

## Critérios de Sucesso
- Usuário Free consegue navegar e iniciar um treino básico.
- Conteúdo é claro e consistente com o design.

## Dependências
- 2.0 Design System.
- 3.0 Domain.
- 4.0 Data (blocos/ catálogo local).
- 9.0 UI do treino (para reutilizar execução).

## Observações
- A Biblioteca é o caminho “sem Pro” e precisa ser bem organizada e rápida.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/library</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 11.0: Biblioteca Free

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Biblioteca com treinos fixos e básicos para usuários Free. Deve ser simples, rápida e funcionar offline.

<requirements>
- Lista de treinos fixos por objetivo/estrutura.
- Iniciar treino básico (sem adaptação diária).
- Reutilizar o máximo possível da UI do treino.
</requirements>

## Subtarefas

- [ ] 11.1 Implementar catálogo e modelagem para biblioteca.
- [ ] 11.2 Implementar telas de listagem/detalhe e CTA iniciar.
- [ ] 11.3 Integrar com fluxo de execução do treino (reuso).

## Detalhes de Implementação

Referenciar:
- “Biblioteca de Treinos (Free)” em `prd.md`.
- “WorkoutBlocksRepository” e modelagem em `techspec.md`.

## Critérios de Sucesso

- Usuário Free completa o fluxo Biblioteca → Iniciar treino sem paywall.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`



