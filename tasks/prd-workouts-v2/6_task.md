# [6.0] Refinamento com OpenAI: prompt+JSON schema rígido + fallback (L)

## Objetivo
- Melhorar o treino gerado usando OpenAI como refinador (não gerador do zero), com saída JSON rígida e validação/fallback para garantir qualidade e custo controlado.

## Subtarefas
- [ ] 6.1 Definir schema JSON de resposta (IDs + ordem + sets/reps/rest + notas)
- [ ] 6.2 Montar prompt incorporando regras de `personal-active/` e constraints do app
- [ ] 6.3 Implementar parsing/validação e fallback para composer local

## Critérios de Sucesso
- OpenAI retorna apenas JSON válido; respostas inválidas caem no fallback local.
- Nenhum exercício fora do catálogo é aceito.
- Ajustes respeitam DOMS/motivação e objetivo do usuário.

## Dependências
- 5.0 Motor Local “especialista” (fallback base)

## Observações
- Manter custo: tokens limitados, temperatura baixa, cache por hash do prompt e limiter diário quando aplicável.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/infra/openai</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 6.0: Refinamento com OpenAI: prompt+JSON schema rígido + fallback

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Conectar os guias de especialidade aos ajustes via OpenAI para melhorar estrutura e prescrição do treino diário, mantendo a segurança via validação e fallback local.

<requirements>
- Prompt deve proibir invenção de exercícios e exigir retorno JSON
- Resposta deve conter apenas IDs e parâmetros ajustáveis (ordem/sets/reps/rest)
- Implementar validação pós-OpenAI e fallback completo
</requirements>

## Subtarefas

- [ ] 6.1 Criar schema e exemplo de resposta no composer
- [ ] 6.2 Integrar cache (`OpenAIResponseCache`) e limiter (`OpenAIUsageLimiter`)

## Detalhes de Implementação

Referências: `tasks/prd-workouts-v2/techspec.md` (seções: “OpenAI”, “Riscos Conhecidos”, “Requisitos Especiais”).

## Critérios de Sucesso

- Falhas de OpenAI não quebram o fluxo do usuário
- Melhoria perceptível de completude (mais exercícios coerentes e melhor ordem)

## Arquivos relevantes
- `FitToday/FitToday/Data/Services/OpenAI/OpenAIClient.swift`
- `FitToday/FitToday/Data/Services/OpenAI/OpenAIWorkoutPlanComposer.swift`
- `FitToday/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`



