# [13.0] Testes: unitários + UI tests + StoreKit Testing (M)

## Objetivo
- Garantir qualidade do MVP com testes unitários (Domain/Data) e testes de UI dos fluxos críticos, incluindo cenários de StoreKit (assinatura/restore) via configuração de teste.

## Subtarefas
- [ ] 13.1 Criar testes unitários para UseCases (perfil, motor de treino, histórico).
- [ ] 13.2 Criar testes para loader de JSON e mappers (Data).
- [ ] 13.3 Criar UI tests para:
  - onboarding → setup → home
  - diário → paywall → compra → treino
  - navegação independente por tab (preserva stacks)
  - histórico atualiza após conclusão
- [ ] 13.4 Configurar StoreKit Testing no target de UI tests quando aplicável.
- [ ] 13.5 Garantir execução estável (IDs e estados determinísticos; sem flakiness).

## Critérios de Sucesso
- Testes cobrem os fluxos mais importantes e evitam regressões.
- Cenários Pro (compra/restore) validados no ambiente de teste.

## Dependências
- 3.0 Domain.
- 4.0 Data.
- 5.0–12.0 Features (para UI tests completos).

## Observações
- Preferir injeção de dependências (repos fake) para tornar testes determinísticos.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>testing/mvp</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 13.0: Testes (unit + UI + StoreKit)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Consolidar qualidade com testes focados no valor: o loop diário, o motor de treino e a monetização Pro. Também validar que a navegação por tabs não perde o estado.

<requirements>
- Unit tests para UseCases principais.
- UI tests para fluxos críticos do MVP.
- StoreKit Testing configurado para cenários de assinatura.
</requirements>

## Subtarefas

- [ ] 13.1 Implementar unit tests do Domain/Data.
- [ ] 13.2 Implementar UI tests dos fluxos críticos.
- [ ] 13.3 Configurar e validar StoreKit Testing.

## Detalhes de Implementação

Referenciar:
- “Abordagem de Testes” em `techspec.md`.
- Fluxos e métricas em `prd.md`.

## Critérios de Sucesso

- Testes passam de forma estável em CI local (Xcode).
- Cobertura mínima do motor de treino e gating Pro.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/techspec.md`
- `tasks/prd-mvp-fittoday/prd.md`




