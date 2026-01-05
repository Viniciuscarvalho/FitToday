# [12.0] Histórico: vínculo com Programa + evolução (calorias/duração) (M/L)

## Objetivo
- Melhorar o Histórico para permitir observar o treino registrado e, quando aplicável, exibir o **programa** associado, além de apresentar evolução (calorias e duração) ao longo do tempo.

## Subtarefas
- [ ] 12.1 Definir como vincular `WorkoutHistoryEntry` a `Program` (programId ou inferência via templateId)
- [ ] 12.2 Atualizar UI do histórico para mostrar programa associado e métricas por sessão
- [ ] 12.3 Implementar visão simples de evolução (ex.: gráfico/linha ou lista agregada) para calorias e duração

## Critérios de Sucesso
- Histórico mostra treino registrado com duração/calorias.
- Quando houver vínculo, exibe programa associado.
- Evolução por programa (ou geral) fica disponível e compreensível.

## Dependências
- Depende de 4.0/5.0 (Programas).
- Depende do modelo de histórico existente.

## Observações
- Se calorias não existirem hoje, definir estratégia: estimar, manter vazio, ou capturar do treino.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/history</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 12.0: Histórico com programa + evolução

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

O Histórico deve ser mais útil: mostrar contexto do treino e permitir acompanhar evolução (duração/calorias), especialmente quando o treino pertence a um programa.

<requirements>
- Vínculo do histórico a um programa (quando aplicável)
- Exibir métricas de duração/calorias
- Mostrar evolução ao longo do tempo
</requirements>

## Subtarefas

- [ ] 12.1 Atualizar modelo/mapeamento do histórico para armazenar `programId` (ou derivar)
- [ ] 12.2 Ajustar telas do Histórico e adicionar seção de evolução

## Detalhes de Implementação

- Referenciar “Histórico: vínculo com Programa + evolução” em `prd.md` e “Histórico” em `techspec.md`.

## Critérios de Sucesso

- Usuário consegue ver treino, programa associado e evolução

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/History/`
- `FitToday/FitToday/Domain/Entities/HistoryModels.swift`
- `FitToday/FitToday/Data/Repositories/SwiftDataWorkoutHistoryRepository.swift`

