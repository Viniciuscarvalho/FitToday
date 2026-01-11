# [7.0] Progressive Onboarding (L)

## Objetivo
- Implementar onboarding progressivo para reduzir fricção: permitir gerar o primeiro treino com 2-3 inputs críticos e coletar o restante do perfil depois, mantendo defaults inteligentes e opção de “Treinar agora”.

## Subtarefas
- [x] 7.1 Definir "campos mínimos" do onboarding (objetivo + estrutura + nível default) e defaults ✅
- [x] 7.2 Implementar fluxo de telas (2-3 passos) + CTA "Gerar meu primeiro treino" ✅
- [x] 7.3 Implementar persistência progressiva do perfil (salvar parciais sem quebrar geração) ✅
- [x] 7.4 Adicionar opção "Personalize seu perfil depois" e entrypoint para completar perfil ✅
- [x] 7.5 Ajustar roteamento para não reabrir onboarding após completar mínimos ✅
- [x] 7.6 Testes unitários em XCTest (validação, persistência, roteamento) ✅

## Critérios de Sucesso
- Usuário consegue chegar ao primeiro treino respondendo apenas o mínimo (2-3 passos).
- Defaults aplicados são consistentes e previsíveis (sem crash/estado inválido).
- Perfil pode ser completado depois sem perder dados já informados.
- Testes em XCTest cobrindo: validação, persistência e transições de estado.

## Dependências
- PRD/Spec desta pasta (Fase 2): `/Users/vinicius.marques/Documents/Projects/pessoal/FitToday/tasks/prd-performance-quality-sprint/prd.md`
- Fluxo atual de onboarding e repositório de perfil (para reaproveitar persistência).

## Observações
- Testes devem ser em **XCTest** (não usar Swift Testing).
- Referenciar a `techspec.md` nas seções de arquitetura/Clean Architecture e padrões de ViewModels.

## markdown

## status: completed

<task_context>
<domain>presentation/features/onboarding</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 7.0: Progressive Onboarding

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O onboarding atual exige muitas informações upfront. Nesta tarefa, implementaremos um onboarding progressivo em 2-3 passos para permitir que o usuário experimente valor (primeiro treino) rapidamente, coletando dados complementares depois. Isso reduz abandono e aumenta ativação.

<requirements>
- Fluxo de onboarding com 2-3 passos (mínimo) antes do primeiro treino
- CTA “Gerar meu primeiro treino” (com defaults para campos não coletados)
- “Pular / Personalizar depois” sem bloquear o usuário
- Persistir perfil parcial sem quebrar o composer e sem deixar o app em estado inválido
- Entry point pós-treino para completar perfil (Settings ou modal)
- Testes em XCTest para validação de inputs e persistência
</requirements>

## Subtarefas

- [x] 7.1 Revisar PRD: F4 (Progressive Onboarding) e mapear campos mínimos ✅
- [x] 7.2 Implementar UI do fluxo em `Presentation/Features/Onboarding/` (novas telas ou refactor do flow) ✅
- [x] 7.3 Implementar defaults: level/intermediate, frequency 3x/semana, method mixed (ou conforme PRD) ✅
- [x] 7.4 Persistir perfil parcial no repositório sem sobrescrever dados existentes indevidamente ✅
- [x] 7.5 Ajustar roteamento (evitar loop de onboarding e garantir "first workout") ✅
- [x] 7.6 Adicionar prompt pós-primeiro-treino: "Personalize seu perfil" (opcional) ✅
- [x] 7.7 Testes unitários em XCTest (inputs mínimos, defaults, persistência incremental) ✅

## Detalhes de Implementação

- Referenciar `techspec.md` (arquitetura Clean, padrões de ViewModel e repositórios).
- Integrar com os repositórios existentes (perfil) e com o fluxo atual de navegação/roteamento.
- Garantir que o gerador de treino funcione com defaults quando dados faltarem.

## Critérios de Sucesso

- Fluxo mínimo gera treino sem exigir onboarding completo.
- Usuário consegue pular e completar perfil posteriormente.
- Nenhum crash/estado inválido ao persistir perfil parcial.
- Testes em XCTest cobrindo casos de sucesso/erro.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Onboarding/OnboardingFlowView.swift`
- `FitToday/FitToday/Presentation/Features/Onboarding/OnboardingFlowViewModel.swift`
- `FitToday/FitToday/Domain/Protocols/Repositories.swift` (UserProfileRepository)
- `FitToday/FitToday/Domain/UseCases/` (casos de uso relacionados a perfil/geração)

