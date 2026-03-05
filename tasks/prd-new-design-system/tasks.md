# Tasks — Nova Identidade Visual

**PRD:** prd-new-design-system
**Total Tasks:** 7

---

## Task 1: Atualizar paleta de cores em DesignTokens.swift
**Status:** pending
**File:** `FitToday/Presentation/DesignSystem/DesignTokens.swift`

Substituir todos os valores hex das cores de marca, backgrounds, texto, e bordas conforme tabela do techspec. Apenas trocar valores — nao renomear tokens.

**Acceptance Criteria:**
- [ ] brandPrimary = #3B82F6
- [ ] brandSecondary = #60A5FA
- [ ] brandAccent = #FB7185
- [ ] background = #111111
- [ ] backgroundElevated = #1A1A1A
- [ ] surface = #1E1E1E
- [ ] surfaceElevated = #252525
- [ ] textSecondary = #94A3B8
- [ ] textTertiary = #64748B
- [ ] outline = #2A2A2A
- [ ] outlineVariant = #3A3A3A

---

## Task 2: Atualizar gradientes em DesignTokens.swift
**Status:** pending
**File:** `FitToday/Presentation/DesignSystem/DesignTokens.swift`

Atualizar gradientPrimary, gradientSecondary, gradientBackground. Adicionar gradientAccent e gradientSurface. Atualizar gradientes de categoria (Strength, Aerobic, Endurance).

**Acceptance Criteria:**
- [ ] gradientPrimary usa azul #3B82F6 -> #1D4ED8
- [ ] gradientSecondary usa #60A5FA -> #3B82F6
- [ ] gradientAccent adicionado (coral #FB7185 -> #F43F5E)
- [ ] gradientSurface adicionado (#1A1A1A -> #111111)
- [ ] gradientStrength = azul primario
- [ ] gradientAerobic = coral
- [ ] gradientEndurance = azul claro

---

## Task 3: Remover tokens e efeitos legado
**Status:** pending
**File:** `FitToday/Presentation/DesignSystem/DesignTokens.swift` + views que usam

**Pre-condition:** Confirmar zero usos fora de DesignTokens.swift via grep.

Remover: neon colors, grid/tech colors, glitch colors, retro gradients, retro View extensions, retro Pattern structs.

**Acceptance Criteria:**
- [ ] grep retorna zero usos de tokens legado em todo o codebase
- [ ] ~110 linhas removidas de DesignTokens.swift
- [ ] Todas as views que usavam efeitos retro atualizadas

---

## Task 4: Adicionar fontes Plus Jakarta Sans e Inter ao bundle
**Status:** pending
**Files:** Xcode project, Info.plist, font files

Baixar e adicionar font files (.ttf) ao Xcode target. Registrar em Info.plist/UIAppFonts.

**Fonts needed:**
- PlusJakartaSans-Bold.ttf
- PlusJakartaSans-SemiBold.ttf
- PlusJakartaSans-Medium.ttf
- Inter-Regular.ttf
- Inter-Medium.ttf
- Inter-SemiBold.ttf

**Acceptance Criteria:**
- [ ] Font files adicionados ao target
- [ ] UIAppFonts registrado em Info.plist
- [ ] Fontes carregam em runtime (testar com Font.custom)

---

## Task 5: Migrar FitTodayFont e FitTodayTypography
**Status:** pending
**File:** `FitToday/Presentation/DesignSystem/DesignTokens.swift`

Substituir font names de Orbitron/Rajdhani/Bungee para Plus Jakarta Sans/Inter. Reduzir tracking em FitTodayTypography.

**Acceptance Criteria:**
- [ ] FitTodayFont.display usa Plus Jakarta Sans
- [ ] FitTodayFont.ui usa Inter
- [ ] FitTodayFont.accent usa Plus Jakarta Sans SemiBold
- [ ] Tracking reduzido conforme tabela do techspec
- [ ] Remover antigos font name constants (orbitronBold, rajdhaniBold, etc)

---

## Task 6: Atualizar comentarios e headers
**Status:** pending
**File:** `FitToday/Presentation/DesignSystem/DesignTokens.swift`

Atualizar comentarios do arquivo para refletir nova identidade.

**Acceptance Criteria:**
- [ ] Header comment atualizado para "Calm Blue / Wellness"
- [ ] MARK sections atualizados

---

## Task 7: Build e validacao visual
**Status:** pending

Build o projeto e validar que tudo compila. Verificar runtime fonts.

**Acceptance Criteria:**
- [ ] Build passa sem erros
- [ ] Zero grep hits para tokens removidos
- [ ] Zero grep hits para fontes antigas (Orbitron, Rajdhani, Bungee)
