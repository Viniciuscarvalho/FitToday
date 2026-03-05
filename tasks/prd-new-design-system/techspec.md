# Technical Specification

**Project Name:** Nova Identidade Visual — Constancia & Equilibrio Mental
**Version:** 1.0
**Date:** 2026-03-05
**Author:** Claude Code
**Status:** Draft

---

## Overview

### Problem Statement
O design system atual usa tema "Purple Futuristic / Retro-Synthwave" com cores neon, fontes retro e efeitos visuais agressivos. A mudanca requer atualizar `DesignTokens.swift` (centro do design system) e propagar para ~90 arquivos que usam tipografia customizada.

### Goals
- Atualizar paleta de cores (hex swap centralizado)
- Remover tokens/efeitos legado retro
- Migrar tipografia de Orbitron/Rajdhani/Bungee para Plus Jakarta Sans/Inter
- Adicionar novos gradientes (accent, surface)

---

## Scope

### In Scope
- `DesignTokens.swift` — cores, gradientes, fontes, extensions, patterns
- Font bundle — adicionar Plus Jakarta Sans e Inter, remover Orbitron/Rajdhani/Bungee
- Limpeza de usos de tokens legado em views

### Out of Scope
- Mudancas de layout ou componentes
- Light mode
- Animacoes
- Cores de status (success/warning/error)
- gradientPro

---

## Technical Approach

### Architecture Overview

O design system e centralizado em `FitTodayColor`, `FitTodayFont`, `FitTodayTypography` dentro de `DesignTokens.swift`. Todas as views referenciam esses enums. A mudanca e primariamente um swap de valores — nenhuma interface publica muda de nome.

### Files to Modify

| File | Change |
|------|--------|
| `Presentation/DesignSystem/DesignTokens.swift` | Cores, gradientes, fontes, remover legacy |
| `Info.plist` (or build settings) | Registrar novas fontes, remover antigas |
| `*.swift` (90 arquivos) | Apenas se usam tokens legado diretamente |

### Component 1: Color Palette Swap

Mudanca puramente de valores hex. Nenhum token e renomeado.

```swift
// BEFORE
static let brandPrimary = Color(hex: "#7C3AED")
// AFTER
static let brandPrimary = Color(hex: "#3B82F6")
```

**Full mapping:**
| Token | Old Hex | New Hex |
|-------|---------|---------|
| brandPrimary | #7C3AED | #3B82F6 |
| brandSecondary | #A78BFA | #60A5FA |
| brandAccent | #5B21B6 | #FB7185 |
| background | #0D0D14 | #111111 |
| backgroundElevated | #1A1A28 | #1A1A1A |
| surface | #1E1E2E | #1E1E1E |
| surfaceElevated | #24243A | #252525 |
| textSecondary | #A0A0B8 | #94A3B8 |
| textTertiary | #64648C | #64748B |
| outline | #2A2A3C | #2A2A2A |
| outlineVariant | #3D3D52 | #3A3A3A |

### Component 2: Gradient Updates

```swift
// Primary: azul calmo
static let gradientPrimary = LinearGradient(
    colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")], ...
)

// Accent: coral (novo)
static let gradientAccent = LinearGradient(
    colors: [Color(hex: "#FB7185"), Color(hex: "#F43F5E")], ...
)

// Surface: sutil (novo)
static let gradientSurface = LinearGradient(
    colors: [Color(hex: "#1A1A1A"), Color(hex: "#111111")], ...
)
```

Category gradients:
| Category | Old | New |
|----------|-----|-----|
| Strength | #7C3AED->#5B21B6 | #3B82F6->#1D4ED8 |
| Aerobic | #EC4899->#BE185D | #FB7185->#F43F5E |
| Endurance | #3B82F6->#1D4ED8 | #60A5FA->#3B82F6 |
| Conditioning | no change | no change |
| Wellness | no change | no change |

### Component 3: Legacy Removal

