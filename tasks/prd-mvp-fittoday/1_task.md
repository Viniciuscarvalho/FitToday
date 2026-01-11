# [1.0] Fundação do app: camadas, Swinject, Router/DeepLinks e TabBar com stacks independentes (L)

## Objetivo
- Estabelecer a base do app para suportar todas as features do MVP: organização em camadas (Domain/Data/Presentation), DI com Swinject, navegação via Router com deep links, e TabBar onde cada tab mantém sua própria navegação.

## Subtarefas
- [ ] 1.1 Criar estrutura de diretórios `Domain/`, `Data/`, `Presentation/` (sem módulos separados) e regras de dependência (Domain não importa SwiftUI/SwiftData).
- [ ] 1.2 Adicionar Swinject via SPM e definir `AppContainer` (wrapper do `Swinject.Container`) + `Assembly` por área (Core, Repos, UseCases, Features).
- [ ] 1.3 Implementar `AppRouter` com suporte a tabs (`AppTab`) e rotas (`AppRoute`) e API de navegação (push/pop/select).
- [ ] 1.4 Implementar parser de deep links (`DeepLink`) e integração com `onOpenURL`.
- [ ] 1.5 Implementar `TabRootView` com `TabView` e um `NavigationStack` por tab (paths independentes e persistentes durante a sessão).
- [ ] 1.6 Substituir o template atual (`ContentView`) pelo shell do app (TabRoot + Router + gating inicial para onboarding/setup).

## Critérios de Sucesso
- App abre em um shell com TabBar e cada tab preserva seu próprio stack ao alternar tabs.
- É possível rotear para telas por ação do usuário e por deep link (`onOpenURL`) sem acoplamento direto entre Views.
- Dependências são resolvidas via Swinject (sem singletons globais ad-hoc).

## Dependências
- Nenhuma (primeira tarefa).

## Observações
- Priorizar simplicidade: Router stateful com paths por tab (ex.: `[AppTab: NavigationPath]`).
- ViewModels e Router devem respeitar concurrency: Router pode ser `@MainActor` por ser UI-bound.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>infra/app-foundation</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>high</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 1.0: Fundação do app (DI + Router/DeepLinks + TabBar independente)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Criar o “esqueleto” do app com camadas bem definidas, DI via Swinject e uma navegação robusta (Router + deep links). A TabBar precisa manter stacks independentes para que o usuário volte exatamente onde estava em cada aba.

<requirements>
- Usar Swinject para DI (SPM).
- Implementar Router central para navegação e deep links.
- TabBar com `NavigationStack` independente por tab.
- Sem criação de módulos separados (apenas organização por pastas/camadas).
</requirements>

## Subtarefas

- [ ] 1.1 Estruturar diretórios e regras de dependência entre camadas.
- [ ] 1.2 Configurar Swinject (Container + Assemblies) e registrar Router/Repos/UseCases base.
- [ ] 1.3 Implementar `AppRouter`, `AppTab`, `AppRoute` e deep link parsing.
- [ ] 1.4 Implementar `TabRootView` com paths independentes por tab.
- [ ] 1.5 Integrar Router/DI no entrypoint do app e remover `ContentView` do template.

## Detalhes de Implementação

Referenciar as seções:
- “Arquitetura do Sistema” e “Design de Implementação / Router” em `techspec.md`.
- “Experiência do Usuário / TabBar com navegação independente” em `prd.md`.

## Critérios de Sucesso

- Alternar tabs preserva o stack de navegação de cada tab.
- Deep link abre a tela correta (mínimo: paywall e onboarding/setup) sem crash.
- DI resolve instâncias sem circular dependency e sem `fatalError` em runtime.

## Arquivos relevantes
- `FitToday/FitToday/FitTodayApp.swift`
- `FitToday/FitToday/ContentView.swift`
- `tasks/prd-mvp-fittoday/techspec.md`




