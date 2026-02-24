---
description: Architecture decisions — MVVM, layer separation, dependency injection, data flow in FitToday
type: moc
---

# architecture

Architecture decisions and patterns for FitToday. This guide covers the MVVM architecture with @Observable, layer separation (Data/Domain/Presentation), dependency injection with SwiftInject, and data flow decisions.

## Core Patterns

(Patterns will be added as they are captured and processed)

## Current Architecture

- **Data Layer:** Repository implementations, DTOs, DataMappers — known by Application Layer
- **Domain Layer:** Pure structs, business logic, Repository protocols for UseCases
- **Presentation Layer:** Features only — UI/Views, ViewModels — known by Application Layer

## Decisions

- MVVM with @Observable is the architecture standard
- SwiftInject for dependency injection
- Value types (structs) preferred over reference types (classes)
- Guard for early exits

## Open Questions

- How should the architecture evolve as feature count grows?
- What patterns work best for cross-feature communication?

---

Domains:
- [[index]]