Remove ~110 lines from DesignTokens.swift:
- Lines 103-138: neon colors, grid/tech, glitch, retro gradients
- Lines 293-322: retroGridOverlay, diagonalStripes, techCornerBorders, scanlineOverlay view extensions
- Lines 352-463: RetroGridPattern, DiagonalStripesPattern, TechCornerBordersOverlay, ScanlinePattern structs

**Pre-removal verification:**
```bash
grep -r "neonCyan\|neonMagenta\|neonPurple\|gridLine\|scanLine\|techBorder\|glitchRed\|gradientSynthwave" --include="*.swift" | grep -v DesignTokens.swift
```
Must return zero results.

### Component 4: Typography Migration

**New fonts:**
- Plus Jakarta Sans: Bold, SemiBold, Medium (titulos, headings)
- Inter: Regular, Medium, SemiBold (corpo, captions)

**Font registration:**
Add .ttf/.otf files to Xcode target and register in Info.plist under `UIAppFonts`.

**FitTodayFont changes:**
```swift
enum FitTodayFont {
    // Font names
    static let jakartaBold = "PlusJakartaSans-Bold"
    static let jakartaSemiBold = "PlusJakartaSans-SemiBold"
    static let jakartaMedium = "PlusJakartaSans-Medium"
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"

    static func display(size: CGFloat, weight: DisplayWeight = .bold) -> Font {
        switch weight {
        case .bold: return .custom(jakartaBold, size: size)
        case .extraBold: return .custom(jakartaBold, size: size)
        case .black: return .custom(jakartaBold, size: size)
        }
    }

    static func ui(size: CGFloat, weight: UIWeight = .medium) -> Font {
        switch weight {
        case .medium: return .custom(interMedium, size: size)
        case .semiBold: return .custom(interSemiBold, size: size)
        case .bold: return .custom(interSemiBold, size: size)
        }
    }

    static func accent(size: CGFloat) -> Font {
        .custom(jakartaSemiBold, size: size)
    }
}
```

**Tracking reduction in FitTodayTypography:**
| Level | Old Tracking | New Tracking |
|-------|-------------|-------------|
| largeTitle | 1.5 | 0.3 |
| title | 1.2 | 0.2 |
| title2 | 1.0 | 0.2 |
| heading | 0.8 | 0.1 |
| subheading | 0.5 | 0 |
| body | 0.3 | 0 |
| caption | 0.5 | 0.2 |
| badge | 0.8 | 0.5 |

### Component 5: Comment/Header Updates

- Update file header comment from "Purple Futuristic" to "Calm Blue / Wellness"
- Update MARK comments to reflect new theme

---

## Testing Strategy

### Verification Steps
1. `grep` para tokens legado → zero hits fora de DesignTokens.swift
2. Build limpo no simulador
3. Visual check das telas principais: Home, Workouts, Programs, Profile
4. Contraste WCAG: texto branco sobre #111111, #94A3B8 sobre #111111
5. Fontes carregam corretamente (nao fallback para system)

### Build Validation
- `mcp__xcodebuildmcp__build_sim_name_proj` deve passar sem erros
- Nenhum warning de font not found em runtime

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Font files nao incluidas no bundle | Alto | Medio | Verificar Target Membership apos adicionar |
| Token legado usado em view nao detectada | Medio | Baixo | grep exaustivo com pattern completo |
| FitTodayFont.display/ui API muda | Alto | Baixo | Manter mesma API, so trocar nomes internos |

---

## Success Criteria

- [ ] Todas as cores de marca atualizadas para nova paleta
- [ ] Gradientes primarios e de categoria atualizados
- [ ] Todos os tokens/efeitos legado removidos
- [ ] Fontes Plus Jakarta Sans e Inter funcionando
- [ ] Tracking reduzido em FitTodayTypography
- [ ] Build limpo sem erros
- [ ] Zero referencias a tokens removidos
