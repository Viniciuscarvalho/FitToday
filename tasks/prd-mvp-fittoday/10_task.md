# [10.0] Histórico: lista por dia + status concluído/pulado (M)

## Objetivo
- Implementar a feature de Histórico com listagem simples por dia e status (concluído/pulado), alimentada pelos eventos do fluxo de treino.

## Subtarefas
- [ ] 10.1 Definir modelo de histórico no Domain e persistência no Data (se ainda não estiver completo).
- [ ] 10.2 Implementar tela de histórico (lista vertical, agrupada por data).
- [ ] 10.3 Implementar detalhe simples do registro (opcional no MVP) ou apenas leitura.
- [ ] 10.4 Garantir atualização imediata após concluir/pular treino.
- [ ] 10.5 Garantir que a lista usa IDs estáveis e não recalcula pesado no `body`.

## Critérios de Sucesso
- Registros aparecem após concluir/pular treino.
- Tela é rápida e consistente com o Design System.

## Dependências
- 3.0 Domain.
- 4.0 Data.
- 9.0 Fluxo de treino (para gerar registros).

## Observações
- Sem gráficos e métricas avançadas no MVP.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/history</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 10.0: Histórico

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O histórico do MVP é simples e funcional: lista por dia, tipo de treino e status. Serve para retenção e percepção de progresso sem virar um dashboard complexo.

<requirements>
- Lista por dia com status concluído/pulado.
- Persistência local e atualização após ações do usuário.
</requirements>

## Subtarefas

- [ ] 10.1 Implementar View + ViewModel do histórico.
- [ ] 10.2 Integrar com repositório e UseCase de listagem.
- [ ] 10.3 Garantir performance (IDs estáveis e sem trabalho pesado no body).

## Detalhes de Implementação

Referenciar:
- “Histórico (bem simples)” em `prd.md`.
- “WorkoutHistoryRepository” em `techspec.md`.

## Critérios de Sucesso

- Histórico reflete corretamente os treinos recentes.
- Navegação do tab Histórico preserva stack independente.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





