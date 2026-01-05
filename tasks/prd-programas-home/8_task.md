# [8.0] Implementar UI de cards: ProgramCard (large/small) + WorkoutCard (L)

## Objetivo
- Criar componentes de UI reutilizáveis para a nova Home e Programas:
  - `ProgramCard` grande (imagem, nome, duração, CTA)
  - `ProgramCard` small (horizontal, sem CTA grande; tap → detalhe)
  - `WorkoutCard` (imagem, tipo, tempo, badge de intensidade)

## Subtarefas
- [ ] 8.1 Desenhar e implementar `ProgramCardLarge` com overlay e CTA
- [ ] 8.2 Implementar `ProgramCardSmall` e `WorkoutCard` com badges e tokens do Design System
- [ ] 8.3 Integrar os cards na Home e na listagem de Programas (collection)

## Critérios de Sucesso
- Cards seguem Design System (cores/spacing/raio) e ficam legíveis em dark mode.
- Coleções rodam suave (sem layout thrash) com placeholders de imagem.

## Dependências
- Depende de 3.0 (mídia) para imagens reais, mas pode usar placeholders.
- Depende de 4.0/5.0 (Programas) para dados reais.

## Observações
- Evitar computação pesada no `body` e garantir identidade estável em `ForEach`.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/designsystem</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 8.0: Implementar cards (Program/Workout)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Cards são a base visual da nova Home e da nova listagem em coleção. Precisam ser consistentes e performáticos.

<requirements>
- Implementar ProgramCard large/small e WorkoutCard
- Usar tokens/componentes do Design System
- Integrar nos lugares de uso (Home/Programas)
</requirements>

## Subtarefas

- [ ] 8.1 Criar componentes SwiftUI e previews
- [ ] 8.2 Integrar com `ExerciseMediaImage` (placeholder + carregamento)

## Detalhes de Implementação

- Referenciar “Cards” no `prd.md` e componentes em `techspec.md`.

## Critérios de Sucesso

- Cards renderizam bem e são reutilizados em Home e Programas

## Arquivos relevantes
- `FitToday/FitToday/Presentation/DesignSystem/`
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/FitToday/Presentation/Features/Library/` (Programas)


