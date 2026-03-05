//
//  DesignTokens.swift
//  FitToday
//
//  Design System — Constancia & Equilibrio Mental
//  Tema Dark Mode com paleta azul calma e tipografia humanista
//

import SwiftUI

// MARK: - Color System (Dark Theme - Calm Blue / Wellness)

enum FitTodayColor {
    // Cores de marca - Azul calmo como cor principal
    static let brandPrimary = Color(hex: "#3B82F6")  // Azul confianca
    static let brandSecondary = Color(hex: "#60A5FA")  // Azul claro
    static let brandAccent = Color(hex: "#FB7185")  // Coral — esforco/calorias

    // Backgrounds - Dark neutral theme
    static let background = Color(hex: "#111111")  // Preto neutro
    static let backgroundElevated = Color(hex: "#1A1A1A")  // Elevacao leve
    static let surface = Color(hex: "#1E1E1E")  // Cards e superficies
    static let surfaceElevated = Color(hex: "#252525")  // Cards elevados

    // Texto
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#94A3B8")  // Cinza lavanda
    static let textTertiary = Color(hex: "#64748B")  // Cinza slate
    static let textInverse = Color(hex: "#111111")  // Para botoes com fundo claro

    // Separadores e bordas
    static let outline = Color(hex: "#2A2A2A")
    static let outlineVariant = Color(hex: "#3A3A3A")

    // Status colors
    static let success = Color(hex: "#22C55E")  // Verde moderno
    static let warning = Color(hex: "#F59E0B")  // Amber
    static let error = Color(hex: "#EF4444")  // Vermelho moderno
    static let info = Color(hex: "#3B82F6")  // Azul moderno

    // Gradientes principais
    static let gradientPrimary = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSecondary = LinearGradient(
        colors: [Color(hex: "#60A5FA"), Color(hex: "#3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientAccent = LinearGradient(
        colors: [Color(hex: "#FB7185"), Color(hex: "#F43F5E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientPro = LinearGradient(
        colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientBackground = LinearGradient(
        colors: [background, Color(hex: "#0D0D0D")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let gradientSurface = LinearGradient(
        colors: [Color(hex: "#1A1A1A"), Color(hex: "#111111")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Program Category Gradients

    // Strength - Blue (matches brand)
    static let gradientStrength = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Conditioning - Orange
    static let gradientConditioning = LinearGradient(
        colors: [Color(hex: "#F97316"), Color(hex: "#C2410C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Aerobic - Coral
    static let gradientAerobic = LinearGradient(
        colors: [Color(hex: "#FB7185"), Color(hex: "#F43F5E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Endurance - Light Blue
    static let gradientEndurance = LinearGradient(
        colors: [Color(hex: "#60A5FA"), Color(hex: "#3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Wellness - Green
    static let gradientWellness = LinearGradient(
        colors: [Color(hex: "#22C55E"), Color(hex: "#15803D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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

// MARK: - Font System (Humanist / Wellness)

enum FitTodayFont {
    // Font names — Plus Jakarta Sans (titles) + Inter (body)
    static let jakartaBold = "PlusJakartaSans-Bold"
    static let jakartaSemiBold = "PlusJakartaSans-SemiBold"
    static let jakartaMedium = "PlusJakartaSans-Medium"
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"

    // Display fonts (Plus Jakarta Sans)
    static func display(size: CGFloat, weight: DisplayWeight = .bold) -> Font {
        switch weight {
        case .bold: return .custom(jakartaBold, size: size)
        case .extraBold: return .custom(jakartaBold, size: size)
        case .black: return .custom(jakartaBold, size: size)
        }
    }

    // UI fonts (Inter)
    static func ui(size: CGFloat, weight: UIWeight = .medium) -> Font {
        switch weight {
        case .medium: return .custom(interMedium, size: size)
        case .semiBold: return .custom(interSemiBold, size: size)
        case .bold: return .custom(interSemiBold, size: size)
        }
    }

    // Accent font (Plus Jakarta Sans SemiBold)
    static func accent(size: CGFloat) -> Font {
        .custom(jakartaSemiBold, size: size)
    }

    enum DisplayWeight {
        case bold, extraBold, black
    }

    enum UIWeight {
        case medium, semiBold, bold
    }
}

// MARK: - Typography (Humanist / Wellness)

enum FitTodayTypography {
    static func largeTitle(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 36, weight: .bold))
            .tracking(0.3)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func title(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 30, weight: .bold))
            .tracking(0.2)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func title2(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.display(size: 24, weight: .bold))
            .tracking(0.2)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func heading(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 20, weight: .bold))
            .tracking(0.1)
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func subheading(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 16, weight: .semiBold))
            .foregroundStyle(FitTodayColor.textSecondary)
    }

    static func body(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 17, weight: .medium))
            .foregroundStyle(FitTodayColor.textPrimary)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.ui(size: 12, weight: .medium))
            .tracking(0.2)
            .foregroundStyle(FitTodayColor.textTertiary)
    }

    static func badge(_ text: String) -> some View {
        Text(text)
            .font(FitTodayFont.accent(size: 11))
            .tracking(0.5)
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

