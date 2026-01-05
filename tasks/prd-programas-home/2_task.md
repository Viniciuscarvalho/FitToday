# [2.0] Infra Keychain + bootstrap local (Debug) para OpenAI e RapidAPI (M)

## Objetivo
- Implementar armazenamento seguro de segredos via Keychain e um mecanismo de bootstrap local (apenas Debug) para popular OpenAI e RapidAPI keys **sem UI** e **sem commitar** chaves no repositório.

## Subtarefas
- [ ] 2.1 Criar `KeychainStore` (read/write string) com chaves tipadas (`KeychainKey`)
- [ ] 2.2 Implementar bootstrap Debug (arquivo local ignorado ou build setting) que popula Keychain no primeiro launch
- [ ] 2.3 Integrar leitura do Keychain nos serviços OpenAI e ExerciseDB (RapidAPI) e definir comportamento quando ausente

## Critérios de Sucesso
- Chaves não aparecem no código versionado nem em logs.
- App consegue acessar OpenAI/RapidAPI em Debug com bootstrap local.
- Em ausência de chaves, app se comporta de forma segura (desabilita integração, placeholder, logs não sensíveis).

## Dependências
- 1.0 pode ser paralelo, mas recomendado antes por impacto global.

## Observações
- Sem UI de inserção/validação; foco em pipeline local (dev) e segurança.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>infra/security</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 2.0: Infra Keychain + bootstrap local (Debug)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Precisamos usar OpenAI e RapidAPI sem expor chaves no repositório. A solução deve guardar segredos no Keychain e permitir bootstrap apenas em Debug a partir de fonte local ignorada pelo git.

<requirements>
- Implementar `KeychainStore` e `KeychainKey`
- Implementar bootstrap Debug para popular Keychain sem UI
- Serviços devem ler do Keychain e não logar segredos
</requirements>

## Subtarefas

- [ ] 2.1 Criar `KeychainStore` (read/write/remove) e erros tipados
- [ ] 2.2 Definir fonte de bootstrap (ex.: `Secrets.plist` ignorado, xcconfig, ou argumentos de launch) e fluxo de “primeiro launch”
- [ ] 2.3 Integrar com `OpenAIClient`/config e `ExerciseDBService` (RapidAPI)

## Detalhes de Implementação

- Referenciar “Keychain: armazenamento de chaves sem UI” em `techspec.md`.
- Garantir que o bootstrap rode somente em Debug e nunca em Release.

## Critérios de Sucesso

- Keys nunca aparecem em git ou logs
- Keychain populado em Debug por bootstrap local
- Integrações usam Keychain como fonte única

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/OpenAI/`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`

