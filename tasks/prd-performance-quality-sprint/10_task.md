# [10.0] Optimized Paywall (M)

## Objetivo
- Implementar paywall otimizado com **trial de 7 dias** e regras de bloqueio mais claras (“paywall mais forte”), garantindo restauração de compra e mensagens consistentes, sem quebrar os fluxos core do app.

## Subtarefas
- [ ] 10.1 Definir regras de acesso (Free vs Trial vs Pro) e pontos de bloqueio na navegação
- [ ] 10.2 Implementar UI do paywall (variante única nesta fase) com comparação de benefícios
- [ ] 10.3 Implementar Trial 7 dias via StoreKit 2 (assinatura) + restauração de compra
- [ ] 10.4 Integrar paywall nos pontos definidos (ex: após questionário / antes de recursos Pro)
- [ ] 10.5 Error handling (ErrorPresenting) para falhas de compra/restauração
- [ ] 10.6 Testes unitários em XCTest (entitlements, gating, fluxo de restore)

## Critérios de Sucesso
- Trial de 7 dias funcional (início, estado ativo, expiração/renovação conforme StoreKit).
- “Paywall mais forte”: regras de bloqueio respeitadas de forma consistente.
- Usuário consegue restaurar compra com sucesso.
- Mensagens de erro user-friendly (PT-BR) para falhas comuns.
- Testes em XCTest cobrindo gating e estados principais.

## Dependências
- StoreKit/Entitlement já existente (repos/infra atuais).
- Ajustes de navegação/roteamento onde o paywall é apresentado.

## Observações
- Testes devem ser em **XCTest**.
- Separar “gating” em task própria (10.1) reduz risco de regressões.

## markdown

## status: completed

<task_context>
<domain>presentation/features/pro</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 10.0: Optimized Paywall

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O paywall é parte crítica de monetização e precisa ser claro, confiável e resiliente a falhas. Nesta tarefa, vamos implementar **trial de 7 dias** e reforçar as regras de bloqueio (“paywall mais forte”), mantendo “restaurar compra” sempre disponível.

<requirements>
- Trial de 7 dias implementado (StoreKit 2)
- Paywall com comparação Free vs Pro (benefícios claros)
- Regras de bloqueio consistentes (Free/Trial/Pro)
- Restaurar compra visível e funcional
- Error handling com mensagens user-friendly (ErrorPresenting)
- Testes unitários em XCTest (entitlement/gating/restore)
</requirements>

## Subtarefas

- [ ] 10.1 Revisar PRD: F6 (Optimized Paywall) e formalizar regra “paywall mais forte”
- [ ] 10.2 Implementar layout do paywall (sem A/B nesta fase; variante única)
- [ ] 10.3 Integrar StoreKit 2: iniciar trial, observar entitlement, atualizar UI
- [ ] 10.4 Integrar “Restaurar compra” e tratar erros com ErrorPresenting
- [ ] 10.5 Aplicar gating nos fluxos definidos (ver task 10.1 se separada)
- [ ] 10.6 Testes em XCTest: estados Free/Trial/Pro, restore, erros comuns

## Detalhes de Implementação

- Referenciar `techspec.md` para padrões de DI (Swinject) e ErrorPresenting.
- Reutilizar `EntitlementRepository` e telas existentes em `Presentation/Features/Pro/`.
- Garantir que o paywall não bloqueie features essenciais Free (conforme PRD).

## Critérios de Sucesso

- Trial funcional e estados refletidos corretamente no app.
- Gating consistente (sem telas “vazando” para Free).
- Restore funciona e atualiza UI/entitlement.
- Testes em XCTest cobrindo principais estados e fluxos.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Pro/PaywallView.swift`
- `FitToday/FitToday/Presentation/Features/Pro/ProfileProView.swift`
- `FitToday/FitToday/Presentation/Features/Pro/APIKeySettingsView.swift`
- `FitToday/FitToday/Domain/Protocols/Repositories.swift` (EntitlementRepository)

