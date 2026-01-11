# [5.0] Onboarding + Setup (Questionário inicial com stepper) (L)

## Objetivo
- Implementar o fluxo inicial: 3 telas de onboarding + questionário inicial (6 passos, 1 pergunta por tela) para criar e persistir o `UserProfile`.

## Subtarefas
- [ ] 5.1 Implementar telas do onboarding (proposta de valor, como funciona, Free vs Pro) com CTAs.
- [ ] 5.2 Implementar fluxo de setup com stepper (1/6…6/6) e cards selecionáveis.
- [ ] 5.3 Implementar multi-select para condições de saúde.
- [ ] 5.4 Persistir `UserProfile` via UseCase e navegar para Home.
- [ ] 5.5 Estados de erro e validações (não permitir avançar sem seleção).

## Critérios de Sucesso
- Usuário consegue concluir onboarding + setup e cair na Home com `UserProfile` salvo.
- Fluxo é rápido e sem texto livre; UX consistente com Design System.

## Dependências
- 1.0 Fundação (Router/DI/TabRoot).
- 2.0 Design System.
- 3.0 Domain.
- 4.0 Data (persistência do perfil).

## Observações
- Evitar over-engineering: stepper simples e state mínimo.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/onboarding</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 5.0: Onboarding + Setup inicial

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Construir o fluxo que reduz abandono inicial: sem login, onboarding curto e setup guiado por stepper. Ao final, o perfil fica persistido e o usuário entra no loop diário.

<requirements>
- 3 telas de onboarding (valor, como funciona, Free vs Pro).
- Setup com 6 passos, 1 pergunta por tela, opções em cards.
- Persistir `UserProfile` localmente via UseCase.
</requirements>

## Subtarefas

- [ ] 5.1 Implementar Views e ViewModels do onboarding.
- [ ] 5.2 Implementar stepper do setup e perguntas estruturadas.
- [ ] 5.3 Integrar com UseCases de criação/salvamento de perfil.
- [ ] 5.4 Navegar para Home ao concluir e mostrar confirmação (“Perfil criado”).

## Detalhes de Implementação

Referenciar:
- “Onboarding + Setup Inicial” em `prd.md`.
- “Domain / UserProfile” e “Repos / UserProfileRepository” em `techspec.md`.

## Critérios de Sucesso

- `UserProfile` é salvo e carregado ao relançar o app.
- Navegação funciona via Router (sem acoplamento entre telas).

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





