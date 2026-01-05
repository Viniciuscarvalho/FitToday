# [4.0] Criar entidade `Program` + repositório + mapear treinos existentes (L)

## Objetivo
- Introduzir a entidade de domínio `Program`, criar um repositório para listagem/detalhe e mapear os treinos já existentes (seed/bundle) dentro de programas, habilitando UI e recomendação.

## Subtarefas
- [ ] 4.1 Definir `Program` (Domain) e enums/tags necessárias (metabolic/strength etc.)
- [ ] 4.2 Criar `ProgramRepository` + implementação (bundle seed) e registrar no DI
- [ ] 4.3 Mapear treinos existentes (biblioteca atual) para `Program` (IDs/templates) e validar integridade

## Critérios de Sucesso
- Existem `Program`s carregáveis via repositório.
- Cada `Program` referencia treinos existentes válidos (sem IDs quebrados).
- UI consegue listar programas e abrir detalhe sem crash.

## Dependências
- Pode ser feito em paralelo com 1.0–3.0, mas recomendado após 3.0 para cards com mídia.

## Observações
- Começar simples: 2 tags (`metabolic`, `strength`) e expandir depois.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>domain/data</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 4.0: Criar entidade `Program` + repositório + mapear treinos existentes

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

“Programas” serão a nova unidade principal de descoberta de treinos. Precisamos modelar o domínio e carregar seeds iniciais, mapeando o catálogo atual.

<requirements>
- Criar entidade `Program` no Domain
- Implementar `ProgramRepository` com seed no bundle
- Mapear treinos existentes dentro de `Program`
</requirements>

## Subtarefas

- [ ] 4.1 Criar `Program` e `ProgramGoalTag` (e campos: nome, duração, imagem, IDs de templates)
- [ ] 4.2 Implementar repositório (bundle) e registrar no `AppContainer`
- [ ] 4.3 Escrever validação simples (ex.: asserts/throw) para IDs inexistentes

## Detalhes de Implementação

- Referenciar “Modelos de Dados” e “ProgramRepository” em `techspec.md`.

## Critérios de Sucesso

- `ProgramsView` lista 3–5 programas seed
- `ProgramDetailView` consegue resolver seus treinos/itens

## Arquivos relevantes
- `FitToday/FitToday/Domain/Entities/`
- `FitToday/FitToday/Domain/Protocols/Repositories.swift`
- `FitToday/FitToday/Data/Resources/` (seed)
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`


