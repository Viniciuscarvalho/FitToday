//
//  DesignTokens.swift
//  FitToday
//
//  Design System inspirado no Gym App UI Kit (ui8.net)
//  Tema Dark Mode completo com cores vibrantes de fitness
//

import SwiftUI

// MARK: - Color System (Dark Theme - Purple Futuristic)

enum FitTodayColor {
    // Cores de marca - Roxo/Purple como cor principal
    static let brandPrimary = Color(hex: "#7C3AED")  // Purple vibrante
    static let brandSecondary = Color(hex: "#A78BFA")  // Purple claro
    static let brandAccent = Color(hex: "#5B21B6")  // Purple escuro

    // Backgrounds - Dark purple theme
    static let background = Color(hex: "#0D0D14")  // Deep dark purple/navy
    static let backgroundElevated = Color(hex: "#1A1A28")  // Elevação leve
    static let surface = Color(hex: "#1E1E2E")  // Cards e superfícies
    static let surfaceElevated = Color(hex: "#24243A")  // Cards elevados

    // Texto
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#A0A0B8")  // Cinza azulado claro
    static let textTertiary = Color(hex: "#64648C")  // Cinza azulado médio
    static let textInverse = Color(hex: "#0D0D14")  // Para botões com fundo claro

    // Separadores e bordas
    static let outline = Color(hex: "#2A2A3C")
    static let outlineVariant = Color(hex: "#3D3D52")

    // Status colors
    static let success = Color(hex: "#22C55E")  // Verde moderno
    static let warning = Color(hex: "#F59E0B")  // Amber
    static let error = Color(hex: "#EF4444")  // Vermelho moderno
    static let info = Color(hex: "#3B82F6")  // Azul moderno

