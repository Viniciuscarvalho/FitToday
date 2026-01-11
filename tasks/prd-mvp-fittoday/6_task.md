# [6.0] Home (“Treino de Hoje”) + estados de jornada (M)

## Objetivo
- Implementar a Home como a tela central do app, refletindo o estado do usuário (sem perfil / respondeu hoje / treino disponível) e oferecendo acesso rápido às principais seções.

## Subtarefas
- [ ] 6.1 Criar layout da Home (header com saudação/data/objetivo badge + card “Treino de Hoje”).
- [ ] 6.2 Implementar estados e CTAs:
  - Sem perfil → ir para setup
  - Não respondeu hoje → ir para questionário diário
  - Já respondeu → ver treino do dia
- [ ] 6.3 Integrar com UseCases para carregar perfil e status diário.
- [ ] 6.4 Adicionar cards secundários: Biblioteca, Histórico, Upgrade Pro (se Free).

## Critérios de Sucesso
- Home é a “hub” do app e conduz o usuário ao core loop com 1 toque.
- Estados são determinísticos e atualizam corretamente após ações do usuário.

## Dependências
- 1.0 Fundação (Router/TabRoot/DI).
- 2.0 Design System.
- 3.0 Domain.
- 4.0 Data (perfil/histórico).
- 5.0 Onboarding/Setup (para garantir perfil existente).

## Observações
- Evitar lógica pesada no `body`; preferir ViewModel com estado derivado.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/home</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 6.0: Home (“Treino de Hoje”)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Construir a tela mais importante do MVP: o usuário entende “o que fazer hoje” em segundos, com CTA claro e acesso aos atalhos.

<requirements>
- Mostrar saudação, data e objetivo.
- Card “Treino de Hoje” com CTA contextual.
- Acesso rápido à Biblioteca/Histórico/Pro.
</requirements>

## Subtarefas

- [ ] 6.1 Implementar View + ViewModel da Home.
- [ ] 6.2 Integrar com UseCases (perfil/status diário).
- [ ] 6.3 Integrar com Router (navegação para diário/treino/paywall).

## Detalhes de Implementação

Referenciar:
- “Home – Treino de Hoje” em `prd.md`.
- “Router” e “UseCases” em `techspec.md`.

## Critérios de Sucesso

- CTA correto em cada estado.
- Nenhuma navegação quebra o stack independente por tab.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





