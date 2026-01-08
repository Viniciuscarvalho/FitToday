# [9.0] Exercise Substitution (M)

## Objetivo
- Adicionar substituição rápida de exercícios (“Não consigo fazer”) durante a execução do treino, sugerindo alternativa compatível (mesmo grupo muscular, equipamento disponível, nível do usuário) com fallback claro quando não houver alternativa.

## Subtarefas
- [ ] 9.1 Definir regras de compatibilidade (músculo, equipamento, nível, restrições)
- [ ] 9.2 Implementar UI/UX do botão “Não consigo fazer” e seleção de alternativa
- [ ] 9.3 Implementar motor de sugestão (local primeiro; IA opcional conforme disponibilidade)
- [ ] 9.4 Persistir substituição na sessão (não perder ao navegar/reabrir)
- [ ] 9.5 Tratamento de erros com ErrorPresenting (mensagens user-friendly)
- [ ] 9.6 Testes unitários em XCTest (regras de substituição + persistência)

## Critérios de Sucesso
- Usuário consegue substituir um exercício em 1-2 taps.
- Alternativa respeita o músculo-alvo e equipamento disponível.
- Substituição persiste na sessão e não quebra o progresso do treino.
- Testes em XCTest cobrindo regras de compatibilidade e casos de borda.

## Dependências
- Task 8.0 (Execução/Tracking) recomendada para melhor integração de UX.
- Catálogo de exercícios e estrutura de `WorkoutPlan`/`WorkoutSessionStore`.

## Observações
- A primeira versão pode ser 100% local (sem IA) para reduzir custo/latência.
- Testes devem ser em **XCTest**.

## markdown

## status: completed

<task_context>
<domain>domain/usecases</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 9.0: Exercise Substitution

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Durante a execução, usuários podem não conseguir fazer um exercício (equipamento ocupado, dor, limitação). Implementaremos um fluxo simples de substituição que mantém a coerência do treino e evita frustração.

<requirements>
- Botão “Não consigo fazer” na tela do exercício
- Sugestão de alternativa compatível (músculo/equipamento)
- Confirmar substituição e atualizar a sessão imediatamente
- Persistir substituição durante a sessão
- Error handling padronizado (ErrorPresenting)
- Testes em XCTest (regras + persistência)
</requirements>

## Subtarefas

- [ ] 9.1 Revisar PRD: F5 (substituição) e definir regras de compatibilidade
- [ ] 9.2 Implementar UseCase `SuggestExerciseSubstitutionUseCase` (local-first)
- [ ] 9.3 Integrar na UI (`WorkoutExerciseDetailView`) com sheet/modal de alternativas
- [ ] 9.4 Persistir substituição no estado da sessão (e restaurar ao voltar)
- [ ] 9.5 Integrar ErrorPresenting para falhas (sem alternativas, falha de catálogo, etc.)
- [ ] 9.6 Testes unitários em XCTest para casos: sem alternativa, várias alternativas, restrições

## Detalhes de Implementação

- Referenciar `techspec.md` para padrões de ViewModels/ErrorPresenting.
- Reutilizar catálogo local e/ou ExerciseDB (conforme disponibilidade) para encontrar alternativas.
- Garantir que a substituição não invalide o tracking (sets/reps) e o progresso do treino.

## Critérios de Sucesso

- Substituição rápida e previsível.
- Consistência do treino mantida (músculo e estrutura).
- Persistência na sessão e sem regressões na execução.
- Testes em XCTest cobrindo regras críticas.

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutExerciseDetailView.swift`
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutSessionStore.swift`
- `FitToday/FitToday/Domain/Entities/WorkoutModels.swift`
- `FitToday/FitToday/Domain/UseCases/` (criar novo use case)

