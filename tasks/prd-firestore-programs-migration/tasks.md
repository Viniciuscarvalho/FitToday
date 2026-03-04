# Tasks — Migração de Programas: WGER → Catálogo Firestore

**Feature slug:** `prd-firestore-programs-migration`

## Issues GitHub criadas: #52–#64

| Task | Issue | Título |
|---|---|---|
| 1.1 | #52 | Criar entidade FirestoreExercise |
| 1.2 | #53 | Criar protocolo ProgramExerciseRepository |
| 1.3 | #54 | Mapear WorkoutTemplateType para categorias Firestore |
| 2.1 | #55 | Criar FirestoreProgramExerciseRepository |
| 2.2 | #56 | Testes unitários FirestoreProgramExerciseRepository |
| 3.1 | #57 | Adicionar exerciseId e primaryMuscles em ProgramExercise |
| 3.2 | #58 | Sobrecarga FirestoreExercise em ProgramWorkout.create |
| 4.1 | #59 | Migrar views para ExerciseAnimatedView |
| 4.2 | #60 | Integrar repositório no ViewModel |
| 5.1 | #61 | Atualizar AppContainer |
| 5.2 | #62 | Remover campos WgerExercise de ProgramExercise |
| 5.3 | #63 | Remover arquivos WGER (coordenar com #50) |
| 6   | #64 | Validação end-to-end (Firestore, offline, regressão) |

## Dependências

```
1.1 ──┬──▶ 1.2 ──▶ 2.1 ──▶ 2.2
      └──▶ 3.1 ──┐
1.3 ──────▶ 2.1  │
                  ▼
              3.2 ──▶ 4.1 ──▶ 5.2 ──▶ 5.3 ──▶ 6
              4.2 ──▶ 5.1 ──┘
```

## Estimativa Total: 11–16h