    // Gradientes principais
    static let gradientPrimary = LinearGradient(
        colors: [brandPrimary, brandAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSecondary = LinearGradient(
        colors: [brandSecondary, brandPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientPro = LinearGradient(
        colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientBackground = LinearGradient(
        colors: [background, Color(hex: "#121218")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Program Category Gradients

    // Strength - Purple (matches brand)
    static let gradientStrength = LinearGradient(
        colors: [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Conditioning - Orange
    static let gradientConditioning = LinearGradient(
        colors: [Color(hex: "#F97316"), Color(hex: "#C2410C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Aerobic - Pink
    static let gradientAerobic = LinearGradient(
        colors: [Color(hex: "#EC4899"), Color(hex: "#BE185D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Endurance - Blue
    static let gradientEndurance = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Wellness - Green
    static let gradientWellness = LinearGradient(
        colors: [Color(hex: "#22C55E"), Color(hex: "#15803D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Legacy/Accent Colors (mantidos para compatibilidade)

    // Neon Accents
    static let neonCyan = Color(hex: "#00E5FF")
    static let neonMagenta = Color(hex: "#FF00E5")
    static let neonYellow = Color(hex: "#FFEA00")
    static let neonPurple = Color(hex: "#B026FF")

    // Grid & Tech Elements
    static let gridLine = Color(hex: "#7C3AED").opacity(0.1)
    static let gridAccent = Color(hex: "#A78BFA").opacity(0.15)
    static let scanLine = Color.white.opacity(0.02)
    static let techBorder = Color(hex: "#7C3AED").opacity(0.3)

    // VHS / Glitch Effects
    static let glitchRed = Color(hex: "#FF0040")
    static let glitchCyan = Color(hex: "#00FFFF")

    // Enhanced Gradients
    static let gradientRetroSunset = LinearGradient(
        colors: [neonPurple, neonMagenta, Color(hex: "#F97316")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSynthwave = LinearGradient(
        colors: [Color(hex: "#2E1F54"), Color(hex: "#1A0633")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let gradientNeonGlow = LinearGradient(
        colors: [brandSecondary, brandPrimary, brandAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Spacing System (8pt Grid)

enum FitTodaySpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Border Radius

enum FitTodayRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let pill: CGFloat = 999
}

// MARK: - Font System (Retro-Futuristic)

enum FitTodayFont {
    // Font names
    static let orbitronBold = "Orbitron-Bold"
    static let orbitronExtraBold = "Orbitron-ExtraBold"
    static let orbitronBlack = "Orbitron-Black"
    static let rajdhaniBold = "Rajdhani-Bold"
    static let rajdhaniSemiBold = "Rajdhani-SemiBold"
    static let rajdhaniMedium = "Rajdhani-Medium"
    static let bungeeRegular = "Bungee-Regular"

    // Display fonts (Orbitron)
    static func display(size: CGFloat, weight: DisplayWeight = .bold) -> Font {
        switch weight {
        case .bold: return .custom(orbitronBold, size: size)
        case .extraBold: return .custom(orbitronExtraBold, size: size)
        case .black: return .custom(orbitronBlack, size: size)
        }
    }

    // UI fonts (Rajdhani)
    static func ui(size: CGFloat, weight: UIWeight = .medium) -> Font {
        switch weight {
        case .medium: return .custom(rajdhaniMedium, size: size)
        case .semiBold: return .custom(rajdhaniSemiBold, size: size)
        case .bold: return .custom(rajdhaniBold, size: size)
        }
    }

    // Accent font (Bungee)
    static func accent(size: CGFloat) -> Font {
        .custom(bungeeRegular, size: size)
    }

    enum DisplayWeight {
        case bold, extraBold, black
    }

    enum UIWeight {
        case medium, semiBold, bold
    }
}

// MARK: - Typography (Retro-Futuristic)

enum FitTodayTypography {
    static func largeTitle(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 36, weight: .extraBold))
            .tracking(1.5)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func title(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 30, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func title2(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 24, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func heading(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 20, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func subheading(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 16, weight: .semiBold))
            .tracking(0.5)
            .foregroundStyle(FitTodayColor.textSecondary)
    }

    static func body(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 17, weight: .medium))
            .tracking(0.3)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 12, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(FitTodayColor.textTertiary)
    }

    static func badge(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.accent(size: 11))
            .tracking(0.8)
            .textCase(.uppercase)
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica sombra suave usada em cards principais (estilo dark mode).
    func fitCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    /// Sombra mais sutil para elementos menores.
    func fitSubtleShadow() -> some View {
        shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    /// Aplica borda sutil para cards em dark mode.
    func fitCardBorder() -> some View {
        overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline, lineWidth: 1)
        )
    }
    
    /// Glow effect para elementos de destaque.
    func fitGlowEffect(color: Color = FitTodayColor.brandPrimary) -> some View {
        shadow(color: color.opacity(0.5), radius: 16, x: 0, y: 4)
    }

    // MARK: - Retro Visual Effects

    /// Adds retro grid overlay
    func retroGridOverlay(lineColor: Color = FitTodayColor.gridLine, spacing: CGFloat = 20) -> some View {
        self.overlay(
            RetroGridPattern(lineColor: lineColor, spacing: spacing)
        )
    }

    /// Adds diagonal stripe pattern
    func diagonalStripes(color: Color = FitTodayColor.brandPrimary, spacing: CGFloat = 8, opacity: Double = 0.1) -> some View {
        self.overlay(
            DiagonalStripesPattern(color: color, spacing: spacing, opacity: opacity)
        )
    }

    /// Adds tech corner borders (L-shaped corners)
    func techCornerBorders(color: Color = FitTodayColor.techBorder, length: CGFloat = 20, thickness: CGFloat = 2) -> some View {
        self.overlay(
            TechCornerBordersOverlay(color: color, length: length, thickness: thickness)
        )
    }

    /// Adds scanline overlay (VHS effect)
    func scanlineOverlay(lineSpacing: CGFloat = 4, opacity: Double = 0.03) -> some View {
        self.overlay(
            ScanlinePattern(lineSpacing: lineSpacing, opacity: opacity)
        )
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Retro Pattern Views

struct RetroGridPattern: View {
    let lineColor: Color
    let spacing: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                let cols = Int(geometry.size.width / spacing)
                for i in 0...cols {
                    let x = CGFloat(i) * spacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }

                // Horizontal lines
                let rows = Int(geometry.size.height / spacing)
                for i in 0...rows {
                    let y = CGFloat(i) * spacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(lineColor, lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct DiagonalStripesPattern: View {
    let color: Color
    let spacing: CGFloat
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let diagonal = sqrt(pow(geometry.size.width, 2) + pow(geometry.size.height, 2))
                let stripes = Int(diagonal / spacing)

                for i in 0...stripes {
                    let offset = CGFloat(i) * spacing
                    path.move(to: CGPoint(x: -geometry.size.height + offset, y: 0))
                    path.addLine(to: CGPoint(x: offset, y: geometry.size.height))
                }
            }
            .stroke(color.opacity(opacity), lineWidth: 2)
        }
        .rotationEffect(.degrees(45))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TechCornerBordersOverlay: View {
    let color: Color
    let length: CGFloat
    let thickness: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Top-left
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))

                // Top-right
                path.move(to: CGPoint(x: geometry.size.width - length, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: length))

                // Bottom-left
                path.move(to: CGPoint(x: 0, y: geometry.size.height - length))
                path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                path.addLine(to: CGPoint(x: length, y: geometry.size.height))

                // Bottom-right
                path.move(to: CGPoint(x: geometry.size.width - length, y: geometry.size.height))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - length))
            }
            .stroke(color, lineWidth: thickness)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ScanlinePattern: View {
    let lineSpacing: CGFloat
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let lines = Int(geometry.size.height / lineSpacing)
                for i in 0...lines {
                    let y = CGFloat(i) * lineSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(opacity), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
