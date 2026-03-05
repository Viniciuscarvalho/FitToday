# Product Requirements Document (PRD)

**Project Name:** Nova Identidade Visual — Constancia & Equilibrio Mental
**Version:** 1.0
**Date:** 2026-03-05
**Author:** Claude Code
**Status:** Draft

---

## Executive Summary

**Problem Statement:**
O tema atual do FitToday ("Purple Futuristic / Retro-Synthwave") comunica adrenalina e high-performance com cores neon agressivas, backgrounds roxo escuro e fontes Orbitron/Bungee. Esse visual nao reflete o posicionamento atual do app: constancia e equilibrio mental.

**Proposed Solution:**
Migrar a paleta de cores de roxo neon para azul calmo, substituir fontes retro por tipografia humanista (Plus Jakarta Sans + Inter), e remover todos os efeitos visuais legado (grid, scanline, glitch, neon).

**Business Value:**
- Alinhamento visual com o posicionamento de bem-estar e constancia
- Melhor legibilidade e menor fadiga ocular em dark mode
- App mais acolhedor para novos usuarios

**Success Metrics:**
- Zero tokens legado (neon/grid/scanline/glitch) no codebase
- Todas as cores de marca atualizadas para nova paleta
- Tipografia migrada para Plus Jakarta Sans + Inter
- Build limpo sem erros

---

## Functional Requirements

### FR-001: Atualizar Paleta de Cores de Marca [MUST]

**Description:**
Substituir todas as cores de marca em `FitTodayColor` de roxo/purple para azul calmo e coral.

**Acceptance Criteria:**
- `brandPrimary` = `#3B82F6` (azul)
- `brandSecondary` = `#60A5FA` (azul claro)
- `brandAccent` = `#FB7185` (coral/rosa)
- `background` = `#111111` (preto neutro)
- `backgroundElevated` = `#1A1A1A`
- `surface` = `#1E1E1E`
- `surfaceElevated` = `#252525`
- `textSecondary` = `#94A3B8` (cinza lavanda)
- `textTertiary` = `#64748B` (cinza slate)
- `outline` = `#2A2A2A`
- `outlineVariant` = `#3A3A3A`
- `info` unificado com `brandPrimary` (`#3B82F6`)

---

### FR-002: Atualizar Gradientes [MUST]

**Description:**
Substituir gradientes de roxo para nova paleta azul/coral.

**Acceptance Criteria:**
- `gradientPrimary` = `#3B82F6` -> `#1D4ED8`
- `gradientSecondary` = `#60A5FA` -> `#3B82F6`
- Novo `gradientAccent` = `#FB7185` -> `#F43F5E`
- Novo `gradientSurface` = `#1A1A1A` -> `#111111`
- `gradientStrength` = azul primario `#3B82F6` -> `#1D4ED8`
- `gradientAerobic` = coral `#FB7185` -> `#F43F5E`
- `gradientEndurance` = azul claro `#60A5FA` -> `#3B82F6`
- `gradientConditioning` permanece laranja (nao muda)
- `gradientWellness` permanece verde (nao muda)
- `gradientPro` permanece dourado (nao muda)

---

### FR-003: Remover Tokens e Efeitos Legado [MUST]

**Description:**
Remover todos os tokens, views e patterns do tema retro-futurista.

**Acceptance Criteria:**
- Remover cores: `neonCyan`, `neonMagenta`, `neonYellow`, `neonPurple`
- Remover cores: `gridLine`, `gridAccent`, `scanLine`, `techBorder`
- Remover cores: `glitchRed`, `glitchCyan`
- Remover gradientes: `gradientRetroSunset`, `gradientSynthwave`, `gradientNeonGlow`
- Remover extension View: `retroGridOverlay`, `diagonalStripes`, `techCornerBorders`, `scanlineOverlay`
- Remover structs: `RetroGridPattern`, `DiagonalStripesPattern`, `TechCornerBordersOverlay`, `ScanlinePattern`
- Remover todos os usos desses tokens/efeitos em views do app

---

### FR-004: Migrar Tipografia [MUST]

**Description:**
Substituir fontes retro (Orbitron, Rajdhani, Bungee) por fontes humanistas (Plus Jakarta Sans para titulos, Inter para corpo).

**Acceptance Criteria:**
- `FitTodayFont` usa Plus Jakarta Sans (titulos) e Inter (corpo)
- Remover referencia a Orbitron, Rajdhani, Bungee
- Reduzir tracking para valores menores (mais calmo)
- 565 usos em 90 arquivos atualizados
- Fontes .ttf/.otf adicionadas ao bundle e Info.plist

---

## Non-Functional Requirements

### NFR-001: Contraste WCAG [MUST]

**Description:**
Garantir contraste adequado para acessibilidade.

**Acceptance Criteria:**
- Texto branco sobre `#111111` atinge WCAG AA
- `#94A3B8` (textSecondary) sobre `#111111` atinge WCAG AA
- `brandAccent` (`#FB7185`) visualmente distinto de `error` (`#EF4444`)

### NFR-002: Zero Breaking Changes na API [MUST]

**Description:**
Nenhum token deve ser renomeado — apenas valores hex sao alterados. Tokens removidos devem primeiro ter zero usos confirmados.

---

## Out of Scope

1. Light mode — continua apenas dark mode
2. Redesign de layouts ou componentes — apenas cores e fontes mudam
3. Animacoes ou transicoes novas
4. Mudanca em cores de status (success, warning, error)
5. Mudanca em `gradientPro` (dourado para usuarios Pro)

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Fontes customizadas nao carregam em runtime | Alto | Medio | Testar em simulador imediatamente apos adicionar; fallback para system fonts |
| Tokens legado usados em views nao detectadas | Medio | Baixo | grep exaustivo antes de remover |
| Conflito visual brandAccent vs error | Medio | Baixo | Cores suficientemente diferentes (#FB7185 vs #EF4444) |
| 90 arquivos precisam mudar tipografia | Alto | Alto | Mudanca centralizada em FitTodayFont minimiza impacto |

---

## References

- GitHub Issue: https://github.com/Viniciuscarvalho/FitToday/issues/65
- Arquivo principal: `FitToday/Presentation/DesignSystem/DesignTokens.swift`
