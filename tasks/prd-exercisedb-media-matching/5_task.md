# [5.0] Ferramentas DEBUG: limpar cache/mapping e validar em device (S)

## Objetivo
- Fornecer ferramentas em builds DEBUG para limpar caches (mapping e targetList) e facilitar validação da resolução de mídia em device/simulator.

## Subtarefas
- [ ] 5.1 Adicionar ação para limpar cache de mapping (`exercisedb_id_mapping_v1`)
- [ ] 5.2 Adicionar ação para limpar cache de `targetList` (`exercisedb_target_list_v1`)
- [ ] 5.3 Documentar um checklist de validação manual (exercício com nome divergente → mídia aparece)

## Critérios de Sucesso
- Em DEBUG, desenvolvedor consegue forçar re-match e observar logs/resultado sem reinstalar o app.

## Dependências
- 2.0 (catálogo de targets com persistência) — para existir a chave de cache.
- 4.0 (logs) — para facilitar validação.

## Observações
- Essas ações devem ficar restritas ao modo debug (já existe seção debug no Perfil).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>integration</type>
<scope>configuration</scope>
<complexity>low</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 5.0: Ferramentas DEBUG: limpar cache/mapping e validar em device

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Como a estratégia depende de cache persistido (mapping e targetList), precisamos de botões de limpeza em DEBUG para validar rapidamente novas heurísticas e correções, sem precisar reinstalar o app.

<requirements>
- Ação para limpar mapping persistido.
- Ação para limpar targetList persistido.
- Checklist de validação manual.
</requirements>

## Subtarefas

- [ ] 5.1 Atualizar seção DEBUG em `ProfileProView` com opção “Limpar cache de targetList”
- [ ] 5.2 Garantir que limpar cache não afete builds release
- [ ] 5.3 Criar checklist de validação (README curto na Observações ou comentário no task)

## Detalhes de Implementação

- Referenciar **Cache** e **Observabilidade DEBUG** em `techspec.md`.

## Critérios de Sucesso

- Após limpar caches, o app refaz `targetList` e re-resolve mappings conforme navegação.
- Exercícios antes sem mídia passam a ter tentativa nova sem reinstalação.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Pro/ProfileProView.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseMediaResolver.swift`


