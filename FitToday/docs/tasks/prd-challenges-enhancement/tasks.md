# Tasks: Challenges Enhancement

**PRD:** `prd.md`
**Tech Spec:** `techspec.md`
**Status:** Ready for Implementation

---

## Visão Geral

| Métrica | Valor |
|---------|-------|
| Total de Tasks | 15 |
| Fases | 6 |
| Complexidade | Média |

---

## Fase 1: Infraestrutura (Foundation)

> Tasks paralelizáveis - podem ser executadas simultaneamente

| Task | Descrição | Arquivo | Status |
|------|-----------|---------|--------|
| [1.0](tasks/01_domain_models.md) | Criar modelos de domínio CheckIn | `Domain/Entities/CheckInModels.swift` | ⬜ |
| [2.0](tasks/02_storage_service.md) | Criar Firebase Storage Service | `Data/Services/Firebase/FirebaseStorageService.swift` | ⬜ |
| [3.0](tasks/03_image_compressor.md) | Criar Image Compressor Service | `Data/Services/ImageCompressor.swift` | ⬜ |

---

## Fase 2: Data Layer

| Task | Descrição | Dependência | Status |
|------|-----------|-------------|--------|
| [4.0](tasks/04_repository_protocol.md) | Criar CheckInRepository protocol + DTO | 1.0 | ⬜ |
| [5.0](tasks/05_firebase_repository.md) | Implementar FirebaseCheckInRepository | 2.0, 4.0 | ⬜ |

---

## Fase 3: Domain Layer

| Task | Descrição | Dependência | Status |
|------|-----------|-------------|--------|
| [6.0](tasks/06_checkin_usecase.md) | Implementar CheckInUseCase | 3.0, 5.0 | ⬜ |

---

## Fase 4: Presentation Layer

> Tasks 8.0, 9.0, 10.0 podem ser executadas em paralelo após 7.0

| Task | Descrição | Dependência | Status |
|------|-----------|-------------|--------|
| [7.0](tasks/07_checkin_viewmodel.md) | Criar CheckInViewModel | 6.0 | ⬜ |
| [8.0](tasks/08_checkin_photo_view.md) | Criar CheckInPhotoView | 7.0 | ⬜ |
| [9.0](tasks/09_checkin_feed_view.md) | Criar CheckInFeedView + ViewModel | 5.0 | ⬜ |
| [10.0](tasks/10_celebration_overlay.md) | Criar CelebrationOverlay | - | ⬜ |

---

## Fase 5: Integração

| Task | Descrição | Dependência | Status |
|------|-----------|-------------|--------|
| [11.0](tasks/11_workout_completion_integration.md) | Integrar na WorkoutCompletionView | 8.0 | ⬜ |
| [12.0](tasks/12_group_dashboard_integration.md) | Integrar Feed na GroupDashboardView | 9.0 | ⬜ |
| [13.0](tasks/13_dependency_injection.md) | Registrar no AppContainer | 6.0 | ⬜ |

---

## Fase 6: Finalização

| Task | Descrição | Dependência | Status |
|------|-----------|-------------|--------|
| [14.0](tasks/14_localization.md) | Adicionar strings EN/PT-BR | 8.0, 9.0 | ⬜ |
| [15.0](tasks/15_tests.md) | Escrever testes unitários | 6.0, 7.0 | ⬜ |

---

## Diagrama de Dependências

```
Fase 1 (Paralelo):
  1.0 ──┬──→ 4.0 ──→ 5.0 ──┬──→ 6.0 ──→ 7.0 ──→ 8.0 ──→ 11.0
  2.0 ──┘                  │                            │
  3.0 ─────────────────────┘                            │
                                                        ├──→ 14.0
  10.0 (independente) ──────────────────────────────────┘

  5.0 ──→ 9.0 ──→ 12.0

  6.0 ──→ 13.0
  6.0, 7.0 ──→ 15.0
```

---

## Legenda de Status

| Símbolo | Significado |
|---------|-------------|
| ⬜ | Não iniciado |
| 🔄 | Em progresso |
| ✅ | Concluído |
| ❌ | Bloqueado |
