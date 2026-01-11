# [3.0] Domain: modelos, protocolos e UseCases (M)

## Objetivo
- Implementar a camada Domain com value types (structs/enums), protocolos de repositório e UseCases que encapsulam as regras do MVP (sem dependência de SwiftUI/SwiftData).

## Subtarefas
- [ ] 3.1 Definir modelos de domínio: `UserProfile`, `DailyCheckIn`, `WorkoutPlan`, `Exercise`, `WorkoutHistoryEntry`, `ProEntitlement`.
- [ ] 3.2 Definir enums e validações: objetivo, estrutura, metodologia, nível, dor, status do histórico.
- [ ] 3.3 Definir protocolos de repositório (async + `Sendable`) para perfil, blocos, histórico e entitlement.
- [ ] 3.4 Implementar UseCases principais para criar/ler perfil, salvar check-in, gerar plano, salvar histórico.
- [ ] 3.5 Criar erros de domínio (`DomainError`) e regras de fallback (ex.: ausência de blocos).

## Critérios de Sucesso
- Domain compila isoladamente (sem imports de UI/persistência).
- UseCases têm testes unitários viáveis via repos fake/mocks.
- Tipos são `Sendable` quando aplicável e seguros para concorrência.

## Dependências
- 1.0 Fundação (estrutura de pastas e DI pode existir, mas Domain pode ser feito em paralelo).

## Observações
- Preferir structs imutáveis e regras explícitas (evitar “stringly typed”).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>domain/core</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 3.0: Domain (modelos + protocolos + UseCases)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Modelar o coração do MVP: quem é o usuário (perfil), o que ele responde no dia (check-in), como o treino é representado (plano e exercícios), e como registramos histórico. UseCases encapsulam regras e tornam a UI simples.

<requirements>
- Domain não importa SwiftUI/SwiftData.
- Protocolos de repositório async e `Sendable`.
- Regras básicas de validação (ex.: dor influencia volume).
</requirements>

## Subtarefas

- [ ] 3.1 Criar modelos e enums do domínio.
- [ ] 3.2 Criar protocolos de repositório.
- [ ] 3.3 Implementar UseCases (perfil, check-in, geração, histórico, entitlement).
- [ ] 3.4 Definir erros e casos de fallback.

## Detalhes de Implementação

Referenciar:
- “Modelos de Dados (Domain)” e “Interfaces Principais” em `techspec.md`.
- “Funcionalidades Principais / Motor de Treino” em `prd.md`.

## Critérios de Sucesso

- Domain e UseCases suportam todas as telas do MVP (inputs/outputs definidos).
- Testabilidade: UseCases aceitam repos via DI e permitem repos fake em testes.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/techspec.md`
- `tasks/prd-mvp-fittoday/prd.md`





