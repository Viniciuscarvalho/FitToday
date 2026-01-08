# [10.1] Paywall Gating (M)

## Objetivo
- Centralizar e padronizar as regras de bloqueio (gating) para recursos Pro/Trial/Free, garantindo consistência entre Home, Questionário, Treino, Biblioteca e Programas, evitando “vazamentos” de acesso e reduzindo regressões.

## Subtarefas
- [ ] 10.1.1 Mapear pontos de entrada (onde o usuário acessa features Pro) e decidir bloqueios
- [ ] 10.1.2 Implementar camada única de decisão (Policy) para gating por entitlement
- [ ] 10.1.3 Integrar com roteador/navegação (push paywall ao invés de falhar silenciosamente)
- [ ] 10.1.4 Garantir restore e atualização de estado em tempo real (stream de entitlement)
- [ ] 10.1.5 Testes unitários em XCTest para matriz Free/Trial/Pro (e expiração)

## Critérios de Sucesso
- Mesma regra aplicada em todos os fluxos (sem duplicação de ifs divergentes).
- Nenhum acesso Pro indevido quando Free.
- Trial permite acesso Pro durante o período.
- Restore atualiza o estado e libera recursos imediatamente.
- Testes em XCTest cobrindo matriz de gating (mínimo: 12 cenários).

## Dependências
- 10.0 Optimized Paywall (trial + UI).
- EntitlementRepository / StoreKit 2 existentes.

## Observações
- Testes devem ser em **XCTest**.
- Priorizar uma API simples (ex: `EntitlementPolicy.canAccess(_ feature: Feature) -> Bool`).

## markdown

## status: completed

<task_context>
<domain>presentation/router</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 10.1: Paywall Gating

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Conforme reforçamos o paywall (trial + bloqueio), a maior fonte de regressão tende a ser o gating “espalhado” em várias telas. Esta tarefa cria uma abordagem central para decidir acesso a features Pro e aplica isso nos principais entrypoints.

<requirements>
- Matriz clara de acesso (Free/Trial/Pro) para features relevantes
- Camada centralizada de policy (evitar duplicação)
- Integração com navegação: quando não permitido, redirecionar para paywall
- Restore/stream de entitlement refletindo mudanças sem restart do app
- Testes em XCTest para cenários principais e edge cases
</requirements>

## Subtarefas

- [ ] 10.1.1 Levantar features com gating na Fase 2 (IA, biblioteca premium, etc.)
- [ ] 10.1.2 Criar `EntitlementPolicy` (Domain ou Presentation, conforme arquitetura)
- [ ] 10.1.3 Integrar policy nos fluxos (Home → gerar/ver treino; Programs; Library; Settings Pro)
- [ ] 10.1.4 Garantir ações de fallback claras (mostrar paywall ou explicar limitação)
- [ ] 10.1.5 Testes em XCTest: tabela de decisão e integração de navegação (unit tests)

## Detalhes de Implementação

- Referenciar `techspec.md` para padrões de DI (Swinject) e ErrorPresenting.
- Reutilizar `EntitlementRepository.entitlementStream()` para atualizar UI ao vivo.
- Evitar lógica duplicada: usar policy como única fonte da verdade.

## Critérios de Sucesso

- Consistência de gating em todas as telas-alvo.
- Trial e restore atualizando o acesso imediatamente.
- Testes em XCTest cobrindo a policy e os principais fluxos.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Router/` (roteamento para paywall)
- `FitToday/FitToday/Presentation/Features/Pro/PaywallView.swift`
- `FitToday/FitToday/Domain/Protocols/Repositories.swift` (EntitlementRepository)

