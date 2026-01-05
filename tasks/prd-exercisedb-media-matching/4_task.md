# [4.0] Melhorar fallback por nome e observabilidade (logs) (S)

## Objetivo
- Melhorar o fallback por nome para casos onde target não é válido/retorna vazio e adicionar logs DEBUG explicando o caminho de resolução e a escolha do candidato.

## Subtarefas
- [ ] 4.1 Padronizar normalização e geração de queries (nome completo, simplificado, palavras-chave)
- [ ] 4.2 Garantir que fallback por nome não sobrescreva mapping por target quando já existe mapping persistido
- [ ] 4.3 Adicionar logs DEBUG estruturados (target derivado, candidatos, scores, razão da escolha)

## Critérios de Sucesso
- Quando o match por target falhar, o fallback por nome ainda consegue resolver mídia em parte dos casos.
- Logs permitem diagnosticar rapidamente por que um exercício ficou sem mídia.

## Dependências
- 3.0 (resolver por target) — esta tarefa refina os caminhos de fallback/log.

## Observações
- Logs devem ser DEBUG-only para não poluir produção.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/exercisedb</domain>
<type>implementation</type>
<scope>performance</scope>
<complexity>low</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 4.0: Melhorar fallback por nome e observabilidade (logs)

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Mesmo com estratégia por target, ainda existirão casos onde o target não é válido/retorna vazio ou o exercício local não tem dados suficientes. O fallback por nome continua importante para aumentar cobertura. Além disso, logs ajudam a entender “por que não achou” ou “por que escolheu” um candidato.

<requirements>
- Melhorar queries de fallback por nome (progressivas).
- Logs DEBUG explicativos e padronizados.
- Não regredir comportamento com mapping persistido.
</requirements>

## Subtarefas

- [ ] 4.1 Ajustar normalização e queries de nome (ver `techspec.md` Heurística)
- [ ] 4.2 Garantir precedência: mapping persistido > id numérico > target > nome
- [ ] 4.3 Adicionar logs DEBUG (top 3 candidatos e scores)

## Detalhes de Implementação

- Referenciar **Heurística de Resolução** e **Observabilidade DEBUG** em `techspec.md`.

## Critérios de Sucesso

- Em DEBUG, ao resolver um exercício, logs mostram claramente qual caminho foi usado.
- Fallback por nome melhora cobertura em casos que não possuem target válido.

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseMediaResolver.swift`
- `FitToday/FitToday/Data/Services/ExerciseDB/ExerciseDBService.swift`

