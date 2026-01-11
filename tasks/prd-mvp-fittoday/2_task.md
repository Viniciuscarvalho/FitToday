# [2.0] Design System SwiftUI + componentes base (M)

## Objetivo
- Criar um conjunto de componentes e tokens visuais (cores, tipografia, espaçamento) para acelerar a implementação das telas do MVP com consistência, inspirando-se no kit “Gym App UI Kit” e respeitando HIG (touch targets, contraste, estados).

## Subtarefas
- [ ] 2.1 Definir tokens: cores (light/dark), tipografia, espaçamentos e raios (design system).
- [ ] 2.2 Criar componentes base: `PrimaryButton`, `SecondaryButton`, `Card`, `OptionCard` (seleção), `Badge`, `SectionHeader`.
- [ ] 2.3 Criar componentes de fluxo: `StepperHeader` (1/6 etc.), `ProgressPill`, `PaywallFeatureRow`.
- [ ] 2.4 Padronizar estilos de lista e células (para Biblioteca e Histórico) com identidade estável.
- [ ] 2.5 Acessibilidade: labels, contraste, tamanhos mínimos 44pt, suporte a `Reduce Motion` onde aplicável.

## Critérios de Sucesso
- Componentes são reutilizados por múltiplas telas (onboarding, setup, questionário diário, paywall).
- UI consistente em light/dark e com touch targets adequados.
- Não há lógica pesada no `body` (formatters/cache fora da árvore de views).

## Dependências
- 1.0 Fundação (para integrar em Shell e previews com DI, se necessário).

## Observações
- Referência visual: kit do UI8 (inspirar layout e hierarquia; não copiar assets diretamente).
- Priorizar SwiftUI idiomático e componentes pequenos para reduzir invalidações.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/design-system</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 2.0: Design System SwiftUI + componentes base

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Construir um “kit interno” de UI para acelerar telas do MVP com consistência e performance. A inspiração é o estilo de apps de fitness modernos (cards, hero, CTAs claros), mas com execução alinhada ao padrão iOS.

<requirements>
- Tokens de tema (light/dark) e componentes reutilizáveis.
- Componentes com touch targets ≥ 44pt e estados (normal/pressed/disabled).
- Evitar trabalho pesado em `body` e manter identidades estáveis.
</requirements>

## Subtarefas

- [ ] 2.1 Implementar tokens de tema (cores/typography/spacing).
- [ ] 2.2 Implementar botões e cards reutilizáveis.
- [ ] 2.3 Implementar componentes de stepper e seleção por cards (onboarding/setup/diário).
- [ ] 2.4 Implementar células padrão para listas (histórico/biblioteca).
- [ ] 2.5 Adicionar guidelines de acessibilidade e previews.

## Detalhes de Implementação

Referenciar:
- “Experiência do Usuário” em `prd.md` (cards, stepper, CTA).
- “Performance e acessibilidade” em `techspec.md` (identidade estável, sem trabalho pesado no body).

## Critérios de Sucesso

- Componentes usados por pelo menos 3 features diferentes.
- UI correta em light/dark, com contraste e tamanhos mínimos.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`




