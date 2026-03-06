# AGENTS

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>swift-concurrency</name>
<description>'Expert guidance on Swift Concurrency best practices, patterns, and implementation. Use when developers mention: (1) Swift Concurrency, async/await, actors, or tasks, (2) "use Swift Concurrency" or "modern concurrency patterns", (3) migrating to Swift 6, (4) data races or thread safety issues, (5) refactoring closures to async/await, (6) @MainActor, Sendable, or actor isolation, (7) concurrent code architecture or performance optimization, (8) concurrency-related linter warnings (SwiftLint or similar; e.g. async_without_await, Sendable/actor isolation/MainActor lint).'</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>

---

## Engineering Rules & Learnings

> Extraídos de PR analysis — confirmados pelo autor em 2026-03-05.

### [C001] Validar integridade referencial de seed data antes de commitar

**Contexto:** PR #73 — 5 de 12 programas referenciavam 33 `workoutTemplateIds` inexistentes, causando 0 exercícios carregados silenciosamente (sem erro ou warning).

**Regra:**
> Antes de commitar seed data (JSON), cross-check todos os IDs referenciados contra os IDs existentes nos arquivos de origem. Um programa sem templates válidos não deve existir no seed.

**Prevenção:** script de validação (ou assertion em unit test) que falhe se qualquer FK estiver quebrada. Exemplo mínimo:
```swift
// FitTodayTests — SeedIntegrityTests.swift
func testAllProgramTemplatesExist() throws {
    let programs = try loadPrograms()
    let templateIds = Set(try loadWorkoutTemplates().map(\.id))
    for program in programs {
        for id in program.workoutTemplateIds {
            XCTAssertTrue(templateIds.contains(id),
                "Program '\(program.id)' references missing template '\(id)'")
        }
    }
}
```

---

### [C002] Alinhar tipos de contrato entre domínio local e Firestore no início da feature

**Contexto:** PR #49 — `categoryIds` era `[Int]` no domain layer mas `String` no Firestore. Type mismatch retornava 0 exercícios silenciosamente, custando um refactor de 80+ arquivos.

**Regra:**
> Ao criar uma nova entidade que persiste no Firestore, definir e documentar o schema exato (tipos, field names) **antes** de implementar o domain layer. Validar com um teste de round-trip (encode → Firestore → decode) antes de construir a UI.

**Template de documentação de schema (colocar no topo do DTO):**
```swift
/// Firestore schema: exercises/{id}
/// Fields:
///   - categoryIds: [String]   ← NUNCA [Int]
///   - name: String
///   - templateId: String
struct ExerciseDTO: Codable { ... }
```

---

### [C003] Migrations de design token devem ser totais, não parciais

**Contexto:** PR #72 — tokens legados (neon/retro/glitch) se espalharam por 23 views antes de remoção em bulk. Fontes antigas (Orbitron, Rajdhani, Bungee) permaneceram no bundle mesmo após migração tipográfica.

**Regra:**
> Ao criar um novo design token que substitui um legado, remover ou marcar como `@available(*, deprecated)` o token antigo **na mesma PR**. Fontes registradas no `Info.plist` devem ser auditadas a cada mudança tipográfica.

**Checklist de migração de token:**
- [ ] Novo token criado em `DesignTokens.swift`
- [ ] Token antigo removido ou marcado `deprecated`
- [ ] Busca global pelo nome do token antigo — todas as referências migradas
- [ ] Fontes no `Info.plist` batem com as realmente usadas no app
- [ ] Build sem warnings de uso de símbolo deprecated

---

### [C004] API keys nunca devem ser embarcadas em builds de produção

**Contexto:** Issue #84 — chave OpenAI do developer estava acessível via `APIKeySettingsView` e potencialmente extraível do bundle via `Secrets.plist`.

**Regra:**
> Chaves de API **nunca** devem ser embarcadas no bundle do app (IPA). O `KeychainBootstrap` e a `APIKeySettingsView` devem existir **apenas** em builds `DEBUG` (`#if DEBUG`). Em produção, chaves devem vir de Firebase Remote Config ou serem intermediadas por Firebase Functions (proxy server-side).

**Checklist de segurança para API keys:**
- [ ] `Secrets.plist` está no `.gitignore` e **nunca** é commitado
- [ ] `KeychainBootstrap` está inteiramente dentro de `#if DEBUG`
- [ ] Toda navegação para `APIKeySettingsView` está dentro de `#if DEBUG`
- [ ] Nenhuma chave de API aparece hardcoded no código-fonte
- [ ] Em Release, chaves são obtidas via Firebase Remote Config ou proxy server-side
